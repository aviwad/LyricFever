//
//  MulticolorGradientShader.metal
//  RandomPathAinmation
//
//  Created by Alexey Vorobyov on 09.09.2023.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    int32_t pointCount;
    float bias;
    float power;
    float noise;
    float2 points[8];
    float3 colors[8];
} Uniforms;

float2 hash23(float3 p3) {
    p3 = fract(p3 * float3(443.897, 441.423, .0973));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}


[[ stitchable ]] half4 gradient(
    float2 position,
    half4 currentColor,
    float4 box,
    constant Uniforms& uniforms [[buffer(0)]],
    int size_in_bytes
) {
    float2 size = box.zw;
    float2 noise = hash23(float3(position / float2(size.x, size.x), 0));
    float2 uv = (position + float2(sin(noise.x * 2 * M_PI_F), sin(noise.y * 2 * M_PI_F)) * uniforms.noise) / float2(size.x, size.x);

    float totalContribution = 0.0;
    float contribution[8];
    
    // Compute contributions
    for (int i = 0; i < uniforms.pointCount; i++) {
        float2 pos = uniforms.points[i] * float2(1.0, float(size.y) / float(size.x));
        pos = uv - pos;
        float dist = length(pos);
        float c = 1.0 / (uniforms.bias + pow(dist, uniforms.power));
        contribution[i] = c;
        totalContribution += c;
    }
    
    // Contributions normalisation
    float3 col = float3(0, 0, 0);
    float inverseContribution = 1.0 / totalContribution;
    for (int i = 0; i < uniforms.pointCount; i++) {
        col += contribution[i] * inverseContribution * uniforms.colors[i];
    }
    return half4(half3(col), 1.0);
}
