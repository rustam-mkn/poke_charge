# Инструкция по включению и отключению скрипта

poke_charge/
├── play_gif_and_sound.sh         # Основной скрипт для воспроизведения GIF и MP3
├── com.user.chargeSoundAndGif.plist # Aвтоматический запуск скрипта
├── qwe.gif                       
├── the-microsoft-sound.mp3       
├── charge_status.txt             # Бинарный статус зарядки (создаётся автоматически)
└── README.txt                    # 。゜゜(´o`) ゜゜。


Включение
└── launchctl load /Users/user/Dev/Script/poke_charge/com.user.chargeSoundAndGif.plist 


Выключение  
└── launchctl unload /Users/user/Dev/Script/poke_charge/com.user.chargeSoundAndGif.plist



