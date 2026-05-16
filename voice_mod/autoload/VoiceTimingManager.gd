extends Node

# Таймкод менеджер для The Coffin of Andy and Leyley
# Автоматически находит или создаёт таймкоды для озвучки
# Сохраняет данные в файл при первом запуске игры

signal timing_data_ready(line_id: String, duration: float)
signal timing_scan_started()
signal timing_scan_finished(total_files: int)

# Путь к папке с голосовыми файлами
const VOICE_FOLDER := "res://voice_mod/audio/"

# Путь к файлу с таймкодами
const TIMING_FILE_PATH := "user://voice_timing_cache.json"

# Кэш таймкодов: { line_id: duration_in_seconds }
var _timing_cache: Dictionary = {}

# Кэш загруженных аудио потоков для анализа
var _audio_streams_cache: Dictionary = {}

# Флаг загрузки
var _is_loaded: bool = false

# Очередь файлов для анализа длительности
var _scan_queue: Array[String] = []

# Текущий анализируемый файл
var _current_analyzing_file: String = ""

# Аудио плеер для анализа (не воспроизводит, только измеряет)
var _analysis_player: AudioStreamPlayer = null

func _ready() -> void:
	add_to_group("voice_timing_manager")
	_create_analysis_player()
	_load_timing_cache()
	print("[VoiceTimingManager] Инициализирован")

func _create_analysis_player() -> void:
	_analysis_player = AudioStreamPlayer.new()
	_analysis_player.bus = "Master"
	_analysis_player.volume_db = -80.0  # Полностью тихий
	add_child(_analysis_player)

# Загрузить кэш таймкодов из файла
func _load_timing_cache() -> void:
	if FileAccess.file_exists(TIMING_FILE_PATH):
		var file = FileAccess.open(TIMING_FILE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var error = json.parse(content)
			if error == OK:
				_timing_cache = json.data
				_is_loaded = true
				print("[VoiceTimingManager] Кэш таймкодов загружен. Записей: ", _timing_cache.size())
			else:
				print("[VoiceTimingManager] Ошибка парсинга кэша: ", error)
				_timing_cache = {}
	else:
		print("[VoiceTimingManager] Кэш таймкодов не найден. Будет создан при первом использовании.")
		_timing_cache = {}

# Сохранить кэш таймкодов в файл
func save_timing_cache() -> void:
	var file = FileAccess.open(TIMING_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(_timing_cache, "  ")
		file.store_string(json_string)
		file.close()
		print("[VoiceTimingManager] Кэш таймкодов сохранён: ", TIMING_FILE_PATH)
	else:
		print("[VoiceTimingManager] Ошибка сохранения кэша")

# Получить длительность аудио для реплики по ID
func get_timing_for_line(line_id: String, character: String = "") -> float:
	# Сначала пробуем найти в кэше по line_id
	if _timing_cache.has(line_id):
		return _timing_cache[line_id]
	
	# Если нет, пробуем найти по имени файла
	var filename = VoiceManager.text_to_filename(VoiceManager.get_russian_text(line_id), character)
	if not filename.is_empty() and _timing_cache.has(filename):
		return _timing_cache[filename]
	
	# Если нет в кэше, пробуем найти файл и измерить
	var voice_manager = get_node_or_null("/root/VoiceManager")
	if voice_manager:
		var voice_file = voice_manager.get_voice_file_for_russian_line(line_id, character)
		if not voice_file.is_empty():
			var duration = _analyze_audio_file(VOICE_FOLDER + voice_file)
			if duration > 0:
				# Сохраняем в кэш
				_timing_cache[line_id] = duration
				_timing_cache[voice_file] = duration
				save_timing_cache()
				return duration
	
	return 0.0

# Получить длительность аудио по имени файла
func get_timing_for_file(filename: String) -> float:
	if _timing_cache.has(filename):
		return _timing_cache[filename]
	
	var full_path = VOICE_FOLDER + filename
	var duration = _analyze_audio_file(full_path)
	
	if duration > 0:
		_timing_cache[filename] = duration
		save_timing_cache()
	
	return duration

# Анализировать длительность аудио файла
func _analyze_audio_file(file_path: String) -> float:
	if not ResourceLoader.exists(file_path):
		print("[VoiceTimingManager] Файл не найден: ", file_path)
		return 0.0
	
	# Проверяем кэш загруженных потоков
	if _audio_streams_cache.has(file_path):
		var stream = _audio_streams_cache[file_path]
		return stream.get_length()
	
	# Загружаем аудио поток
	var stream = load(file_path) as AudioStream
	if stream == null:
		print("[VoiceTimingManager] Не удалось загрузить: ", file_path)
		return 0.0
	
	# Кэшируем поток
	_audio_streams_cache[file_path] = stream
	
	# Получаем длительность
	var duration = stream.get_length()
	print("[VoiceTimingManager] Длительность ", file_path, ": ", duration, " сек")
	
	return duration

# Сканировать всю папку с аудио и создать таймкоды
func scan_all_audio_files() -> void:
	timing_scan_started.emit()
	_scan_queue.clear()
	
	# Рекурсивно сканируем папку
	_scan_directory(VOICE_FOLDER)
	
	print("[VoiceTimingManager] Начато сканирование ", _scan_queue.size(), " файлов")
	_process_scan_queue()

func _scan_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				# Рекурсивно сканируем подпапки
				if file_name != "." and file_name != "..":
					_scan_directory(path + "/" + file_name)
			else:
				# Проверяем расширение
				if file_name.ends_with(".flac") or file_name.ends_with(".ogg") or \
				   file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
					_scan_queue.append(path + "/" + file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("[VoiceTimingManager] Не удалось открыть папку: ", path)

func _process_scan_queue() -> void:
	if _scan_queue.is_empty():
		timing_scan_finished.emit(_timing_cache.size())
		print("[VoiceTimingManager] Сканирование завершено. Найдено ", _timing_cache.size(), " таймкодов")
		return
	
	var file_path = _scan_queue.pop_front()
	var duration = _analyze_audio_file(file_path)
	
	if duration > 0:
		# Извлекаем имя файла из пути
		var filename = file_path.get_file()
		_timing_cache[filename] = duration
	
	# Продолжаем обработку
	_process_scan_queue()

# Синхронная версия сканирования (для использования вне сцены)
func scan_all_audio_files_sync() -> int:
	var total_scanned = 0
	var dir = DirAccess.open(VOICE_FOLDER)
	
	if dir:
		var files = _get_all_audio_files_recursive(VOICE_FOLDER)
		
		for file_path in files:
			var duration = _analyze_audio_file(file_path)
			if duration > 0:
				var filename = file_path.get_file()
				_timing_cache[filename] = duration
				total_scanned += 1
		
		save_timing_cache()
		print("[VoiceTimingManager] Синхронное сканирование завершено. Обработано: ", total_scanned)
	
	return total_scanned

func _get_all_audio_files_recursive(path: String) -> Array[String]:
	var result: Array[String] = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					result.append_array(_get_all_audio_files_recursive(path + "/" + file_name))
			else:
				if file_name.ends_with(".flac") or file_name.ends_with(".ogg") or \
				   file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
					result.append(path + "/" + file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return result

# Очистить кэш таймкодов
func clear_timing_cache() -> void:
	_timing_cache.clear()
	var file = FileAccess.open(TIMING_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string("{}")
		file.close()
	print("[VoiceTimingManager] Кэш таймкодов очищен")

# Получить статистику
func get_stats() -> Dictionary:
	return {
		"total_timings": _timing_cache.size(),
		"cached_streams": _audio_streams_cache.size(),
		"is_loaded": _is_loaded,
		"cache_file_exists": FileAccess.file_exists(TIMING_FILE_PATH)
	}

# Экспорт таймкодов в CSV для внешнего использования
func export_timing_to_csv(output_path: String) -> void:
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_line("filename,line_id,duration_seconds")
		
		for key in _timing_cache.keys():
			var duration = _timing_cache[key]
			# Пробуем найти соответствующий line_id
			var line_id = _find_line_id_for_filename(key)
			file.store_line("%s,%s,%.3f" % [key, line_id, duration])
		
		file.close()
		print("[VoiceTimingManager] Таймкоды экспортированы в CSV: ", output_path)

func _find_line_id_for_filename(filename: String) -> String:
	# Упрощённая реализация - можно расширить
	# В идеале нужно искать в русификаторе текст соответствующий имени файла
	return ""

# Получить все таймкоды
func get_all_timings() -> Dictionary:
	return _timing_cache.duplicate()
