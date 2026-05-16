extends Node

# Voice Manager для The Coffin of Andy and Leyley
# Автоматически воспроизводит озвучку при появлении текста диалога
# Поддерживает русификатор из The Coffin of Andy and Leyley\www\languages

signal voice_started(file_name: String)
signal voice_finished()

# Путь к папке с голосовыми файлами
const VOICE_FOLDER := "res://voice_mod/audio/"

# Путь к файлу русификатора (настраивается под вашу структуру)
const RUSIFIER_PATH := "res://voice_mod/languages/Русский.cld"

# Кэш загруженных аудио потоков
var _audio_cache: Dictionary = {}
# Текущий проигрыватель аудио
var _current_player: AudioStreamPlayer = null
# Текущий проигрываемый файл
var _current_file: String = ""
# Очередь файлов для воспроизведения
var _queue: Array[String] = []
# Флаг, что сейчас играет голос
var is_playing: bool = false

# Данные русификатора
var _rusifier_data: Dictionary = {}
var _rusifier_loaded: bool = false

# Маппинг имен персонажей (можно расширять)
const CHARACTER_NAMES := {
	"andy": "andy",
	"энди": "andy",
	"leyley": "leyley",
	"лейли": "leyley",
	"leyla": "leyley",
	"лейла": "leyley",
}

func _ready() -> void:
	add_to_group("voice_manager")
	_create_audio_player()
	_load_rusifier()
	print("[VoiceManager] Инициализирован. Папка: ", VOICE_FOLDER)
	if _rusifier_loaded:
		print("[VoiceManager] Русификатор загружен. Строк: ", _rusifier_data.get("linesLUT", {}).size())
	else:
		print("[VoiceManager] Русификатор не найден или не загружен. Будет работать без него.")

func _create_audio_player() -> void:
	_current_player = AudioStreamPlayer.new()
	_current_player.bus = "Voice"
	add_child(_current_player)
	_current_player.finished.connect(_on_voice_finished)

func _on_voice_finished() -> void:
	is_playing = false
	_current_file = ""
	voice_finished.emit()
	_process_queue()

# Загрузка данных русификатора
func _load_rusifier() -> void:
	if not ResourceLoader.exists(RUSIFIER_PATH):
		print("[VoiceManager] Файл русификатора не найден: ", RUSIFIER_PATH)
		_rusifier_loaded = false
		return
	
	var file = FileAccess.open(RUSIFIER_PATH, FileAccess.READ)
	if file == null:
		print("[VoiceManager] Не удалось открыть файл русификатора")
		_rusifier_loaded = false
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Убираем префикс LANGDATA если есть
	if content.begins_with("LANGDATA"):
		content = content.substr(8)
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		print("[VoiceManager] Ошибка парсинга JSON русификатора: ", error)
		_rusifier_loaded = false
		return
	
	_rusifier_data = json.data
	_rusifier_loaded = true

# Основная функция для воспроизводства голоса по имени файла
func play_voice(file_name: String) -> void:
	if file_name.is_empty():
		return
	
	# Добавляем расширение если нет
	if not file_name.ends_with(".flac") and not file_name.ends_with(".ogg") and not file_name.ends_with(".wav") and not file_name.ends_with(".mp3"):
		file_name += ".flac"
	
	_queue.append(file_name)
	_process_queue()

# Воспроизвести конкретный файл немедленно (без очереди)
func play_voice_immediate(file_name: String) -> void:
	if file_name.is_empty():
		return
	
	if not file_name.ends_with(".flac") and not file_name.ends_with(".ogg") and not file_name.ends_with(".wav") and not file_name.ends_with(".mp3"):
		file_name += ".flac"
	
	_queue.clear()
	_queue.append(file_name)
	_process_queue()

func _process_queue() -> void:
	if _queue.is_empty() or is_playing:
		return
	
	var next_file = _queue.pop_front()
	_play_file(next_file)

func _play_file(file_name: String) -> void:
	if is_playing:
		return
	
	var full_path = VOICE_FOLDER + file_name
	
	# Проверяем существование файла
	if not ResourceLoader.exists(full_path):
		print("[VoiceManager] Файл не найден: ", full_path)
		_process_queue()
		return
	
	# Загружаем аудио поток
	var stream: AudioStream = _load_audio_stream(full_path)
	if stream == null:
		print("[VoiceManager] Не удалось загрузить: ", full_path)
		_process_queue()
		return
	
	_current_file = file_name
	_current_player.stream = stream
	_current_player.play()
	is_playing = true
	voice_started.emit(file_name)
	print("[VoiceManager] Воспроизводится: ", file_name)

func _load_audio_stream(path: String) -> AudioStream:
	# Проверяем кэш
	if _audio_cache.has(path):
		return _audio_cache[path]
	
	# Загружаем и кэшируем
	var stream = load(path) as AudioStream
	if stream != null:
		_audio_cache[path] = stream
	
	return stream

# Получить русский текст реплики по ID из русификатора
# Возвращает пустую строку если не найдено (не ломается)
func get_russian_text(line_id: String) -> String:
	if not _rusifier_loaded:
		return ""
	
	var lines_lut = _rusifier_data.get("linesLUT", {})
	if lines_lut.has(line_id):
		var entry = lines_lut[line_id]
		if entry is Array and entry.size() > 0:
			return str(entry[0])
		elif entry is String:
			return entry
	
	return ""

# Утилита для создания имени файла из текста реплики
# Например: "Привет, Энди!" -> "privet_endi.flac"
static func text_to_filename(text: String, character: String = "") -> String:
	if text.is_empty():
		return ""
	
	var filename = text.to_lower()
	
	# Удаляем спецсимволы
	var allowed_chars = "abcdefghijklmnopqrstuvwxyzабвгдеєжзийклмнопрстуфхцчшщьюя0123456789_"
	var result = ""
	for char in filename:
		if char in allowed_chars or char == " ":
			result += char
		elif char == "ё":
			result += "е"
	
	# Заменяем пробелы на подчеркивания
	result = result.replace(" ", "_")
	
	# Удаляем множественные подчеркивания
	while "__" in result:
		result = result.replace("__", "_")
	
	# Удаляем начало и конец если там подчеркивания
	result = result.strip_edges("_")
	
	# Добавляем префикс персонажа если указан
	if not character.is_empty():
		result = character + "_" + result
	
	# Ограничиваем длину имени файла
	if result.length() > 100:
		result = result.substr(0, 100)
	
	if result.is_empty():
		return ""
	
	return result + ".flac"

# Функция для получения имени файла на основе контекста
# Можно вызывать из диалоговой системы
func get_voice_file(character: String, dialogue_id: String, line_number: int = -1) -> String:
	var char_key = CHARACTER_NAMES.get(character.to_lower(), character.to_lower())
	
	if line_number >= 0:
		return "%s_ch%s_line%d.flac" % [char_key, dialogue_id, line_number]
	else:
		return "%s_%s.flac" % [char_key, dialogue_id]

# Получить имя файла озвучки для русской реплики по ID
# Если реплики нет в русификаторе - вернет пустую строку (не ломается)
func get_voice_file_for_russian_line(line_id: String, character: String = "") -> String:
	var russian_text = get_russian_text(line_id)
	if russian_text.is_empty():
		return ""  # Реплика не найдена, возвращаем пустую строку
	
	return text_to_filename(russian_text, character)

# Очистить кэш аудио (освободить память)
func clear_cache() -> void:
	_audio_cache.clear()
	print("[VoiceManager] Кэш очищен")

# Остановить текущее воспроизведение
func stop() -> void:
	if _current_player and is_playing:
		_current_player.stop()
		is_playing = false
		_current_file = ""
		voice_finished.emit()

# Громкость голоса (0.0 - 1.0)
func set_volume(volume_db: float) -> void:
	if _current_player:
		_current_player.volume_db = volume_db

func get_current_file() -> String:
	return _current_file

func is_busy() -> bool:
	return is_playing or not _queue.is_empty()

func is_rusifier_loaded() -> bool:
	return _rusifier_loaded
