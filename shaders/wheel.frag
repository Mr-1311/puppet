#include <flutter/runtime_effect.glsl>

#define PI 3.1415926538

uniform vec2 uSize;
uniform float uSectionSize;
uniform float uHoveredSection;

out vec4 fragColor;

void main(void) {
    vec4 col = vec4(0);

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
    
    float dist = length(uv);
    float radius = 0.5;
    
    float circleBackground = smoothstep(radius, radius-0.006, dist);
    col = vec4(circleBackground);
    
    float sectionAngle = 2 * PI / uSectionSize;
    float hoveredSectionBegin = sectionAngle * uHoveredSection - sectionAngle;
    float hoveredSectionEnd = sectionAngle * uHoveredSection;

    // angle of current pixel
    float angle = atan(uv.y, uv.x);
    if (angle < 0) {
        // remap bottom angle from (-PI - 0) to (PI - 2PI) left to right
        angle += 2 * PI; 
    }
    
    // hovered section color
    if (angle > hoveredSectionBegin && angle < hoveredSectionEnd) {
        col *= vec4(0, 0, 1, 1);
    }

    fragColor = col;
}