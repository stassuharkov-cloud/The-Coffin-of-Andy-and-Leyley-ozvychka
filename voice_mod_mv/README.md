# Мод озвучки для RPG Maker MV

Этот мод добавляет систему воспроизводства голосовой озвучки для диалогов в играх на RPG Maker MV.
**Поддерживает автоматическую работу с русификатором** (файл `Русский.cld`).

## 📁 Структура папок

```
project/
├── audio/
│   └── voice/              <-- Папка с голосами
│       ├── andy_hello.ogg
│       ├── leyley_greeting.ogg
│       └── ...
├── data/
│   └── Русский.cld         <-- Файл русификатора (опционально)
└── js/
    └── plugins/
        └── VoiceMod.js     <-- Плагин озвучки
```

## ⚙️ Установка

### Шаг 1: Скопируйте плагин

Поместите файл `VoiceMod.js` в папку `js/plugins/` вашего проекта RPG Maker MV.

### Шаг 2: Включите плагин

1. Откройте редактор RPG Maker MV
2. Перейдите в `Tools` → `Plugin Manager` (F10)
3. Добавьте новый плагин: `VoiceMod`
4. Установите параметры:
   - **VoiceFolder**: `audio/voice` (путь к папке с голосами)
   - **RusifierPath**: `data/Русский.cld` (путь к файлу русификатора)
   - **DefaultVolume**: `100` (громкость 0-100)
   - **PlaybackMode**: `queue` (режим: queue/immediate/wait)

### Шаг 3: Добавьте аудиофайлы

Создайте папку `audio/voice` и поместите туда файлы озвучки в формате OGG, MP3 или WAV.

### Шаг 4: Добавьте русификатор (опционально)

Скопируйте файл `Русский.cld` из вашей игры в папку `data/`.

## 🎤 Как работает озвучка с русификатором

### Автоматический режим

Система **автоматически** использует реплики из русификатора:

1. При показе реплики система берет её **ID**
2. Находит русский текст в файле `Русский.cld`
3. Преобразует русский текст в имя файла (транслитерация)
4. Воспроизводит соответствующий аудиофайл

**Пример:**
- ID реплики: `F6mK5ZQ0`
- Русский текст: `"У тебя кружится голова..."`
- Имя файла: `u_tebya_kruzhitsya_golova.ogg`

### Что если реплики нет в русификаторе?

**Система не ломается!** Если реплика не найдена:
- Озвучка просто не воспроизводится
- Игра продолжает работать нормально
- В консоли появляется сообщение об отсутствии файла

## 📝 Использование через события

### Plugin Commands

Добавьте команду в событие:

```
PlayVoice filename [character]
```
Пример: `PlayVoice andy_hello`

```
PlayVoiceForLine lineId [character]
```
Пример: `PlayVoiceForLine F6mK5ZQ0 andy`

```
StopVoice
```

```
SetVoiceVolume volume
```
Пример: `SetVoiceVolume 80`

### Script Commands

В событии выберите `Script` и добавьте:

```javascript
// Воспроизвести голос по имени файла
VoiceManager.playVoice("andy_hello");

// Воспроизвести для реплики по ID
VoiceManager.playVoiceForLine("F6mK5ZQ0", "andy");

// Воспроизвести для текста (авто-генерация имени)
VoiceManager.playVoiceForText("Привет, Энди!", "andy");

// Остановить
VoiceManager.stop();

// Громкость (0-100)
VoiceManager.setVolume(80);

// Проверка состояния
if (VoiceManager.isPlaying()) {
    // голос играет
}

// Получить текущий файл
var current = VoiceManager.getCurrentFile();

// Получить русский текст по ID
var text = VoiceManager.getRussianText("F6mK5ZQ0");

// Проверить загружен ли русификатор
if (VoiceManager.isRusifierLoaded()) {
    // русификатор активен
}
```

## 🔧 Интеграция с диалоговой системой

### Вариант A: Ручной вызов в событиях

В каждом событии с диалогом добавьте после показа текста:

```
◆Script：VoiceManager.playVoiceForText($gameMessage.text(), '');
```

### Вариант B: Автоматическая интеграция

Создайте дополнительный плагин (например, `VoiceAuto.js`) и поместите его **после** `VoiceMod.js`:

```javascript
(function() {
    'use strict';
    
    var _Window_Message_startMessage = Window_Message.prototype.startMessage;
    Window_Message.prototype.startMessage = function() {
        _Window_Message_startMessage.call(this);
        if (this._textState && this._textState.text) {
            // Автоматически воспроизводить голос при показе текста
            VoiceManager.playVoiceForText(this._textState.text, '');
        }
    };
    
    // Остановка голоса при закрытии окна сообщения
    var _Window_Message_endMessage = Window_Message.prototype.endMessage;
    Window_Message.prototype.endMessage = function() {
        _Window_Message_endMessage.call(this);
        VoiceManager.stop();
    };
})();
```

### Вариант C: Для визуальных новелл (Yanmessage или другие)

Если используете плагин для визуальных новелл, интегрируйтесь через его API:

```javascript
// Пример для кастомной системы диалогов
MyDialogueSystem.onShowText = function(text, speaker) {
    VoiceManager.playVoiceForText(text, speaker);
};
```

## 🎵 Поддерживаемые форматы

- **OGG** (рекомендуется)
- MP3
- WAV
- WebM
- M4A

RPG Maker MV автоматически конвертирует аудио при сборке проекта.

## 💡 Советы по организации файлов

### Рекомендуемая структура:

```
audio/voice/
├── chapter1/
│   ├── andy_001.ogg
│   ├── andy_002.ogg
│   └── leyley_001.ogg
├── chapter2/
│   └── ...
└── common/
    ├── andy_greeting.ogg
    └── leyley_laugh.ogg
```

### Именование файлов:

- Используйте латинские буквы
- Разделяйте слова подчеркиванием: `privet_drug.ogg`
- Добавляйте префикс персонажа: `andy_privet.ogg`
- Избегайте специальных символов

## 🔍 Отладка

Откройте консоль браузера (F12) для просмотра логов:

```
[VoiceManager] Инициализирован. Папка: audio/voice
[VoiceManager] Русификатор загружен. Строк: 15114
[VoiceManager] Воспроизводится: u_tebya_kruzhitsya_golova.ogg
[VoiceManager] Нет озвучки для реплики: Какая-то реплика
```

## ❓ Частые проблемы

### Файл русификатора не найден
- Убедитесь что файл `Русский.cld` находится в папке `data/`
- Проверьте параметр `RusifierPath` в настройках плагина

### Озвучка не воспроизводится
- Проверьте что файлы находятся в папке `audio/voice/`
- Убедитесь что имена файлов совпадают (регистр не важен)
- Проверьте консоль на ошибки
- Убедитесь что громкость не установлена в 0

### Голос прерывается
- Измените `PlaybackMode` на `wait` в настройках плагина
- Не вызывайте `VoiceManager.stop()` преждевременно

### Низкая производительность
- Используйте формат OGG вместо WAV
- Уменьшите качество аудио для длинных файлов
- Оптимизируйте количество одновременных запросов

## 📞 Совместимость

- ✅ RPG Maker MV 1.0.x - 1.6.x
- ✅ Все плагины диалоговых систем
- ✅ Русификаторы формата .cld
- ✅ Работает БЕЗ русификатора
- ✅ Мобильные браузеры (требуется взаимодействие пользователя)
- ✅ NW.js сборка

## 📄 Лицензия

Свободное использование для модификации игр на RPG Maker MV.

## 🆚 Отличия от версии для Godot

| Функция | Godot | RPG Maker MV |
|---------|-------|--------------|
| Язык | GDScript | JavaScript |
| Аудио API | AudioStreamPlayer | AudioManager.playBgm() |
| Загрузка файлов | ResourceLoader | XMLHttpRequest |
| Таймкоды | Авто-сканирование | Не поддерживаются* |
| Очередь | Есть | Есть |
| Русификатор | Есть | Есть |

*В RPG Maker MV нет встроенного способа получить длительность аудио без воспроизведения.
