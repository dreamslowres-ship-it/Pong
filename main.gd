extends Node2D

var puntos_jugador: int = 0
var puntos_ia: int = 0
var puntos_para_ganar: int = 5  
var juego_terminado: bool = false

# 🔥 NUEVO: Controla si el jugador ya puede tocar la pantalla para salir
var puede_volver_al_menu: bool = false 

# Precargamos la escena de la pelota
const ESCENA_PELOTA = preload("res://pelota.tscn")

# Permite arrastrar el LanzadorPausa directamente desde el panel de escena al Inspector
@export var lanzador_pausa: Node2D

# Referencias a los textos del marcador
@onready var texto_puntaje_ia: Label = $CanvasLayer/TextoPuntajeIA
@onready var texto_puntaje_player: Label = $CanvasLayer/TextoPuntajePlayer

# Referencias a la pantalla de victoria/derrota
@onready var pantalla_final: ColorRect = $CanvasLayer/PantallaFinal
@onready var texto_resultado: Label = $CanvasLayer/PantallaFinal/gg/TextoResultado

# Referencia al sonido de gol
@onready var sonido_gol: AudioStreamPlayer = $SonidoGol

func _ready() -> void:
	get_tree().root.set_theme(preload("res://tema_minimalista.tres"))
	
	if pantalla_final:
		pantalla_final.visible = false
		
	# Inicializar los puntajes en ceros en el lanzador al arrancar
	if lanzador_pausa and lanzador_pausa.has_method("actualizar_puntajes"):
		lanzador_pausa.actualizar_puntajes(0, 0)
		
	# Conexión por código de seguridad
	if lanzador_pausa and not lanzador_pausa.pelota_lanzada.is_connected(_on_pelota_lanzada):
		lanzador_pausa.pelota_lanzada.connect(_on_pelota_lanzada)

func _on_gol_arriba_body_entered(body: Node2D) -> void:
	if body.name == "pelota" and not juego_terminado:
		puntos_jugador += 1
		reproducir_audio_gol()
		actualizar_marcador()
		verificar_ganador(body)

func _on_gol_abajo_body_entered(body: Node2D) -> void:
	if body.name == "pelota" and not juego_terminado:
		puntos_ia += 1
		reproducir_audio_gol()
		actualizar_marcador()
		verificar_ganador(body)

func actualizar_marcador() -> void:
	if texto_puntaje_ia and texto_puntaje_player:
		texto_puntaje_ia.text = str(puntos_ia)       
		texto_puntaje_player.text = str(puntos_jugador) 
		
	if lanzador_pausa and lanzador_pausa.has_method("actualizar_puntajes"):
		lanzador_pausa.actualizar_puntajes(puntos_jugador, puntos_ia)
		
		if not juego_terminado and lanzador_pausa.has_method("mostrar_puntajes_por_gol"):
			lanzador_pausa.mostrar_puntajes_por_gol()

func verificar_ganador(pelota: Node2D) -> void:
	pelota.queue_free() 
	
	if puntos_jugador >= puntos_para_ganar:
		juego_terminado = true
		mostrar_pantalla_final("VICTORY")
	elif puntos_ia >= puntos_para_ganar:
		juego_terminado = true
		mostrar_pantalla_final("GAME OVER")
	else:
		if lanzador_pausa:
			lanzador_pausa.iniciar_secuencia_lanzamiento()

func _on_pelota_lanzada(posicion_salida: Vector2, velocidad_inicial: Vector2) -> void:
	var nueva_pelota = ESCENA_PELOTA.instantiate()
	
	add_child(nueva_pelota)
	nueva_pelota.global_position = posicion_salida
	nueva_pelota.direccion = velocidad_inicial.normalized()
	nueva_pelota.velocidad_actual = velocidad_inicial.length()

# 🔥 MODIFICADO: Añadido el retraso de 2 segundos
func mostrar_pantalla_final(mensaje: String) -> void:
	if pantalla_final and texto_resultado:
		texto_resultado.text = mensaje
		pantalla_final.visible = true
		
		puede_volver_al_menu = false # Bloqueamos el toque inmediato
		
		# Esperamos 2 segundos antes de permitir tocar la pantalla
		await get_tree().create_timer(2.0).timeout
		
		puede_volver_al_menu = true # Habilitamos el toque

func reproducir_audio_gol() -> void:
	if sonido_gol and sonido_gol.stream:
		sonido_gol.play()

# 🔥 MODIFICADO: Ahora manda al Menú Principal en vez de reiniciar la escena
func _input(event: InputEvent) -> void:
	if puede_volver_al_menu and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		# Opcional: Evitar que un toque rápido active el botón del nuevo menú por error
		get_tree().change_scene_to_file("res://menu_principal.tscn")
