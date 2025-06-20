#version 460 core

precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

// Pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Generate star position and properties
vec3 getStar(int index) {
    vec2 seed = vec2(float(index) * 0.1, float(index) * 0.2);
    float x = random(seed) * 2.0 - 1.0;
    float y = random(seed + vec2(1.0, 0.0)) * 2.0 - 1.0;
    float z = random(seed + vec2(0.0, 1.0)) * 0.8 + 0.2; // depth 0.2 to 1.0
    return vec3(x, y, z);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    
    vec3 color = vec3(0.0);
    float time = mod(u_time, 8.0); // 8 second loop
    
    // Render 200 stars
    for (int i = 0; i < 200; i++) {
        vec3 star = getStar(i);
        
        // Animate star movement toward center with time offset
        float timeOffset = random(vec2(float(i) * 0.3, float(i) * 0.7)) * 8.0;
        float animTime = mod(time + timeOffset, 8.0);
        float progress = animTime / 8.0;
        
        // Move star toward center and forward
        vec2 starPos = star.xy * (1.0 - progress * 0.7);
        float starDepth = star.z + progress * 2.0;
        
        // Perspective scaling
        float scale = 1.0 / (starDepth + 0.1);
        starPos *= scale;
        
        // Distance from current pixel to star
        float dist = length(uv - starPos);
        
        // Star size based on depth and animation
        float starSize = (0.002 + 0.008 * (1.0 - star.z)) * scale;
        
        // Star brightness with fade in/out
        float brightness = 1.0 - smoothstep(0.0, starSize, dist);
        brightness *= smoothstep(0.0, 0.2, progress) * smoothstep(1.0, 0.8, progress);
        
        // Add glow effect when alpha > 0.5
        if (brightness > 0.5) {
            float glowSize = starSize * 3.0;
            float glow = 1.0 - smoothstep(0.0, glowSize, dist);
            glow *= 0.3 * (brightness - 0.5) * 2.0;
            brightness += glow;
        }
        
        // Star color - slightly blue-white
        vec3 starColor = vec3(0.9, 0.95, 1.0) * brightness;
        color += starColor;
    }
    
    fragColor = vec4(color, 1.0);
}
