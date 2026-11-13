extends Control

# Referencias a los botones de control táctil de los costados y el enter
@export var boton_izquierdo: Button
@export var boton_derecho: Button
@export var boton_enter: Button

# Escenas de destino
const ESCENA_PARTIDA = "res://main.tscn"
const ESCENA_AJUSTES = "res://settings.tscn"

# Opciones del menú con sus respectivas descripciones
var opciones_menu = [
	{
		"titulo": "MODO IA",
		"descripcion": "Enfrentate a la inteligencia artificial en un duelo clásico a 5 puntos"
	},
	{
		"titulo": "AJUSTES",
		"descripcion": "Personaliza los niveles de volumen de la música y efectos de sonido"
	},
	{
		"titulo": "SALIR",
		"descripcion": "Cierra la aplicación de juego"
	}
]

var indice_opcion: int = 0

# Ruta exacta respetando la jerarquía que me marcaste
@onready var texto_modo: Label = $VBoxContainer/TextoModo
@onready var texto_descripcion: Label = $VBoxContainer/PanelDescripcion/TextoDescripcion


func _ready() -> void:
	# 1. Configurar el ajuste de línea y restricciones de tamaño para evitar que crezca a los costados
	if texto_descripcion:
		texto_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto_descripcion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Si notas que aún se pasa, puedes acotar un ancho máximo horizontal fijo en píxeles aquí:
		# texto_descripcion.custom_minimum_size.x = 350

	# 2. Reproducir la música del menú con Fade In automático al abrir la escena
	Configuracion.reproducir_musica_menu()
	
	actualizar_interfaz_menu()
	
	# Conexiones por código para los botones laterales y el enter
	if boton_izquierdo and not boton_izquierdo.pressed.is_connected(_on_izquierdo_pressed):
		boton_izquierdo.pressed.connect(_on_izquierdo_pressed)
		
	if boton_derecho and not boton_derecho.pressed.is_connected(_on_derecho_pressed):
		boton_derecho.pressed.connect(_on_derecho_pressed)
		
	if boton_enter and not boton_enter.pressed.is_connected(_on_enter_pressed):
		boton_enter.pressed.connect(_on_enter_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or (event is InputEventKey and event.keycode == KEY_LEFT):
		cambiar_opcion(-1)
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.keycode == KEY_RIGHT):
		cambiar_opcion(1)
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)):
		ejecutar_opcion_actual()

func cambiar_opcion(direccion: int) -> void:
	indice_opcion += direccion
	if indice_opcion < 0:
		indice_opcion = opciones_menu.size() - 1
	elif indice_opcion >= opciones_menu.size():
		indice_opcion = 0
	actualizar_interfaz_menu()

func _on_izquierdo_pressed() -> void:
	cambiar_opcion(-1)

func _on_derecho_pressed() -> void:
	cambiar_opcion(1)

func _on_enter_pressed() -> void:
	ejecutar_opcion_actual()

func actualizar_interfaz_menu() -> void:
	var opcion_actual = opciones_menu[indice_opcion]
	
	if texto_modo:
		texto_modo.text = opcion_actual["titulo"]
		
	if texto_descripcion:
		texto_descripcion.text = opcion_actual["descripcion"]

func ejecutar_opcion_actual() -> void:
	var seleccion = opciones_menu[indice_opcion]["titulo"]
	
	if seleccion == "MODO IA":
		Configuracion.detener_musica_menu()
		get_tree().change_scene_to_file(ESCENA_PARTIDA)
		
	elif seleccion == "AJUSTES":
		get_tree().change_scene_to_file(ESCENA_AJUSTES)
		
	elif seleccion == "SALIR":
		Configuracion.detener_musica_menu()
		get_tree().quit()
