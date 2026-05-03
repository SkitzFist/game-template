#version 410 core

layout(location = 0) in vec2 vp;
layout(location = 1) in vec4 aColor;
layout(location = 2) in vec2 aLocal;
layout(location = 3) in float aRadius;

out vec4 vColor;
out vec2 vLocal;
out vec2 vHalfSize;
out float vRadius;

void main() {
    gl_Position = vec4(vp, 0.0, 1.0);
    vColor = aColor;
    vLocal = aLocal;
    vHalfSize = abs(aLocal);
    vRadius = aRadius;
}
