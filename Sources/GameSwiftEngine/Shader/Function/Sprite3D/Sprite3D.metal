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

    return out;
}

fragment float4
sprite3DFragmentShader(
                       RasterizerData  in           [[stage_in]],
                       texture2d<half> colorTexture [[ texture(0) ]],
                       depth2d_array<float, access::sample> shadows [[ texture(1) ]],
                       constant Light *lights [[ buffer(0) ]],
                       constant int *numberOfLights [[ buffer(1) ]]
                       )
{
    constexpr sampler linerSampler (mag_filter::linear,
                                    min_filter::linear);
    constexpr sampler nearestSampler (mag_filter::nearest,
                                      min_filter::nearest);
    float4 colorSample = float4(colorTexture.sample (nearestSampler, in.textureCoordinate));

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
            float4 position = lights[i].shadowProjection * float4(in.realPosition, 1);
            float2 cordinate = position.xy / position.w;

            cordinate.y = -cordinate.y / 2 + 0.5;
            cordinate.x = cordinate.x / 2 + 0.5;

            float zLight = float(shadows.sample(linerSampler, cordinate, lights[i].shadowMap)) * position.w;
            if (position.z - 0.001 > zLight - lights[i].shadowShiftZ) {
                power = 0;
            }
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

fragment float4 sprite3DEmptyFragmentShader(RasterizerData in [[stage_in]] ){
    return float4( 0, 0, 0, 0);
}
