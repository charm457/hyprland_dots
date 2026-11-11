#!/bin/bash
# Убиваем старый swaybg
killall swaybg
# Запускаем с новой картинкой
swaybg -i "$1" -m fill &
