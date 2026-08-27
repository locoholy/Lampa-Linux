# Lampa for Linux

Builds a native Linux app of the **Lampa** media centre from its official
Windows release, using the open-source NW.js runtime. One script, no root,
no package manager. Works on any x86_64 or arm64 Linux — and on **Steam Deck**,
including Gaming Mode.

**English** · [Русский](README.ru.md)

![Linux](https://img.shields.io/badge/Linux-x86__64_·_arm64-1a9fff?style=flat-square)
![SteamOS](https://img.shields.io/badge/SteamOS-Gaming_Mode-5ba32b?style=flat-square)
![Install](https://img.shields.io/badge/install-one_script-e5a50a?style=flat-square)
![No root](https://img.shields.io/badge/root-not_required-7a8894?style=flat-square)

---

## Install

```bash
git clone https://github.com/<you>/Lampa-Linux
cd Lampa-Linux
chmod +x install-lampa.sh
./install-lampa.sh
```

Everything lands under `$HOME` — nothing is written to `/usr`, so a SteamOS
update cannot wipe it and no password is ever asked for.

**Requirements:** `curl`, plus either `bsdtar` or `unzip`+`tar`. About 500 MB
free while downloading, ~300 MB once installed.

## Why a script and not a package

Lampa ships officially for Windows, Android, webOS and Tizen — but not for
Linux. The Windows build is not a native binary: it is a web app wrapped in
NW.js, and NW.js itself is published for Linux too. So the app and the runtime
can simply be recombined.

That is all the script does:

1. downloads the portable Lampa release and a Linux NW.js of a matching version;
2. strips the Windows half of the wrapper — `.exe`, `.dll`, `.pak`, the bundled
   SwiftShader and locale blobs — leaving only the app itself;
3. drops in **ffmpeg with H.264/H.265**, without which the built-in player
   opens a black window: the stock NW.js ffmpeg ships without those codecs
   for licensing reasons;
4. writes a launcher, a `.desktop` entry and a `lampa` symlink.

Nothing is patched or repacked — each part is used as its author published it.

## Steam Deck

The launcher detects where it was started from and sizes itself accordingly:
fullscreen under Steam, 1280×800 in SteamOS Desktop Mode, untouched elsewhere.

To get it into Gaming Mode: **Steam → Library → ⊕ → Add a Non-Steam Game →**
`~/.local/lib/lampa/lampa`. Artwork can be set afterwards through
right-click → Manage.

On KDE the `.desktop` files are marked trusted automatically
(`user.xdg.trusted`), otherwise Plasma shows the file name instead of the app
name and refuses to launch it from the desktop.

## Proxy

Add the flag to the `exec` line in `~/.local/lib/lampa/lampa`:

```sh
exec "$DIR/nwjs/nw" "$DIR/app" --disable-devtools --proxy-server="http://host:port" $EXTRA "$@"
```

## Update and uninstall

Re-run `install-lampa.sh` — it offers to reinstall over an existing copy.
Pinned versions live at the top of the script (`LAMPA_VER`, `NWJS_VER`).

```bash
rm -rf ~/.local/lib/lampa
rm -f  ~/.local/share/applications/lampa.desktop ~/.local/bin/lampa ~/Desktop/lampa.desktop
```

## Credits

This repository contains only the installer. Lampa itself belongs to its
authors, NW.js to theirs.

* Lampa — <https://github.com/yumata/lampa>
* NW.js — <https://nwjs.io>
* ffmpeg builds — <https://github.com/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt>

## License

MIT — see [LICENSE](LICENSE). Applies to the installer script only.
