/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>

using namespace metal;

struct RasterizerData
{
    float4 clipSpacePosition [[position]];
    float3 realPosition;
    float2 textureCoordinate;
    short atlas;
};

struct BoneBind {
    int index;
    float width;
};

struct InputVertex {
    float3 position;
    float2 uv;

    BoneBind boneA;
    BoneBind boneB;
    BoneBind boneC;
    BoneBind boneD;

    short atlas;
};

struct InputAtlas {
    float2 uvPosition;
    float2 uvSize;
};

struct Light {
    float3 position;
    float3 color;
    float power;
    float ceilStep;
    float3 direction;
    float angle;
    float attenuationAngle;
    float4x4 shadowProjection;
    int shadowMap;
    float shadowShiftZ;
    float shadowScaleZ;
};

struct ShadowInfo {
    float shadowMapSize;
    int shadowSoftWidth;
    float shadowSoftSize;
};

vertex RasterizerData
sprite3DVertexShader(
                     uint vertexID [[ vertex_id ]],
                     constant float4x4 *projectionMatrix [[ buffer(0) ]],
                     constant float4x4 *positionMatrix [[ buffer(1) ]],
                     constant InputVertex *input [[ buffer(2) ]],
                     constant float4x4 *bones [[ buffer(3) ]],
                     constant int *numberOfBones [[ buffer(4) ]]
                     )

{
    InputVertex current = input[vertexID];
    RasterizerData out;
    float4 localPosition = float4(current.position, 1);
    if (current.boneA.index > 0 && *numberOfBones > 0) {
        float4 updatePosition = float4(0, 0, 0, 0);

        updatePosition += (bones[current.boneA.index] * localPosition) * current.boneA.width;
        updatePosition += (bones[current.boneB.index] * localPosition) * current.boneB.width;
        updatePosition += (bones[current.boneC.index] * localPosition) * current.boneC.width;
        updatePosition += (bones[current.boneD.index] * localPosition) * current.boneD.width;

        updatePosition.w = 1;
        localPosition = updatePosition;
    }
    float4 position = (*positionMatrix) * localPosition;
    out.clipSpacePosition = (*projectionMatrix) * position;
    out.realPosition = position.xyz;
    out.textureCoordinate = current.uv;
    out.atlas = current.atlas;
    return out;
}

float4
light3DFragmentShader(
                       RasterizerData  in,
                       float4 colorSample,
                       texture2d<half> colorTexture,
                       depth2d_array<float, access::sample> shadows,
                       constant Light *lights,
                       constant int *numberOfLights,
                       constant ShadowInfo *shadowInfo
                       )
{
    constexpr sampler linerSampler (mag_filter::linear,
                                    min_filter::linear);

    const int shadowWidth = (*shadowInfo).shadowSoftWidth;
    const float shadowSize = (*shadowInfo).shadowSoftSize;
    const float shadowMapSize = (*shadowInfo).shadowMapSize;
    // Light
    float4 light = float4(0, 0, 0, 1);
    for (int i = 0; i < *numberOfLights; i++) {
        float3 direction = in.realPosition - lights[i].position;
        float lng = length(direction);
        float ceilStep = lights[i].ceilStep;
        direction = normalize(direction);
        float power = lights[i].power / lng / lng;
        float angle = acos(dot(lights[i].direction, direction));
        float lightAngle = lights[i].angle;
        float attenuationAngle = lights[i].attenuationAngle;
        if (lightAngle > 0) {
            if (angle < lightAngle) {
                power = power;
            } else if (angle < lightAngle + attenuationAngle) {
                float power2 = (attenuationAngle - (angle-lightAngle)) / attenuationAngle;
                power = power * power2 * power2;
            } else {
                power = 0;
            }
        }
        if (ceilStep > 0) {
            lng = ceil(power / ceilStep) * power;
        }
        if (lights[i].shadowMap > -1 && power > 0.001) {
            float shadowTotal = 0;
            float4 position = lights[i].shadowProjection * float4(in.realPosition, 1);
            float2 cordinate = position.xy / position.w;
            cordinate.y = -cordinate.y / 2 + 0.5;
            cordinate.x = cordinate.x / 2 + 0.5;
            /// maby position.z * m[2][2]
            float posiztionZ = (position.z + lights[i].shadowShiftZ) / position.w;
            for (int x = -shadowWidth; x <= shadowWidth; x++) {
                for (int y = -shadowWidth; y <= shadowWidth; y++) {
                    float2 shift = float2(x, y);
                    float zLight = float(shadows.sample(linerSampler, cordinate + shift / shadowMapSize, lights[i].shadowMap));
                    if (posiztionZ > zLight) {
                        shift = shift / shadowWidth;
                        shadowTotal += 2 - (shift.x * shift.x + shift.y * shift.y);
                    }
                }
            }
            power = power * (1 - shadowTotal / shadowSize);
        }
        float3 color = lights[i].color * power;
        light = light + float4(color, 1);
    }
    if (*numberOfLights > 0) {
        colorSample = colorSample * light;
    }
    return float4(colorSample);
}

fragment float4
sprite3DFragmentShader(
                       RasterizerData  in           [[stage_in]],
                       texture2d<half> colorTexture [[ texture(0) ]],
                       depth2d_array<float, access::sample> shadows [[ texture(1) ]],
                       constant Light *lights [[ buffer(0) ]],
                       constant int *numberOfLights [[ buffer(1) ]],
                       constant ShadowInfo *shadowInfo [[ buffer(2) ]]
                       )
{

    constexpr sampler nearestSampler (mag_filter::nearest,
                                      min_filter::nearest);
    float4 colorSample = float4(colorTexture.sample (nearestSampler, in.textureCoordinate));

    return light3DFragmentShader(in, colorSample, colorTexture, shadows, lights, numberOfLights, shadowInfo);
}

fragment float4
sprite3DAtlasFragmentShader(
                       RasterizerData  in           [[stage_in]],
                       texture2d<half> colorTexture [[ texture(0) ]],
                       depth2d_array<float, access::sample> shadows [[ texture(1) ]],
                       constant Light *lights [[ buffer(0) ]],
                       constant int *numberOfLights [[ buffer(1) ]],
                       constant ShadowInfo *shadowInfo [[ buffer(2) ]],
                       constant InputAtlas *atlas [[ buffer(3) ]]
                       )
{

    constexpr sampler nearestSampler (mag_filter::nearest,
                                      min_filter::nearest);
    float2 uv = in.textureCoordinate;
    InputAtlas current = atlas[in.atlas];

    uv.x = fract(uv.x) * current.uvSize.x + current.uvPosition.x;
    uv.y = fract(uv.y) * current.uvSize.y + current.uvPosition.y;
//    uv.x =
//    uv.y =

    //float2 uv2 = float2(uv.y, uv.x);

    float4 colorSample = float4(colorTexture.sample (nearestSampler, uv));
//    colorSample.r = uv.x;
//    colorSample.g = uv.y;
//    colorSample.b = 0;

    return light3DFragmentShader(in, colorSample, colorTexture, shadows, lights, numberOfLights, shadowInfo);
}


fragment float4
sprite3DMirrorFragmentShader(
                       RasterizerData  in           [[stage_in]],
                       texture2d<half> colorTexture [[ texture(0) ]]
                       )
{
    constexpr sampler nearestSampler (mag_filter::nearest,
                                      min_filter::nearest);
    float4 colorSample = float4(colorTexture.sample (nearestSampler, in.textureCoordinate));

    return colorSample;
}

struct FragmentShaderOut {
    float depth [[depth(any)]];
    half4 color [[color(0)]];
};

fragment FragmentShaderOut
simpleGizmoTextureFragmentShader(
                       RasterizerData  in           [[stage_in]],
                       texture2d<half> texture [[ texture(0) ]]
                       )
{
    constexpr sampler nearestSampler (mag_filter::nearest, min_filter::nearest);

    float4 colorSample = float4(texture.sample (nearestSampler, in.textureCoordinate));

    FragmentShaderOut out;
    out.depth = 0;
    out.color = half4(colorSample);

    if (colorSample.w < 0.01) {
        out.depth = 1;
        out.color = half4(0, 0, 0, 0);
    }

    return out;
}

fragment float4 sprite3DEmptyFragmentShader(RasterizerData in [[stage_in]] ){
    return float4( 0, 0, 0, 0);
}


struct ObjectInfo {
    float4x4 modelMatrix;
    unsigned int textureIndex;
};

vertex RasterizerData
array3DVertexShader(
                     uint vertexID [[ vertex_id ]],
                     constant float4x4 *projectionMatrix [[ buffer(0) ]],
                     constant ObjectInfo *infos [[ buffer(1) ]],
                     constant InputVertex *input [[ buffer(2) ]],
                     constant float4x4 *bones [[ buffer(3) ]],
                     constant int *numberOfBones [[ buffer(4) ]],
                     constant unsigned int *indexes [[ buffer(5) ]],
                     constant int *vertexCount [[ buffer(6) ]]
                     )

{
    int objectIndex = vertexID / *vertexCount;

    InputVertex current = input[indexes[vertexID % (*vertexCount)]];
    RasterizerData out;
    float4 localPosition = float4(current.position, 1);
    if (current.boneA.index > 0 && *numberOfBones > 0) {
        float4 updatePosition = float4(0, 0, 0, 0);
        int boneShift = objectIndex * (*numberOfBones);
        updatePosition += (bones[boneShift + current.boneA.index] * localPosition) * current.boneA.width;
        updatePosition += (bones[boneShift + current.boneB.index] * localPosition) * current.boneB.width;
        updatePosition += (bones[boneShift + current.boneC.index] * localPosition) * current.boneC.width;
        updatePosition += (bones[boneShift + current.boneD.index] * localPosition) * current.boneD.width;

        updatePosition.w = 1;
        localPosition = updatePosition;
    }
    float4 position = (infos[objectIndex].modelMatrix) * localPosition;
    out.clipSpacePosition = (*projectionMatrix) * position;
    out.realPosition = position.xyz;
    out.textureCoordinate = current.uv;

    return out;
}
