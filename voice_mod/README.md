# Мод озвучки для The Coffin of Andy and Leyley

Этот мод добавляет систему воспроизводства голосовой озвучки для диалогов в игре.

## 📁 Структура папок

```
voice_mod/
├── autoload/
│   ├── VoiceManager.gd              # Основной менеджер голоса
│   └── DialogueVoiceIntegration.gd  # Интеграция с диалогами
├── audio/                           # ПАПКА ДЛЯ ВАШИХ ФАЙЛОВ ОЗВУЧКИ
│   ├── andy_hello.flac
│   ├── leyley_greeting.flac
│   └── ...
└── config/
    └── voice_settings.ini           # Настройки мода
```

## 🎤 Как добавить озвучку

### Вариант 1: Именование по тексту реплики (автоматическое)

Система автоматически преобразует текст реплики в имя файла:

**Пример:**
- Реплика: `"Привет, Энди!"` от персонажа `andy`
- Имя файла: `andy_privet_endi.flac`

**Правила именования:**
1. Текст переводится в нижний регистр
2. Спецсимволы удаляются
3. Пробелы заменяются на `_`
4. Добавляется префикс персонажа
5. Расширение `.flac` (также поддерживаются `.ogg`, `.wav`, `.mp3`)

### Вариант 2: Ручное указание имени файла

Вы можете вручную указать имя файла для каждой реплики в формате:
```
{персонаж}_{контекст}.flac
```

**Примеры:**
- `andy_ch1_intro_line1.flac` - Энди, глава 1, интро, строка 1
- `leyley_kitchen_angry.flac` - Лейли, кухня, злая реплика
- `andy_final_boss_taunt.flac` - Энди, финальный босс, насмешка

## 📝 Поддерживаемые имена персонажей

| В игре | В имени файла |
|--------|---------------|
| andy, энди, andrew, эндру | andy |
| leyley, лейли, leyla, лейла, ashley, эштли | leyley |

## 🔧 Установка в проект Godot

### Шаг 1: Скопируйте файлы мода

Переместите папку `voice_mod` в корень проекта игры:
```
TheCoffinOfAndyAndLeyley/
├── voice_mod/          ← скопировать сюда
├── scenes/
├── scripts/
└── project.godot
```

### Шаг 2: Добавьте автозагрузку

1. Откройте `Project` → `Project Settings` → `Autoload`
2. Добавьте следующие файлы как autoload:
   - `res://voice_mod/autoload/VoiceManager.gd` → имя: `VoiceManager`
   - `res://voice_mod/autoload/DialogueVoiceIntegration.gd` → имя: `DialogueVoice` (опционально)

### Шаг 3: Интеграция с диалоговой системой

#### Способ A: Автоматическая интеграция

В основном скрипте диалогов добавьте:

```gdscript
func _ready() -> void:
    # Найти узлы текста диалога
    var dialogue_label = $DialogueContainer/TextLabel
    var speaker_label = $DialogueContainer/SpeakerLabel
    
    # Настроить интеграцию
    DialogueVoice.setup_voice_integration(
        get_tree().root,
        ^"Path/To/DialogueNode",
        ^"Path/To/TextLabel",
        ^"Path/To/SpeakerLabel"
    )
```

#### Способ B: Ручной вызов

В месте где показывается текст диалога:

```gdscript
func show_dialogue(text: String, speaker: String) -> void:
    # Ваш существующий код показа текста
    dialogue_label.text = text
    speaker_label.text = speaker
    
    # Добавить воспроизведение голоса
    if VoiceManager:
        var filename = VoiceManager.text_to_filename(text, speaker)
        VoiceManager.play_voice(filename)
```

#### Способ C: Прямое указание имени файла

```gdscript
func play_character_voice(character: String, filename: String) -> void:
    VoiceManager.play_voice(character + "_" + filename)

# Пример использования:
play_character_voice("andy", "hello.flac")  # Воспроизведёт voice_mod/audio/andy_hello.flac
```

## 🎮 Использование в игре

### Основные функции VoiceManager

```gdscript
# Воспроизвести файл
VoiceManager.play_voice("andy_hello.flac")

# Воспроизвести немедленно (очистить очередь)
VoiceManager.play_voice_immediate("leyley_scream.flac")

# Проверить, играет ли сейчас голос
if VoiceManager.is_playing:
    print("Голос воспроизводится")

# Остановить текущее воспроизведение
VoiceManager.stop()

# Установить громкость (в dB)
VoiceManager.set_volume(-5.0)

# Получить текущий файл
var current = VoiceManager.get_current_file()
```

### Сигналы

```gdscript
# Подключение к сигналам
VoiceManager.voice_started.connect(_on_voice_started)
VoiceManager.voice_finished.connect(_on_voice_finished)

func _on_voice_started(file_name: String) -> void:
    print("Начало воспроизведения: ", file_name)

func _on_voice_finished() -> void:
    print("Воспроизведение завершено")
```

## 📋 Конфигурация

Отредактируйте `voice_mod/config/voice_settings.ini`:

```ini
[general]
enabled=true              # Включить/выключить озвучку
volume_db=0.0            # Громкость в децибелах
cache_enabled=true       # Кэширование аудио файлов

[behavior]
playback_mode="queue"    # queue/immediate/wait
on_click_behavior="stop" # stop/wait/ignore при клике

[debug]
log_enabled=true         # Логирование в консоль
```

## 💡 Советы по организации файлов

### Рекомендуемая структура для больших проектов:

```
voice_mod/audio/
├── chapter_1/
│   ├── andy/
│   │   ├── intro_line1.flac
│   │   └── kitchen_scene.flac
│   └── leyley/
│       ├── intro_line1.flac
│       └── basement_scene.flac
├── chapter_2/
│   └── ...
└── common/
    ├── andy_greeting.flac
    └── leyley_laugh.flac
```

### Для совместимости с русификатором Playground:

Используйте формат именования который соответствует ключам перевода:

```
# Если в русификаторе ключ: dialogue.ch1.andys_room.line_001
# Назовите файл: ch1_andys_room_line_001.flac

# Или проще - по тексту:
# Ключ: "Привет! Как дела?"
# Файл: privet_kak_dela.flac
```

## 🔍 Отладка

Включите логирование в конфиге и следите за консолью:

```
[VoiceManager] Инициализирован. Папка: res://voice_mod/audio/
[VoiceManager] Воспроизводится: andy_hello.flac
[VoiceManager] Файл не найден: res://voice_mod/audio/leyley_test.flac
```

## ❓ Частые проблемы

### Файл не воспроизводится
- Проверьте что файл находится в `voice_mod/audio/`
- Убедитесь что имя файла точно совпадает (регистр важен!)
- Проверьте консоль на ошибки загрузки

### Голос прерывается
- Измените `on_click_behavior` на `wait` в конфиге
- Или не вызывайте `VoiceManager.stop()` при клике

### Низкая производительность
- Включите кэширование в настройках
- Используйте формат `.ogg` вместо `.wav` для длинных файлов

## 📞 Совместимость

- ✅ Все главы (1, 2, 3)
- ✅ Любой русификатор (включая Playground)
- ✅ Любые форматы аудио: FLAC, OGG, WAV, MP3
- ✅ Godot 4.x

## 📄 Лицензия

Свободное использование для модификации игры.
