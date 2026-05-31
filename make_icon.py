"""
Generates deuce app icon PNGs using only Python stdlib.
Design: clay tennis court top-down, white net, yellow ball centre.
"""
import struct, zlib, math, os

# ── Colour palette ─────────────────────────────────────────────────────────────
CLAY_DARK  = (161,  82,  41)   # court (bottom half, slightly darker)
CLAY_LIGHT = (178,  95,  50)   # court (top half)
LINE       = (230, 210, 190)   # court lines
NET_BAND   = (200, 200, 200)   # net
NET_TOP    = (220, 220, 220)   # net top cord
BALL_Y     = (220, 200,  30)   # tennis ball yellow-green
BALL_CURVE = (180, 160,  10)   # ball seam

BG         = (20,  20,  20)    # letterbox background (not visible with mask)

# ── Minimal PNG writer ─────────────────────────────────────────────────────────

def _write_chunk(chunk_type: bytes, data: bytes) -> bytes:
    c = chunk_type + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)

def save_png(pixels, w, h, path):
    """pixels: flat list of (R,G,B) tuples, row-major."""
    raw = b''
    for y in range(h):
        raw += b'\x00'
        for x in range(w):
            r, g, b = pixels[y * w + x]
            raw += bytes([r, g, b])
    compressed = zlib.compress(raw, 9)
    png  = b'\x89PNG\r\n\x1a\n'
    png += _write_chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    png += _write_chunk(b'IDAT', compressed)
    png += _write_chunk(b'IEND', b'')
    with open(path, 'wb') as f:
        f.write(png)

# ── Drawing helpers ────────────────────────────────────────────────────────────

def lerp_color(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def blend(base, over, alpha):
    return tuple(int(base[i] * (1 - alpha) + over[i] * alpha) for i in range(3))

def draw_rect(px, w, x0, y0, x1, y1, col, alpha=1.0):
    for y in range(max(0, y0), min(len(px) // w, y1)):
        for x in range(max(0, x0), min(w, x1)):
            px[y * w + x] = blend(px[y * w + x], col, alpha)

def draw_circle(px, w, h, cx, cy, r, col, alpha=1.0):
    for y in range(max(0, int(cy - r) - 1), min(h, int(cy + r) + 2)):
        for x in range(max(0, int(cx - r) - 1), min(w, int(cx + r) + 2)):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if dist < r:
                a = alpha * min(1.0, (r - dist))   # anti-alias edge
                px[y * w + x] = blend(px[y * w + x], col, a)

def draw_hline(px, w, h, y, x0, x1, col, thickness=1, alpha=1.0):
    for dy in range(thickness):
        draw_rect(px, w, x0, y + dy, x1, y + dy + 1, col, alpha)

def draw_vline(px, w, h, x, y0, y1, col, thickness=1, alpha=1.0):
    for dx in range(thickness):
        draw_rect(px, w, x + dx, y0, x + dx + 1, y1, col, alpha)

# ── Icon painter ───────────────────────────────────────────────────────────────

def make_icon(size):
    S = size
    px = [BG] * (S * S)

    # No outer margin – court fills full square (watchOS applies circular mask)
    cx0, cy0 = 0, 0
    cx1, cy1 = S, S

    # Court halves
    net_y  = (cy0 + cy1) // 2
    net_th = max(2, S // 32)

    # Top half – slightly lighter
    draw_rect(px, S, cx0, cy0, cx1, net_y, CLAY_LIGHT)
    # Bottom half – slightly darker
    draw_rect(px, S, cx0, net_y, cx1, cy1, CLAY_DARK)

    # Court outline
    line_th = max(1, S // 64)
    draw_rect(px, S, cx0, cy0, cx1, cy0 + line_th, LINE)          # top
    draw_rect(px, S, cx0, cy1 - line_th, cx1, cy1, LINE)          # bottom
    draw_rect(px, S, cx0, cy0, cx0 + line_th, cy1, LINE)          # left
    draw_rect(px, S, cx1 - line_th, cy0, cx1, cy1, LINE)          # right

    # Centre service line – only between the two service box lines, not to baseline
    mid_x = (cx0 + cx1) // 2
    draw_vline(px, S, S, mid_x - line_th // 2,
               net_y - sbox_off, net_y + sbox_off, LINE, line_th)

    # Service box horizontal lines (each half, at ~40% from net outwards)
    sbox_off = int((net_y - cy0) * 0.45)
    draw_hline(px, S, S, net_y - sbox_off, cx0, cx1, LINE, line_th)  # top service line
    draw_hline(px, S, S, net_y + sbox_off, cx0, cx1, LINE, line_th)  # bottom service line

    # Net
    draw_rect(px, S, cx0, net_y - net_th // 2, cx1, net_y + net_th // 2 + 1, NET_BAND)
    draw_hline(px, S, S, net_y - net_th // 2, cx0, cx1, NET_TOP, max(1, net_th // 3))

    # Tennis ball – centred on whole court
    ball_cx = (cx0 + cx1) / 2
    ball_cy = (cy0 + cy1) / 2
    ball_r  = max(4, S // 5)

    draw_circle(px, S, S, ball_cx, ball_cy, ball_r, BALL_Y)

    # Seam: two S-curves (classic tennis ball look from top-down)
    # Each seam is a sine-wave arc sweeping left-to-right across the ball
    seam_w = max(1, S // 90)
    steps  = 400
    for sign in (+1, -1):
        for i in range(steps + 1):
            t  = (i / steps) * math.pi * 2   # 0 → 2π
            # sweep horizontally across ball, sine wave vertically
            sx = ball_cx + (i / steps - 0.5) * ball_r * 1.9
            sy = ball_cy + sign * ball_r * 0.45 * math.sin(t)
            dist = math.sqrt((sx - ball_cx) ** 2 + (sy - ball_cy) ** 2)
            if dist < ball_r * 0.92:
                draw_circle(px, S, S, sx, sy, seam_w, BALL_CURVE, 0.8)

    return px

# ── watchOS required sizes ─────────────────────────────────────────────────────
SIZES = [1024]   # primary; add more if needed

out_dir = os.path.join(os.path.dirname(__file__),
                       "deuce", "deuce Watch App", "Assets.xcassets",
                       "AppIcon.appiconset")
os.makedirs(out_dir, exist_ok=True)

for s in SIZES:
    px = make_icon(s)
    path = os.path.join(out_dir, f"icon_{s}.png")
    save_png(px, s, s, path)
    print(f"  wrote {path}  ({s}×{s})")

print("done.")
