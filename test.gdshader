shader_type spatial;

uniform sampler2D base_texture : source_color;

void fragment() {
    vec4 tex_color = texture(base_texture, UV);
    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a;
}
