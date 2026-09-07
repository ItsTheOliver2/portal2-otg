set -e

BOX_NAME="otg"

echo "=== Portal 2 OTG Setup (Distrobox) ==="

# 1. Create distrobox
if ! distrobox list --json 2>/dev/null | grep -q "\"$BOX_NAME\""; then
    echo "[1/4] Creating distrobox '$BOX_NAME'..."
    distrobox create --name "$BOX_NAME" --image ubuntu:24.04
else
    echo "[1/4] Distrobox '$BOX_NAME' already exists, skipping."
fi

# 2. Install packages
echo "[2/4] Installing dependencies..."
distrobox enter "$BOX_NAME" -- bash -c '
    apt update -qq
    apt install -y -qq xdotool python3-tk
'

# 3. Write overlay script
echo "[3/4] Writing otg_overlay.py..."
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

# 4. xhost
echo "[4/4] Granting X access..."
xhost +si:localuser:$USER >/dev/null 2>&1 || true
if ! grep -q 'xhost +si:localuser' ~/.distroboxrc 2>/dev/null; then
    echo 'xhost +si:localuser:$USER >/dev/null 2>&1' >> ~/.distroboxrc
fi

# Write the wrapper
cat > ~/otg_wrapper.sh << 'EOF'
#!/bin/bash
setsid /usr/bin/distrobox enter otg -- python3 ~/otg_overlay.py > /dev/null 2>&1 &
sleep 2
exec "$@"
EOF
chmod +x ~/otg_wrapper.sh

echo ""
echo "=== Done! ==="
echo ""
echo "Steam launch option for P2CE:"
echo "  ~/otg_wrapper.sh"
echo ""
echo "Manual run (without Steam):"
echo "  distrobox enter otg -- python3 ~/otg_overlay.py"
echo ""
echo "Press Escape in-game to close the overlay."
