extends Node2D

signal pelota_lanzada(posicion_salida: Vector2, velocidad_inicial: Vector2)

enum Estado { OCULTO, ENCENDIENDO, GIRANDO, APUNTANDO, DISPARANDO, EN_JUEGO, MENU_ABIERTO }
var estado_actual: Estado = Estado.OCULTO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var zona_tactil: Control = $ZonaTactilCentro

# Distancia desde el centro del lanzador hasta la boca del cañón.
@export var distancia_boca: float = 80.0 

# LISTA DE DIRECCIONES EXACTAS (Frame 0 al 7)
const DIRECCIONES = [
	Vector2(0, -1),  # Frame 0: ⬆️ Arriba
	Vector2(1, -1),  # Frame 1: ↗️ Arriba-Derecha
	Vector2(1, 0),   # Frame 2: ➡️ Derecha (Prohibido)
	Vector2(1, 1),   # Frame 3: ↘️ Abajo-Derecha
	Vector2(0, 1),   # Frame 4: ⬇️ Abajo
	Vector2(-1, 1),  # Frame 5: ↙️ Abajo-Izquierda
	Vector2(-1, 0),  # Frame 6: ⬅️ Izquierda (Prohibido)
	Vector2(-1, -1)  # Frame 7: ↖️ Arriba-Izquierda
]

# UI Pausa
@onready var menu_pausa_panel: Control = $CapaPausa/MenuPausaPanel
@onready var btn_continuar: Button = get_node_or_null("CapaPausa/MenuPausaPanel/VBoxContainer/BtnContinuar")
@onready var btn_home: Button = get_node_or_null("CapaPausa/MenuPausaPanel/VBoxContainer/BtnHome")

# UI Puntajes (Ahora sueltos, sin VBoxContainer)
@onready var label_jugador: Label = get_node_or_null("CapaPausa/LabelJugador")
@onready var label_ia: Label = get_node_or_null("CapaPausa/LabelIA")
var tween_puntajes: Tween = null

const VELOCIDAD_DISPARO: float = 950.0   
const FRAMES_INVALIDOS = [2, 6] 

var historial_clics: Array = []
const TIEMPO_VENTANA_CLICS: float = 0.45 

var frame_disparo: int = 0 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if menu_pausa_panel:
		menu_pausa_panel.visible = false
		
	# Ocultamos los Labels sueltos al inicio
	if label_jugador:
		label_jugador.visible = false
		label_jugador.modulate.a = 0.0
	if label_ia:
		label_ia.visible = false
		label_ia.modulate.a = 0.0
	
	if btn_continuar:
		btn_continuar.pressed.connect(_on_continuar_pressed)
	if btn_home:
		btn_home.pressed.connect(_on_home_pressed)
		
	if zona_tactil:
		zona_tactil.gui_input.connect(_on_zona_tactil_gui_input)
	
	iniciar_secuencia_lanzamiento()

func iniciar_secuencia_lanzamiento() -> void:
	estado_actual = Estado.OCULTO
	if menu_pausa_panel:
		menu_pausa_panel.visible = false
	get_tree().paused = false 
	
	# Animación de apagar (fondo)
	if sprite and sprite.sprite_frames.has_animation("apaga"):
		sprite.play("apaga")
		sprite.stop()
		var ultimo_frame = sprite.sprite_frames.get_frame_count("apaga") - 1
		sprite.frame = ultimo_frame
	
	# Breve pausa antes de encender
	await get_tree().create_timer(0.4).timeout
	
	# Estado: Encendiendo
	estado_actual = Estado.ENCENDIENDO
	if sprite and sprite.sprite_frames.has_animation("enciende"):
		sprite.play("enciende")
		await sprite.animation_finished
		
	# ── ESTADO: GIRANDO (RULETA ALEATORIA) ──
	estado_actual = Estado.GIRANDO
	
	# 1. Elegimos el frame final AL AZAR
	frame_disparo = randi_range(0, 7)
	
	# 2. Si cae en un costado prohibido (2 o 6), lo movemos a la diagonal
	if frame_disparo in FRAMES_INVALIDOS:
		frame_disparo = (frame_disparo + 1) % 8
		
	if sprite:
		# 3. Preparamos el sprite para el giro
		sprite.play("girar")
		sprite.stop() 
		sprite.frame = 0
		
		var vueltas = 3
		var frame_final_absoluto = frame_disparo + (vueltas * 8)
		
		# 4. Tween que obliga a actualizar el frame visualmente paso a paso
		var tween_giro = create_tween()
		tween_giro.tween_method(
			func(valor: float): 
				sprite.frame = wrapi(int(valor), 0, 8),
			0.0, 
			float(frame_final_absoluto), 
			1.2 
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		# Esperamos a que termine el giro
		await tween_giro.finished
	
	# Estado: Apuntando
	estado_actual = Estado.APUNTANDO
	await get_tree().create_timer(0.25).timeout
	
	# Estado: Disparando
	disparar_pelota()

func disparar_pelota() -> void:
	estado_actual = Estado.DISPARANDO
	
	# 1. Obtenemos la dirección desde nuestra lista usando el frame elegido
	var direccion_salida = DIRECCIONES[frame_disparo].normalized()
	var velocidad_inicial = direccion_salida * VELOCIDAD_DISPARO
	
	# 2. Posición de salida
	var posicion_salida = global_position + (direccion_salida * distancia_boca)
	
	# 3. Emitimos la señal al Main
	emit_signal("pelota_lanzada", posicion_salida, velocidad_inicial)
	
	# Animación de ocultamiento
	if sprite and sprite.sprite_frames.has_animation("apaga"):
		sprite.play("apaga")
		await sprite.animation_finished
		
	estado_actual = Estado.EN_JUEGO

# ────────────────────────────────────────────────────────
# FUNCIONES DE UI, PAUSA Y PUNTAJES
# ────────────────────────────────────────────────────────

func _on_zona_tactil_gui_input(event: InputEvent) -> void:
	if estado_actual != Estado.EN_JUEGO:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tiempo_actual = Time.get_ticks_msec() / 1000.0
		historial_clics.append(tiempo_actual)
		
		historial_clics = historial_clics.filter(func(t): return tiempo_actual - t < TIEMPO_VENTANA_CLICS)
		
		if historial_clics.size() >= 3:
			historial_clics.clear()
			abrir_menu_pausa()
		else:
			get_tree().create_timer(TIEMPO_VENTANA_CLICS).timeout.connect(func():
				if historial_clics.size() == 1 and historial_clics[0] == tiempo_actual:
					mostrar_puntajes_temporalmente()
					historial_clics.clear()
			)

# Animación normal (al tocar 1 vez la pantalla para ver los puntos)
func mostrar_puntajes_temporalmente() -> void:
	if not label_jugador or not label_ia:
		return
		
	if tween_puntajes and tween_puntajes.is_running():
		tween_puntajes.kill()
		
	label_jugador.visible = true
	label_ia.visible = true
	
	tween_puntajes = create_tween().set_parallel(true)
	tween_puntajes.tween_property(label_jugador, "modulate:a", 1.0, 0.2)
	tween_puntajes.tween_property(label_ia, "modulate:a", 1.0, 0.2)
	
	tween_puntajes.chain().tween_interval(1.5)
	
	tween_puntajes.chain().tween_property(label_jugador, "modulate:a", 0.0, 0.6)
	tween_puntajes.chain().tween_property(label_ia, "modulate:a", 0.0, 0.6)
	
	tween_puntajes.chain().tween_callback(func(): 
		label_jugador.visible = false
		label_ia.visible = false
	)

# 🔥 ANIMACIÓN AL ANOTAR UN GOL (Llamada desde main.gd)
func mostrar_puntajes_por_gol() -> void:
	if not label_jugador or not label_ia:
		return
		
	if tween_puntajes and tween_puntajes.is_running():
		tween_puntajes.kill()
		
	# Centramos el pivote para que crezca desde el medio
	label_jugador.pivot_offset = label_jugador.size / 2.0
	label_ia.pivot_offset = label_ia.size / 2.0
	
	# Reiniciamos visibilidad y escala
	label_jugador.visible = true
	label_ia.visible = true
	label_jugador.modulate.a = 1.0
	label_ia.modulate.a = 1.0
	label_jugador.scale = Vector2(1.0, 1.0)
	label_ia.scale = Vector2(1.0, 1.0)
	
	tween_puntajes = create_tween()
	
	# 1. Efecto Pop (Crecen rápido a 1.4 y vuelven a 1.0)
	tween_puntajes.set_parallel(true)
	tween_puntajes.tween_property(label_jugador, "scale", Vector2(1.4, 1.4), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_puntajes.tween_property(label_ia, "scale", Vector2(1.4, 1.4), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween_puntajes.chain().set_parallel(true)
	tween_puntajes.tween_property(label_jugador, "scale", Vector2(1.0, 1.0), 0.2)
	tween_puntajes.tween_property(label_ia, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 2. Se quedan quietos (1.2 segundos, coincidiendo con el giro del cañón)
	tween_puntajes.chain().tween_interval(1.2)
	
	# 3. Se desvanecen
	tween_puntajes.chain().set_parallel(true)
	tween_puntajes.tween_property(label_jugador, "modulate:a", 0.0, 0.5)
	tween_puntajes.tween_property(label_ia, "modulate:a", 0.0, 0.5)
	
	# 4. Se ocultan al terminar
	tween_puntajes.chain().tween_callback(func():
		label_jugador.visible = false
		label_ia.visible = false
	)

func actualizar_puntajes(puntos_jugador: int, puntos_ia: int) -> void:
	if label_jugador:
		label_jugador.text = str(puntos_jugador) # 🔥 Formato normal
	if label_ia:
		label_ia.text = str(puntos_ia)           # 🔥 Formato normal

func abrir_menu_pausa() -> void:
	estado_actual = Estado.MENU_ABIERTO
	if menu_pausa_panel:
		menu_pausa_panel.visible = true
	get_tree().paused = true 

func _on_continuar_pressed() -> void:
	if menu_pausa_panel:
		menu_pausa_panel.visible = false
	get_tree().paused = false
	estado_actual = Estado.EN_JUEGO

func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu_principal.tscn")
