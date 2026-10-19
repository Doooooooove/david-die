shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float amount = 0.0;
void fragment() {
    vec2 step_size = SCREEN_PIXEL_SIZE * amount;
    vec4 col = texture(screen_texture, SCREEN_UV) * 0.2;
    col += texture(screen_texture, SCREEN_UV + vec2(step_size.x, 0.0)) * 0.12;
    col += texture(screen_texture, SCREEN_UV - vec2(step_size.x, 0.0)) * 0.12;
    col += texture(screen_texture, SCREEN_UV + vec2(0.0, step_size.y)) * 0.12;
    col += texture(screen_texture, SCREEN_UV - vec2(0.0, step_size.y)) * 0.12;
    col += texture(screen_texture, SCREEN_UV + step_size) * 0.08;
    col += texture(screen_texture, SCREEN_UV - step_size) * 0.08;
    col += texture(screen_texture, SCREEN_UV + vec2(step_size.x, -step_size.y)) * 0.08;
    col += texture(screen_texture, SCREEN_UV + vec2(-step_size.x, step_size.y)) * 0.08;
    COLOR = col;
}
