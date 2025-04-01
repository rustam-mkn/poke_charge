#!/bin/bash

# Файл для хранения статуса зарядки
STATUS_FILE="/Users/user/Dev/Script/poke_charge/charge_status.txt"

# Проверка, подключено ли устройство к зарядке
IS_CHARGING=$(pmset -g ps | grep -c "AC Power")

# Читаем предыдущий статус из файла (если файл существует)
if [[ -f "$STATUS_FILE" ]]; then
    PREV_STATUS=$(cat "$STATUS_FILE")
else
    PREV_STATUS=0
fi

# Если сейчас подключено к зарядке, но ранее не было — запускаем воспроизведение
if [[ $IS_CHARGING -eq 1 && $PREV_STATUS -eq 0 ]]; then
    # Путь к GIF и звуку
    GIF_PATH="/Users/user/Dev/Script/poke_charge/qwe.gif"
    SOUND_PATH="/Users/user/Dev/Script/poke_charge/the-microsoft-sound.mp3"

    # Открываем GIF с помощью QuickLook
    qlmanage -p "$GIF_PATH" &

    # Воспроизводим звук
    afplay "$SOUND_PATH"

    # Ждем завершения GIF (укажите длительность вручную)
    sleep 5  # Замените 5 на длительность GIF

    # Закрываем QuickLook
    pkill qlmanage
fi

# Обновляем текущий статус зарядки в файл
echo "$IS_CHARGING" > "$STATUS_FILE"
