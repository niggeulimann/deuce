from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).parent
MASTER_DIR = ROOT / "masters"
NORMALIZED_MASTER_DIR = ROOT / "masters-1242x2688"
FINAL_DIR = ROOT / "final"
DESIGN_SIZE = (1320, 2868)
SIZE = (1242, 2688)

FONT = "/System/Library/Fonts/SFNS.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

LOCALIZED_SPECS = {
    "de": [
        {
            "source": "01-play.png",
            "output": "01-einfach-spielen.png",
            "eyebrow": "DEUCE",
            "headline": ["Einfach spielen."],
            "subline": "Deuce zählt mit.",
        },
        {
            "source": "02-score.png",
            "output": "02-punkte-im-blick.png",
            "eyebrow": "LIVE AUF DER WATCH",
            "headline": ["Punkte im Blick."],
            "subline": "Schnell, klar und direkt am Handgelenk.",
        },
        {
            "source": "03-serve.png",
            "output": "03-aufschlag-klar.png",
            "eyebrow": "IMMER RICHTIG STEHEN",
            "headline": ["Aufschlag?", "Klar."],
            "subline": "Spielstand und Position auf einen Blick.",
        },
        {
            "source": "04-stats.png",
            "output": "04-mehr-aus-jedem-match.png",
            "eyebrow": "NACH DEM MATCH",
            "headline": ["Mehr aus jedem", "Match."],
            "subline": "Statistiken, Trends und Gegnerbilanzen.",
        },
        {
            "source": "05-companion-clean-v2.png",
            "output": "05-watch-und-iphone.png",
            "eyebrow": "WATCH + IPHONE",
            "headline": ["Spielen. Tracken.", "Besser werden."],
            "subline": "Beim Match am Handgelenk. Danach alle Auswertungen.",
        },
    ],
    "en": [
        {
            "source": "01-play.png",
            "output": "01-just-play.png",
            "eyebrow": "DEUCE",
            "headline": ["Just play."],
            "subline": "Deuce keeps score.",
        },
        {
            "source": "02-score.png",
            "output": "02-score-at-a-glance.png",
            "eyebrow": "LIVE ON YOUR WATCH",
            "headline": ["Score at a glance."],
            "subline": "Fast, clear and right on your wrist.",
        },
        {
            "source": "03-serve.png",
            "output": "03-serve-with-confidence.png",
            "eyebrow": "KNOW WHERE TO SERVE",
            "headline": ["Serve?", "Sorted."],
            "subline": "Score and serving position at a glance.",
        },
        {
            "source": "04-stats.png",
            "output": "04-more-from-every-match.png",
            "eyebrow": "AFTER THE MATCH",
            "headline": ["More from every", "match."],
            "subline": "Stats, trends and head-to-head records.",
        },
        {
            "source": "05-companion-clean-v2.png",
            "output": "05-watch-and-iphone.png",
            "eyebrow": "WATCH + IPHONE",
            "headline": ["Play. Track.", "Improve."],
            "subline": "On your wrist during play. All insights afterwards.",
        },
    ],
}

SCREEN_DIR = ROOT / "screens"
PHONE_SCREENSHOT = SCREEN_DIR / "iphone-companion.jpg"
WATCH_SCREENSHOT = SCREEN_DIR / "watch.jpg"


def font(size: int, rounded: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if rounded else FONT, size=size)


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def rounded_image(
    image: Image.Image, size: tuple[int, int], radius: int
) -> Image.Image:
    result = cover(image.convert("RGB"), size).convert("RGBA")
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0], size[1]), radius=radius, fill=255
    )
    result.putalpha(mask)
    return result


def glass_screen(
    screenshot: Image.Image, width: int, radius: int, padding: int
) -> Image.Image:
    source = screenshot.convert("RGB")
    height = round(width * source.height / source.width)
    screen = source.resize((width, height), Image.Resampling.LANCZOS).convert("RGBA")

    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, screen.width - 1, screen.height - 1),
        radius=radius,
        fill=255,
    )
    screen.putalpha(mask)

    panel_size = (width + padding * 2, height + padding * 2)
    panel = Image.new("RGBA", panel_size, (0, 0, 0, 0))
    panel_draw = ImageDraw.Draw(panel)
    panel_draw.rounded_rectangle(
        (0, 0, panel.width - 1, panel.height - 1),
        radius=radius + padding,
        fill=(12, 12, 10, 225),
        outline=(232, 178, 70, 225),
        width=3,
    )
    panel.alpha_composite(screen, (padding, padding))
    return panel


def add_glass_shadow(
    image: Image.Image, panel: Image.Image, position: tuple[int, int]
) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    silhouette = Image.new("RGBA", panel.size, (0, 0, 0, 0))
    ImageDraw.Draw(silhouette).rounded_rectangle(
        (0, 0, panel.width - 1, panel.height - 1),
        radius=44,
        fill=(0, 0, 0, 185),
    )
    shadow.alpha_composite(silhouette, (position[0] + 12, position[1] + 20))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(shadow)
    image.alpha_composite(panel, position)


def add_top_gradient(image: Image.Image) -> None:
    height = 940
    overlay = Image.new("RGBA", (DESIGN_SIZE[0], height), (0, 0, 0, 0))
    pixels = overlay.load()
    for y in range(height):
        progress = y / max(height - 1, 1)
        alpha = round(250 * (1 - progress) ** 1.65)
        for x in range(DESIGN_SIZE[0]):
            pixels[x, y] = (7, 7, 5, alpha)
    image.alpha_composite(overlay, (0, 0))


def add_copy(image: Image.Image, spec: dict[str, object]) -> None:
    draw = ImageDraw.Draw(image)
    yellow = (243, 219, 40, 255)
    cream = (248, 244, 233, 255)

    eyebrow = str(spec["eyebrow"])
    eyebrow_font = font(35)
    eyebrow_box = draw.textbbox((0, 0), eyebrow, font=eyebrow_font)
    pill_width = eyebrow_box[2] - eyebrow_box[0] + 62
    draw.rounded_rectangle(
        (96, 104, 96 + pill_width, 168),
        radius=30,
        fill=yellow,
    )
    draw.text((127, 116), eyebrow, font=eyebrow_font, fill=(20, 19, 12, 255))

    headline_font = font(112, rounded=True)
    y = 250
    for line in spec["headline"]:
        draw.text(
            (96, y + 7),
            str(line),
            font=headline_font,
            fill=(0, 0, 0, 135),
            stroke_width=5,
            stroke_fill=(0, 0, 0, 75),
        )
        draw.text((96, y), str(line), font=headline_font, fill=cream)
        y += 126

    draw.text(
        (96, y + 28),
        str(spec["subline"]),
        font=font(48),
        fill=(248, 244, 233, 215),
    )


def add_real_screens(image: Image.Image) -> None:
    if PHONE_SCREENSHOT.exists():
        phone = glass_screen(Image.open(PHONE_SCREENSHOT), 350, 30, 10)
        add_glass_shadow(image, phone, (870, 1115))

    if WATCH_SCREENSHOT.exists():
        watch = glass_screen(Image.open(WATCH_SCREENSHOT), 270, 28, 10)
        add_glass_shadow(image, watch, (55, 1560))


def compose() -> None:
    FINAL_DIR.mkdir(parents=True, exist_ok=True)
    NORMALIZED_MASTER_DIR.mkdir(parents=True, exist_ok=True)

    source_names = {
        str(spec["source"])
        for specs in LOCALIZED_SPECS.values()
        for spec in specs
    }
    for source_name in source_names:
        master = Image.open(MASTER_DIR / source_name).convert("RGB")
        cover(master, SIZE).save(
            NORMALIZED_MASTER_DIR / source_name,
            quality=96,
            optimize=True,
        )

    for locale, specs in LOCALIZED_SPECS.items():
        locale_dir = FINAL_DIR / locale
        locale_dir.mkdir(parents=True, exist_ok=True)
        finals: list[Image.Image] = []

        for index, spec in enumerate(specs):
            image = Image.open(MASTER_DIR / str(spec["source"])).convert("RGBA")
            image = cover(image, DESIGN_SIZE)
            add_top_gradient(image)
            if index == 4:
                add_real_screens(image)
            add_copy(image, spec)
            export = cover(image, SIZE).convert("RGB")
            export.save(
                locale_dir / str(spec["output"]), quality=96, optimize=True
            )
            if locale == "de":
                export.save(
                    FINAL_DIR / str(spec["output"]), quality=96, optimize=True
                )
            finals.append(export)

        thumb_size = (248, 538)
        sheet = Image.new("RGB", (1316, 538), (21, 21, 19))
        for index, image in enumerate(finals):
            thumb = image.convert("RGB").resize(
                thumb_size, Image.Resampling.LANCZOS
            )
            sheet.paste(thumb, (index * 267, 0))
        sheet.save(ROOT / f"app-store-contact-sheet-{locale}.png", optimize=True)


if __name__ == "__main__":
    compose()
