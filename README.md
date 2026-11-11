# 🌟 Hyprland Custom Dotfiles

[![English](https://img.shields.io/badge/Language-English-blue)](#-english-version)
[![Russian](https://img.shields.io/badge/Language-Русский-red)](#-hyprland-custom-dotfiles-русский)

A modern, highly modular configuration for **Hyprland** (Wayland) featuring:
- **Interactive Control Sidebar** powered by **GtkLayerShell** with audio visualizer, volume & brightness sliders, and audio output sink switcher.
- **Bilingual Interface** with on-the-fly language switching (English / Russian).
- **4 Design Families with Extended Sub-themes**: Total Black, Total White, Apple macOS (Liquid Glass & Full Pitch Dark), and Cyberpunk/Nord.
- **Window Layout Modes**: Auto-Tiling, Monocle (Fullscreen **with Waybar visible**), and Windows Mode (Stacking floating windows with mouse drag/resize).
- **Screenshots System**: Automatically saved to `~/Screenshots/` and copied to clipboard.
- **Keybindings Cheatsheet Window**: Accessible via `Super + /` or `Super + F1`.
- **Universal Installer (`install.sh`)**: For both clean installations and updating existing setups with automatic timestamped backups.

---

## 🇬🇧 English Version

### ✨ Key Features

1. **Dual Language Support (EN / RU)**:
   - Language prompt upon running `./install.sh`.
   - On-the-fly UI language toggle in the sidebar (`[ 🌐 EN | RU ]`) or via shortcut `Super + Alt + L`.

2. **Window Layout Modes**:
   - ⛶ **Fullscreen with Waybar (Monocle / Maximize)**: Windows expand to full screen while keeping **Waybar interactive and visible** (`fullscreen 1`).
   - 🪟 **Windows Mode (Floating)**: All windows float freely, can overlap, and can be dragged (`Super + LMB`) or resized (`Super + RMB`). New windows open floating automatically.
   - ▦ **Tiling Mode**: Standard Hyprland dynamic dwindle tiling.
   - Interactive switcher in Waybar (`[ ▦ Tiling | ⛶ Max | 🪟 Win ]`) and Sidebar.

3. **4 Theme Families & Sub-themes**:
   - ⬛ **Total Black**:
     - *Pure OLED*: 100% solid pitch black, zero blur, maximum contrast.
     - *Matte Stealth*: Dark graphite with subtle blur.
     - *Smoked Glass*: Translucent dark obsidian glass with deep blur.
   - ⬜ **Total White**:
     - *Snow Clean*: Crisp bright white minimalism with high contrast dark text.
     - *Frosted Glass*: Translucent acrylic white glass.
     - *Catppuccin Latte*: Warm soothing cream pastel.
   - 🍎 **Apple macOS**:
     - *macOS Liquid Glass*: Full window and bar transparency, 4-pass blur, floating pill island,  menu.
     - *macOS Pitch Dark*: Full dark glass with soft dark-white/silver symbols and icons.
     - *macOS Dark Glass*: Sonoma-style dark glass.
     - *macOS Light Glass*: Cupertino light frosted glass.
   - ⚡ **Cyber & Nord**:
     - *Cyber Neon*: High-voltage cyan/magenta synthwave glow.
     - *Nord Arctic*: Polar ice-blue aesthetic.

4. **Compact Player & Control Center (Sidebar)**:
   - Sleek compact height.
   - Live animated visualizer / equalizer bars when music is playing.
   - Expandable drawer with:
     - Volume slider (`pactl`).
     - Brightness slider (`brightnessctl`).
     - **Audio Output Selector**: easily switch between Speakers, Headphones, Bluetooth, and HDMI with live stream routing.

5. **Screenshots & Keybindings Cheatsheet**:
   - All screenshots saved directly to `~/Screenshots/Screenshot_YYYY-MM-DD_HH-MM-SS.png` and copied to clipboard.
   - Floating keybindings help cheatsheet available at `Super + /` or `Super + F1`.

---

### 🚀 Quick Start & Installation

```bash
git clone https://github.com/charm457/hyprland_dots.git ~/hyprland_dots
cd ~/hyprland_dots
chmod +x install.sh
./install.sh
```

Choose your preferred language (**English** or **Русский**), then select:
- **1) Clean Install**: Checks and installs missing packages, deploys modular configs.
- **2) Update Existing**: Creates a timestamped backup in `~/.config/hypr_backup_...` and cleanly applies new configs with live reload.

---

### ⌨️ Keybindings (Cheatsheet)

| Shortcut | Description |
|---|---|
| **`Super + /`** or **`Super + F1`** | **Show Keybindings Cheatsheet Window** |
| **`Super + P`** | Toggle Control Sidebar |
| **`Super + Shift + S`** | Screenshot area (copied & saved to `~/Screenshots`) |
| **`Print`** | Screenshot full screen |
| **`Super + Print`** | Screenshot active window |
| **`Super + Alt + S`** | Interactive screenshot menu |
| **`Super + Z`** or **`Super + M`** | **Fullscreen WITH Waybar** (Monocle) |
| **`Super + F`** | Fullscreen **WITHOUT** Waybar |
| **`Super + V`** | Toggle current window Floating / Tiled |
| **`Super + W`** | Cycle window modes: [Tiling ↔ Fullscreen with Waybar ↔ Windows Floating] |
| **`Super + Shift + W`** | Enable Windows floating mode on active workspace |
| **`Super + Shift + T`** | Reset active workspace to Tiling |
| **`Super + LMB (drag)`** | Drag floating windows with mouse |
| **`Super + RMB (drag)`** | Resize floating windows with mouse |
| **`Super + Alt + L`** | Toggle interface language (EN / RU) |
| **`Super + Alt + P`** | Cycle Waybar position (Top ↔ Bottom ↔ Hide) |
| **`Super + ]`** / **`[`** | Next / previous wallpaper in `~/wallpapers` |
| **`Super + Return`** | Kitty terminal |
| **`Super + Space`** / **`D`** | Rofi application launcher |
| **`Super + Q`** | Close focused window |
| **`Super + Shift + M`** | Safe exit from Hyprland |

---

<br>

## 🇷🇺 Hyprland Custom Dotfiles (Русский)

Модульная сборка для **Hyprland** (Wayland) с интерактивной боковой панелью управления на **GtkLayerShell**, переключателем стилей, режимами окон и поддержкой двух языков.

### ✨ Главные возможности

1. **Поддержка двух языков (RU / EN)**:
   - Выбор языка в начале работы `install.sh`.
   - Мгновенное переключение языка прямо в сайдбаре (`[ 🌐 EN | RU ]`) или по клавише `Super + Alt + L`.

2. **Режимы окон**:
   - ⛶ **На весь экран с Waybar (Monocle / Maximize)**: Окно раскрывается на весь экран, но **Waybar остается на виду и доступен для кликов** (`fullscreen 1`).
   - 🪟 **Как в обычной Windows (Плавающие окна)**: Окна свободно плавают, перекрываются, перемещаются мышью (`Super + ЛКМ`) и масштабируются (`Super + ПКМ`). Новые окна открываются плавающими.
   - ▦ **Тайлинг (Плитка)**: Классический тайлинг Hyprland (dwindle).

3. **4 Семейства тем с подстилями**:
   - ⬛ **Total Black**: Чистый OLED без размытия, Графитовый Stealth, Дымчатое стекло.
   - ⬜ **Total White**: Чистый белый Snow Clean, Белое стекло, Catppuccin Latte.
   - 🍎 **Apple macOS**:
     - *macOS Liquid Glass*: полная прозрачность, 4-проходный блюр, значок ``.
     - *macOS Pitch Dark*: глубокое темное стекло со спокойными темно-белыми/серебряными символами.
     - *macOS Dark / Light*: темное и светлое матовое стекло Sonoma/Cupertino.
   - ⚡ **Кибер & Норд**: Cyber Neon (киберпанк), Nord Arctic (ледяной синий).

4. **Компактный плеер и Центр управления (Сайдбар Win+P)**:
   - Уменьшенная высота плеера.
   - Анимированный эквалайзер.
   - Выдвижной отсек:
     - Ползунок громкости (`pactl`).
     - Ползунок яркости (`brightnessctl`).
     - **Выбор аудиовыхода**: переключение вывода звука между динамиками, наушниками, Bluetooth и HDMI.

5. **Скриншоты и Шпаргалка клавиш**:
   - Скриншоты автоматически сохраняются в `~/Screenshots/` и копируются в буфер обмена.
   - Всплывающее окно со всеми комбинациями клавиш вызывается по `Super + /` или `Super + F1`.

---

### 🚀 Установка

```bash
git clone https://github.com/charm457/hyprland_dots.git ~/hyprland_dots
cd ~/hyprland_dots
chmod +x install.sh
./install.sh
```

Выберите язык и желаемый тип установки (чистая или обновление с авто-бэкапом).

---

## 📄 License
MIT License
