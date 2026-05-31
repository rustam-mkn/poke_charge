# Poke Charge

Анимация и звук при подключении зарядки MacBook.

![Poke Charge Demo](./qwe.gif)  

## Как это работает

Проект больше не опрашивает `pmset` каждые 10 секунд и не хранит статус зарядки в файле. Вместо этого `poke-charge-monitor` подписывается на системные IOKit-уведомления о смене источника питания и запускает `play_gif_and_sound.sh` только при переходе с батареи на AC Power.

`play_gif_and_sound.sh` теперь отвечает только за эффект: открывает GIF через Quick Look, проигрывает звук и закрывает только тот preview-процесс, который был запущен этим скриптом.

## Структура

```text
poke_charge/
├── src/poke_charge_monitor.c          # Event-driven монитор питания через IOKit
├── play_gif_and_sound.sh              # Действие: GIF + звук
├── com.user.chargeSoundAndGif.plist   # Пример LaunchAgent
├── Makefile                           # Сборка, проверка, установка
├── qwe.gif
├── the-microsoft-sound.mp3
└── README.md
```

## Установка

1. Соберите монитор:

```bash
make
```

2. Проверьте текущий источник питания без запуска эффекта:

```bash
build/poke-charge-monitor --once
```

3. Проверьте plist:

```bash
plutil -lint com.user.chargeSoundAndGif.plist
```

4. Установите и запустите LaunchAgent:

```bash
make install
```

`make install` собирает бинарник, генерирует `~/Library/LaunchAgents/com.user.chargeSoundAndGif.plist` с абсолютными путями текущего репозитория и запускает агент через `launchctl`.

## Ручной запуск эффекта

```bash
./play_gif_and_sound.sh
```

Длительность preview можно переопределить:

```bash
POKE_CHARGE_PREVIEW_SECONDS=7 ./play_gif_and_sound.sh
```

## Диагностика

Лог агента:

```bash
tail -f ~/Library/Logs/poke_charge.log
```

Статус launchd:

```bash
launchctl print gui/$(id -u)/com.user.chargeSoundAndGif
```

## Отключение

```bash
make uninstall
```
