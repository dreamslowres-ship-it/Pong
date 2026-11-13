extends CharacterBody2D

@export var velocidad_inicial: float = 600.0
@export var incremento_velocidad: float = 100.0  
@export var velocidad_maxima: float = 1700.0

var velocidad_actual: float = 0.0
var direccion: Vector2 = Vector2.ZERO

# 🔥 NUEVO: Contador para tu idea de cambiar la ruta cada X golpes
var golpes_seguidos: int = 0 

@onready var sonido_rebote: AudioStreamPlayer = $SonidoRebote

func _ready() -> void:
	resetear_pelota()
	
	if $Sprite2D:
		$Sprite2D.z_index=200

func _physics_process(delta: float) -> void:
	velocity = direccion * velocidad_actual
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		
		# Si choca contra una paleta, aplicamos el ángulo arcade
		if collider and ("Jugador" in collider.name or "IA" in collider.name):
			golpes_seguidos += 1 # 🔥 Sumamos un golpe
			
			var hit_offset = global_position.x - collider.global_position.x
			# 🔥 AÑADIDO: Un pequeño ruido aleatorio al offset para que no sea matemáticamente exacto
			var ruido = randf_range(-15.0, 15.0) 
			direccion.x = (hit_offset + ruido) * 0.03 
			direccion.y = -direccion.y 
			
			# 🔥 TU IDEA: Si hay 4 golpes seguidos (sin tocar pared), forzamos un cambio de ruta
			if golpes_seguidos >= 4:
				golpes_seguidos = 0 # Reiniciamos el contador
				# Giramos la dirección bruscamente hacia un lado al azar (entre -25 y 25 grados)
				var giro_brusco = randf_range(deg_to_rad(-25.0), deg_to_rad(25.0))
				direccion = direccion.rotated(giro_brusco)
			
			direccion = direccion.normalized()
		else:
			# Rebote normal en paredes
			golpes_seguidos = 0 # 🔥 Si toca pared, el contador se reinicia
			direccion = direccion.bounce(collision.get_normal())
		
		# 🛡️ PROTECCIÓN ANTI-BUCLES HORIZONTALES MEJORADA
		if abs(direccion.y) < 0.35:
			# 🔥 En vez de usar 0.35 fijo, elegimos un valor al azar entre 0.4 y 0.6
			var fuerza_y = randf_range(0.4, 0.6) 
			direccion.y = fuerza_y if direccion.y > 0 else -fuerza_y
			direccion = direccion.normalized()
		
		reproducir_rebote()
		
		# Aceleración progresiva limitada al tope máximo
		velocidad_actual = min(velocidad_actual + incremento_velocidad, velocidad_maxima)

func resetear_pelota() -> void:
	# Centro exacto de tu arena (2340x1080)
	global_position = Vector2(1170, 540)
	velocidad_actual = velocidad_inicial
	
	golpes_seguidos = 0 # 🔥 Reiniciamos el contador al sacar
	
	# 🔥 SAQUE MEJORADO: En lugar de -0.4 a 0.4 (que es muy vertical), 
	# elegimos un ángulo real de hasta 45 grados hacia los lados.
	var angulo_saque = randf_range(deg_to_rad(-45.0), deg_to_rad(45.0))
	var random_y = 1.0 if randf() > 0.5 else -1.0
	direccion = Vector2(sin(angulo_saque), cos(angulo_saque) * random_y).normalized()

func reproducir_rebote() -> void:
	if sonido_rebote and sonido_rebote.stream:
		sonido_rebote.play()
