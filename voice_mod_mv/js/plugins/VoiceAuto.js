/*:
 * @plugindesc Автоматическая озвучка диалогов для RPG Maker MV
 * @author Voice Mod Port
 * @parent VoiceMod
 * 
 * @help
 * ============================================================================
 * АВТОМАТИЧЕСКАЯ ОЗВУЧКА ДИАЛОГОВ
 * ============================================================================
 * 
 * Этот плагин автоматически воспроизводит голос при показе текста в окне сообщений.
 * Требует установленный плагин VoiceMod.js
 * 
 * ============================================================================
 * УСТАНОВКА:
 * ============================================================================
 * 
 * 1. Установите основной плагин VoiceMod.js
 * 2. Поместите этот плагин ПОСЛЕ VoiceMod.js в списке плагинов
 * 3. Включите плагин
 * 
 * Плагин не имеет настроек - всё работает автоматически.
 */

(function() {
    'use strict';

    // Проверка наличия основного плагина
    if (typeof VoiceManager === 'undefined') {
        console.error('[VoiceAuto] VoiceManager не найден! Убедитесь что VoiceMod.js включен и стоит перед этим плагином.');
        return;
    }

    // Перехват начала показа сообщения
    var _Window_Message_startMessage = Window_Message.prototype.startMessage;
    Window_Message.prototype.startMessage = function() {
        _Window_Message_startMessage.call(this);
        
        // Воспроизводим голос при начале показа текста
        if (this._textState && this._textState.text) {
            var text = this._textState.text;
            
            // Очищаем текст от кодов управления
            var cleanText = text.replace(/\x1b\[[A-Z]\]/g, '');
            cleanText = cleanText.replace(/\x1b[<>].*?\x1b[<>]/g, '');
            
            // Получаем имя говорящего если есть
            var speaker = '';
            if ($gameMessage.senderName && $gameMessage.senderName() !== '') {
                speaker = $gameMessage.senderName();
            }
            
            // Воспроизводим голос
            VoiceManager.playVoiceForText(cleanText, speaker);
        }
    };

    // Перехват конца показа сообщения (опционально - останавливаем голос)
    var _Window_Message_endMessage = Window_Message.prototype.endMessage;
    Window_Message.prototype.endMessage = function() {
        _Window_Message_endMessage.call(this);
        
        // Опционально: остановить голос при закрытии окна
        // Раскомментируйте если нужно:
        // VoiceManager.stop();
    };

    // Перехват клика по окну сообщения (для пропуска голоса)
    var _Window_Message_isTriggered = Window_Message.prototype.isTriggered;
    Window_Message.prototype.isTriggered = function() {
        var result = _Window_Message_isTriggered.call(this);
        
        // Если игрок кликнул во время воспроизведения голоса - останавливаем
        if (result && VoiceManager.isPlaying()) {
            // Проверяем настройку режима поведения при клике
            if (VoiceManager._playbackMode !== 'wait') {
                VoiceManager.stop();
            }
        }
        
        return result;
    };

})();
