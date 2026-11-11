# Hyprland Dotfiles

Моя персональная сборка конфигов для **Hyprland** (Wayland compositeur) с боковой панелью на GtkLayerShell.

## Структура

```
hyprland-dotfiles/
├── hypr/
│   ├── hyprland.conf          # Основной конфиг Hyprland
│   ├── hyprpaper.conf         # Конфиг обоев
│   ├── hyprsettings.toml      # Настройки Hyprland (изテーマ)
│   ├── change_wallpaper.sh    # Смена обоев
│   └── sidebar/
│       ├── sidebar.py         # Боковая панель (GtkLayerShell, Win+P)
│       ├── toggle.sh          # Переключатель видимости панели
│       ├── wallpaper_cycle.sh # Цикл обоев
│       └── waybar_position.sh # Позиция waybar (top/bottom/hide)
├── waybar/
│   ├── config                 # Конфиг waybar
│   └── style.css              # Стили waybar (меняются при смене темы)
└── kitty/
    ├── kitty.conf             # Конфиг терминала
    ├── theme.conf             # Тема kitty
    └── userprefs.conf         # Предпочтения kitty
```

## Быстрый старт

```bash
# Клонировать
git clone <твой-репозиторий>
cd hyprland-dotfiles

# Скопировать конфиги в ~/.config/hypr/
cp -r hypr/* ~/.config/hypr/
cp -r waybar/* ~/.config/waybar/
cp -r kitty/* ~/.config/kitty/

# Выдать права на скрипты
chmod +x ~/.config/hypr/sidebar/*.sh
chmod +x ~/.config/hypr/change_wallpaper.sh

# Перезагрузить Hyprland (Super + M или через меню)
```

## Горячие клавиши

| Клавиша | Действие |
|---------|----------|
| `Super + P` | Показать/скрыть боковую панель |
| `Super + Return` | Kitty терминал |
| `Super + D` / `Super + Space` | Rofi launcher |
| `Super + Q` | Закрыть окно |
| `Super + F` | Полноэкранный режим |
| `Super + M` | Выход из Hyprland |
| `Super + Shift + стрелки` | Переместить окно между workspace |
| `Super + 1…0` | Переключение workspace |

## Боковая панель (Win+P)

Панель создана на **GtkLayerShell** с `exclusive_zone`, поэтому:
- приклеена строго к **правому краю** экрана,
- не плавает и не съезжает,
- при открытии сдвигает плиточные окна влево (резервирует 316 px),
- фон чёрный (`#0a0a0a`),
- углы скруглены (`border-radius: 12px`),
- при смене темы waybar не вытесняется (панели восстанавливают свои слои).

## Лицензия

MIT — используй как хочешь.
