/*:
 * @plugindesc Примеры использования VoiceMod для RPG Maker MV
 * @author Voice Mod Port
 * 
 * @help
 * ============================================================================
 * ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ
 * ============================================================================
 * 
 * Этот файл содержит примеры кода для различных сценариев использования
 * системы озвучки. Не включайте этот плагин - просто используйте код как
 * образец.
 */

// ============================================================================
// ПРИМЕР 1: Озвучка конкретного события
// ============================================================================
// В событии игры добавьте после показа текста:
//
// ◆Script：VoiceManager.playVoice("andy_chapter1_intro");

// ============================================================================
// ПРИМЕР 2: Озвучка по ID реплики (с русификатором)
// ============================================================================
// Если у вас есть ID реплики из русификатора:
//
// ◆Script：VoiceManager.playVoiceForLine("F6mK5ZQ0", "Энди");

// ============================================================================
// ПРИМЕР 3: Автоматическая озвучка всех диалогов
// ============================================================================
// Создайте отдельный плагин и поместите ПОСЛЕ VoiceMod.js:

(function() {
    'use strict';
    
    // Вариант A: Для стандартной системы диалогов
    var _Window_Message_startMessage = Window_Message.prototype.startMessage;
    Window_Message.prototype.startMessage = function() {
        _Window_Message_startMessage.call(this);
        if (this._textState && this._textState.text) {
            var text = this._textState.text.replace(/\x1b\[[A-Z]\]/g, '');
            VoiceManager.playVoiceForText(text, $gameMessage.senderName ? $gameMessage.senderName() : '');
        }
    };
})();

// ============================================================================
// ПРИМЕР 4: Интеграция с Yanfly Message Core
// ============================================================================
// Если используете YEP_MessageCore, добавьте после него:

(function() {
    'use strict';
    
    var _YEP_Window_Message_startMessage = Window_Message.prototype.startMessage;
    Window_Message.prototype.startMessage = function() {
        _YEP_Window_Message_startMessage.call(this);
        if (this._textState && this._textState.text) {
            var cleanText = this._textState.text.replace(/\x1b\[[A-Z]\]/g, '');
            VoiceManager.playVoiceForText(cleanText, this._name || '');
        }
    };
})();

// ============================================================================
// ПРИМЕР 5: Озвучка только для определенных персонажей
// ============================================================================

(function() {
    'use strict';
    
    var SPEAKERS_WITH_VOICE = ['Энди', 'Эшли', 'Лейли', 'Andy', 'Ashley', 'Leyley'];
    
    var _Window_Message_startMessage = Window_Message.prototype.startMessage;
    Window_Message.prototype.startMessage = function() {
        _Window_Message_startMessage.call(this);
        
        if (this._textState && this._textState.text) {
            var speaker = $gameMessage.senderName ? $gameMessage.senderName() : '';
            
            // Проверяем есть ли у этого персонажа озвучка
            if (SPEAKERS_WITH_VOICE.indexOf(speaker) !== -1) {
                var text = this._textState.text.replace(/\x1b\[[A-Z]\]/g, '');
                VoiceManager.playVoiceForText(text, speaker);
            }
        }
    };
})();

// ============================================================================
// ПРИМЕР 6: Разная громкость для разных персонажей
// ============================================================================

(function() {
    'use strict';
    
    var CHARACTER_VOLUMES = {
        'Энди': 100,
        'Эшли': 80,
        'Лейли': 90,
        'default': 100
    };
    
    var _Game_Interpreter_pluginCommand = Game_Interpreter.prototype.pluginCommand;
    Game_Interpreter.prototype.pluginCommand = function(command, args) {
        _Game_Interpreter_pluginCommand.call(this, command, args);
        
        if (command === 'PlayVoiceWithCharacterVolume') {
            var fileName = args[0];
            var character = args[1] || 'default';
            var volume = CHARACTER_VOLUMES[character] || CHARACTER_VOLUMES['default'];
            
            VoiceManager.setVolume(volume);
            VoiceManager.playVoice(fileName);
            
            // Возвращаем громкость по умолчанию через 2 секунды
            setTimeout(function() {
                VoiceManager.setVolume(CHARACTER_VOLUMES['default']);
            }, 2000);
        }
    };
})();

// ============================================================================
// ПРИМЕР 7: Озвучка с задержкой (для эффекта)
// ============================================================================

(function() {
    'use strict';
    
    window.VoiceManagerDelayed = {
        playWithDelay: function(fileName, delayMs) {
            setTimeout(function() {
                VoiceManager.playVoice(fileName);
            }, delayMs);
        },
        
        playSequentially: function(fileNames, gapMs) {
            var index = 0;
            var self = this;
            
            function playNext() {
                if (index >= fileNames.length) return;
                
                VoiceManager.playVoice(fileNames[index]);
                index++;
                
                // Ждем окончания текущего файла + дополнительный интервал
                setTimeout(playNext, gapMs || 1000);
            }
            
            playNext();
        }
    };
    
    // Использование в скрипте:
    // VoiceManagerDelayed.playWithDelay("andy_whisper.ogg", 2000);
    // VoiceManagerDelayed.playSequentially(["a.ogg", "b.ogg", "c.ogg"], 1500);
})();

// ============================================================================
// ПРИМЕР 8: Проверка наличия файла перед воспроизведением
// ============================================================================

(function() {
    'use strict';
    
    window.VoiceManagerSafe = {
        playIfExists: function(fileName, fallbackFileName) {
            var xhr = new XMLHttpRequest();
            var url = VoiceManager._voiceFolder + '/' + fileName;
            
            xhr.open('HEAD', url);
            xhr.onload = function() {
                if (xhr.status < 400) {
                    VoiceManager.playVoice(fileName);
                } else if (fallbackFileName) {
                    console.log('[VoiceManagerSafe] Файл не найден, используем запасной:', fallbackFileName);
                    VoiceManager.playVoice(fallbackFileName);
                } else {
                    console.log('[VoiceManagerSafe] Файл не найден:', fileName);
                }
            }.bind(this);
            xhr.onerror = function() {
                if (fallbackFileName) {
                    VoiceManager.playVoice(fallbackFileName);
                }
            }.bind(this);
            xhr.send();
        }
    };
    
    // Использование:
    // VoiceManagerSafe.playIfExists("andy_rare_line.ogg", "andy_default.ogg");
})();

// ============================================================================
// ПРИМЕР 9: Озвучка только в определенных главах/локациях
// ============================================================================

(function() {
    'use strict';
    
    var ENABLED_MAPS = [1, 2, 3, 5]; // ID карт где включена озвучка
    
    var _Window_Message_startMessage = Window_Message.prototype.startMessage;
    Window_Message.prototype.startMessage = function() {
        // Проверяем текущую карту
        if (ENABLED_MAPS.indexOf($gameMap.mapId()) === -1) {
            _Window_Message_startMessage.call(this);
            return;
        }
        
        _Window_Message_startMessage.call(this);
        
        if (this._textState && this._textState.text) {
            var text = this._textState.text.replace(/\x1b\[[A-Z]\]/g, '');
            VoiceManager.playVoiceForText(text, $gameMessage.senderName ? $gameMessage.senderName() : '');
        }
    };
})();

// ============================================================================
// ПРИМЕР 10: Логирование для отладки
// ============================================================================

(function() {
    'use strict';
    
    var _VoiceManager_playVoice = VoiceManager.prototype.playVoice;
    VoiceManager.prototype.playVoice = function(fileName) {
        console.log('[VoiceDebug] Попытка воспроизведения:', fileName, 
                    '| Карта:', $gameMap.mapId(), 
                    '| Время:', new Date().toLocaleTimeString());
        _VoiceManager_playVoice.call(this, fileName);
    };
    
    var _VoiceManager_stop = VoiceManager.prototype.stop;
    VoiceManager.prototype.stop = function() {
        console.log('[VoiceDebug] Остановка воспроизведения');
        _VoiceManager_stop.call(this);
    };
})();

// ============================================================================
// ПРИМЕР 11: Кастомные Plugin Commands
// ============================================================================

(function() {
    'use strict';
    
    var _Game_Interpreter_pluginCommand = Game_Interpreter.prototype.pluginCommand;
    Game_Interpreter.prototype.pluginCommand = function(command, args) {
        _Game_Interpreter_pluginCommand.call(this, command, args);
        
        // PlayVoiceFade filename volume duration
        // Плавное появление голоса
        if (command === 'PlayVoiceFade') {
            var fileName = args[0];
            var targetVolume = parseInt(args[1]) || 100;
            var duration = parseInt(args[2]) || 1000;
            
            VoiceManager.setVolume(0);
            VoiceManager.playVoice(fileName);
            
            var startTime = Date.now();
            var fadeInterval = setInterval(function() {
                var elapsed = Date.now() - startTime;
                var progress = Math.min(elapsed / duration, 1);
                var currentVolume = Math.floor(progress * targetVolume);
                
                VoiceManager.setVolume(currentVolume);
                
                if (progress >= 1) {
                    clearInterval(fadeInterval);
                }
            }, 50);
        }
        
        // PlayVoiceLoop filename
        // Зацикленное воспроизведение
        if (command === 'PlayVoiceLoop') {
            var fileName = args[0];
            
            // Сохраняем оригинальный BGM
            var originalBgm = $gameSystem.currentBgm();
            
            VoiceManager.playVoice(fileName);
            
            // Перезапускаем при окончании (костыль для MV)
            setTimeout(function loopCheck() {
                if (VoiceManager.isPlaying() && $gameSystem._bgm && $gameSystem._bgm.name) {
                    setTimeout(loopCheck, 1000);
                } else {
                    // Файл закончился, запускаем снова если нужно
                    // VoiceManager.playVoice(fileName);
                }
            }, 1000);
        }
    };
})();

