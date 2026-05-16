# INSTALLATION.md - Инструкция по установке мода озвучки

## Быстрая установка

### 1. Скопируйте файлы в проект игры

```
Скопируйте папку voice_mod/ в корень проекта The Coffin of Andy and Leyley:

TheCoffinOfAndyAndLeyley/
├── voice_mod/              ← СКОПИРОВАТЬ СЮДА
│   ├── autoload/
│   ├── audio/
│   └── config/
├── scenes/
├── scripts/
└── project.godot
```

### 2. Добавьте автозагрузку в Godot

1. Откройте проект в Godot Engine
2. Перейдите в `Project` → `Project Settings` → `Autoload`
3. Нажмите `+` и добавьте:
   - **Путь:** `res://voice_mod/autoload/VoiceManager.gd`
   - **Имя:** `VoiceManager`
   - Нажмите `Add`

4. (Опционально) Добавьте интеграцию с диалогами:
   - **Путь:** `res://voice_mod/autoload/DialogueVoiceIntegration.gd`
   - **Имя:** `DialogueVoice`
   - Нажмите `Add`

### 3. Настройте аудио шину (опционально, но рекомендуется)

1. Откройте `Project` → `Project Settings` → `Audio`
2. В разделе `Buses` нажмите `+` чтобы добавить новую шину
3. Назовите её `Voice`
4. Настройте громкость по вкусу

### 4. Добавьте свои аудиофайлы

Поместите файлы озвучки в папку:
```
voice_mod/audio/
```

**Примеры имен файлов:**
- `andy_privet.flac` - Энди говорит "Привет"
- `leyley_smeh.flac` - Лейли смеётся
- `andy_glava1_line1.flac` - Энди, глава 1, строка 1

Смотрите `voice_mod/audio/FILE_NAMING_EXAMPLES.txt` для полного списка примеров.

### 5. Интегрируйте с диалоговой системой

Откройте основной скрипт диалогов (обычно находится в `scripts/` или `scenes/`) и найдите место где показывается текст диалога.

**Вариант A: Простая интеграция (рекомендуется)**

Найдите функцию которая показывает текст диалога и добавьте вызов VoiceManager:

```gdscript
# Было:
func show_dialogue(text: String, speaker: String) -> void:
    dialogue_label.text = text
    speaker_label.text = speaker

# Стало:
func show_dialogue(text: String, speaker: String) -> void:
    dialogue_label.text = text
    speaker_label.text = speaker
    
    # Добавить озвучку:
    if VoiceManager:
        var filename = VoiceManager.text_to_filename(text, speaker)
        VoiceManager.play_voice(filename)
```

**Вариант B: Ручное управление**

Если вы хотите вручную указывать имена файлов:

```gdscript
func play_voice_for_line(character: String, line_id: String) -> void:
    if VoiceManager:
        VoiceManager.play_voice(character + "_" + line_id + ".flac")

# Использование:
play_voice_for_line("andy", "hello")  # Воспроизведёт andy_hello.flac
```

**Вариант C: Автоматическая интеграция через DialogueVoice**

Если добавили DialogueVoice как autoload:

```gdscript
func _ready() -> void:
    DialogueVoice.dialogue_label = $DialogueContainer/TextLabel
    DialogueVoice.speaker_label = $DialogueContainer/SpeakerLabel
    
    # Подключиться к сигналам вашей системы диалогов
    YourDialogueSystem.text_changed.connect(DialogueVoice.show_dialogue)
```

### 6. Проверьте работу

1. Запустите игру (F5)
2. Откройте консоль отладки (обычно F2 или в меню)
3. Должны увидеть сообщение: `[VoiceManager] Инициализирован. Папка: res://voice_mod/audio/`
4. При появлении диалога должно воспроизводиться аудио

## Настройка

### Изменение громкости

**Способ 1: Через код**
```gdscript
VoiceManager.set_volume(-5.0)  # -5 dB
```

**Способ 2: Через конфиг**
Откройте `voice_mod/config/voice_settings.ini`:
```ini
[general]
volume_db=-3.0
```

### Отключение озвучки

**Временно через код:**
```gdscript
VoiceManager.enabled = false
```

**Через конфиг:**
```ini
[general]
enabled=false
```

## Структура файлов озвучки

### Рекомендуемая организация

Для большого количества файлов используйте подпапки:

```
voice_mod/audio/
├── ch1/                    # Глава 1
│   ├── andy/
│   │   ├── intro_001.flac
│   │   └── kitchen_015.flac
│   └── leyley/
│       ├── intro_001.flac
│       └── kitchen_016.flac
├── ch2/                    # Глава 2
│   └── ...
├── ch3/                    # Глава 3
│   └── ...
└── common/                 # Общие звуки
    ├── andy_laugh.flac
    └── leyley_giggle.flac
```

### Форматы файлов

Поддерживаются:
- `.flac` - **рекомендуется** (без потерь, хорошее сжатие)
- `.ogg` - хорошо для длинных файлов
- `.wav` - без сжатия (больший размер)
- `.mp3` - максимальное сжатие

## Решение проблем

### Файл не воспроизводится

1. Проверьте путь к файлу:
   ```
   voice_mod/audio/andy_test.flac
   ```

2. Проверьте имя файла (чувствительно к регистру):
   - ✅ `andy_privet.flac`
   - ❌ `Andy_Privet.flac`
   - ❌ `ANDY_PRIVET.FLAC`

3. Посмотрите логи в консоли:
   ```
   [VoiceManager] Файл не найден: res://voice_mod/audio/test.flac
   ```

### Голос прерывается при клике

Измените поведение в конфиге `voice_settings.ini`:
```ini
[behavior]
on_click_behavior="wait"  # Ждать окончания вместо остановки
```

### Игра тормозит при загрузке

Включите кэширование в конфиге:
```ini
[general]
cache_enabled=true
```

Используйте формат `.ogg` для длинных файлов.

### Ошибка "Voice bus not found"

Создайте аудио шину `Voice`:
1. `Project` → `Project Settings` → `Audio`
2. Добавьте новую шину с именем `Voice`

Или измените имя шины в коде:
```gdscript
# В VoiceManager.gd найдите:
_current_player.bus = "Voice"
# Замените на существующую шину:
_current_player.bus = "Master"
```

## Совместимость с русификаторами

Мод совместим с любым русификатором, включая популярный русификатор от Playground.

### Для русификатора Playground

Используйте один из форматов именования:

**По тексту реплики:**
```
privet_kak_dela.flac        # "Привет! Как дела?"
ya_ne_hochu_tuda.flac       # "Я не хочу туда..."
```

**По ключу перевода:**
Если в русификаторе ключи вида `dialogue.ch1.line_001`:
```
ch1_line_001_andy.flac
ch1_line_002_leyley.flac
```

## Дополнительные возможности

### Сигналы для продвинутой интеграции

```gdscript
# Подключиться к событиям начала/окончания голоса
VoiceManager.voice_started.connect(_on_voice_started)
VoiceManager.voice_finished.connect(_on_voice_finished)

func _on_voice_started(file_name: String) -> void:
    # Например, показать индикатор говорящего
    speaking_indicator.visible = true

func _on_voice_finished() -> void:
    speaking_indicator.visible = false
```

### Проверка наличия файла перед воспроизведением

```gdscript
func safe_play_voice(filename: String) -> void:
    var path = "res://voice_mod/audio/" + filename
    if ResourceLoader.exists(path):
        VoiceManager.play_voice(filename)
    else:
        print("Файл не найден: ", filename)
```

### Динамическая загрузка файлов

```gdscript
# Загрузить файл во время игры
var stream = load("res://voice_mod/audio/andy_new.flac")
if stream:
    $AudioStreamPlayer.stream = stream
    $AudioStreamPlayer.play()
```

## Тестирование

Создайте тестовую сцену для проверки:

```gdscript
extends Node

func _ready() -> void:
    pass

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1:
                VoiceManager.play_voice("andy_privet.flac")
            KEY_2:
                VoiceManager.play_voice("leyley_privet_brat.flac")
            KEY_3:
                VoiceManager.stop()
            KEY_R:
                VoiceManager.clear_cache()
```

Нажмите 1 или 2 для воспроизводства тестовых фраз, R для очистки кэша.

## Обратная связь

Если возникли проблемы:
1. Проверьте консоль на ошибки
2. Убедитесь что файлы в правильной папке
3. Проверьте имена файлов
4. Убедитесь что VoiceManager добавлен в autoload

Удачи с модом! 🎤
