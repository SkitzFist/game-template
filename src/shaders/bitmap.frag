#version 420 core

layout(std140, binding = 0) uniform GlobalData {
    float time;
};

uniform sampler2D tex;

in vec4 vColor;
in vec2 vTexCords;

out vec4 frag_colour;

void main() {
    frag_colour = texture(tex, vTexCords).r * vColor;    
}
