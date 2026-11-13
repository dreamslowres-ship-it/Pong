extends Node

const RUTA_ARCHIVO = "user://config.save"

var musica_val: int = 80
var sfx_val: int = 80

var reproductor_musica: AudioStreamPlayer
# 🎵 CAMBIA ESTA RUTA por el archivo de audio de tu música de menú:
var stream_menu = preload("res://Music.mp3") 

func _ready() -> void:
	reproductor_musica = AudioStreamPlayer.new()
	reproductor_musica.stream = stream_menu
	reproductor_musica.bus = "Music"
	add_child(reproductor_musica)
	
	cargar_configuracion()
	aplicar_volumenes()

func guardar_configuracion() -> void:
	var archivo = FileAccess.open(RUTA_ARCHIVO, FileAccess.WRITE)
	if archivo:
		archivo.store_var(musica_val)
		archivo.store_var(sfx_val)
		archivo.close()

func cargar_configuracion() -> void:
	if FileAccess.file_exists(RUTA_ARCHIVO):
		var archivo = FileAccess.open(RUTA_ARCHIVO, FileAccess.READ)
		if archivo:
			musica_val = archivo.get_var()
			sfx_val = archivo.get_var()
			archivo.close()
	aplicar_volumenes()

func aplicar_volumenes() -> void:
	var idx_music = AudioServer.get_bus_index("Music")
	if idx_music != -1:
		if musica_val == 0:
			AudioServer.set_bus_mute(idx_music, true)
		else:
			AudioServer.set_bus_mute(idx_music, false)
			AudioServer.set_bus_volume_db(idx_music, linear_to_db(musica_val / 100.0))
			
	var idx_sfx = AudioServer.get_bus_index("SFX")
	if idx_sfx != -1:
		if sfx_val == 0:
			AudioServer.set_bus_mute(idx_sfx, true)
		else:
			AudioServer.set_bus_mute(idx_sfx, false)
			AudioServer.set_bus_volume_db(idx_sfx, linear_to_db(sfx_val / 100.0))

func reproducir_musica_menu() -> void:
	if not reproductor_musica.playing:
		reproductor_musica.volume_db = -80.0
		reproductor_musica.play()
	
	var target_db = linear_to_db(musica_val / 100.0) if musica_val > 0 else -80.0
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(reproductor_musica, "volume_db", target_db, 1.5)

func detener_musica_menu() -> void:
	if reproductor_musica.playing:
		var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween.tween_property(reproductor_musica, "volume_db", -80.0, 1.0)
		tween.tween_callback(reproductor_musica.stop)
