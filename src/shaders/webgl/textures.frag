#version 300 es

precision highp float;

layout(std140) uniform GlobalData {
    float time;
};

uniform sampler2D tex;

in vec4 vColor;
in vec2 vTexCords;

out vec4 frag_colour;

void main() {
    frag_colour = texture(tex, vTexCords) * vColor;    
}
