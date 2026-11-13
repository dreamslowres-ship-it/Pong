extends CharacterBody2D

# 1. Definimos si esta paleta es controlada por la Inteligencia Artificial o por el Jugador
@export var es_ia: bool = false

# 2. Velocidad de movimiento de la paleta en píxeles por segundo
@export var velocidad: float = 1300.0

# 3. Referencias a los botones táctiles (solo para el jugador)
@export var boton_izquierdo: Button
@export var boton_derecho: Button

# 🟢 NUEVO: Referencia a la paleta del jugador para calcular las tácticas de la IA
@export var nodo_jugador: Node2D 

# --- Config IA (tuneable desde el inspector) ---
@export_group("IA - Comportamiento")
@export_range(0.3, 1.2, 0.05) var ia_factor_velocidad: float = 0.85
@export var ia_zona_muerta: float = 14.0        
@export var ia_error_max: float = 20.0          
@export var ia_intervalo_decision: float = 0.10 
@export var ia_suavizado_error: float = 3.0     
@export var ia_volver_al_centro: bool = false   
@export var offset_sprite_y: float = -20.0

@export_group("IA - Tácticas")
@export var ia_usar_tacticas: bool = true       
@export var ia_distancia_tactica: float = 350.0 
@export var ia_fuerza_efecto: float = 30.0      

# --- Constantes de la arena ---
const ARENA_IZQ: float = 705.0   
const ARENA_DER: float = 1635.0  

# --- Estado interno ---
var posicion_y_fija: float
var _objetivo_x: float
var _error_actual: float = 0.0
var _timer_decision: float = 0.0
var _pelota: Node2D = null 

# Búsqueda inteligente y segura del nodo visual
@onready var animated_sprite: AnimatedSprite2D = _encontrar_sprite_visual()

func _ready() -> void:
	posicion_y_fija = position.y
	_objetivo_x = position.x
	
	if es_ia:
		_pelota = get_parent().get_node_or_null("pelota")
		if nodo_jugador == null:
			nodo_jugador = get_parent().get_node_or_null("paleta_jugador")
			
	if animated_sprite:
		animated_sprite.play("idle")
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)

func _encontrar_sprite_visual() -> AnimatedSprite2D:
	var sprite = find_child("*Sprite*")
	if sprite is AnimatedSprite2D:
		return sprite
	return null

func _physics_process(delta: float) -> void:
	if not es_ia:
		_control_jugador()
	else:
		_control_ia(delta)

	velocity.y = 0.0
	move_and_slide()
	position.x = clamp(position.x, ARENA_IZQ, ARENA_DER)
	position.y = posicion_y_fija

	# --- DETECCIÓN DE IMPACTO FÍSICO CON LA PELOTA (Respaldada) ---
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and "pelota" in collider.name.to_lower():
			disparar_animacion_golpe()

func _control_jugador() -> void:
	var direccion := 0.0
	if boton_izquierdo and boton_izquierdo.button_pressed:
		direccion -= 1.0
	if boton_derecho and boton_derecho.button_pressed:
		direccion += 1.0
	velocity.x = direccion * velocidad

func _control_ia(delta: float) -> void:
	if _pelota == null:
		_pelota = get_parent().get_node_or_null("pelota")
	if _pelota == null:
		velocity.x = 0.0
		return

	# Error humano suavizado
	_error_actual = lerp(
		_error_actual,
		randf_range(-ia_error_max, ia_error_max),
		delta * ia_suavizado_error
	)

	# Recalcular objetivo cada "tiempo de reacción"
	_timer_decision -= delta
	if _timer_decision <= 0.0:
		_timer_decision = ia_intervalo_decision
		var prediccion_base := _predecir_x_impacto(_pelota)
		
		if ia_usar_tacticas:
			_objetivo_x = _calcular_objetivo_tactico(_pelota, prediccion_base)
		else:
			_objetivo_x = prediccion_base

	var target := _objetivo_x + _error_actual
	var dx := target - position.x

	if abs(dx) > ia_zona_muerta:
		velocity.x = sign(dx) * velocidad * ia_factor_velocidad
	else:
		velocity.x = 0.0

# ==========================================
# CEREBRO TÁCTICO (IA)
# ==========================================
func _calcular_objetivo_tactico(pelota: Node2D, prediccion_centro: float) -> float:
	if nodo_jugador == null:
		return prediccion_centro 
		
	var distancia_y: float = abs(pelota.position.y - position.y)
	
	if distancia_y > ia_distancia_tactica:
		return prediccion_centro
		
	var centro_arena: float = (ARENA_IZQ + ARENA_DER) * 0.5
	var lado_jugador: float = sign(nodo_jugador.position.x - centro_arena) 
	var lado_objetivo: float = -lado_jugador 
	var desplazamiento: float = -lado_objetivo * ia_fuerza_efecto
	
	if distancia_y < 120.0 and randf() > 0.4: 
		desplazamiento = -desplazamiento * 1.2
		
	return prediccion_centro + desplazamiento

# ==========================================
# PREDICCIÓN FÍSICA (IA)
# ==========================================
func _predecir_x_impacto(pelota: Node2D) -> float:
	var vel := _obtener_velocidad(pelota)

	if vel.y >= -1.0:
		if ia_volver_al_centro:
			return (ARENA_IZQ + ARENA_DER) * 0.5
		return pelota.position.x

	var dy: float = position.y - pelota.position.y
	var t: float = dy / vel.y
	
	if t <= 0.0:
		return pelota.position.x

	var x_futuro: float = pelota.position.x + vel.x * t
	var ancho: float = ARENA_DER - ARENA_IZQ
	var periodo: float = 2.0 * ancho
	var r: float = fmod(x_futuro - ARENA_IZQ, periodo)
	if r < 0.0:
		r += periodo
	return ARENA_IZQ + min(r, periodo - r)

func _obtener_velocidad(nodo: Node) -> Vector2:
	if nodo is CharacterBody2D:
		return nodo.velocity
	elif nodo is RigidBody2D:
		return nodo.linear_velocity
	elif "velocity" in nodo:
		return nodo.velocity
	return Vector2.ZERO

# ==========================================
# GESTIÓN DE ANIMACIONES
# ==========================================
func disparar_animacion_golpe() -> void:
	if animated_sprite and animated_sprite.animation != "golpe":
		animated_sprite.play("golpe")

func _on_animation_finished() -> void:
	if animated_sprite and animated_sprite.animation == "golpe":
		animated_sprite.play("idle")
