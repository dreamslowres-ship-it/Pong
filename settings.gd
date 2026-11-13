extends Control

# Las 3 páginas de configuración
var paginas = [
	{ "titulo": "MÚSICA", "bus": "Music" },
	{ "titulo": "EFECTOS SFX", "bus": "SFX" },
	{ "titulo": "SOBRE ESTE JUEGO", "bus": "" }
]

var indice_pagina: int = 0
var musica_val: int = 80  # Valor inicial música
var sfx_val: int = 80     # Valor inicial efectos SFX

# Bandera para saber si el usuario está deslizando el dedo o el mouse
var arrastrando: bool = false

@export var btn_izquierdo: Button
@export var btn_derecho: Button

@onready var texto_seccion: Label = $VBoxContainer/TextoSeccion

# RichTextLabel para soportar BBCode
@onready var texto_creditos: RichTextLabel = $VBoxContainer/TextoCreditos
@onready var boton_volver = $BotonVolver

# RUTAS EXACTAS
@onready var area_tactil_barra: Control = $CAPA/AreaTactilBarra
@onready var contenedor_visual: Control = $ContenedorVisual
@onready var sprite_barra: AnimatedSprite2D = $ContenedorVisual/AnimatedSprite2D

# 🔥 CORREGIDO: La ruta ahora apunta directamente a la raíz de la escena
@onready var texto_porcentaje: Label = $Porcentajes

# RUTA DE TU FUENTE (Confirmada)
const RUTA_FUENTE_EMOJI = "res://DotGothic16-Regular.ttf" 

func _ready() -> void:
	# Sincronizamos con los valores reales guardados en el Autoload global
	musica_val = Configuracion.musica_val
	sfx_val = Configuracion.sfx_val
	
	# 🔥 CONFIGURACIÓN DEL TEXTO CON BBCode
	if texto_creditos:
		texto_creditos.bbcode_enabled = true
		
		# Forzamos centrado y evitamos que el texto se divida en varias líneas
		texto_creditos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		texto_creditos.autowrap_mode = TextServer.AUTOWRAP_OFF
		
		# Cargamos tu tema minimalista para obtener la fuente correcta
		var tema_juego = load("res://tema_minimalista.tres")
		if tema_juego and tema_juego.default_font:
			# Aplicamos la fuente del tema al texto normal del RichTextLabel
			texto_creditos.add_theme_font_override("normal_font", tema_juego.default_font)
		
		# Usamos '♥' y quitamos el [font_size] para que no aplaste el texto.
		texto_creditos.text = "Hecho con [font=" + RUTA_FUENTE_EMOJI + "]♥[/font] y tiempo libre.\n¡Peoximamente Multijugador Wifi!\nversión actual: v1.0.0\n"
		texto_creditos.visible = false
	
	actualizar_interfaz()
	aplicar_volumenes_globales()
	
	if boton_volver and boton_volver.has_signal("pressed"):
		boton_volver.pressed.connect(_on_boton_volver_pressed)
		
	# Botones laterales para cambiar de página
	if btn_izquierdo:
		btn_izquierdo.pressed.connect(func(): cambiar_pagina(-1))
	if btn_derecho:
		btn_derecho.pressed.connect(func(): cambiar_pagina(1))
		
	# Conexión táctil exclusiva al área protegida por CAPA
	if area_tactil_barra:
		area_tactil_barra.gui_input.connect(_on_area_tactil_gui_input)

func _input(event: InputEvent) -> void:
	if indice_pagina == 2:
		return

	# 1. Navegación por teclado / acciones
	if event.is_action_pressed("ui_left") or (event is InputEventKey and event.keycode == KEY_LEFT):
		cambiar_pagina(-1)
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.keycode == KEY_RIGHT):
		cambiar_pagina(1)
		
	# 2. MOVIMIENTO GLOBAL: Lectura fluida
	if arrastrando:
		if event is InputEventMouseMotion:
			var local_x = event.global_position.x - area_tactil_barra.global_position.x
			calcular_volumen_por_posicion(local_x)
		elif event is InputEventScreenDrag:
			var local_x = event.position.x - area_tactil_barra.global_position.x
			calcular_volumen_por_posicion(local_x)
			
	# 3. SOLTAR: Detectar cuando se levanta el dedo o el mouse
	if (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
	or (event is InputEventScreenTouch and not event.pressed):
		# Guardamos la configuración solo al soltar para evitar lag
		if arrastrando:
			Configuracion.guardar_configuracion()
		arrastrando = false

func cambiar_pagina(direccion: int) -> void:
	indice_pagina += direccion
	if indice_pagina < 0:
		indice_pagina = paginas.size() - 1
	elif indice_pagina >= paginas.size():
		indice_pagina = 0
	actualizar_interfaz()

func _on_area_tactil_gui_input(event: InputEvent) -> void:
	if indice_pagina == 2:
		return
		
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
	or (event is InputEventScreenTouch and event.pressed):
		arrastrando = true
		calcular_volumen_por_posicion(event.position.x)

func calcular_volumen_por_posicion(pos_x: float) -> void:
	var nuevo_valor: int = 0
	
	# Mapeo exacto según tus rangos de píxeles medidos en la gráfica
	if pos_x <= 30:
		nuevo_valor = 0
	elif pos_x <= 73:
		nuevo_valor = 10
	elif pos_x <= 116:
		nuevo_valor = 20
	elif pos_x <= 159:
		nuevo_valor = 30
	elif pos_x <= 202:
		nuevo_valor = 40
	elif pos_x <= 245:
		nuevo_valor = 50
	elif pos_x <= 288:
		nuevo_valor = 60
	elif pos_x <= 331:
		nuevo_valor = 70
	elif pos_x <= 374:
		nuevo_valor = 80
	elif pos_x <= 417:
		nuevo_valor = 90
	else:
		nuevo_valor = 100
		
	if indice_pagina == 0:
		musica_val = nuevo_valor
		Configuracion.musica_val = nuevo_valor
		Configuracion.reproducir_musica_menu() 
		if texto_porcentaje: texto_porcentaje.text = str(musica_val) + "%" # 🔥 Actualiza el %
	elif indice_pagina == 1:
		sfx_val = nuevo_valor
		Configuracion.sfx_val = nuevo_valor
		if texto_porcentaje: texto_porcentaje.text = str(sfx_val) + "%" # 🔥 Actualiza el %
		
	aplicar_volumenes_globales()
	
	# Solo actualizamos el frame visual de la barra
	if sprite_barra:
		if indice_pagina == 0:
			sprite_barra.frame = int(musica_val / 10.0)
		elif indice_pagina == 1:
			sprite_barra.frame = int(sfx_val / 10.0)

func actualizar_interfaz() -> void:
	var pagina = paginas[indice_pagina]
	texto_seccion.text = pagina["titulo"]
	
	if indice_pagina == 0:
		mostrar_seccion_volumen(true)
		if sprite_barra:
			sprite_barra.frame = int(musica_val / 10.0)
		if texto_porcentaje: 
			texto_porcentaje.text = str(musica_val) + "%" # 🔥 Lo inicializa al entrar a Música
	elif indice_pagina == 1:
		mostrar_seccion_volumen(true)
		if sprite_barra:
			sprite_barra.frame = int(sfx_val / 10.0)
		if texto_porcentaje: 
			texto_porcentaje.text = str(sfx_val) + "%" # 🔥 Lo inicializa al entrar a SFX
	else:
		mostrar_seccion_volumen(false)

func mostrar_seccion_volumen(mostrar: bool) -> void:
	if area_tactil_barra: 
		area_tactil_barra.visible = mostrar
	if contenedor_visual:
		contenedor_visual.visible = mostrar
	if texto_porcentaje:
		texto_porcentaje.visible = mostrar # 🔥 Lo oculta/muestra dependiendo de la página
	if texto_creditos: 
		texto_creditos.visible = !mostrar

func aplicar_volumenes_globales() -> void:
	var bus_music_idx = AudioServer.get_bus_index("Music")
	if bus_music_idx != -1:
		if musica_val == 0:
			AudioServer.set_bus_mute(bus_music_idx, true)
		else:
			AudioServer.set_bus_mute(bus_music_idx, false)
			AudioServer.set_bus_volume_db(bus_music_idx, linear_to_db(musica_val / 100.0))
			
	var bus_sfx_idx = AudioServer.get_bus_index("SFX")
	if bus_sfx_idx != -1:
		if sfx_val == 0:
			AudioServer.set_bus_mute(bus_sfx_idx, true)
		else:
			AudioServer.set_bus_mute(bus_sfx_idx, false)
			AudioServer.set_bus_volume_db(bus_sfx_idx, linear_to_db(sfx_val / 100.0))
			
	Configuracion.musica_val = musica_val
	Configuracion.sfx_val = sfx_val
	Configuracion.aplicar_volumenes()

func _on_boton_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_principal.tscn")
