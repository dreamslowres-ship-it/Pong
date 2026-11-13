shader_type canvas_item;

// Captura lo que hay detrás del texto en pantalla
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Define tus dos colores en formato HEX (por defecto blanco y negro)
uniform vec4 color_a : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Equivalente a blanco
uniform vec4 color_b : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Equivalente a negro

void fragment() {
    // Obtenemos la opacidad y forma de la letra del Label
    vec4 text_color = texture(TEXTURE, UV);
    
    // Obtenemos el color de lo que hay justo detrás (la animación)
    vec3 background_color = texture(screen_texture, SCREEN_UV).rgb;
    
    // Calculamos el brillo del fondo para saber cuándo cambiar de color
    float brightness = dot(background_color, vec3(0.299, 0.587, 0.114));
    
    // Mezclamos entre tu Color A y tu Color B basándonos en el fondo
    vec3 final_color = mix(color_a.rgb, color_b.rgb, step(0.5, brightness));
    
    // Aplicamos el color manteniendo la transparencia de la letra
    COLOR = vec4(final_color, text_color.a);
}
