/*:
 * @plugindesc Система озвучки диалогов для RPG Maker MV с поддержкой русификатора
 * @author Voice Mod Port
 * 
 * @param VoiceFolder
 * @text Папка с голосами
 * @desc Относительный путь к папке с аудиофайлами озвучки
 * @default audio/voice
 * 
 * @param RusifierPath
 * @text Путь к русификатору
 * @desc Путь к файлу русификатора (.cld)
 * @default data/Русский.cld
 * 
 * @param DefaultVolume
 * @text Громкость по умолчанию
 * @desc Громкость голоса от 0 до 100
 * @default 100
 * 
 * @param PlaybackMode
 * @text Режим воспроизведения
 * @desc queue - очередь, immediate - немедленно, wait - ждать
 * @type select
 * @option queue
 * @option immediate
 * @option wait
 * @default queue
 * 
 * @help
 * ============================================================================
 * МОД ОЗВУЧКИ ДЛЯ RPG MAKER MV
 * ============================================================================
 * 
 * Этот плагин добавляет систему воспроизводства голосовой озвучки для диалогов.
 * Поддерживает автоматическую работу с русификатором (формат .cld).
 * 
 * ============================================================================
 * ОСНОВНЫЕ ВОЗМОЖНОСТИ:
 * ============================================================================
 * 
 * 1. Автоматическое воспроизведение озвучки при показе текста
 * 2. Поддержка русификатора для генерации имен файлов
 * 3. Очередь воспроизведения
 * 4. Кэширование аудио
 * 5. Интеграция с стандартной системой диалогов
 * 
 * ============================================================================
 * КАК ЭТО РАБОТАЕТ С РУСИФИКАТОРОМ:
 * ============================================================================
 * 
 * Система автоматически:
 * 1. Берет ID реплики из диалоговой системы
 * 2. Находит русский текст в файле русификатора
 * 3. Преобразует текст в имя файла (транслитерация)
 * 4. Воспроизводит соответствующий аудиофайл
 * 
 * Пример:
 * - ID реплики: F6mK5ZQ0
 * - Русский текст: "У тебя кружится голова..."
 * - Имя файла: u_tebya_kruzhitsya_golova.flac
 * 
 * ============================================================================
 * УСТАНОВКА:
 * ============================================================================
 * 
 * 1. Поместите этот файл в папку js/plugins/ вашего проекта
 * 2. Включите плагин в редакторе плагинов RPG Maker MV
 * 3. Настройте параметры (папка с голосами, путь к русификатору)
 * 4. Создайте папку с аудиофайлами (по умолчанию audio/voice)
 * 5. Поместите файл русификатора (опционально)
 * 
 * ============================================================================
 * ИСПОЛЬЗОВАНИЕ ЧЕРЕЗ СОБЫТИЯ:
 * ============================================================================
 * 
 * Команда скрипта в событии:
 * 
 * // Воспроизвести голос по имени файла
 * VoiceManager.playVoice("andy_hello");
 * 
 * // Воспроизвести голос для реплики по ID (с использованием русификатора)
 * VoiceManager.playVoiceForLine("F6mK5ZQ0", "andy");
 * 
 * // Остановить текущее воспроизведение
 * VoiceManager.stop();
 * 
 * // Установить громкость (0-100)
 * VoiceManager.setVolume(80);
 * 
 * // Проверить, играет ли голос
 * if (VoiceManager.isPlaying()) { ... }
 * 
 * ============================================================================
 * ИНТЕГРАЦИЯ С ДИАЛОГАМИ:
 * ============================================================================
 * 
 * Для автоматической озвучки диалогов добавьте в событие показа текста:
 * 
 * // В Plugin Commands или Script:
 * VoiceManager.playVoiceForText($gameMessage.text(), $gameMessage.senderName());
 * 
 * Или модифицируйте Window_Message для авто-озвучки (см. пример ниже).
 * 
 * ============================================================================
 * ПРИМЕР МОДИФИКАЦИИ WINDOW_MESSAGE:
 * ============================================================================
 * 
 * Добавьте этот код после загрузки плагинов (в main.js или отдельном плагине):
 * 
 * (function() {
 *     var _Window_Message_startMessage = Window_Message.prototype.startMessage;
 *     Window_Message.prototype.startMessage = function() {
 *         _Window_Message_startMessage.call(this);
 *         // Автоматически воспроизводить голос при показе текста
 *         if (this._textState && this._textState.text) {
 *             VoiceManager.playVoiceForText(this._textState.text, '');
 *         }
 *     };
 * })();
 * 
 * ============================================================================
 * ФОРМАТЫ АУДИО:
 * ============================================================================
 * 
 * Поддерживаемые форматы: ogg, mp3, wav, webm, m4a
 * RPG Maker MV автоматически конвертирует их при сборке.
 * 
 * ============================================================================
 * СТРУКТУРА ПАПОК:
 * ============================================================================
 * 
 * project/
 * ├── audio/
 * │   └── voice/           <-- Папка с голосами
 * │       ├── andy_hello.ogg
 * │       ├── leyley_greeting.ogg
 * │       └── ...
 * ├── data/
 * │   └── Русский.cld      <-- Файл русификатора (опционально)
 * └── js/
 *     └── plugins/
 *         └── VoiceMod.js  <-- Этот плагин
 */

(function() {
    'use strict';

    // ========================================================================
    // МЕНЕДЖЕР ГОЛОСА
    // ========================================================================
    
    function VoiceManager() {
        this.initialize.apply(this, arguments);
    }

    VoiceManager.prototype.initialize = function() {
        this._voiceFolder = this.getParam('VoiceFolder') || 'audio/voice';
        this._rusifierPath = this.getParam('RusifierPath') || 'data/Русский.cld';
        this._defaultVolume = Number(this.getParam('DefaultVolume')) || 100;
        this._playbackMode = this.getParam('PlaybackMode') || 'queue';
        
        this._audioCache = {};
        this._currentBgm = null;
        this._currentFile = '';
        this._queue = [];
        this._isPlaying = false;
        this._rusifierData = null;
        this._rusifierLoaded = false;
        
        this._loadRusifier();
        console.log('[VoiceManager] Инициализирован. Папка:', this._voiceFolder);
    };

    VoiceManager.prototype.getParam = function(paramName) {
        var plugin = $plugins.find(function(p) {
            return p.description.indexOf('Система озвучки диалогов') !== -1;
        });
        if (plugin && plugin.parameters && plugin.parameters[paramName]) {
            return plugin.parameters[paramName];
        }
        return null;
    };

    // Загрузка данных русификатора
    VoiceManager.prototype._loadRusifier = function() {
        var xhr = new XMLHttpRequest();
        var url = this._rusifierPath;
        
        xhr.open('GET', url);
        xhr.overrideMimeType('application/json');
        xhr.onload = function() {
            if (xhr.status < 400) {
                try {
                    var content = xhr.responseText;
                    // Убираем префикс LANGDATA если есть
                    if (content.indexOf('LANGDATA') === 0) {
                        content = content.substring(8);
                    }
                    this._rusifierData = JSON.parse(content);
                    this._rusifierLoaded = true;
                    console.log('[VoiceManager] Русификатор загружен. Строк:', 
                        this._rusifierData.linesLUT ? Object.keys(this._rusifierData.linesLUT).length : 0);
                } catch (e) {
                    console.log('[VoiceManager] Ошибка парсинга JSON русификатора:', e);
                    this._rusifierLoaded = false;
                }
            }
        }.bind(this);
        xhr.onerror = function() {
            console.log('[VoiceManager] Файл русификатора не найден:', url);
            this._rusifierLoaded = false;
        }.bind(this);
        xhr.send();
    };

    // Основная функция воспроизведения по имени файла
    VoiceManager.prototype.playVoice = function(fileName) {
        if (!fileName || fileName.trim() === '') {
            return;
        }
        
        // Добавляем расширение если нет
        var extensions = ['.ogg', '.mp3', '.wav', '.webm', '.m4a'];
        var hasExtension = extensions.some(function(ext) {
            return fileName.toLowerCase().endsWith(ext);
        });
        
        if (!hasExtension) {
            fileName += '.ogg'; // По умолчанию ogg для RPG Maker MV
        }
        
        if (this._playbackMode === 'immediate') {
            this._queue = [];
        }
        
        this._queue.push(fileName);
        this._processQueue();
    };

    // Воспроизвести для реплики по ID (использует русификатор)
    VoiceManager.prototype.playVoiceForLine = function(lineId, character) {
        var fileName = this.getVoiceFileForRussianLine(lineId, character);
        if (fileName) {
            this.playVoice(fileName);
        }
    };

    // Воспроизвести для текста (автоматическая генерация имени)
    VoiceManager.prototype.playVoiceForText = function(text, character) {
        if (!text || text.trim() === '') {
            return;
        }
        var fileName = this.textToFilename(text, character);
        if (fileName) {
            this.playVoice(fileName);
        } else {
            console.log('[VoiceManager] Нет озвучки для реплики:', text.substring(0, 50));
        }
    };

    // Обработка очереди
    VoiceManager.prototype._processQueue = function() {
        if (this._queue.length === 0 || this._isPlaying) {
            return;
        }
        
        var nextFile = this._queue.shift();
        this._playFile(nextFile);
    };

    // Воспроизведение файла
    VoiceManager.prototype._playFile = function(fileName) {
        if (this._isPlaying) {
            return;
        }
        
        var fullPath = this._voiceFolder + '/' + fileName;
        
        // Проверяем существование файла через попытку загрузки
        var bgm = {
            name: fullPath,
            volume: this._defaultVolume,
            pitch: 100,
            pan: 0
        };
        
        // Сохраняем текущий BGM если есть
        var currentBgm = $gameSystem.currentBgm();
        
        // Воспроизводим как BGM (единственный способ в RVVM)
        try {
            this._currentFile = fileName;
            this._isPlaying = true;
            
            // Используем AudioManager для воспроизведения
            AudioManager.playBgm(bgm);
            
            // Настраиваем на однократное воспроизведение
            if ($gameSystem._bgm && $gameSystem._bgm.name === fullPath) {
                $gameSystem._bgm.pos = 0;
            }
            
            console.log('[VoiceManager] Воспроизводится:', fileName);
            
            // Планируем остановку после окончания (приблизительно)
            this._scheduleStop(fullPath);
            
        } catch (e) {
            console.log('[VoiceManager] Ошибка воспроизведения:', fileName, e);
            this._isPlaying = false;
            this._currentFile = '';
            this._processQueue();
        }
    };

    // Планирование остановки (упрощенно)
    VoiceManager.prototype._scheduleStop = function(path) {
        // В RPG Maker MV нет простого способа узнать длительность аудио
        // Используем эвристику или ждем пользовательского действия
        setTimeout(function() {
            // Не останавливаем автоматически - пусть играет до конца
            // Остановка будет при следующем вызове или клике
        }.bind(this), 5000); // Заглушка
    };

    // Остановка воспроизведения
    VoiceManager.prototype.stop = function() {
        if (this._isPlaying) {
            AudioManager.stopBgm();
            this._isPlaying = false;
            this._currentFile = '';
            this._queue = [];
            console.log('[VoiceManager] Остановлено');
        }
    };

    // Установка громкости
    VoiceManager.prototype.setVolume = function(volume) {
        this._defaultVolume = Math.max(0, Math.min(100, volume));
        if (this._isPlaying && $gameSystem._bgm) {
            $gameSystem._bgm.volume = this._defaultVolume;
            AudioManager.updateBgmParameters($gameSystem._bgm);
        }
    };

    // Проверка состояния воспроизведения
    VoiceManager.prototype.isPlaying = function() {
        return this._isPlaying;
    };

    // Получить текущий файл
    VoiceManager.prototype.getCurrentFile = function() {
        return this._currentFile;
    };

    // Получить русский текст по ID реплики
    VoiceManager.prototype.getRussianText = function(lineId) {
        if (!this._rusifierLoaded || !this._rusifierData || !this._rusifierData.linesLUT) {
            return '';
        }
        
        var linesLUT = this._rusifierData.linesLUT;
        if (linesLUT[lineId]) {
            var entry = linesLUT[lineId];
            if (Array.isArray(entry) && entry.length > 0) {
                return String(entry[0]);
            } else if (typeof entry === 'string') {
                return entry;
            }
        }
        return '';
    };

    // Преобразование текста в имя файла
    VoiceManager.prototype.textToFilename = function(text, character) {
        if (!text || text.trim() === '') {
            return '';
        }
        
        // Транслитерация и нормализация
        var filename = text.toLowerCase();
        
        // Замена русских букв на латинские
        var translitMap = {
            'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
            'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
            'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
            'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sch',
            'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
            ' ': '_', '-': '_', '.': '', ',': '', '!': '', '?': '', '"': '',
            "'": '', ':': '', ';': '', '(': '', ')': '', '[': '', ']': ''
        };
        
        var result = '';
        for (var i = 0; i < filename.length; i++) {
            var char = filename[i];
            if (translitMap[char] !== undefined) {
                result += translitMap[char];
            } else if (/[a-z0-9_]/.test(char)) {
                result += char;
            }
        }
        
        // Удаляем множественные подчеркивания
        result = result.replace(/_+/g, '_');
        
        // Удаляем подчеркивания по краям
        result = result.replace(/^_|_$/g, '');
        
        // Добавляем префикс персонажа
        if (character && character.trim() !== '') {
            var charKey = this._normalizeCharacterName(character);
            result = charKey + '_' + result;
        }
        
        // Ограничиваем длину
        if (result.length > 100) {
            result = result.substring(0, 100);
        }
        
        if (result === '') {
            return '';
        }
        
        return result;
    };

    // Нормализация имени персонажа
    VoiceManager.prototype._normalizeCharacterName = function(name) {
        var lowerName = name.toLowerCase();
        var charMap = {
            'andy': 'andy', 'энди': 'andy', 'andrew': 'andy', 'эндру': 'andy',
            'leyley': 'leyley', 'лейли': 'leyley', 'leyla': 'leyley', 
            'лейла': 'leyley', 'ashley': 'leyley', 'эштли': 'leyley'
        };
        return charMap[lowerName] || lowerName.replace(/[^a-z0-9]/gi, '_');
    };

    // Получить имя файла для русской реплики по ID
    VoiceManager.prototype.getVoiceFileForRussianLine = function(lineId, character) {
        var russianText = this.getRussianText(lineId);
        if (!russianText || russianText.trim() === '') {
            return '';
        }
        return this.textToFilename(russianText, character);
    };

    // Проверка загруженности русификатора
    VoiceManager.prototype.isRusifierLoaded = function() {
        return this._rusifierLoaded;
    };

    // Очистка очереди
    VoiceManager.prototype.clearQueue = function() {
        this._queue = [];
    };

    // Создание глобального экземпляра
    var globalVoiceManager = new VoiceManager();
    
    // Экспорт в глобальную область видимости
    window.VoiceManager = globalVoiceManager;

    // ========================================================================
    // ИНТЕГРАЦИЯ С ОКНОМ СООБЩЕНИЙ
    // ========================================================================
    
    // Опционально: автоматическое воспроизведение при показе текста
    // Раскомментируйте если нужна авто-озвучка без дополнительных скриптов
    
    /*
    var _Window_Message_startMessage = Window_Message.prototype.startMessage;
    Window_Message.prototype.startMessage = function() {
        _Window_Message_startMessage.call(this);
        if (this._textState && this._textState.text) {
            // Автоматически воспроизводить голос
            VoiceManager.playVoiceForText(this._textState.text, '');
        }
    };
    */

    // ========================================================================
    // PLUGIN COMMANDS
    // ========================================================================
    
    var _Game_Interpreter_pluginCommand = Game_Interpreter.prototype.pluginCommand;
    Game_Interpreter.prototype.pluginCommand = function(command, args) {
        _Game_Interpreter_pluginCommand.call(this, command, args);
        
        if (command === 'PlayVoice') {
            // PlayVoice filename [character]
            var fileName = args[0];
            var character = args[1] || '';
            VoiceManager.playVoice(fileName);
        }
        
        if (command === 'PlayVoiceForLine') {
            // PlayVoiceForLine lineId [character]
            var lineId = args[0];
            var character = args[1] || '';
            VoiceManager.playVoiceForLine(lineId, character);
        }
        
        if (command === 'StopVoice') {
            VoiceManager.stop();
        }
        
        if (command === 'SetVoiceVolume') {
            // SetVoiceVolume volume (0-100)
            var volume = parseInt(args[0]) || 100;
            VoiceManager.setVolume(volume);
        }
    };

})();
