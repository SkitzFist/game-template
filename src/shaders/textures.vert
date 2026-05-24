#version 420 core

layout(std140, binding = 0) uniform GlobalData {
    float time;
};

layout(location = 0) in vec2 vp;
layout(location = 1) in vec4 aColor;
layout(location = 2) in vec2 aTexCords;

out vec4 vColor;
out vec2 vTexCords;

void main() {
    gl_Position = vec4(vp, 0.0, 1.0);
    vColor = aColor;
    vTexCords = aTexCords;
}
