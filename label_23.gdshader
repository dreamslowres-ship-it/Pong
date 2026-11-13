shader_type canvas_item;

uniform float velocidad_barrido : hint_range(0.1, 5.0) = 1.5; 
uniform float ancho_barrido     : hint_range(0.01, 0.5) = 0.1; 
uniform float intensidad_brillo : hint_range(0.1, 3.0) = 1.5; 
uniform vec4  color_brillo      : source_color = vec4(1.0, 1.0, 1.0, 1.0); 

void fragment() {
    vec4 letra = texture(TEXTURE, UV);
    
    float pos_luz = fract(TIME * velocidad_barrido);
    float distancia = abs(UV.x - pos_luz);
    
    float nucleo = 1.0 - smoothstep(0.0, ancho_barrido, distancia);
    float halo = 1.0 - smoothstep(0.0, ancho_barrido * 2.5, distancia);
    
    float brillo_total = (halo * 0.4 + nucleo) * intensidad_brillo;
    
    // 🔥 FIX: Sumamos el brillo y lo limitamos a 1.0 (Blanco máximo)
    letra.rgb += color_brillo.rgb * brillo_total;
    letra.rgb = clamp(letra.rgb, 0.0, 1.0); 
    
    COLOR = letra * COLOR;
}