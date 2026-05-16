extends Node

# Интеграция VoiceManager с диалоговой системой The Coffin of Andy and Leyley
# Этот скрипт нужно подключить к узлу диалоговой системы или тексту диалога

# Ссылка на VoiceManager (автозагрузка)
@onready var voice_manager: Node = get_node_or_null("/root/VoiceManager")

# Настройки
@export_group("Voice Settings")
@export var enable_voice: bool = true  # Включить/выключить озвучку
@export var character_name: String = "andy"  # Имя текущего персонажа
@export var use_auto_filename: bool = true  # Автоматически создавать имя файла из текста
@export var manual_filename: String = ""  # Ручное имя файла (если use_auto_filename = false)
@export var voice_volume_db: float = 0.0  # Громкость голоса в dB

# Ссылки на узлы текста (настроить под структуру игры)
@onready var dialogue_label: Label = null  # Узел с текстом диалога
@onready var speaker_label: Label = null  # Узел с именем говорящего

# Текущая реплика
var current_text: String = ""
var is_waiting_for_voice: bool = false

func _ready() -> void:
	if voice_manager:
		voice_manager.set_volume(voice_volume_db)
		print("[DialogueVoice] Интеграция активирована")
	else:
		push_warning("[DialogueVoice] VoiceManager не найден!")

# Вызывать при показе новой реплики
func show_dialogue(text: String, speaker: String = "") -> void:
	current_text = text
	
	if speaker and not speaker.is_empty():
		character_name = speaker
		if speaker_label:
			speaker_label.text = speaker
	
	if dialogue_label:
		dialogue_label.text = text
	
	if enable_voice and voice_manager:
		_play_voice_for_text(text, character_name)

# Воспроизвести голос для текущей реплики
func _play_voice_for_text(text: String, speaker: String) -> void:
	var filename: String = ""
	
	if use_auto_filename:
		if manual_filename and not manual_filename.is_empty():
			filename = manual_filename
		else:
			# Автоматическое создание имени файла из текста
			filename = VoiceManager.text_to_filename(text, speaker)
	else:
		if manual_filename and not manual_filename.is_empty():
			filename = manual_filename
	
	if not filename.is_empty():
		is_waiting_for_voice = true
		voice_manager.play_voice(filename)

# Вызывать когда игрок кликает для продолжения диалога
func on_next_button_pressed() -> void:
	if voice_manager and voice_manager.is_playing:
		# Если голос еще играет, можно либо остановить, либо подождать
		# Вариант 1: Остановить голос
		voice_manager.stop()
		is_waiting_for_voice = false
		# Тут логика перехода к следующей реплике
		return
	
	# Если голос закончился или отключен - переходим дальше
	is_waiting_for_voice = false
	# Тут логика перехода к следующей реплике

# Альтернативный вариант: ждать окончания голоса перед продолжением
func can_advance_dialogue() -> bool:
	if not enable_voice:
		return true
	
	if not voice_manager:
		return true
	
	return not voice_manager.is_playing

# Для интеграции с существующей системой диалогов
# Вызывать из основного скрипта диалогов
func integrate_with_existing_system(dialogue_node: Node, label_node: Label = null, speaker_node: Label = null) -> void:
	dialogue_label = label_node
	speaker_label = speaker_node
	
	# Подключаемся к сигналам существующей системы
	if dialogue_node.has_signal("dialogue_started"):
		dialogue_node.dialogue_started.connect(_on_existing_dialogue_started)
	
	if dialogue_node.has_signal("text_displayed"):
		dialogue_node.text_displayed.connect(_on_text_displayed)
	
	if dialogue_node.has_signal("dialogue_ended"):
		dialogue_node.dialogue_ended.connect(_on_dialogue_ended)

func _on_existing_dialogue_started(data: Dictionary) -> void:
	if data.has("text"):
		show_dialogue(data["text"], data.get("speaker", ""))

func _on_text_displayed(text: String) -> void:
	show_dialogue(text, character_name)

func _on_dialogue_ended() -> void:
	if voice_manager:
		voice_manager.stop()
	is_waiting_for_voice = false

# Утилита для быстрой настройки
static func setup_voice_integration(root: Node, dialogue_path: NodePath, label_path: NodePath = ^"", speaker_path: NodePath = ^"") -> Node:
	var dialogue_node = root.get_node_or_null(dialogue_path)
	if not dialogue_node:
		push_error("[DialogueVoice] Узел диалога не найден: ", dialogue_path)
		return null
	
	var integrator = new()
	root.add_child(integrator)
	
	var label_node: Label = null
	var speaker_node: Label = null
	
	if label_path:
		label_node = root.get_node_or_null(label_path) as Label
	
	if speaker_path:
		speaker_node = root.get_node_or_null(speaker_path) as Label
	
	integrator.integrate_with_existing_system(dialogue_node, label_node, speaker_node)
	
	return integrator
