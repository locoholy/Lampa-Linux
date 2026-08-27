# Lampa для Linux

Собирает нативное Linux-приложение медиацентра **Lampa** из официальной
Windows-сборки на открытом рантайме NW.js. Один скрипт, без root и без
пакетного менеджера. Работает на любом x86_64 или arm64 Linux — и на
**Steam Deck**, в том числе в игровом режиме.

[English](README.md) · **Русский**

![Linux](https://img.shields.io/badge/Linux-x86__64_·_arm64-1a9fff?style=flat-square)
![SteamOS](https://img.shields.io/badge/SteamOS-игровой_режим-5ba32b?style=flat-square)
![Установка](https://img.shields.io/badge/установка-один_скрипт-e5a50a?style=flat-square)
![Без root](https://img.shields.io/badge/root-не_нужен-7a8894?style=flat-square)

---

## Установка

```bash
git clone https://github.com/<вы>/Lampa-Linux
cd Lampa-Linux
chmod +x install-lampa.sh
./install-lampa.sh
```

Всё ставится в `$HOME`, в `/usr` не пишется ничего — поэтому обновление
SteamOS ничего не сотрёт, а пароль не спрашивается ни разу.

**Нужны:** `curl` и либо `bsdtar`, либо `unzip` с `tar`. ~500 МБ свободного
места на время загрузки, ~300 МБ после установки.

## Почему скрипт, а не пакет

Lampa официально выходит для Windows, Android, webOS и Tizen — но не для
Linux. При этом Windows-сборка не нативная: это веб-приложение, завёрнутое
в NW.js, а сам NW.js выходит и под Linux. Значит, приложение и рантайм можно
просто пересобрать заново.

Ровно это скрипт и делает:

1. качает портативный релиз Lampa и Linux-версию NW.js подходящей версии;
2. выкидывает windows-половину обёртки — `.exe`, `.dll`, `.pak`, встроенный
   SwiftShader и локали, — оставляя само приложение;
3. подкладывает **ffmpeg с H.264/H.265**, без которого встроенный плеер
   открывает чёрное окно: штатный ffmpeg в NW.js идёт без этих кодеков
   по лицензионным причинам;
4. пишет лончер, `.desktop` и симлинк `lampa`.

Ничего не патчится и не перепаковывается — каждая часть используется в том
виде, в каком её выложил автор.

## Steam Deck

Лончер сам понимает, откуда его запустили, и подбирает размер окна:
полный экран под Steam, 1280×800 в десктопном режиме SteamOS, в остальных
случаях не трогает ничего.

Чтобы добавить в игровой режим: **Steam → Библиотека → ⊕ → Добавить
стороннее приложение →** `~/.local/lib/lampa/lampa`. Обложку потом можно
поставить через правую кнопку → «Управление».

На KDE `.desktop` помечаются доверенными автоматически (`user.xdg.trusted`),
иначе Plasma показывает имя файла вместо имени приложения и отказывается
запускать ярлык с рабочего стола.

## Прокси

Добавьте флаг в строку `exec` файла `~/.local/lib/lampa/lampa`:

```sh
exec "$DIR/nwjs/nw" "$DIR/app" --disable-devtools --proxy-server="http://адрес:порт" $EXTRA "$@"
```

## Обновление и удаление

Запустите `install-lampa.sh` снова — он предложит переустановить поверх.
Версии закреплены вверху скрипта (`LAMPA_VER`, `NWJS_VER`).

```bash
rm -rf ~/.local/lib/lampa
rm -f  ~/.local/share/applications/lampa.desktop ~/.local/bin/lampa ~/Desktop/lampa.desktop
```

## Благодарности

В этом репозитории лежит только установщик. Сама Lampa принадлежит её
авторам, NW.js — своим.

* Lampa — <https://github.com/yumata/lampa>
* NW.js — <https://nwjs.io>
* сборки ffmpeg — <https://github.com/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt>

## Лицензия

MIT — см. [LICENSE](LICENSE). Распространяется на скрипт установки.
