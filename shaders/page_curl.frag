#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uProgress;
uniform vec2 uTouch;
uniform float uRadius;
uniform float uAngle;
uniform sampler2D uCurrentPage;
uniform sampler2D uNextPage;

out vec4 fragColor;

const float PI = 3.14159265358979323846;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    float progress = clamp(uProgress, 0.0, 1.0);
    if (progress <= 0.0001) {
        fragColor = texture(uCurrentPage, uv);
        return;
    }
    if (progress >= 0.9999) {
        fragColor = texture(uNextPage, uv);
        return;
    }

    float r = clamp(uRadius, 0.04, 0.35);
    float curlOrigin = (1.0 + PI * r) * (1.0 - progress) - PI * r * progress;

    // Angle of curl line
    float angle = uAngle;
    vec2 dir = vec2(cos(angle), sin(angle));

    // Distance from the curl line
    vec2 curlPoint = vec2(curlOrigin, 0.5);
    float dist = dot(uv - curlPoint, dir);

    if (dist < 0.0) {
        // Flat, uncurled portion of current page
        vec4 baseColor = texture(uCurrentPage, uv);

        // Soft drop shadow cast by the curled page flap
        float shadowDist = -dist;
        if (shadowDist < PI * r * 1.5) {
            float shadowIntensity = (1.0 - shadowDist / (PI * r * 1.5)) * 0.35;
            baseColor.rgb *= (1.0 - shadowIntensity);
        }

        fragColor = baseColor;
        return;
    }

    if (dist >= PI * r) {
        // Completely exposed area revealing the next page underneath
        vec4 nextColor = texture(uNextPage, uv);

        // Soft inner shadow where the curl meets the next page
        float underShadowDist = dist - PI * r;
        if (underShadowDist < 0.15) {
            float shadowFactor = smoothstep(0.0, 0.15, underShadowDist);
            nextColor.rgb *= mix(0.70, 1.0, shadowFactor);
        }

        fragColor = nextColor;
        return;
    }

    // Inside the rolling cylinder region
    float angleOnCylinder = dist / r;
    
    if (angleOnCylinder < PI * 0.5) {
        // Front side curving upward into the cylinder
        float projectedDist = sin(angleOnCylinder) * r;
        vec2 mappedUv = uv - dir * (dist - projectedDist);
        mappedUv = clamp(mappedUv, 0.0, 1.0);

        vec4 frontColor = texture(uCurrentPage, mappedUv);

        // Dynamic specular highlight on the peak of the curl cylinder
        float specular = pow(sin(angleOnCylinder), 3.0) * 0.18;
        frontColor.rgb += vec3(specular);

        // Slight shadow at the base of the curl
        float baseShadow = cos(angleOnCylinder);
        frontColor.rgb *= mix(0.85, 1.0, baseShadow);

        fragColor = frontColor;
    } else {
        // Back side of the curled page (curving back down and mirrored)
        float flatDist = PI * r - dist;
        vec2 backUv = uv + dir * (dist + flatDist);
        backUv.x = 1.0 - backUv.x; // Mirrored horizontally for paper back
        backUv = clamp(backUv, 0.0, 1.0);

        vec4 backColor = texture(uCurrentPage, backUv);

        // Paper translucency & bleed-through: blend with pure paper tone
        vec3 paperBase = vec3(0.96, 0.95, 0.93);
        backColor.rgb = mix(paperBase, backColor.rgb, 0.28);

        // Lighting gradient across the back curve
        float backLighting = sin(angleOnCylinder);
        backColor.rgb *= mix(0.75, 1.05, backLighting);

        fragColor = backColor;
    }
}
