# Мод озвучки для The Coffin of Andy and Leyley

Этот мод добавляет систему воспроизводства голосовой озвучки для диалогов в игре.
**Поддерживает автоматическую работу с русификатором** (файл `Русский.cld` из `The Coffin of Andy and Leyley\www\languages`).

## 📁 Структура папок

```
voice_mod/
├── autoload/
│   ├── VoiceManager.gd              # Основной менеджер голоса
│   └── DialogueVoiceIntegration.gd  # Интеграция с диалогами
├── languages/                       # ПАПКА ДЛЯ РУСИФИКАТОРА
│   └── Русский.cld                  # Файл русификатора (обязателен для авто-озвучки)
├── audio/                           # ПАПКА ДЛЯ ВАШИХ ФАЙЛОВ ОЗВУЧКИ
│   ├── andy_hello.flac
│   ├── leyley_greeting.flac
│   └── ...
└── config/
    └── voice_settings.ini           # Настройки мода
```

## 🎤 Как работает озвучка с русификатором

### Автоматический режим (рекомендуется)

Система **автоматически** использует реплики из русификатора для генерации имён файлов озвучки:

1. При показе реплики система берёт её **ID** из диалоговой системы
2. Находит русский текст этой реплики в файле `Русский.cld`
3. Преобразует русский текст в имя файла
4. Воспроизводит соответствующий аудиофайл

**Пример:**
- ID реплики в игре: `F6mK5ZQ0`
- Русский текст из русификатора: `"У тебя кружится голова..."`
- Имя файла озвучки: `u_tebya_kruzhitsya_golova.flac`

### Что если реплики нет в русификаторе?

**Система не ломается!** Если реплика не найдена в русификаторе:
- Озвучка просто не воспроизводится для этой реплики
- Игра продолжает работать нормально
- В консоли появляется сообщение: `[DialogueVoice] Нет озвучки для реплики: ...`

### Ручной режим

Вы можете вручную указать имя файла для каждой реплики (как было раньше):

```gdscript
# Прямое указание имени файла
VoiceManager.play_voice("andy_ch1_intro_line1.flac")
```

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

### Шаг 2: Добавьте файл русификатора

Скопируйте файл русификатора в папку `voice_mod/languages/`:
```
voice_mod/languages/Русский.cld
```

Файл берётся из оригинальной игры: `The Coffin of Andy and Leyley\www\languages\Русский.cld`

### Шаг 3: Добавьте автозагрузку

1. Откройте `Project` → `Project Settings` → `Autoload`
2. Добавьте следующие файлы как autoload:
   - `res://voice_mod/autoload/VoiceManager.gd` → имя: `VoiceManager`
   - `res://voice_mod/autoload/DialogueVoiceIntegration.gd` → имя: `DialogueVoice` (опционально)

### Шаг 4: Интеграция с диалоговой системой

#### Способ A: Автоматическая интеграция (с поддержкой русификатора)

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

**Важно:** Передавайте ID реплики при вызове `show_dialogue()`:

```gdscript
# В вашей диалоговой системе:
func show_next_line() -> void:
    var line_data = get_current_line()  # Ваши данные реплики
    DialogueVoice.show_dialogue(
        line_data.text,
        line_data.speaker,
        line_data.id  # ID реплики для поиска в русификаторе!
    )
```

#### Способ B: Ручной вызов

В месте где показывается текст диалога:

```gdscript
func show_dialogue(text: String, speaker: String, line_id: String = "") -> void:
    # Ваш существующий код показа текста
    dialogue_label.text = text
    speaker_label.text = speaker
    
    # Добавить воспроизведение голоса (с ID для русификатора)
    if VoiceManager:
        # Если есть ID - система сама найдёт реплику в русификаторе
        if not line_id.is_empty():
            var filename = VoiceManager.get_voice_file_for_russian_line(line_id, speaker)
            if not filename.is_empty():
                VoiceManager.play_voice(filename)
        else:
            # Или по старинке - из текста
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
# Получить русский текст по ID реплики
var russian_text = VoiceManager.get_russian_text("F6mK5ZQ0")
# Вернёт: "У тебя кружится голова..."

# Получить имя файла озвучки для русской реплики
var filename = VoiceManager.get_voice_file_for_russian_line("F6mK5ZQ0", "andy")
# Вернёт: "u_tebya_kruzhitsya_golova.flac"

# Проверить загружен ли русификатор
if VoiceManager.is_rusifier_loaded():
    print("Русификатор активен!")

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
use_rusifier=true        # Использовать русификатор для авто-имён

[behavior]
playback_mode="queue"    # queue/immediate/wait
on_click_behavior="stop" # stop/wait/ignore при клике

[debug]
log_enabled=true         # Логирование в консоль
```

## 💡 Советы по организации файлов

### Рекомендуемая структура для больших проектов:

```
voice_mod/
├── languages/
│   └── Русский.cld
├── audio/
│   ├── chapter_1/
│   │   ├── andy/
│   │   │   ├── u_tebya_kruzhitsya_golova.flac
│   │   │   └── ya_ne_hochu_umirat.flac
│   │   └── leyley/
│   │       ├── privet_bratrik.flac
│   │       └── davay_poedim.flac
│   ├── chapter_2/
│   │   └── ...
│   └── common/
│       ├── andy_greeting.flac
│       └── leyley_laugh.flac
```

### Как узнать ID реплики?

ID реплик можно найти в файле русификатора `Русский.cld`. Это короткие строки типа:
- `F6mK5ZQ0`
- `rz4CQmyz`
- `bz5c1ClQ`

Используйте эти ID в вашей диалоговой системе для автоматической озвучки.

## 🔍 Отладка

Включите логирование в конфиге и следите за консолью:

```
[VoiceManager] Инициализирован. Папка: res://voice_mod/audio/
[VoiceManager] Русификатор загружен. Строк: 15114
[DialogueVoice] Найдена реплика в русификаторе для ID: F6mK5ZQ0
[VoiceManager] Воспроизводится: u_tebya_kruzhitsya_golova.flac
[DialogueVoice] Нет озвучки для реплики: Какая-то реплика без озвучки
```

## ❓ Частые проблемы

### Файл русификатора не найден
- Убедитесь что файл `Русский.cld` находится в `voice_mod/languages/`
- Проверьте что путь указан правильно в `VoiceManager.gd`: `const RUSIFIER_PATH := "res://voice_mod/languages/Русский.cld"`

### Озвучка не работает для некоторых реплик
- Проверьте что ID реплики передаётся в `show_dialogue()`
- Убедитесь что реплика есть в русификаторе
- Система **не ломается** если реплики нет - она просто пропускает озвучку

### Файл озвучки не воспроизводится
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
- ✅ Русификатор Playground и другие (формат `.cld`)
- ✅ Работает БЕЗ русификатора (не ломается)
- ✅ Любые форматы аудио: FLAC, OGG, WAV, MP3
- ✅ Godot 4.x

## 📄 Лицензия

Свободное использование для модификации игры.
