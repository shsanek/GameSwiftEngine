#include <metal_stdlib>

using namespace metal;

struct RasterizerData
{
    float4 clipSpacePosition [[position]];
    float3 realPosition;
    float2 textureCoordinate;
    short atlas;
};
