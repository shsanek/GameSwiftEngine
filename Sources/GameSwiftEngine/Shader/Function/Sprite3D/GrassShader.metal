#include "BaseStruct.h"

struct GrassInfo {
    int lowPoly;
    int hightPoly;
    int hightPolyCount;
    float maxHeight;

    float density;

    float windForce;
    float windNoiseScale;
};

struct GrassVertex {
    float3 position;
    float2 uv;
    short atlas;
};

struct GrassRasterizerData {
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
};

constant float pi = 3.141592;

float rand(float2 co){
    return fract(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}

float4 rotateY(float4 vector, float alpha) {
    float cosAlpha = cos(alpha);
    float sinAlpha = sin(alpha);

    float x = cosAlpha * vector.x - sinAlpha * vector.z;
    float z = sinAlpha * vector.x + cosAlpha * vector.z;


    // Умножение вектора на матрицу поворота
    return float4(x, vector.y, z, 1);
}

float2 cubicBezier(float t, float2 p0, float2 p1, float2 p2, float2 p3) {
    float a = 1.0 - t;
    float b = a * a;
    return a * b * p0 + 3 * b * t * p1 + 3 * a * t * t * p2 + t * t * t * p3;
}

float perlin(float2 P) {
    float2 i = floor(P);
    float2 f = fract(P);

    // Запомним градиенты в углах ячейки
    float a = rand(i);
    float b = rand(i + float2(1.0, 0.0));
    float c = rand(i + float2(0.0, 1.0));
    float d = rand(i + float2(1.0, 1.0));

    // Интерполяция градиентов
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float angleBetweenVectors(float2 A, float2 B) {
    float dotProduct = dot(A, B);
    float lengthA = length(A);
    float lengthB = length(B);
    return acos(dotProduct / (lengthA * lengthB));
}

float angleBetweenVectors(float2 A) {
    float2 a = normalize(A);
    return atan2(a.y, a.x) - atan2(-1.0, 0.0);
}

vertex RasterizerData grassVertexShader(
    uint vertexID [[ vertex_id ]],
    constant float4x4 *projectionMatrix [[ buffer(0) ]],
    constant float4x4 *positionMatrix [[ buffer(1) ]],
    constant GrassInfo *info [[ buffer(2) ]],
    constant GrassVertex *lowPoly [[ buffer(3) ]],
    constant GrassVertex *hightPoly [[ buffer(4) ]],
    constant float *time [[ buffer(5) ]]
)
{
    GrassVertex current;
    float positionIn = 0;
    if (int(vertexID) >= info->hightPolyCount) {
        positionIn = (vertexID - info->hightPolyCount) / info->lowPoly * 7 + info->hightPolyCount / info->hightPoly;
        current = lowPoly[(vertexID - info->hightPolyCount) % info->lowPoly];
    } else {
        positionIn = vertexID / info->hightPoly;
        current = hightPoly[(vertexID % info->hightPoly)];
    }
    float minSize = floor(sqrt(float(positionIn)));
    float nextR = ceil(minSize / 2) * 2 + 1;
    float nextS = nextR * nextR;
    int index = int(nextS - float(positionIn)) - 1;
    int shift = int(nextR) / 2;
    int x = 0;
    int y = 0;

    if (index % 2 == 0) {
        x = shift;
        y = shift - index / 4;
    } else {
        x = -shift + index / 4;
        y = shift;
    }

    int rx = x;
    int ry = y;

    if ((index / 2) % 2 == 0) {
        rx = -x;
        ry = -y;
    }

    float2 globalPosition = float2(rx, ry);
    float sx = rand(globalPosition);
    float sy = rand(-globalPosition);


    RasterizerData out;
    float4 localPosition = float4(current.position, 1);
    float4 windPosition = localPosition;
    float t = localPosition.y / info->maxHeight;

    float2 wind = float2(0.0, 1);
    float windAnge = angleBetweenVectors(wind);
    float strongWind = perlin(globalPosition / 20 * info->windNoiseScale + *time * wind * info->windNoiseScale) * info->windForce;

    float bezierMoveY = cos(*time * rand(globalPosition) * 5 + rand(globalPosition)) * 0.1 * (strongWind + info->windForce);

    float2 base = cubicBezier(
        t,
        float2(0,0),
        float2(0.25, 0.25),
        float2(1 - 0.25, 1 - 0.25),
        float2(1 + bezierMoveY, 1 - bezierMoveY)
    );
    float h = (-rand(globalPosition) * 0.2) + info->maxHeight;
    localPosition.z = base.x * (h / 2);
    localPosition.y = base.y * h;
    localPosition = rotateY(localPosition, rand(globalPosition * 10) * 2 * pi);


    windPosition.z = base.x * (h);
    windPosition.y = base.y * (h / 2);
    windPosition = rotateY(windPosition, windAnge);


    localPosition = localPosition * (1 - strongWind) + windPosition * strongWind;

    localPosition.x += float(rx + sx) * info->density;
    localPosition.z += float(ry + sy) * info->density;
    float4 position = (*positionMatrix) * localPosition;
    out.clipSpacePosition = (*projectionMatrix) * position;
    out.realPosition = position.xyz;
    out.textureCoordinate = current.uv;
    out.atlas = current.atlas;
    return out;
}


struct ObjectOut
{
    float3 position;
};

[[object]]
void meshShaderObjectStageFunction(
        object_data ObjectOut& payload            [[payload]],
        mesh_grid_properties meshGridProperties,
        constant float4x4*   cameraPositionMatrix         [[buffer(0)]],
        constant float4x4*   positionMatrix           [[buffer(1)]],
        constant GrassInfo *info [[ buffer(2) ]],
        uint2                 positionInGrid       [[threadgroup_position_in_grid]]
)
{
    payload.position = float3(positionInGrid.x, positionInGrid.y, 0);

    float4 localPosition = float4(positionInGrid.x, 0, positionInGrid.y, 1);
    float4 position = (*positionMatrix) * (localPosition * info->density);
    float4 pos = (*cameraPositionMatrix) * position;
    float z = -pos.z;

    if (z < -1) {
        meshGridProperties.set_threadgroups_per_grid(uint3(0, 0, 0));
        return;
    }
    
    float dist = 10;

    if (z <= dist / 16) {
        meshGridProperties.set_threadgroups_per_grid(uint3(16, 1, 1));
        return;
    } else if (z >= dist) {
        meshGridProperties.set_threadgroups_per_grid(uint3(1, 1, 1));
        return;
    }

    float lod = 1 / ((z / dist));


    meshGridProperties.set_threadgroups_per_grid(uint3(lod, 1, 1));
}

using TriangleMeshType = metal::mesh<RasterizerData, void, 96, 16, metal::topology::triangle>;

[[mesh]]
void meshShaderMeshStageFunction(
    TriangleMeshType output,
    const object_data ObjectOut& payload [[payload]],
    constant float4x4 *projectionMatrix [[ buffer(0) ]],
    constant float4x4 *positionMatrix [[ buffer(1) ]],
    constant GrassInfo *info [[ buffer(2) ]],
    constant GrassVertex *lowPoly [[ buffer(3) ]],
    constant GrassVertex *hightPoly [[ buffer(4) ]],
    constant float *time [[ buffer(5) ]],
    uint lid [[thread_index_in_threadgroup]],
    uint tid [[threadgroup_position_in_grid]]
)
{
    GrassVertex current;

    output.set_primitive_count(info->hightPoly / 3);

    if (lid < uint(info->hightPoly / 3)) {
        uint i = (3*lid);
        output.set_index(i+0, i+0);
        output.set_index(i+1, i+1);
        output.set_index(i+2, i+2);
    }

    if (lid >= uint(info->hightPoly)) {
        return;
    }
    current = hightPoly[lid];

    float rx = payload.position.x * 4 + tid / 4;
    float ry = payload.position.y * 4 + tid % 4;

    float2 globalPosition = float2(rx, ry);
    float sx = rand(globalPosition);
    float sy = rand(-globalPosition);


    RasterizerData out;
    float4 localPosition = float4(current.position, 1);
    float4 windPosition = localPosition;
    float t = localPosition.y / info->maxHeight;

    float2 wind = float2(0.0, 1);
    float windAnge = angleBetweenVectors(wind);
    float strongWind = perlin(globalPosition / 20 * info->windNoiseScale + *time * wind * info->windNoiseScale) * info->windForce;

    float bezierMoveY = cos(*time * rand(globalPosition) * 5 + rand(globalPosition)) * 0.1 * (strongWind + info->windForce);

    float2 base = cubicBezier(
        t,
        float2(0,0),
        float2(0.25, 0.25),
        float2(1 - 0.25, 1 - 0.25),
        float2(1 + bezierMoveY, 1 - bezierMoveY)
    );
    float h = (-rand(globalPosition) * 0.2) + info->maxHeight;
    localPosition.z = base.x * (h / 2);
    localPosition.y = base.y * h;
    localPosition = rotateY(localPosition, rand(globalPosition * 10) * 2 * pi);


    windPosition.z = base.x * (h);
    windPosition.y = base.y * (h / 2);
    windPosition = rotateY(windPosition, windAnge);

    localPosition = localPosition * (1 - strongWind) + windPosition * strongWind;

    localPosition.x += float(rx + sx) * info->density;
    localPosition.z += float(ry + sy) * info->density;
    float4 position = (*positionMatrix) * localPosition;
    out.clipSpacePosition = (*projectionMatrix) * position;
    out.realPosition = position.xyz;
    out.textureCoordinate = current.uv;
    out.atlas = current.atlas;

    output.set_vertex(lid, out);
}
