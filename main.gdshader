shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// --- Efectos CRT ---
uniform float scanline_amount  : hint_range(0.0, 1.0) = 0.2; 
uniform float scanline_density : hint_range(50.0, 1000.0) = 300.0; 
uniform float roll_amount : hint_range(0.0, 0.5) = 0.1; 
uniform float roll_speed  : hint_range(0.0, 3.0) = 0.4; 
uniform float roll_width  : hint_range(0.02, 0.3) = 0.1; 

// --- Brillo y Color ---
uniform float brightness : hint_range(0.1, 1.5) = 0.6; // 🔥 MÁS OSCURO POR DEFECTO
uniform float saturation : hint_range(0.0, 2.0) = 1.1; 

void fragment() {
    vec2 uv = SCREEN_UV;
    vec3 color = texture(screen_texture, uv).rgb;

    // Saturación
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(lum), color, saturation);

    // Scanlines
    float scan = sin(uv.y * scanline_density * 3.14159265) * 0.5 + 0.5;
    color *= mix(1.0, scan, scanline_amount);

    // Haz de luz que baja
    float roll_pos = fract(TIME * roll_speed);
    float d = abs(fract(uv.y - roll_pos + 0.5) - 0.5);
    float band = 1.0 - smoothstep(0.0, roll_width, d);
    color *= 1.0 + band * roll_amount;

    // Brillo final
    color *= brightness;

    COLOR = vec4(color, 1.0);
}