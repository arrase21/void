
#!/usr/bin/env python3
import subprocess
import json
import threading
import time
import queue
import shlex

# ─────────────────────────────────────────────
# 🔧 Configuración
GLYPH_FONT_FAMILY = "Symbols Nerd Font Mono"
SCROLL_TEXT_LENGTH = 25
SCROLL_SPEED = 0.4
PLAYERCTL_PATH = "/usr/bin/playerctl"

# ─────────────────────────────────────────────
# 🎵 Iconos por estado
STATUS_ICONS = {
    "paused": "󰐎",
    "playing": "",
    "stopped": ""
}
DEFAULT_STATUS_ICON = ""

# 🎧 Iconos por reproductor
PLAYER_ICONS = {
    "chromium": "",
    "brave": "",
    "firefox": "",
    "kdeconnect": "",
    "mopidy": "",
    "mpv": "󰐹",
    "spotify": "",
    "vlc": "󰕼",
    "default": ""
}

# ─────────────────────────────────────────────
# 🧩 Funciones auxiliares

def scroll_text(text, length=SCROLL_TEXT_LENGTH):
    text = text.ljust(length)
    scrolling_text = text + ' ' + text[:length]
    while True:
        for i in range(len(scrolling_text) - length):
            yield scrolling_text[i:i + length]

def get_active_player():
    """Devuelve el primer reproductor activo o None."""
    try:
        result = subprocess.run([PLAYERCTL_PATH, "-l"], stdout=subprocess.PIPE)
        players = result.stdout.decode().strip().splitlines()
        if not players:
            return None
        # Preferir los conocidos
        known = ["spotify", "mpv", "vlc", "brave", "chromium", "firefox", "mopidy", "kdeconnect"]
        for p in players:
            lower = p.lower()
            for k in known:
                if k in lower:
                    return lower
        return players[0].lower()
    except Exception:
        return None

def make_output(text, player, status):
    glyph = STATUS_ICONS.get(status, DEFAULT_STATUS_ICON)
    icon = PLAYER_ICONS.get(player, PLAYER_ICONS["default"])
    return {
        "text": f"<span font_family='{GLYPH_FONT_FAMILY}'>{icon} {glyph}</span> {text.strip()}"
    }

# ─────────────────────────────────────────────
# 🎧 Hilo que sigue la metadata de un reproductor activo

def metadata_listener(player, events: queue.Queue):
    cmd = f"{PLAYERCTL_PATH} --player={shlex.quote(player)} --follow metadata --format '{{{{status}}}}|{{{{artist}}}} - {{{{title}}}}'"
    process = subprocess.Popen(
        shlex.split(cmd),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1
    )
    for line in process.stdout:
        events.put(line.strip())
    process.wait()

# ─────────────────────────────────────────────
# 🚀 Ejecución principal

if __name__ == "__main__":
    events = queue.Queue()
    player = None
    listener = None
    song = ""
    status = "stopped"
    scroll = None
    text = ""

    while True:
        try:
            # Buscar reproductor activo si no hay uno
            if not player:
                player = get_active_player()
                if player:
                    threading.Thread(target=metadata_listener, args=(player, events), daemon=True).start()
                else:
                    print(json.dumps({"text": ""}), flush=True)
                    time.sleep(1)
                    continue

            # Procesar eventos nuevos
            while not events.empty():
                line = events.get()
                parts = line.split("|", 1)
                if len(parts) == 2:
                    status, song = parts
                else:
                    status = parts[0]
                scroll = None  # reiniciar scroll

            # Si el reproductor muere, reiniciar todo
            if subprocess.run([PLAYERCTL_PATH, "--player", player, "status"],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
                player = None
                events = queue.Queue()
                scroll = None
                song = ""
                status = "stopped"
                continue

            # Mostrar solo si hay canción activa
            if not song or status == "stopped":
                print(json.dumps({"text": ""}), flush=True)
                time.sleep(SCROLL_SPEED)
                continue

            # Scroll dinámico
            if len(song) > SCROLL_TEXT_LENGTH:
                if scroll is None:
                    scroll = scroll_text(song)
                text = next(scroll)
            else:
                text = song.ljust(SCROLL_TEXT_LENGTH)

            # Imprimir salida Waybar
            print(json.dumps(make_output(text, player, status)), flush=True)
            time.sleep(SCROLL_SPEED if status == "playing" else 1.0)

        except Exception as e:
            print(json.dumps({"text": f" Error: {e}"}), flush=True)
            player = None
            time.sleep(1)
