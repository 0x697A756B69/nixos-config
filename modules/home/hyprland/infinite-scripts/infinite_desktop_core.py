import sys, struct, threading, time, subprocess, json, os
import fcntl
import select
import math
import socket
import random
from evdev import InputDevice, list_devices, ecodes

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (move_window_exact_lua, resize_window_exact_lua,
                      set_floating_lua, focus_window_lua, batch_async)

#ruta deseada /home/usuario/scripts/

# Ya no se pasan rutas de dispositivo a mano: se autodetectan por capacidades.
# Uso: infinite_desktop_core.py [speed]
speed = float(sys.argv[1]) if len(sys.argv) > 1 else 1.0

DEVICE_RESCAN_INTERVAL = 3.0  # segundos entre escaneos de nuevos/removidos dispositivos

EVENT_SIZE = struct.calcsize('llHHi')
EV_KEY=1; EV_REL=2; REL_X=0; REL_Y=1
KEY_LEFTMETA=125; KEY_RIGHTMETA=126
KEY_LEFTALT=56; KEY_RIGHTALT=100
KEY_LEFTCTRL=29; KEY_RIGHTCTRL=97
KEY_LEFT=105; KEY_RIGHT=106
KEY_UP=103; KEY_DOWN=108
BTN_LEFT=272

STATE_FILE = "/tmp/infinite-desktop-state"
PROTECTED_APPS = ['brave-browser', 'chromium', 'chromium-browser', 'google-chrome', 
                  'firefox', 'firefoxdeveloperedition', 'librewolf', 'vivaldi', 
                  'opera', 'microsoft-edge']

lock = threading.Lock()
super_pressed=False; alt_pressed=False; ctrl_pressed=False; btn_left=False
acc_x=0.0; acc_y=0.0
frame_held_hidden=False  # último estado notificado a quickshell (evita spam de llamadas ipc)

# Variables para arrastre de ventanas
window_drag_active = False
last_window_pos = None
last_window_bounds = None
mouse_rel_x = 0
mouse_rel_y = 0

# Paso de movimiento con teclado
KEY_MOVE_STEP = 20

def read_inverted():
    try:
        with open(STATE_FILE) as f:
            return f.read().strip() == 'inverse'
    except:
        return False

def notify_quickshell_hold(state):
    """Avisa a quickshell (IpcHandler target='frame') que esconda/muestre
    el marco. No bloqueante: se lanza en su propio hilo para no meter
    latencia en el loop de lectura de teclado. Silenciosa si quickshell
    no está corriendo (p.ej. durante un reload)."""
    try:
        subprocess.run(
            ['qs', 'ipc', 'call', 'frame', 'setHeldHidden', 'true' if state else 'false'],
            capture_output=True, timeout=1.0
        )
    except Exception:
        pass

def get_monitor_bounds():
    try:
        r = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True, timeout=0.1)
        monitors = json.loads(r.stdout)
        if monitors:
            for m in monitors:
                if m.get('focused', False):
                    return {
                        'left': m['x'],
                        'right': m['x'] + m['width'],
                        'top': m['y'],
                        'bottom': m['y'] + m['height'],
                        'width': m['width'],
                        'height': m['height']
                    }
            m = monitors[0]
            return {
                'left': m['x'],
                'right': m['x'] + m['width'],
                'top': m['y'],
                'bottom': m['y'] + m['height'],
                'width': m['width'],
                'height': m['height']
            }
    except:
        pass
    return {'left': 0, 'right': 1920, 'top': 0, 'bottom': 1080, 'width': 1920, 'height': 1080}

def get_floating_windows(workspace_id):
    try:
        r = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=0.1)
        clients = json.loads(r.stdout)
        floating = []
        for w in clients:
            if w.get('floating') and w.get('workspace', {}).get('id') == workspace_id:
                floating.append(w)
        return floating
    except:
        return []


# ---- Modo flotante: nuevas ventanas se abren flotando ----

MODE_FILE = "/tmp/floating_mode.json"
OPENWINDOW_WAIT = 0.45  # segundos antes de colocar la nueva ventana
FLOAT_OFFSET = 34        # desplazamiento aleatorio máximo respecto a otra ventana
OPENWINDOW_GAP = 40      # espacio (px) entre la nueva ventana y las existentes

def load_floating_mode():
    try:
        with open(MODE_FILE) as f:
            return json.load(f)
    except Exception:
        return {}

def is_floating_mode():
    mode = load_floating_mode()
    return bool(mode.get("active"))


def normalize_addr(addr):
    """Les eventos openwindow devuelven la dirección sin prefijo `0x`,
    mientras que `hyprctl clients -j` la entrega con `0x`. Normaliza."""
    addr = addr.strip()
    if addr and not addr.lower().startswith("0x"):
        return "0x" + addr
    return addr


def get_all_windows(workspace_id):
    try:
        r = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=0.1)
        clients = json.loads(r.stdout)
        return [w for w in clients if w.get('workspace', {}).get('id') == workspace_id]
    except Exception:
        return []


def random_nearby_position(workspace_id, new_window, monitor):
    """Devuelve (x, y) para la nueva ventana flotante, colocada a un lado de
    otra ventana existente (con espacio entre ambas), no superpuesta."""
    others = [w for w in get_all_windows(workspace_id) if w.get('address') != new_window.get('address')]
    nw, nh = new_window.get('size', [800, 600])
    gap = OPENWINDOW_GAP

    if not others:
        cx = (monitor['right'] - monitor['left']) // 2 + monitor['left']
        cy = (monitor['bottom'] - monitor['top']) // 2 + monitor['top']
        x = cx - nw // 2 + random.randint(-FLOAT_OFFSET, FLOAT_OFFSET)
        y = cy - nh // 2 + random.randint(-FLOAT_OFFSET, FLOAT_OFFSET)
        return clamp_position(x, y, nw, nh, monitor)

    # Preferir la ventana enfocada / la más reciente (más relevante visualmente)
    focused = get_focused_window()
    base = None
    if focused and focused.get('floating') and \
       any(w.get('address') == focused.get('address') for w in others):
        base = focused
    if base is None:
        base = others[0]

    bx, by = base['at'][0], base['at'][1]
    bw, bh = base['size'][0], base['size'][1]

    # Intentar a la derecha: base.right + gap .. base.right + gap + nw
    cand = [
        (bx + bw + gap, by + random.randint(-FLOAT_OFFSET, FLOAT_OFFSET)),
        (bx - nw - gap, by + random.randint(-FLOAT_OFFSET, FLOAT_OFFSET)),
        (bx + random.randint(-FLOAT_OFFSET, FLOAT_OFFSET), by + bh + gap),
        (bx + random.randint(-FLOAT_OFFSET, FLOAT_OFFSET), by - nh - gap),
    ]
    for (x, y) in cand:
        if fits_in_monitor(x, y, nw, nh, monitor):
            return clamp_position(x, y, nw, nh, monitor)

    # Si nada cabe, cascada simple con un offset acumulado
    x = bx + bw // 2 - nw // 2 + random.randint(-FLOAT_OFFSET, FLOAT_OFFSET)
    y = by + bh // 2 - nh // 2 + random.randint(-FLOAT_OFFSET, FLOAT_OFFSET)
    return clamp_position(x, y, nw, nh, monitor)


def fits_in_monitor(x, y, w, h, monitor):
    return (x >= monitor['left'] and y >= monitor['top']
            and x + w <= monitor['right'] and y + h <= monitor['bottom'])


def clamp_position(x, y, w, h, monitor):
    x = max(monitor['left'], min(x, monitor['right'] - w))
    y = max(monitor['top'], min(y, monitor['bottom'] - h))
    return int(x), int(y)


def handle_new_window(workspace_id, address, monitor):
    """Fuerza flotante y coloca la nueva ventana cerca de las existentes."""
    address = normalize_addr(address)
    time.sleep(OPENWINDOW_WAIT)
    try:
        clients = hyprctl_json_clients()
        win = next((w for w in clients if w.get('address') == address), None)
        if not win:
            return
        if not is_floating_mode():
            return
        if win.get('workspace', {}).get('id') != workspace_id:
            workspace_id = win['workspace'].get('id', workspace_id)
        if is_protected_app(win):
            return
        x, y = random_nearby_position(workspace_id, win, monitor)
        exprs = []
        if not win.get('floating'):
            exprs.append(set_floating_lua(address, True))
        exprs.append(move_window_exact_lua(x, y, address))
        exprs.append(focus_window_lua(address))
        # Un solo batch: garantiza orden (flotar -> mover -> enfocar) y
        # que el foco siga a la app recién lanzada.
        batch_async(exprs)
    except Exception:
        pass


def hyprctl_json_clients():
    try:
        r = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=0.1)
        return json.loads(r.stdout)
    except Exception:
        return []


def workspace_events_listener():
    """Hilo que escucha el socket de eventos de Hyprland y detecta nuevas
    ventanas (openwindow). Cuando el modo flotante está activo, coloca la
    nueva ventana flotando cerca de las existentes."""
    try:
        sig = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
        sock_path = f"/run/user/{os.getuid()}/hypr/{sig}/.socket2.sock"
        sock = socket.socket(socket.AF_UNIX)
        sock.connect(sock_path)
    except Exception:
        print("Floating-mode: no se pudo conectar al socket de eventos", flush=True)
        return

    sock.settimeout(0.5)
    buf = b""
    while True:
        try:
            data = sock.recv(4096)
            if not data:
                break
            buf += data
            while b"\n" in buf:
                line, _, buf = buf.partition(b"\n")
                line = line.decode(errors="replace").strip()
                if not line:
                    continue
                event, _, rest = line.partition(">>")
                if event == "openwindow":
                    parts = [p.strip() for p in rest.split(",")]
                    address = parts[0] if parts else ""
                    title = parts[1] if len(parts) > 1 else ""
                    windows = hyprctl_json_clients()
                    mon = get_monitor_bounds()
                    threading.Thread(
                        target=handle_new_window,
                        args=(get_cached_workspace_id(), address, mon),
                        daemon=True,
                    ).start()
        except socket.timeout:
            continue
        except Exception:
            break
    try:
        sock.close()
    except Exception:
        pass

def get_focused_window():
    try:
        r = subprocess.run(['hyprctl', 'activewindow', '-j'], capture_output=True, text=True, timeout=0.1)
        return json.loads(r.stdout)
    except:
        return None

def is_protected_app(window):
    if not window:
        return False
    window_class = window.get('class', '').lower()
    return any(app in window_class for app in PROTECTED_APPS)

def get_window_center(window):
    return (window['at'][0] + window['size'][0] // 2,
            window['at'][1] + window['size'][1] // 2)

def get_window_bounds(window):
    x, y = window['at'][0], window['at'][1]
    w, h = window['size'][0], window['size'][1]
    return {
        'left': x,
        'right': x + w,
        'top': y,
        'bottom': y + h,
        'center_x': x + w // 2,
        'center_y': y + h // 2
    }

def windows_overlap_horizontally(bounds1, bounds2):
    return not (bounds1['right'] <= bounds2['left'] or bounds1['left'] >= bounds2['right'])

def windows_overlap_vertically(bounds1, bounds2):
    return not (bounds1['bottom'] <= bounds2['top'] or bounds1['top'] >= bounds2['bottom'])



def pan_other_windows(excluded_addr, dx, dy, workspace_id):
    """Mueve todas las ventanas EXCEPTO la especificada en un solo batch"""
    if dx == 0 and dy == 0:
        return
    try:
        floating_windows = get_floating_windows(workspace_id)
        exprs = []
        for w in floating_windows:
            if w['address'] != excluded_addr:
                nx = int(w['at'][0] + dx)
                ny = int(w['at'][1] + dy)
                exprs.append(move_window_exact_lua(nx, ny, w['address']))
        batch_async(exprs)
    except:
        pass

def get_monitor_center():
    """Devuelve el centro del monitor enfocado."""
    try:
        r = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True, timeout=0.1)
        monitors = json.loads(r.stdout)
        for m in monitors:
            if m.get('focused', False):
                return m['x'] + m['width'] // 2, m['y'] + m['height'] // 2
    except:
        pass
    return 960, 540


def monitor_window_drag():
    """Monitorea si se esta arrastrando una ventana y aplica empuje en bordes"""
    global window_drag_active, last_window_bounds, mouse_rel_x, mouse_rel_y
    
    dragged_window_addr = None
    
    while True:
        try:
            with lock:
                is_dragging = super_pressed and btn_left and not alt_pressed and not ctrl_pressed
                mouse_dx = mouse_rel_x
                mouse_dy = mouse_rel_y
                mouse_rel_x = 0
                mouse_rel_y = 0
            
            if is_dragging and not window_drag_active:
                focused = get_focused_window()
                if focused and focused.get('address'):
                    dragged_window_addr = focused['address']
                    window_drag_active = True
                    last_window_bounds = get_window_bounds(focused)
            
            elif not is_dragging and window_drag_active:
                window_drag_active = False
                dragged_window_addr = None
                last_window_bounds = None
            
            if window_drag_active and dragged_window_addr:
                window = get_focused_window()
                if window and window.get('address') == dragged_window_addr:
                    current_bounds = get_window_bounds(window)
                    monitor = get_monitor_bounds()
                    MARGIN = 10
                    
                    touch_left   = current_bounds['left']   <= monitor['left']   + MARGIN
                    touch_right  = current_bounds['right']  >= monitor['right']  - MARGIN
                    touch_top    = current_bounds['top']    <= monitor['top']    + MARGIN
                    touch_bottom = current_bounds['bottom'] >= monitor['bottom'] - MARGIN
                    
                    if (touch_left or touch_right or touch_top or touch_bottom) and (mouse_dx != 0 or mouse_dy != 0):
                        pan_dx = 0
                        pan_dy = 0
                        
                        if touch_right and mouse_dx > 0:
                            pan_dx = -mouse_dx
                        elif touch_left and mouse_dx < 0:
                            pan_dx = -mouse_dx
                        
                        if touch_bottom and mouse_dy > 0:
                            pan_dy = -mouse_dy
                        elif touch_top and mouse_dy < 0:
                            pan_dy = -mouse_dy
                        
                        if pan_dx != 0 or pan_dy != 0:
                            r = subprocess.run(['hyprctl', 'activeworkspace', '-j'], 
                                             capture_output=True, text=True, timeout=0.1)
                            ws = json.loads(r.stdout)
                            workspace_id = ws['id']
                            pan_other_windows(dragged_window_addr, int(pan_dx), int(pan_dy), workspace_id)
                    
                    last_window_bounds = current_bounds
                else:
                    window_drag_active = False
                    dragged_window_addr = None
            
            time.sleep(0.016)
        except Exception as e:
            time.sleep(0.1)


def move_active_window(direction):
    """Mueve la ventana activa KEY_MOVE_STEP px en la direccion indicada.
    Si toca el borde del monitor, empuja las demas ventanas en sentido contrario."""
    try:
        r = subprocess.run(['hyprctl', 'activeworkspace', '-j'], capture_output=True, text=True, timeout=0.1)
        ws = json.loads(r.stdout)
        workspace_id = ws['id']

        window = get_focused_window()
        if not window or not window.get('floating'):
            return

        monitor = get_monitor_bounds()
        bounds = get_window_bounds(window)
        addr = window['address']

        dx, dy = 0, 0
        if direction == 'left':
            dx = -KEY_MOVE_STEP
        elif direction == 'right':
            dx = KEY_MOVE_STEP
        elif direction == 'up':
            dy = -KEY_MOVE_STEP
        elif direction == 'down':
            dy = KEY_MOVE_STEP

        new_x = window['at'][0] + dx
        new_y = window['at'][1] + dy

        # Detectar si toca borde DESPUÉS del movimiento
        new_bounds_left   = new_x
        new_bounds_right  = new_x + window['size'][0]
        new_bounds_top    = new_y
        new_bounds_bottom = new_y + window['size'][1]

        hits_left   = new_bounds_left   <= monitor['left']
        hits_right  = new_bounds_right  >= monitor['right']
        hits_top    = new_bounds_top    <= monitor['top']
        hits_bottom = new_bounds_bottom >= monitor['bottom']

        hitting_edge = (dx < 0 and hits_left) or (dx > 0 and hits_right) or                        (dy < 0 and hits_top)  or (dy > 0 and hits_bottom)

        # Mover la ventana activa
        subprocess.run(['hyprctl', 'dispatch', move_window_exact_lua(new_x, new_y, addr)],
                       capture_output=True, timeout=0.2)

        # Si toca borde, empujar las demas en sentido contrario
        if hitting_edge:
            pan_other_windows(addr, -dx, -dy, workspace_id)

    except Exception as e:
        print(f"Error en move_active_window: {e}", flush=True)


def classify_device(path):
    """Devuelve 'mouse', 'keyboard' o None segun las capacidades reales del dispositivo,
    sin importar el nombre/marca. Esto es lo que permite que funcione con cualquier
    mouse o teclado (alambrico, inalambrico, el que sea)."""
    try:
        dev = InputDevice(path)
        caps = dev.capabilities()
        dev.close()
    except Exception:
        return None

    keys = set(caps.get(ecodes.EV_KEY, []))
    rels = set(caps.get(ecodes.EV_REL, []))

    is_mouse = (ecodes.REL_X in rels and ecodes.REL_Y in rels and ecodes.BTN_LEFT in keys)
    if is_mouse:
        return 'mouse'

    # Un teclado "real" tiene el rango completo de teclas alfanumericas y las teclas Meta,
    # esto excluye las interfaces auxiliares (Consumer Control, System Control) que
    # muchos recievers 2.4G tambien exponen.
    is_keyboard = (
        ecodes.KEY_A in keys and ecodes.KEY_Z in keys and ecodes.KEY_LEFTSHIFT in keys
        and (ecodes.KEY_LEFTMETA in keys or ecodes.KEY_RIGHTMETA in keys)
    )
    if is_keyboard:
        return 'keyboard'

    return None


def scan_devices():
    keyboards, mice = [], []
    for path in list_devices():
        kind = classify_device(path)
        if kind == 'mouse':
            mice.append(path)
        elif kind == 'keyboard':
            keyboards.append(path)
    return keyboards, mice


def kbd_reader_device(path):
    """Lee eventos de UN teclado especifico. Se lanza un hilo por cada teclado detectado."""
    global super_pressed, alt_pressed, ctrl_pressed, frame_held_hidden
    try:
        fd = open(path, 'rb')
    except Exception:
        return

    while True:
        try:
            data = fd.read(EVENT_SIZE)
        except Exception:
            break
        if not data or len(data) < EVENT_SIZE:
            break
        _, _, etype, code, value = struct.unpack('llHHi', data)
        if etype != EV_KEY:
            continue
        if value == 2:
            continue

        notify_state = None
        with lock:
            if code in (KEY_LEFTMETA, KEY_RIGHTMETA):
                super_pressed = (value == 1)
            elif code in (KEY_LEFTALT, KEY_RIGHTALT):
                alt_pressed = (value == 1)
            elif code in (KEY_LEFTCTRL, KEY_RIGHTCTRL):
                ctrl_pressed = (value == 1)

            combo = super_pressed and alt_pressed
            if combo != frame_held_hidden:
                frame_held_hidden = combo
                notify_state = combo

        # La llamada IPC (subprocess) se hace FUERA del lock y en su
        # propio hilo: qs ipc call puede tardar unos ms y no queremos
        # bloquear la lectura de eventos ni a otros hilos de teclado
        # esperando el mismo lock.
        if notify_state is not None:
            threading.Thread(target=notify_quickshell_hold, args=(notify_state,), daemon=True).start()

    try:
        fd.close()
    except Exception:
        pass


def mouse_reader_device(path):
    """Lee eventos de UN mouse especifico. Se lanza un hilo por cada mouse detectado."""
    global acc_x, acc_y, btn_left, mouse_rel_x, mouse_rel_y
    try:
        fd = open(path, 'rb')
    except Exception:
        return

    while True:
        try:
            data = fd.read(EVENT_SIZE)
        except Exception:
            break
        if not data or len(data) < EVENT_SIZE:
            break
        _, _, etype, code, value = struct.unpack('llHHi', data)

        with lock:
            if etype == EV_KEY and code == BTN_LEFT:
                btn_left = (value == 1)
            elif etype == EV_REL:
                if code == REL_X:
                    mouse_rel_x += value
                elif code == REL_Y:
                    mouse_rel_y += value

                if super_pressed and alt_pressed:
                    sign = -1 if read_inverted() else 1
                    if code == REL_X:
                        acc_x += value * speed * sign
                    elif code == REL_Y:
                        acc_y += value * speed * sign
                else:
                    acc_x = 0.0
                    acc_y = 0.0

    try:
        fd.close()
    except Exception:
        pass


_active_kbd_threads = {}
_active_mouse_threads = {}

def device_manager():
    """Escanea periodicamente /dev/input buscando teclados y mouses nuevos
    (o reconectados) y lanza un hilo lector para cada uno. Si un dispositivo
    se desconecta, su hilo simplemente termina solo al fallar el read().

    Los primeros segundos (WARMUP_DURATION) escanea mucho mas seguido
    (WARMUP_INTERVAL) porque justo al iniciar sesion, dongles inalambricos
    a veces tardan unos segundos en terminar de enumerar sus interfaces USB.
    Despues de ese periodo baja al intervalo normal para no gastar CPU."""
    WARMUP_DURATION = 20.0
    WARMUP_INTERVAL = 0.5
    start_time = time.time()

    while True:
        try:
            keyboards, mice = scan_devices()

            for path in keyboards:
                t = _active_kbd_threads.get(path)
                if t is None or not t.is_alive():
                    nt = threading.Thread(target=kbd_reader_device, args=(path,), daemon=True)
                    nt.start()
                    _active_kbd_threads[path] = nt
                    print(f"[+] Teclado detectado: {path}", flush=True)

            for path in mice:
                t = _active_mouse_threads.get(path)
                if t is None or not t.is_alive():
                    nt = threading.Thread(target=mouse_reader_device, args=(path,), daemon=True)
                    nt.start()
                    _active_mouse_threads[path] = nt
                    print(f"[+] Mouse detectado: {path}", flush=True)
        except Exception as e:
            print(f"Error en device_manager: {e}", flush=True)

        elapsed = time.time() - start_time
        interval = WARMUP_INTERVAL if elapsed < WARMUP_DURATION else DEVICE_RESCAN_INTERVAL
        time.sleep(interval)

# PRECARGAR
print("Precargando...", flush=True)
try:
    subprocess.run(['hyprctl', 'activeworkspace', '-j'], capture_output=True, text=True, timeout=0.5)
    subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=0.5)
except:
    pass

threading.Thread(target=device_manager, daemon=True).start()
threading.Thread(target=monitor_window_drag, daemon=True).start()
threading.Thread(target=workspace_events_listener, daemon=True).start()
print("Infinite Desktop activo (deteccion automatica de dispositivos)", flush=True)
print("Super+click: Arrastrar ventana (al tocar borde, el raton mueve el resto)", flush=True)
print("Super+Alt+mouse: Arrastrar todo el escritorio", flush=True)
print("Super+flechas: Navegacion via hyprland bind", flush=True)
print("Super+Shift+flechas: Mover ventana activa via hyprland bind", flush=True)

# Caché del workspace activo (se refresca cada 2s para no llamar hyprctl cada frame)
_cached_workspace_id = None
_last_workspace_check = 0
WORKSPACE_CACHE_TTL = 2.0

def get_cached_workspace_id():
    global _cached_workspace_id, _last_workspace_check
    now = time.time()
    if _cached_workspace_id is None or (now - _last_workspace_check) > WORKSPACE_CACHE_TTL:
        try:
            r = subprocess.run(['hyprctl', 'activeworkspace', '-j'],
                               capture_output=True, text=True, timeout=0.1)
            ws = json.loads(r.stdout)
            _cached_workspace_id = ws['id']
            _last_workspace_check = now
        except:
            pass
    return _cached_workspace_id

# Loop principal para arrastre de escritorio
while True:
    time.sleep(0.016)

    with lock:
        active_drag = super_pressed and alt_pressed
        dx = acc_x
        dy = acc_y
        acc_x = 0.0
        acc_y = 0.0

    if not active_drag:
        continue

    idx = int(round(dx))
    idy = int(round(dy))

    if idx == 0 and idy == 0:
        continue

    try:
        workspace_id = get_cached_workspace_id()
        if workspace_id is None:
            continue

        r = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=0.1)
        clients = json.loads(r.stdout)

        exprs = []
        for w in clients:
            if w.get('floating') and w.get('workspace', {}).get('id') == workspace_id:
                nx = w['at'][0] + idx
                ny = w['at'][1] + idy
                exprs.append(move_window_exact_lua(nx, ny, w['address']))

        batch_async(exprs)
    except Exception as e:
        pass