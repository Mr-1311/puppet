#include <flutter/runtime_effect.glsl>

#define PI 3.1415926538

uniform vec2 uSize;
uniform float uSectionSize;
uniform float uHoveredSection;

out vec4 fragColor;

vec2 rotatePoint(vec2 point, float angle) {
    float s = sin(angle);
    float c = cos(angle);

    mat2 rotationMatrix = mat2(c, -s, s, c);

    return rotationMatrix * point;
}

vec4 getSeperator(vec2 uv, vec2 p1, vec2 p2, vec4 color )
{
    float t = uSize.x * 0.000008;
    vec2 pa = uv - p1;
    vec2 ba = p2 - p1;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    float d = length( pa - ba*h );
    
    float tScale = length(uv - p2) / length(ba);
    t *= clamp(tScale + 0.3, 0., 1.); 
    
    return smoothstep(t, t * 0.50, d ) * color;
}

vec4 getBackground(vec2 uv, vec4 color) {
    float dist = length(uv);
    float radius = 0.5;
    
    float circleBackgroundMask = smoothstep(radius, radius-0.006, dist);
    return color * circleBackgroundMask;
}

vec4 getHovered(vec2 uv, vec4 color) {
    float sectionAngle = 2 * PI / uSectionSize;
    float hoveredSectionBegin = sectionAngle * uHoveredSection - sectionAngle;
    float hoveredSectionEnd = sectionAngle * uHoveredSection;

    // angle of current pixel
    float angle = atan(uv.y, uv.x);
    if (angle < 0) {
        // remap bottom angle from (-PI - 0) to (PI - 2PI) left to right
        angle += 2 * PI; 
    }
    
    // is angle > sectionBegin and angle < sectionEnd
    float hoveredMask = step(hoveredSectionBegin, angle) * step(angle, hoveredSectionEnd);
    return color * hoveredMask;
}

void main(void) {
    vec4 col = vec4(0.);

    // normalize
    vec2 uv = FlutterFragCoord().xy / uSize;
    // make origin the center
    uv -= vec2(0.5);
    uv.y = -uv.y;
    
    // rescale uv to make circle as big as possible and fully visible,
    // if window will always be square then this can be deleted
    if (uSize.x > uSize.y) {
        uv.x *= uSize.x / uSize.y;
    } else {
        uv.y *= uSize.y / uSize.x;
    }
    
    vec4 background = getBackground(uv, vec4(.6, .9, .7, 1.));
    col = mix(col, background, background.a);
    
    vec4 hovered = getHovered(uv, vec4(.9, .6, .6, 1.));   
    col = mix(col, hovered, hovered.a * col.a);

// fix lines
    // float sectionAngle = 2 * PI / uSectionSize;
    // int a = sectionAngle / (2*PI);
    // vec2 sepPoint = vec2(.4, .0);
    // vec4 seperatorColor = vec4(1., 0., 0., 1.);
    // vec4 sep = getSeperator(uv, vec2(.0, .0), sepPoint, seperatorColor);
    // for(int i = 0; i < a; i++) {
    //    sep += getSeperator(uv, vec2(.0, .0), rotatePoint(sepPoint, sectionAngle * (i+1)), seperatorColor);
    // }
    // col = mix(col, sep, sep.a);
    
    fragColor = col;
}