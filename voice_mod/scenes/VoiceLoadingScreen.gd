extends CanvasLayer

# Загрузочный экран для создания таймкодов озвучки
# Автоматически сканирует папку с аудио и создаёт кэш таймкодов
# Показывает прогресс-бар и информацию о процессе

signal timing_scan_completed(total_files: int, total_duration: float)

# Путь к папке с голосовыми файлами
const VOICE_FOLDER := "res://voice_mod/audio/"

# Путь к файлу с таймкодами
const TIMING_FILE_PATH := "user://voice_timing_cache.json"

# UI элементы
var _panel: Panel
var _vbox: VBoxContainer
var _title_label: Label
var _progress_bar: ProgressBar
var _status_label: Label
var _file_label: Label
var _details_label: Label

# Данные для сканирования
var _files_to_scan: Array[String] = []
var _current_file_index: int = 0
var _timing_cache: Dictionary = {}
var _total_duration: float = 0.0
var _is_scanning: bool = false

# Аудио плеер для анализа
var _analysis_player: AudioStreamPlayer = null

func _ready() -> void:
	_create_ui()
	add_to_group("voice_loading_screen")
	print("[VoiceLoadingScreen] Инициализирован")

func _create_ui() -> void:
	# Основной фон
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Panel"))
	add_child(_panel)
	
	# Вертикальный контейнер
	_vbox = VBoxContainer.new()
	_vbox.set_anchors_preset(Control.PRESET_CENTER)
	_vbox.set_offset(Side.LEFT, -200)
	_vbox.set_offset(Side.TOP, -150)
	_vbox.set_offset(Side.RIGHT, 200)
	_vbox.set_offset(Side.BOTTOM, 150)
	_vbox.add_theme_constant_override("separation", 15)
	_panel.add_child(_vbox)
	
	# Заголовок
	_title_label = Label.new()
	_title_label.text = "Сканирование аудиофайлов..."
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 24)
	_vbox.add_child(_title_label)
	
	# Прогресс бар
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.show_percentage = true
	_progress_bar.custom_minimum_size = Vector2(0, 30)
	_vbox.add_child(_progress_bar)
	
	# Статус
	_status_label = Label.new()
	_status_label.text = "Подготовка..."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(_status_label)
	
	# Текущий файл
	_file_label = Label.new()
	_file_label.text = ""
	_file_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_file_label.add_theme_color_override("font_color", Color.GRAY)
	_vbox.add_child(_file_label)
	
	# Детали
	_details_label = Label.new()
	_details_label.text = "Файлов: 0 | Длительность: 0:00"
	_details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_details_label.add_theme_font_size_override("font_size", 16)
	_vbox.add_child(_details_label)

func _create_analysis_player() -> void:
	if _analysis_player == null:
		_analysis_player = AudioStreamPlayer.new()
		_analysis_player.bus = "Master"
		_analysis_player.volume_db = -80.0  # Полностью тихий
		add_child(_analysis_player)

# Начать сканирование
func start_scanning() -> void:
	if _is_scanning:
		return
	
	_is_scanning = true
	_create_analysis_player()
	
	# Собираем все аудио файлы
	_files_to_scan.clear()
	_scan_directory(VOICE_FOLDER)
	
	if _files_to_scan.is_empty():
		_status_label.text = "Аудиофайлы не найдены!"
		await get_tree().create_timer(2.0).timeout
		queue_free()
		return
	
	_progress_bar.max_value = _files_to_scan.size()
	_current_file_index = 0
	_timing_cache.clear()
	_total_duration = 0.0
	
	_status_label.text = "Найдено файлов: %d" % _files_to_scan.size()
	
	# Начинаем обработку с небольшой задержкой для отображения UI
	await get_tree().create_timer(0.1).timeout
	_process_next_file()

func _scan_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					_scan_directory(path + "/" + file_name)
			else:
				if file_name.ends_with(".flac") or file_name.ends_with(".ogg") or \
				   file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
					_files_to_scan.append(path + "/" + file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("[VoiceLoadingScreen] Не удалось открыть папку: ", path)

func _process_next_file() -> void:
	if _current_file_index >= _files_to_scan.size():
		_finish_scanning()
		return
	
	var file_path = _files_to_scan[_current_file_index]
	_file_label.text = file_path.get_file()
	
	# Анализируем файл
	var duration = _analyze_audio_file(file_path)
	
	if duration > 0:
		var filename = file_path.get_file()
		_timing_cache[filename] = duration
		_total_duration += duration
	
	_current_file_index += 1
	_progress_bar.value = _current_file_index
	
	# Обновляем детали
	var minutes = int(_total_duration / 60)
	var seconds = int(_total_duration) % 60
	_details_label.text = "Обработано: %d/%d | Всего: %d:%02d" % [_current_file_index, _files_to_scan.size(), minutes, seconds]
	
	# Продолжаем следующий кадр для обновления UI
	await get_tree().process_frame
	_process_next_file()

func _analyze_audio_file(file_path: String) -> float:
	if not ResourceLoader.exists(file_path):
		return 0.0
	
	var stream = load(file_path) as AudioStream
	if stream == null:
		return 0.0
	
	return stream.get_length()

func _finish_scanning() -> void:
	_is_scanning = false
	
	# Сохраняем кэш
	_save_timing_cache()
	
	_status_label.text = "Готово!"
	_file_label.text = ""
	
	var minutes = int(_total_duration / 60)
	var seconds = int(_total_duration) % 60
	_details_label.text = "Всего файлов: %d | Общая длительность: %d:%02d" % [_timing_cache.size(), minutes, seconds]
	
	print("[VoiceLoadingScreen] Сканирование завершено. Файлов: %d, Длительность: %.2f сек" % [_timing_cache.size(), _total_duration])
	
	# Ждём немного и закрываем экран
	await get_tree().create_timer(1.5).timeout
	timing_scan_completed.emit(_timing_cache.size(), _total_duration)
	queue_free()

func _save_timing_cache() -> void:
	var file = FileAccess.open(TIMING_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(_timing_cache, "  ")
		file.store_string(json_string)
		file.close()
		print("[VoiceLoadingScreen] Кэш таймкодов сохранён: ", TIMING_FILE_PATH)
	else:
		print("[VoiceLoadingScreen] Ошибка сохранения кэша")

# Статический метод для быстрого создания и запуска
static func create_and_show(root: Node) -> VoiceLoadingScreen:
	var loader = new()
	root.add_child(loader)
	loader.start_scanning()
	return loader

# Получить статистику
func get_stats() -> Dictionary:
	return {
		"total_files": _files_to_scan.size(),
		"processed_files": _current_file_index,
		"cached_timings": _timing_cache.size(),
		"total_duration": _total_duration,
		"is_scanning": _is_scanning
	}
