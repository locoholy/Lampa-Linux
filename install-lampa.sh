#!/bin/sh
# Установщик Lampa для Linux / Steam Deck
# Использование: chmod +x install-lampa.sh && ./install-lampa.sh
set -e

LAMPA_VER=1.4.1    # https://github.com/yumata/lampa/releases
NWJS_VER=0.112.0   # https://github.com/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt/releases

INSTALL_DIR="$HOME/.local/lib/lampa"
DESKTOP_FILE="$HOME/.local/share/applications/lampa.desktop"
BIN_LINK="$HOME/.local/bin/lampa"

# ── приветствие ────────────────────────────────────────────────────────────
cat << 'BANNER'

  ██╗      █████╗ ███╗   ███╗██████╗  █████╗
  ██║     ██╔══██╗████╗ ████║██╔══██╗██╔══██╗
  ██║     ███████║██╔████╔██║██████╔╝███████║
  ██║     ██╔══██║██║╚██╔╝██║██╔═══╝ ██╔══██║
  ███████╗██║  ██║██║ ╚═╝ ██║██║     ██║  ██║
  ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝
  Установщик для Linux / Steam Deck

BANNER

# ── проверяем уже установленную версию ────────────────────────────────────
if [ -d "$INSTALL_DIR" ]; then
    printf "Lampa уже установлена в %s\n" "$INSTALL_DIR"
    printf "Переустановить? [д/н] "
    read -r REPLY
    case "$REPLY" in
        [дДyY]*) rm -rf "$INSTALL_DIR" ;;
        *) printf "Отмена.\n"; exit 0 ;;
    esac
fi

# ── архитектура ────────────────────────────────────────────────────────────
arch=$(uname -m)
case "$arch" in
    x86_64)  nw_arch=linux-x64   ;;
    aarch64) nw_arch=linux-arm64 ;;
    *)
        printf "Ошибка: архитектура %s не поддерживается.\n" "$arch" >&2
        exit 1
        ;;
esac

# ── утилиты распаковки ─────────────────────────────────────────────────────
need() { command -v "$1" >/dev/null 2>&1 || { printf "Нужна утилита: %s\n" "$1" >&2; exit 1; }; }
need curl

if command -v bsdtar >/dev/null 2>&1; then
    xzip() { bsdtar -xf "$1" -C "$2"; }
    xtar() { bsdtar -xf "$1" -C "$2"; }
else
    need unzip; need tar
    xzip() { unzip -q "$1" -d "$2"; }
    xtar() { tar -xf "$1" -C "$2"; }
fi

# ── загрузка ───────────────────────────────────────────────────────────────
printf "[1/4] Скачиваем файлы...\n"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -C - -Lo "$TMP/lampa.zip"   "https://github.com/yumata/lampa/releases/download/v${LAMPA_VER}/lampa-portable.zip"
curl -C - -Lo "$TMP/nwjs.tar.gz" "https://dl.nwjs.io/v${NWJS_VER}/nwjs-v${NWJS_VER}-${nw_arch}.tar.gz"
curl -C - -Lo "$TMP/ffmpeg.zip"  "https://github.com/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt/releases/download/${NWJS_VER}/${NWJS_VER}-${nw_arch}.zip"

# ── сборка ─────────────────────────────────────────────────────────────────
printf "[2/4] Собираем приложение...\n"
mkdir -p "$TMP/build/app"
xzip "$TMP/lampa.zip" "$TMP/build/app"

# Удаляем Windows-специфичные файлы NW.js рантайма
rm -rf "$TMP/build/app/locales" "$TMP/build/app/swiftshader"
find "$TMP/build/app" -maxdepth 1 \( \
    -name "*.bin" -o -name "*.dat" -o -name "*.dll" \
    -o -name "*.exe" -o -name "*.log" -o -name "*.pak" \) -delete
rm -f "$TMP/build/app/vk_swiftshader_icd.json"

printf "[3/4] Устанавливаем NW.js рантайм...\n"
xtar "$TMP/nwjs.tar.gz" "$TMP/build"
mv "$TMP/build/nwjs-v${NWJS_VER}-${nw_arch}" "$TMP/build/nwjs"

# ffmpeg с кодеками H.264/H.265 — без него встроенный плеер не работает
xzip "$TMP/ffmpeg.zip" "$TMP/build/nwjs/lib"

# ── лончер ─────────────────────────────────────────────────────────────────
cat > "$TMP/build/lampa" << 'LAUNCHER'
#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -n "${SteamEnv:-}${STEAM_RUNTIME:-}" ]; then
    # Запущено из Steam (Gaming Mode) — полный экран
    EXTRA="--start-fullscreen"
elif grep -qs "ID=steamos" /etc/os-release 2>/dev/null; then
    # Steam Deck Desktop Mode — нативное разрешение 800p
    EXTRA="--window-size=1280,800"
else
    EXTRA=""
fi

exec "$DIR/nwjs/nw" "$DIR/app" --disable-devtools $EXTRA "$@"
LAUNCHER
chmod +x "$TMP/build/lampa"

# ── установка ──────────────────────────────────────────────────────────────
printf "[4/4] Устанавливаем...\n"
mkdir -p "$HOME/.local/lib" "$HOME/.local/share/applications" "$HOME/.local/bin"
mv "$TMP/build" "$INSTALL_DIR"

# Ярлык на рабочем столе (опционально — создаём на Desktop если есть)
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Lampa
Comment=Movie and TV show media centre
Comment[ru]=Медиацентр — фильмы и сериалы
Icon=${INSTALL_DIR}/app/frame/icon.png
Exec=${INSTALL_DIR}/lampa
Terminal=false
Categories=AudioVideo;Video;
EOF

# Копируем ярлык на рабочий стол если он есть
for DESKTOP_PATH in "$HOME/Desktop" "$HOME/Рабочий стол" "$HOME/Рабочий_стол"; do
    if [ -d "$DESKTOP_PATH" ]; then
        cp "$DESKTOP_FILE" "$DESKTOP_PATH/lampa.desktop"
        chmod +x "$DESKTOP_PATH/lampa.desktop"
        break
    fi
done

# Симлинк для запуска из терминала: lampa
ln -sf "$INSTALL_DIR/lampa" "$BIN_LINK"

# На KDE desktop-файл нужно пометить как доверенный, иначе показывает имя файла
setfattr -n user.xdg.trusted -v "true" "$DESKTOP_FILE" 2>/dev/null || true
for DESKTOP_PATH in "$HOME/Desktop" "$HOME/Рабочий стол" "$HOME/Рабочий_стол"; do
    [ -f "$DESKTOP_PATH/lampa.desktop" ] && \
        setfattr -n user.xdg.trusted -v "true" "$DESKTOP_PATH/lampa.desktop" 2>/dev/null || true
done

# Обновляем кэш приложений (если есть утилита)
command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true

# ── итог ───────────────────────────────────────────────────────────────────
cat << INFO

  ✓ Lampa установлена!

  Запуск из терминала:
    lampa
    (если ~/.local/bin не в PATH, используйте: ${INSTALL_DIR}/lampa)

  Меню приложений (KDE / GNOME):
    Lampa появится в меню автоматически.
    Если не появилась — перезайдите в сессию или выполните:
    update-desktop-database ~/.local/share/applications/

  Steam Deck — Gaming Mode:
    1. Откройте Steam в Desktop Mode
    2. Библиотека → ⊕ → Добавить стороннее приложение
    3. Укажите: ${INSTALL_DIR}/lampa
    4. После добавления — назначьте обложку через правую кнопку → «Управление»

  Прокси (если нужен):
    Откройте файл ${INSTALL_DIR}/lampa
    и добавьте флаг: --proxy-server="протокол://адрес:порт"

  Удаление:
    rm -rf "${INSTALL_DIR}" "${DESKTOP_FILE}" "${BIN_LINK}"
    для очистки с рабочего стола также удалите ~/Desktop/lampa.desktop

INFO
