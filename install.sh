#!/bin/bash
# Portal 2 OTG - Setup Script (Ubuntu native)
# Run on your Ubuntu system

set -e

SCRIPT_NAME="otg_overlay.py"

echo "=== Portal 2 OTG Setup ==="

# 1. Install dependencies
echo "[1/3] Installing dependencies..."
sudo apt update -qq
sudo apt install -y -qq xdotool python3-tk

# 2. Create the overlay script
echo "[2/3] Writing $SCRIPT_NAME..."
cat > ~/otg_overlay.py << 'PYEOF'
import tkinter as tk
import subprocess

root = tk.Tk()
root.attributes('-fullscreen', True)
root.attributes('-alpha', 0.3)
root.attributes('-topmost', True)
root.config(bg='black')

def key_press(key):
    subprocess.run(['xdotool', 'keydown', key], check=False)

def key_release(key):
    subprocess.run(['xdotool', 'keyup', key], check=False)

def key_tap(key):
    subprocess.run(['xdotool', 'key', key], check=False)

def mouse_click(btn):
    subprocess.run(['xdotool', 'click', str(btn)], check=False)

for label, key, x, y in [
    ('W', 'w', 200, 400),
    ('A', 'a', 100, 500),
    ('S', 's', 200, 600),
    ('D', 'd', 300, 500),
]:
    btn = tk.Button(root, text=label, font=("Arial", 32), width=4, height=2)
    btn.bind('<ButtonPress-1>', lambda e, k=key: key_press(k))
    btn.bind('<ButtonRelease-1>', lambda e, k=key: key_release(k))
    btn.place(x=x, y=y)

actions = [
    ('JUMP',     lambda: key_tap('space'),  800,  800),
    ('CROUCH',   lambda: key_tap('ctrl'),   600,  900),
    ('USE',      lambda: key_tap('e'),      1000, 900),
    ('PORTAL B', lambda: mouse_click(1),    1200, 600),
    ('PORTAL O', lambda: mouse_click(3),    1200, 800),
]

for label, action, x, y in actions:
    btn = tk.Button(root, text=label, font=("Arial", 16), width=6, height=2,
                    command=action)
    btn.place(x=x, y=y)

root.bind('<Escape>', lambda e: root.destroy())
root.mainloop()
PYEOF

# 3. Set up xhost for X access (only needed if running under Wayland)
echo "[3/3] Granting X access..."
xhost +si:localuser:$USER >/dev/null 2>&1 || true

echo ""
echo "=== Done! ==="
echo ""
echo "To run the overlay while P2CE is running:"
echo "  python3 ~/otg_overlay.py"
echo ""
echo "Or add this to P2CE Steam launch options for auto-start:"
echo "  sh -c 'python3 ~/otg_overlay.py &; %command'"
echo ""
echo "Press Escape in-game to close the overlay."   
