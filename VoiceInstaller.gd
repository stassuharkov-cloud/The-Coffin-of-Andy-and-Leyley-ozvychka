extends Node

# Путь куда будем устанавливать
const TARGET_BASE_PATH = "res://voice_mod/audio/"
# Поддерживаемые расширения
const SUPPORTED_EXTENSIONS = [".flac", ".ogg", ".wav", ".mp3"]

var timer: Timer
var files_to_process: Array = []
var current_index: int = 0
var total_files: int = 0

@onready var status_label: Label = $StatusLabel

func _ready():
	print("[INSTALLER] Запуск установщика озвучки...")
	if status_label:
		status_label.text = "Поиск файлов озвучки..."
	
	# Даем движку время инициализироваться перед тяжелыми операциями
	await get_tree().process_frame
	start_installation()

func start_installation():
	# 1. Ищем файлы в корне проекта (res://)
	var source_files = find_source_files("res://")
	
	if source_files.is_empty():
		var msg = "Файлы озвучки не найдены в корне проекта.\nПоложите файл(ы) озвучки в папку с проектом (рядом с project.godot).\nОжидаемый формат имени: ID_Персонаж.ext (например: F6mK5ZQ0_andy.flac)"
		print("[INSTALLER] " + msg.replace("\n", " "))
		if status_label:
			status_label.text = msg
		return
	
	files_to_process = source_files
	total_files = files_to_process.size()
	current_index = 0
	
	print("[INSTALLER] Найдено файлов для обработки: %d" % total_files)
	if status_label:
		status_label.text = "Найдено файлов: %d\nНачинаю установку..." % total_files
	
	# Запускаем таймер для пошаговой обработки (чтобы не заморозить редактор/игру)
	timer = Timer.new()
	timer.wait_time = 0.05 # Обрабатываем по файлу каждые 0.05 сек (быстрее, но без фризов)
	timer.timeout.connect(_process_next_file)
	add_child(timer)
	timer.start()

func find_source_files(path: String) -> Array:
	var found_files = []
	var dir = DirAccess.open(path)
	
	if not dir:
		return found_files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path.path_join(file_name)
		
		if dir.current_is_dir():
			# Рекурсивно ищем в подпапках, но пропускаем системные и уже готовые
			if file_name != "voice_mod" and file_name != ".godot" and file_name != ".import":
				found_files.append_array(find_source_files(full_path))
		else:
			# Проверяем расширение
			var ext = file_name.get_extension().to_lower()
			if ext in ["flac", "ogg", "wav", "mp3"]:
				# Игнорируем файлы, которые уже лежат в voice_mod
				if not full_path.contains("/voice_mod/"):
					found_files.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return found_files

func _process_next_file():
	if current_index >= total_files:
		finish_installation()
		return
	
	var source_path = files_to_process[current_index]
	process_file(source_path)
	
	current_index += 1
	
	# Обновляем UI каждые 10 файлов или в конце
	if current_index % 10 == 0 or current_index == total_files:
		if status_label:
			status_label.text = "Обработка: %d / %d" % [current_index, total_files]
		print("[INSTALLER] Прогресс: %d / %d" % [current_index, total_files])

func process_file(source_path: String):
	var file_name = source_path.get_file()
	var base_name = file_name.get_basename()
	var ext = "." + file_name.get_extension()
	
	# Логика парсинга имени: ожидаем "ID_Персонаж" или "Персонаж_ID"
	# Попробуем найти последний подчеркиватель как разделитель
	var last_underscore = base_name.rfind("_")
	
	var char_name = "unknown"
	var line_id = base_name
	
	if last_underscore != -1:
		var part1 = base_name.substr(0, last_underscore)
		var part2 = base_name.substr(last_underscore + 1)
		
		# Эвристика: обычно ID короче или специфичнее, а имя персонажа читаемое
		# Предположим формат: ID_CharName (чаще всего в таких сборках)
		# Если part2 выглядит как имя (длиннее 2 символов и не только цифры), считаем его именем
		if part2.length() > 2 and not part2.is_valid_int():
			char_name = part2
			line_id = part1
		else:
			# Иначе наоборот: CharName_ID
			char_name = part1
			line_id = part2
	else:
		print("[WARN] Не удалось распарсить имя файла: %s. Пропускаем." % file_name)
		return
	
	# Очищаем имя персонажа от мусора
	char_name = char_name.replace(" ", "_").replace("-", "_").to_lower()
	
	# Формируем путь назначения
	var target_dir = TARGET_BASE_PATH.path_join(char_name)
	var target_path = target_dir.path_join(line_id + ext)
	
	# Создаем папку если нет
	var dir = DirAccess.open(TARGET_BASE_PATH)
	if not dir.dir_exists(char_name):
		dir.make_dir(char_name)
	
	# Копируем файл
	if FileAccess.file_exists(target_path):
		# print("[SKIP] Файл уже существует: %s" % target_path)
		return
	
	var err = DirAccess.copy_absolute(source_path, target_path)
	if err == OK:
		# print("[OK] Установлено: %s -> %s" % [file_name, target_path])
		pass
	else:
		print("[ERROR] Ошибка копирования %s: Код %d" % [file_name, err])

func finish_installation():
	print("[INSTALLER] Установка завершена!")
	print("[INSTALLER] Все файлы распределены по папкам: %s" % TARGET_BASE_PATH)
	
	if status_label:
		status_label.text = "Установка завершена!\nФайлов обработано: %d\n\nТеперь запустите игру.\nКэш таймкодов создастся автоматически." % total_files
	
	# Принудительно сканируем таймкоды сразу после установки
	scan_timing_cache()
	
	# Предлагаем удалить исходные файлы (опционально, здесь просто лог)
	print("[INFO] Рекомендуется вручную удалить исходные большие файлы озвучки из корня проекта.")
	
	# Выход из сцены установщика (можно заменить на запуск основной игры)
	print("[INSTALLER] Работа установщика окончена.")
	# get_tree().quit() # Раскомментируйте, если это отдельное приложение-установщик

func scan_timing_cache():
	print("[INSTALLER] Генерация кэша таймкодов...")
	# Здесь мы эмулируем вызов менеджера таймкодов, если бы он был доступен
	# Но так как это установщик, мы просто сообщаем, что теперь VoiceTimingManager
	# при первом запуске игры быстро найдет все файлы.
	# Если нужно сделать прямо сейчас, нужно подключить этот скрипт к autoload или вызвать метод.
	# Для простоты оставим это на первый запуск основной игры, так как файлы уже на месте.
	print("[INSTALLER] Кэш будет создан автоматически при первом запуске игры.")
