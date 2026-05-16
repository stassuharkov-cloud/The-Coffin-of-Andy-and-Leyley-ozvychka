# Voice Loading Screen - Загрузочный экран для сканирования таймкодов

## Описание
Этот скрипт создаёт загрузочный экран, который автоматически сканирует все аудиофайлы в папке `voice_mod/audio/` и создаёт кэш таймкодов при первом запуске игры.

## Функционал

### Автоматическое создание
- При первом запуске игры (если файл `user://voice_timing_cache.json` не существует) автоматически показывается загрузочный экран
- Скрипт сканирует всю папку с аудио рекурсивно
- Поддерживает форматы: `.flac`, `.ogg`, `.wav`, `.mp3`

### Прогресс-бар
- Показывает текущий прогресс сканирования
- Отображает имя текущего обрабатываемого файла
- Показывает общее количество файлов и общую длительность всех аудио

### Сохранение кэша
- После завершения сканирования все таймкоды сохраняются в `user://voice_timing_cache.json`
- При последующих запусках игра использует кэш (мгновенная загрузка)

## Использование

### Вариант 1: Автоматически через DialogueVoiceIntegration
Просто добавьте `DialogueVoiceIntegration.gd` на сцену с диалогами. При первом запуске загрузочный экран появится автоматически.

### Вариант 2: Ручное создание в любой сцене
```gdscript
# В _ready() вашей стартовой сцены
func _ready():
    var loader = load("res://voice_mod/scenes/VoiceLoadingScreen.gd").new()
    add_child(loader)
    loader.start_scanning()
    
    # Ждём завершения
    await loader.timing_scan_completed
    print("Сканирование завершено! Файлов: ", loader.get_stats()["cached_timings"])
```

### Вариант 3: Статический метод
```gdscript
VoiceLoadingScreen.create_and_show(get_tree().current_scene)
await get_tree().process_frame  # Ждём пока UI обновится
```

## Сигналы

### timing_scan_completed(total_files: int, total_duration: float)
Вызывается когда сканирование завершено.
- `total_files` - количество обработанных файлов
- `total_duration` - общая длительность всех аудио в секундах

## Пример интеграции в главную сцену

```gdscript
extends Node

@onready var main_menu: Control = $MainMenu
@onready var loading_screen: VoiceLoadingScreen = null

func _ready():
    # Проверяем нужно ли сканирование
    if not FileAccess.file_exists("user://voice_timing_cache.json"):
        # Показываем загрузочный экран перед главным меню
        loading_screen = load("res://voice_mod/scenes/VoiceLoadingScreen.gd").new()
        add_child(loading_screen)
        
        # Блокируем меню пока идёт сканирование
        main_menu.process_mode = Node.PROCESS_MODE_DISABLED
        
        # Ждём завершения
        await loading_screen.timing_scan_completed
        
        # Разблокируем меню
        main_menu.process_mode = Node.PROCESS_MODE_INHERIT
        loading_screen.queue_free()
```

## Настройка внешнего вида

Можно отредактировать `_create_ui()` в `VoiceLoadingScreen.gd` чтобы изменить:
- Размер и позицию панели
- Цвета и шрифты
- Текст сообщений
- Размер прогресс-бара

## Примечания

1. **Большой файл озвучки**: Если вы используете один огромный файл с прохождением блогера, просто поместите его в `voice_mod/audio/`. Скрипт автоматически найдёт и измерит его длительность.

2. **Производительность**: Сканирование происходит асинхронно с отображением UI, поэтому игра не зависает.

3. **Повторное сканирование**: Если вы добавили новые аудиофайлы, удалите `user://voice_timing_cache.json` или вызовите `VoiceTimingManager.scan_all_audio_files()`.

4. **Папка по умолчанию**: `res://voice_mod/audio/` - можно изменить в константе `VOICE_FOLDER`.
