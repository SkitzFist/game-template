#version 420 core

layout(std140, binding = 0) uniform GlobalData {
    float time;
};

in vec4 vColor;
in vec2 vLocal;
in vec2 vHalfSize;
in float vRadius;

out vec4 frag_colour;

float roundedRectSDF(vec2 p, vec2 halfSize, float radius)
{
    vec2 q = abs(p) - halfSize + vec2(radius);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void main() {
    float maxRadius = min(vHalfSize.x, vHalfSize.y);
    float radius = clamp(vRadius, 0.0, 1.0) * maxRadius;

    vec2 p = vLocal;
    float distance = roundedRectSDF(p, vHalfSize, radius);
    
    float aa = max(fwidth(distance), 0.001);
    float alpha = 1.0 - smoothstep(0.0, aa, distance);

    frag_colour = vec4(vColor.rgb, vColor.a * alpha);
}
