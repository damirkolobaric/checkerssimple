#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float4 color;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4 color;
    float3 lightPosition;
    float3 cameraPosition;
};

// Background rendering structures
struct BackgroundVertex {
    float3 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct BackgroundVertexOut {
    float4 position [[position]];
    float2 uv;
    float time;
};

struct BackgroundUniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float time;
};

vertex VertexOut vertex_main(Vertex in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    
    float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    out.position = mvp * float4(in.position, 1.0);
    out.worldPosition = (uniforms.modelMatrix * float4(in.position, 1.0)).xyz;
    out.normal = normalize((uniforms.modelMatrix * float4(in.normal, 0.0)).xyz);
    out.color = uniforms.color;
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]]) {
    float3 normal = normalize(in.normal);
    float3 lightDir = normalize(uniforms.lightPosition - in.worldPosition);
    float3 viewDir = normalize(uniforms.cameraPosition - in.worldPosition);
    float3 reflectDir = reflect(-lightDir, normal);
    
    // Ambient
    float ambientStrength = 0.3;
    float3 ambient = ambientStrength * in.color.rgb;
    
    // Diffuse
    float diff = max(dot(normal, lightDir), 0.0);
    float3 diffuse = diff * in.color.rgb;
    
    // Specular
    float specularStrength = 0.5;
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
    float3 specular = specularStrength * spec * float3(1.0, 1.0, 1.0);
    
    float3 result = ambient + diffuse + specular;
    return float4(result, in.color.a);
}

// Background shaders
vertex BackgroundVertexOut background_vertex(BackgroundVertex in [[stage_in]],
                                             constant BackgroundUniforms &uniforms [[buffer(1)]]) {
    BackgroundVertexOut out;
    float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    out.position = mvp * float4(in.position, 1.0);
    out.uv = in.uv;
    out.time = uniforms.time;
    return out;
}

// Hash function for better randomness
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// 2D noise function
float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for cloud-like patterns
float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

fragment float4 background_fragment(BackgroundVertexOut in [[stage_in]]) {
    float2 uv = in.uv;
    float time = in.time * 0.1;
    
    // Dynamic gradient with time-based color shifts
    float colorShift = sin(time * 0.3) * 0.1;
    float3 topColor = float3(0.05 + colorShift, 0.1 + colorShift * 0.5, 0.4);
    float3 midColor = float3(0.15, 0.05, 0.3);
    float3 horizonColor = float3(0.5 + sin(time) * 0.1, 0.2, 0.6 + cos(time * 0.7) * 0.1);
    float3 bottomColor = float3(0.1, 0.05, 0.15);
    
    // Multi-level gradient with animated transitions
    float t1 = smoothstep(0.0, 0.3, uv.y);
    float t2 = smoothstep(0.3, 0.5, uv.y);
    float t3 = smoothstep(0.5, 1.0, uv.y);
    
    float3 color = mix(bottomColor, horizonColor, t1);
    color = mix(color, midColor, t2);
    color = mix(color, topColor, t3);
    
    // Animated nebula clouds
    float2 cloudUV = uv * 3.0 + float2(time * 0.05, time * 0.03);
    float clouds = fbm(cloudUV);
    clouds = smoothstep(0.3, 0.7, clouds);
    float3 cloudColor = float3(0.4, 0.15, 0.5) * clouds * 0.3;
    color += cloudColor * (1.0 - uv.y * 0.5);
    
    // Enhanced star field with multiple layers
    float stars = 0.0;
    for (int i = 0; i < 5; i++) {
        float layer = float(i);
        float2 starUV = uv * (15.0 + layer * 5.0);
        float2 offset = float2(layer * 3.7, layer * 2.3);
        float speed = 0.02 + layer * 0.005;
        
        float2 pos = fract(starUV + offset + time * speed);
        float d = length(pos - 0.5);
        float star = smoothstep(0.08, 0.0, d);
        
        // Star twinkle
        float twinkle = sin(time * 3.0 + layer * 2.0 + hash(starUV + offset) * 6.28) * 0.5 + 0.5;
        stars += star * twinkle * (0.4 + layer * 0.1);
    }
    
    // Add star color variation
    float3 starColor = float3(1.0, 0.95 + sin(time * 2.0) * 0.05, 0.85);
    color += stars * starColor * (0.5 + uv.y * 0.5);
    
    // Shooting stars
    float2 shootingStarUV = uv * 10.0;
    float shootingTime = fract(time * 0.3);
    float2 shootingPos = float2(shootingTime * 2.0 - 0.5, 0.7 + sin(shootingTime * 3.14) * 0.2);
    float shootingDist = length(shootingStarUV - shootingPos * 10.0);
    float shooting = smoothstep(0.3, 0.0, shootingDist) * smoothstep(0.0, 0.1, shootingTime) * smoothstep(1.0, 0.9, shootingTime);
    color += shooting * float3(1.0, 0.9, 0.7) * 0.8;
    
    // Dynamic particle effects
    float particles = 0.0;
    for (int i = 0; i < 3; i++) {
        float layer = float(i);
        float2 particleUV = uv * 8.0 + float2(sin(time * 0.5 + layer), cos(time * 0.3 + layer));
        float particleHash = hash(floor(particleUV) + layer);
        float2 particlePos = fract(particleUV + float2(sin(time * 0.5 + particleHash), cos(time * 0.7 + particleHash)));
        float particleDist = length(particlePos - 0.5);
        particles += smoothstep(0.15, 0.0, particleDist) * 0.2;
    }
    float3 particleColor = float3(0.3, 0.5, 0.9);
    color += particles * particleColor * (1.0 - uv.y * 0.3);
    
    // Animated aurora-like waves
    float auroraY = uv.y - 0.6;
    float auroraWave = sin(uv.x * 10.0 + time * 2.0) * 0.1 + sin(uv.x * 5.0 - time * 1.5) * 0.05;
    float aurora = exp(-abs(auroraY - auroraWave) * 15.0);
    float3 auroraColor1 = float3(0.2, 0.8, 0.6);
    float3 auroraColor2 = float3(0.6, 0.3, 0.9);
    float3 auroraColor = mix(auroraColor1, auroraColor2, sin(time * 0.5 + uv.x * 5.0) * 0.5 + 0.5);
    color += aurora * auroraColor * 0.3;
    
    // Dynamic energy field at horizon
    float energyField = 0.0;
    for (int i = 0; i < 3; i++) {
        float layer = float(i);
        float wave = sin(uv.x * 20.0 + time * (2.0 + layer * 0.5) + layer * 2.0) * 0.02;
        float field = exp(-abs(uv.y - 0.35 + wave) * (20.0 - layer * 3.0));
        energyField += field * (0.3 - layer * 0.08);
    }
    float3 energyColor = float3(0.6 + sin(time) * 0.2, 0.3, 0.8 + cos(time * 0.7) * 0.2);
    color += energyField * energyColor;
    
    // Pulsating glow
    float pulseGlow = sin(time * 2.0) * 0.5 + 0.5;
    float glow = exp(-abs(uv.y - 0.4) * 2.0) * 0.2 * pulseGlow;
    color += float3(0.5, 0.3, 0.7) * glow;
    
    // Enhanced noise for texture
    float detailNoise = noise(uv * 200.0 + time * 0.5);
    color += detailNoise * 0.03;
    
    // Dynamic vignette with breathing effect
    float vignetteStrength = 0.3 + sin(time * 0.5) * 0.05;
    float vignette = smoothstep(0.9, 0.2, length(uv - 0.5));
    color *= vignette * (1.0 - vignetteStrength) + vignetteStrength;
    
    // Depth fog effect
    float depthFog = smoothstep(0.0, 0.3, uv.y);
    color = mix(color * 0.7, color, depthFog);
    
    // Final color enhancement
    color = pow(color, float3(0.95)); // Slight gamma adjustment
    color = clamp(color, 0.0, 1.0);
    
    return float4(color, 1.0);
}

