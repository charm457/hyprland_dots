# Hyprland Custom Dotfiles

Modular, high-performance configuration framework for **Hyprland** (Wayland) featuring dynamic theme switching, multiple window layout modes, GtkLayerShell control center, PipeWire audio routing, and bilingual localization (EN / RU).

[English](#installation--quick-start) | [Русская документация](#установка-и-быстрый-старт)

---

## Installation & Quick Start

### 1. Automated Installation (Recommended)

Run the automated installer. It supports fresh systems as well as updating over existing configurations with automatic timestamped backups:

```bash
git clone https://github.com/charm457/hyprland_dots.git ~/hyprland_dots
cd ~/hyprland_dots
chmod +x install.sh
./install.sh
```

### 2. Non-Interactive CLI Execution

```bash
# Clean install with dependency check (English)
./install.sh --fresh --lang=en

# Clean install with dependency check (Russian)
./install.sh --fresh --lang=ru

# Fast update over existing setup (auto-backup, config deploy, live reload)
./install.sh --update

# Restore previous backup
./install.sh --restore
```

### 3. Package Dependencies

If performing a manual installation, ensure the following packages are present:

#### Arch Linux (pacman & yay)
```bash
sudo pacman -S --needed hyprland waybar kitty rofi-wayland grim slurp \
    wl-clipboard swww swaync pipewire pipewire-pulse wireplumber \
    brightnessctl playerctl python python-gobject gtk3 gtk-layer-shell jq
```

#### Fedora (dnf)
```bash
sudo dnf install hyprland waybar kitty rofi-wayland grim slurp \
    wl-clipboard swww swaync pulseaudio-utils brightnessctl playerctl \
    python3 python3-gobject gtk3 gtk-layer-shell jq
```

---

## Screenshots & Gallery

> Drop your screenshots into the `docs/screenshots/` directory or replace the image links below.

| Total Black (Solid OLED) | macOS Liquid Glass |
| :---: | :---: |
| ![Total Black OLED](docs/screenshots/total_black.png) | ![macOS Liquid Glass](docs/screenshots/macos_glass.png) |

| Total White Clean | Cyber Neon / Nord Frost |
| :---: | :---: |
| ![Total White Clean](docs/screenshots/total_white.png) | ![Cyber Neon / Nord](docs/screenshots/cyber_nord.png) |

| Control Sidebar & Audio Output Switcher | Keybindings Cheatsheet (Super + /) |
| :---: | :---: |
| ![Sidebar](docs/screenshots/sidebar.png) | ![Keybindings Help](docs/screenshots/cheatsheet.png) |

---

## Keybindings Reference

### General & System

| Keybinding | Action |
|---|---|
| `Super + /` or `Super + F1` | Open floating Keybindings Cheatsheet window |
| `Super + P` | Toggle Control Sidebar (GtkLayerShell) |
| `Super + Return` | Launch Kitty terminal |
| `Super + Space` or `Super + D` | Launch Rofi application menu |
| `Super + Q` | Close focused window |
| `Super + Shift + M` | Graceful exit from Hyprland |
| `Super + L` | Lock screen (`swaylock` or `hyprlock`) |
| `Super + Alt + L` | Toggle interface language (`EN` ↔ `RU`) |
| `Super + Alt + P` | Cycle Waybar position (`Top` ↔ `Bottom` ↔ `Hidden`) |

### Window Layout & Modes

| Keybinding | Action |
|---|---|
| `Super + W` | Cycle window layout mode (`Default Tiling` ↔ `Free Floating`) |
| `Super + Shift + T` | Enforce Default Mode: all windows strictly tiled and auto-split |
| `Super + Shift + W` | Enforce Free Mode: all windows float freely like in Windows |
| `Super + V` | Toggle active window between Floating and Tiled |
| `Super + F` | Fullscreen mode |
| `Super + LMB (drag)` | Move floating window |
| `Super + RMB (drag)` | Resize floating window |

### Screenshots

All captures are automatically copied to the clipboard and saved to `~/Screenshots/Screenshot_YYYY-MM-DD_HH-MM-SS.png`:

| Keybinding | Action |
|---|---|
| `Super + Shift + S` | Select area to capture |
| `Print` | Capture entire screen |
| `Super + Print` | Capture currently focused window |
| `Super + Alt + S` | Open interactive screenshot menu (Rofi) |

### Audio, Brightness & Media

| Keybinding | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume -5% |
| `XF86AudioMute` | Toggle audio mute |
| `XF86MonBrightnessUp` | Brightness +5% |
| `XF86MonBrightnessDown` | Brightness -5% |
| `XF86AudioPlay` | Play / Pause media |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `Super + ]` / `Super + [` | Next / previous wallpaper from `~/wallpapers` |

---

## Management CLI Commands

Every subsystem provides dedicated shell scripts for scripting and terminal management:

### Theme Management
```bash
# Open interactive theme switcher menu
~/.config/hypr/scripts/theme_ctl.sh menu

# Apply a specific theme by key
~/.config/hypr/scripts/theme_ctl.sh set macos_pitch_dark
~/.config/hypr/scripts/theme_ctl.sh set black_solid
~/.config/hypr/scripts/theme_ctl.sh set white_clean
~/.config/hypr/scripts/theme_ctl.sh set cyber_neon

# Re-apply current theme
~/.config/hypr/scripts/theme_ctl.sh apply

# List all available themes
~/.config/hypr/scripts/theme_ctl.sh list
```

### Audio Routing & Volume
```bash
# List all audio output sinks in JSON format
~/.config/hypr/scripts/audio_output.sh list

# Get active default output sink
~/.config/hypr/scripts/audio_output.sh default

# Switch audio output and move all active audio streams live
~/.config/hypr/scripts/audio_output.sh set <sink_name>

# Get or set volume percentage (0-100)
~/.config/hypr/scripts/audio_output.sh volume
~/.config/hypr/scripts/audio_output.sh set_vol 65

# Toggle mute
~/.config/hypr/scripts/audio_output.sh mute
```

### Window Layout Modes
```bash
# Cycle layout mode (Default Tiling <-> Free Floating)
~/.config/hypr/scripts/window_mode.sh cycle

# Switch explicitly
~/.config/hypr/scripts/window_mode.sh tiling
~/.config/hypr/scripts/window_mode.sh floating

# Print current mode
~/.config/hypr/scripts/window_mode.sh status
```

### Screenshots
```bash
# Capture area, full screen, or window
~/.config/hypr/scripts/screenshot.sh area
~/.config/hypr/scripts/screenshot.sh full
~/.config/hypr/scripts/screenshot.sh window
~/.config/hypr/scripts/screenshot.sh menu
```

### Localization
```bash
# Toggle between English and Russian
~/.config/hypr/scripts/lang_ctl.sh toggle

# Set explicitly
~/.config/hypr/scripts/lang_ctl.sh en
~/.config/hypr/scripts/lang_ctl.sh ru
```

### Waybar & Wallpapers
```bash
# Cycle Waybar position: Top -> Bottom -> Hidden
~/.config/hypr/scripts/waybar_position.sh cycle

# Cycle wallpapers from ~/wallpapers
~/.config/hypr/scripts/wallpaper_cycle.sh next
~/.config/hypr/scripts/wallpaper_cycle.sh prev
```

---

## Theme Families & Styles

1. **Total Black**:
   - `black_solid`: Solid OLED pure pitch black (`#000000`), zero blur, dark-white symbols (`#b0b0b8`), zero eye strain.
   - `black_stealth`: Matte dark graphite (`#121316`) with subtle blur.
   - `black_glass`: Obsidian dark glass (`#0a0a0d`) with blur and saturation.

2. **Total White**:
   - `white_clean`: High-contrast pure white minimalism with crisp dark typography.
   - `white_glass`: Frosted translucent acrylic white glass.
   - `white_latte`: Warm soothing cream pastel (Catppuccin Latte palette).

3. **Apple macOS / iOS**:
   - `macos_pitch_dark`: OLED pitch black (`#000000`), rounded iOS floating bar, dark-white/silver symbols (`#e5e5ea` / `#636366`).
   - `macos_glass`: Transparent liquid glass with 4-pass blur and macOS pill geometry.
   - `macos_dark`: Cupertino dark glass.
   - `macos_light`: Cupertino frosted light glass.

4. **Cyber & Nord**:
   - `cyber_neon`: Synthwave aesthetic with cyan and magenta accents.
   - `nord_frost`: Arctic blue palette with polar contrast.

---

<br>

# Установка и быстрый старт (Русский)

Модульная конфигурация для **Hyprland** (Wayland): система тем оформления с живым переключением, режимы компоновки окон, боковая панель управления (GtkLayerShell), роутинг аудиопотоков PipeWire и двуязычный интерфейс (RU / EN).

---

## Установка и обновление

### 1. Автоматическая установка

Скрипт поддерживает чистую установку с установкой зависимостей и обновление поверх готовой сборки с автоматическим созданием бэкапа:

```bash
git clone https://github.com/charm457/hyprland_dots.git ~/hyprland_dots
cd ~/hyprland_dots
chmod +x install.sh
./install.sh
```

### 2. Неинтерактивные команды CLI

```bash
# Чистая установка с проверкой пакетов на русском
./install.sh --fresh --lang=ru

# Чистая установка на английском
./install.sh --fresh --lang=en

# Быстрое обновление поверх существующей сборки (бэкап + авто-перезагрузка)
./install.sh --update

# Восстановление конфигурации из последнего бэкапа
./install.sh --restore
```

### 3. Зависимости пакетов

#### Arch Linux
```bash
sudo pacman -S --needed hyprland waybar kitty rofi-wayland grim slurp \
    wl-clipboard swww swaync pipewire pipewire-pulse wireplumber \
    brightnessctl playerctl python python-gobject gtk3 gtk-layer-shell jq
```

#### Fedora
```bash
sudo dnf install hyprland waybar kitty rofi-wayland grim slurp \
    pulseaudio-utils brightnessctl playerctl python3 python3-gobject \
    gtk3 gtk-layer-shell jq
```

---

## Место для скриншотов

> Поместите ваши скриншоты в папку `docs/screenshots/` или укажите нужные пути в таблице ниже:

| Total Black (Чистый OLED) | macOS Liquid Glass |
| :---: | :---: |
| ![Total Black OLED](docs/screenshots/total_black.png) | ![macOS Liquid Glass](docs/screenshots/macos_glass.png) |

| Total White Clean | Cyber Neon / Nord Frost |
| :---: | :---: |
| ![Total White Clean](docs/screenshots/total_white.png) | ![Cyber Neon / Nord](docs/screenshots/cyber_nord.png) |

| Боковая панель управления и аудиовыходы | Шпаргалка горячих клавиш (Super + /) |
| :---: | :---: |
| ![Sidebar](docs/screenshots/sidebar.png) | ![Keybindings Help](docs/screenshots/cheatsheet.png) |

---

## Таблица горячих клавиш

### Система и запуск

| Сочетание клавиш | Описание |
|---|---|
| `Super + /` или `Super + F1` | Всплывающее окно со всеми горячими клавишами |
| `Super + P` | Открыть / закрыть боковую панель управления |
| `Super + Return` | Терминал Kitty |
| `Super + Space` или `Super + D` | Меню приложений Rofi |
| `Super + Q` | Закрыть текущее окно |
| `Super + Shift + M` | Безопасный выход из Hyprland |
| `Super + Alt + L` | Переключение языка интерфейса (`RU` ↔ `EN`) |
| `Super + Alt + P` | Переключение положения Waybar (`Сверху` ↔ `Снизу` ↔ `Скрыть`) |

### Управление окнами и режимы

| Сочетание клавиш | Описание |
|---|---|
| `Super + W` | Сменить режим окон (`Обычный тайлинг` ↔ `Свободный плавающий`) |
| `Super + Shift + T` | Включить Обычный режим (тайлинг, все новые окна строго делятся) |
| `Super + Shift + W` | Включить Свободный режим (все окна свободно плавают как в Windows) |
| `Super + V` | Переключить текущее окно между плавающим и тайловым |
| `Super + F` | Полный экран (fullscreen) |
| `Super + ЛКМ (тянуть)` | Перемещение плавающего окна мышью |
| `Super + ПКМ (тянуть)` | Изменение размера окна мышью |

### Скриншоты

Все скриншоты копируются в буфер обмена и сохраняются в `~/Screenshots/Screenshot_YYYY-MM-DD_HH-MM-SS.png`:

| Сочетание клавиш | Описание |
|---|---|
| `Super + Shift + S` | Снимок выделенной области |
| `Print` | Снимок всего экрана |
| `Super + Print` | Снимок активного окна |
| `Super + Alt + S` | Меню скриншотов (Rofi) |

### Звук, яркость и медиа

| Сочетание клавиш | Описание |
|---|---|
| `XF86AudioRaiseVolume` | Громкость +5% |
| `XF86AudioLowerVolume` | Громкость -5% |
| `XF86AudioMute` | Отключение / включение звука |
| `XF86MonBrightnessUp` | Яркость экрана +5% |
| `XF86MonBrightnessDown` | Яркость экрана -5% |
| `Super + ]` / `Super + [` | Следующие / предыдущие обои из папки `~/wallpapers` |

---

## Команды управления из консоли

### Управление темами
```bash
# Меню выбора темы
~/.config/hypr/scripts/theme_ctl.sh menu

# Прямое применение темы
~/.config/hypr/scripts/theme_ctl.sh set macos_pitch_dark
~/.config/hypr/scripts/theme_ctl.sh set black_solid
~/.config/hypr/scripts/theme_ctl.sh set white_clean

# Список всех доступных тем
~/.config/hypr/scripts/theme_ctl.sh list
```

### Управление аудиовыходами
```bash
# Список подключенных устройств вывода в JSON
~/.config/hypr/scripts/audio_output.sh list

# Переключение вывода звука с миграцией всех играющих потоков на лету
~/.config/hypr/scripts/audio_output.sh set <имя_синка>

# Установка громкости (0-100)
~/.config/hypr/scripts/audio_output.sh set_vol 70

# Заглушить / включить звук
~/.config/hypr/scripts/audio_output.sh mute
```

### Режимы компоновки окон
```bash
# Переключение режимов (Обычный тайлинг <-> Свободный плавающий)
~/.config/hypr/scripts/window_mode.sh cycle

# Установка конкретного режима
~/.config/hypr/scripts/window_mode.sh tiling
~/.config/hypr/scripts/window_mode.sh floating
```

---

## Лицензия
MIT License
