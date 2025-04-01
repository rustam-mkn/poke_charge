# Poke Charge ⚡  

🚀 Анимация зарядки MacBook

![Poke Charge Demo](./qwe.gif)  

## 📝 Структура проекта
      poke_charge/
      ├── play_gif_and_sound.sh         # Основной скрипт для воспроизведения GIF и MP3
      ├── com.user.chargeSoundAndGif.plist # Aвтоматический запуск скрипта
      ├── qwe.gif                       
      ├── the-microsoft-sound.mp3       
      ├── charge_status.txt             # Бинарный статус зарядки (создаётся автоматически)
      └── README.md                     # 。゜゜(´o`) ゜゜。



## 📥 Установка  
1. Скачайте репозиторий
```bash
git clone https://github.com/rustam-mkn/poke_charge.git
cd poke_charge
```
2. Дайте права на выполнение скрипта
```bash
chmod +x play_gif_and_sound.sh
```
3. Скопируйте plist-файл в нужную директорию
```bash
cp com.user.chargeSoundAndGif.plist ~/Library/LaunchAgents/
```

## ✅ Включить скрипт
```bash
launchctl load /Users/user/Dev/Script/poke_charge/com.user.chargeSoundAndGif.plist
``` 

## ❌ Отключить скрипт:
```bash
launchctl unload /Users/user/Dev/Script/poke_charge/com.user.chargeSoundAndGif.plist
``` 
