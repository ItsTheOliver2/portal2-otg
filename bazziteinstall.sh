#!/bin/bash
# Portal 2 OTG - Setup Script (Bazzite native)
# Run on Bazzite host. May require a reboot if packages are missing.

set -e

SCRIPT_NAME="otg_overlay.py"
WRAPPER_NAME="otg_wrapper.sh"

echo "=== Portal 2 OTG Setup (Bazzite) ==="

# --- Dependency check ---
MISSING=()

if ! command -v xdotool &>/dev/null; then
    echo "  [MISSING] xdotool"
    MISSING+=("xdotool")
else
    echo "  [OK] xdotool"
fi

if ! python3 -c "import tkinter" &>/dev/null; then
    echo "  [MISSING] python3-tkinter"
    MISSING+=("python3-tkinter")
else
    echo "  [OK] python3-tkinter"
fi

if ! command -v xhost &>/dev/null; then
    echo "  [MISSING] xorg-x11-server-utils"
    MISSING+=("xorg-x11-server-utils")
else
    echo "  [OK] xorg-x11-server-utils"
fi

# --- Install missing (single rpm-ostree call) ---
if [ ${#MISSING[@]} -ne 0 ]; then
    echo ""
    echo "Installing: ${MISSING[*]}"
    echo ""
    rpm-ostree install "${MISSING[@]}"
    echo ""
    echo "!!! REBOOT REQUIRED !!!"
    echo "After reboot, run this script again to finish setup."
    exit 0
fi

echo ""
echo "All dependencies present."
echo ""

# --- Write overlay script ---
echo "[1/3] Writing $SCRIPT_NAME..."
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

# --- Write wrapper ---
echo "[2/3] Writing $WRAPPER_NAME..."
cat > ~/otg_wrapper.sh << 'EOF'
#!/bin/bash
setsid python3 ~/otg_overlay.py > /dev/null 2>&1 &
sleep 2
exec "$@"
EOF
chmod +x ~/otg_wrapper.sh

# --- xhost ---
echo "[3/3] Granting X access..."
xhost +si:localuser:$USER >/dev/null 2>&1 || true

echo ""
echo "=== Done! ==="
echo ""
echo "Steam launch option for P2CE:"
echo "  ~/otg_wrapper.sh"
echo ""
echo "Manual run:"
echo "  python3 ~/otg_overlay.py"
echo ""
echo "Press Escape in-game to close the overlay."   
