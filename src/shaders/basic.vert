#version 410 core

layout(location = 0) in vec2 vp;
layout(location = 1) in vec4 vertex_color;

out vec4 color;

void main() {
    gl_Position = vec4(vp, 0.0, 1.0);
    color = vertex_color;
}
