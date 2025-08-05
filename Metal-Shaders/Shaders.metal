#include <metal_stdlib>
using namespace metal;

// MARK: - Compute Shaders

// Separable Gaussian Blur (Horizontal Pass)
kernel void gaussianBlurHorizontal(texture2d<float, access::read> inputTexture [[texture(0)]],
                                  texture2d<float, access::write> outputTexture [[texture(1)]],
                                  constant float& blurRadius [[buffer(0)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    float4 sum = float4(0.0);
    float totalWeight = 0.0;
    
    for (int i = -int(blurRadius); i <= int(blurRadius); i++) {
        float weight = exp(-(i * i) / (2.0 * blurRadius * blurRadius));
        uint2 samplePos = uint2(gid.x + i, gid.y);
        samplePos.x = clamp(samplePos.x, 0u, uint(inputTexture.get_width() - 1));
        
        sum += inputTexture.read(samplePos) * weight;
        totalWeight += weight;
    }
    
    outputTexture.write(sum / totalWeight, gid);
}

// Separable Gaussian Blur (Vertical Pass)
kernel void gaussianBlurVertical(texture2d<float, access::read> inputTexture [[texture(0)]],
                                texture2d<float, access::write> outputTexture [[texture(1)]],
                                constant float& blurRadius [[buffer(0)]],
                                uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    float4 sum = float4(0.0);
    float totalWeight = 0.0;
    
    for (int i = -int(blurRadius); i <= int(blurRadius); i++) {
        float weight = exp(-(i * i) / (2.0 * blurRadius * blurRadius));
        uint2 samplePos = uint2(gid.x, gid.y + i);
        samplePos.y = clamp(samplePos.y, 0u, uint(inputTexture.get_height() - 1));
        
        sum += inputTexture.read(samplePos) * weight;
        totalWeight += weight;
    }
    
    outputTexture.write(sum / totalWeight, gid);
}

// Edge Detection using Sobel operator
kernel void edgeDetection(texture2d<float, access::read> inputTexture [[texture(0)]],
                         texture2d<float, access::write> outputTexture [[texture(1)]],
                         constant float& edgeStrength [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    float2 texelSize = float2(1.0 / float(inputTexture.get_width()), 1.0 / float(inputTexture.get_height()));
    
    // Sobel kernels
    float3x3 sobelX = float3x3(-1, 0, 1, -2, 0, 2, -1, 0, 1);
    float3x3 sobelY = float3x3(-1, -2, -1, 0, 0, 0, 1, 2, 1);
    
    float4 gx = float4(0.0);
    float4 gy = float4(0.0);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            uint2 samplePos = uint2(gid.x + i, gid.y + j);
            samplePos.x = clamp(samplePos.x, 0u, uint(inputTexture.get_width() - 1));
            samplePos.y = clamp(samplePos.y, 0u, uint(inputTexture.get_height() - 1));
            
            float4 sample = inputTexture.read(samplePos);
            float weightX = sobelX[i + 1][j + 1];
            float weightY = sobelY[i + 1][j + 1];
            
            gx += sample * weightX;
            gy += sample * weightY;
        }
    }
    
    float4 edge = sqrt(gx * gx + gy * gy) * edgeStrength;
    outputTexture.write(edge, gid);
}

// Grayscale filter
kernel void grayscale(texture2d<float, access::read> inputTexture [[texture(0)]],
                     texture2d<float, access::write> outputTexture [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    float4 color = inputTexture.read(gid);
    float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
    outputTexture.write(float4(gray, gray, gray, color.a), gid);
}

// Invert filter
kernel void invert(texture2d<float, access::read> inputTexture [[texture(0)]],
                  texture2d<float, access::write> outputTexture [[texture(1)]],
                  uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    float4 color = inputTexture.read(gid);
    outputTexture.write(float4(1.0 - color.rgb, color.a), gid);
}

// MARK: - Vertex Shaders

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Magnifying glass effect
vertex VertexOut magnifyingGlassVertex(VertexIn in [[stage_in]],
                                      constant float2& center [[buffer(0)]],
                                      constant float& radius [[buffer(1)]],
                                      constant float& strength [[buffer(2)]]) {
    VertexOut out;
    
    float2 uv = in.texCoord;
    float2 delta = uv - center;
    float dist = length(delta);
    
    if (dist < radius) {
        float factor = 1.0 - (dist / radius);
        factor = pow(factor, 2.0);
        uv = center + delta * (1.0 - factor * strength);
    }
    
    out.position = float4(in.position, 1.0);
    out.texCoord = uv;
    
    return out;
}

// Wave distortion
vertex VertexOut waveDistortionVertex(VertexIn in [[stage_in]],
                                     constant float& time [[buffer(0)]],
                                     constant float& frequency [[buffer(1)]],
                                     constant float& amplitude [[buffer(2)]]) {
    VertexOut out;
    
    float2 uv = in.texCoord;
    float wave = sin(uv.x * frequency + time) * amplitude;
    uv.y += wave;
    
    out.position = float4(in.position, 1.0);
    out.texCoord = uv;
    
    return out;
}

// Vertex displacement using sine wave
vertex VertexOut sineDisplacementVertex(VertexIn in [[stage_in]],
                                       constant float& time [[buffer(0)]],
                                       constant float& frequency [[buffer(1)]],
                                       constant float& amplitude [[buffer(2)]]) {
    VertexOut out;
    
    float3 position = in.position;
    float displacement = sin(time + position.x * frequency) * amplitude;
    position.y += displacement;
    
    out.position = float4(position, 1.0);
    out.texCoord = in.texCoord;
    
    return out;
}

// MARK: - Fragment Shaders

// Chromatic aberration
fragment float4 chromaticAberrationFragment(VertexOut in [[stage_in]],
                                          texture2d<float> texture [[texture(0)]],
                                          constant float& aberrationStrength [[buffer(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float2 uv = in.texCoord;
    float2 center = float2(0.5, 0.5);
    float2 direction = normalize(uv - center);
    
    float4 red = texture.sample(textureSampler, uv + direction * aberrationStrength * 0.01);
    float4 green = texture.sample(textureSampler, uv);
    float4 blue = texture.sample(textureSampler, uv - direction * aberrationStrength * 0.01);
    
    return float4(red.r, green.g, blue.b, 1.0);
}

// Tone mapping (Reinhard)
fragment float4 toneMappingFragment(VertexOut in [[stage_in]],
                                  texture2d<float> texture [[texture(0)]],
                                  constant float& exposure [[buffer(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 color = texture.sample(textureSampler, in.texCoord);
    color.rgb *= exposure;
    
    // Reinhard tone mapping
    color.rgb = color.rgb / (1.0 + color.rgb);
    
    return color;
}

// Film grain and vignette
fragment float4 filmGrainFragment(VertexOut in [[stage_in]],
                                 texture2d<float> texture [[texture(0)]],
                                 constant float& time [[buffer(0)]],
                                 constant float& grainStrength [[buffer(1)]],
                                 constant float& vignetteStrength [[buffer(2)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 color = texture.sample(textureSampler, in.texCoord);
    
    // Film grain
    float2 uv = in.texCoord;
    float noise = fract(sin(dot(uv + time, float2(12.9898, 78.233))) * 43758.5453);
    color.rgb += (noise - 0.5) * grainStrength;
    
    // Vignette
    float2 center = float2(0.5, 0.5);
    float dist = length(uv - center);
    float vignette = 1.0 - dist * vignetteStrength;
    vignette = clamp(vignette, 0.0, 1.0);
    color.rgb *= vignette;
    
    return color;
} 