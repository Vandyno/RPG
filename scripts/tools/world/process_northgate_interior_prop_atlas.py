"""Cut and key the reviewed Northgate interior furnishing sheet."""

from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/world/northgate/source/northgate_interior_props_source_v1.png"
OUTPUT = ROOT / "assets/world/northgate/interior_props"

PROPS = [
    ("bed", (20, 30)),
    ("table", (28, 20)),
    ("stool", (16, 16)),
    ("shelf", (30, 18)),
    ("chest", (20, 18)),
    ("hearth", (28, 28)),
    ("rug", (32, 22)),
    ("counter", (34, 18)),
    ("workbench", (30, 20)),
    ("weapon_rack", (28, 26)),
    ("cupboard", (22, 26)),
    ("sacks", (22, 18)),
    ("bucket", (16, 18)),
    ("bench", (28, 14)),
    ("partition", (30, 20)),
    ("altar", (26, 26)),
]


def _remove_checkerboard(image: Image.Image) -> Image.Image:
    """Remove the baked neutral checker without eating dark object shadows."""
    output = image.convert("RGBA")
    pixels = output.load()
    for y in range(output.height):
        for x in range(output.width):
            red, green, blue, alpha = pixels[x, y]
            spread = max(red, green, blue) - min(red, green, blue)
            if spread <= 9 and min(red, green, blue) >= 200:
                pixels[x, y] = (red, green, blue, 0)
    return output


def _fit(image: Image.Image, bounds: tuple[int, int]) -> Image.Image:
    scale = min(bounds[0] / image.width, bounds[1] / image.height)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    red, green, blue, alpha = image.convert("RGBA").split()
    premultiplied = Image.merge(
        "RGBA",
        (
            ImageChops.multiply(red, alpha),
            ImageChops.multiply(green, alpha),
            ImageChops.multiply(blue, alpha),
            alpha,
        ),
    ).resize(size, Image.Resampling.LANCZOS)
    resized = Image.new("RGBA", size, (0, 0, 0, 0))
    source_pixels = premultiplied.load()
    target_pixels = resized.load()
    for y in range(size[1]):
        for x in range(size[0]):
            red, green, blue, alpha = source_pixels[x, y]
            if alpha <= 10:
                continue
            target_pixels[x, y] = (
                min(255, round(red * 255 / alpha)),
                min(255, round(green * 255 / alpha)),
                min(255, round(blue * 255 / alpha)),
                alpha,
            )
    output = Image.new("RGBA", (size[0] + 4, size[1] + 4), (0, 0, 0, 0))
    output.alpha_composite(resized, (2, 2))
    return output


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    columns = 4
    rows = 4
    for index, (name, bounds) in enumerate(PROPS):
        column = index % columns
        row = index // columns
        cell = atlas.crop(
            (
                round(column * atlas.width / columns),
                round(row * atlas.height / rows),
                round((column + 1) * atlas.width / columns),
                round((row + 1) * atlas.height / rows),
            )
        )
        keyed = _remove_checkerboard(cell)
        alpha_bounds = keyed.getchannel("A").getbbox()
        if alpha_bounds is None:
            raise RuntimeError(f"No opaque pixels in source cell for {name}")
        sprite = _fit(keyed.crop(alpha_bounds), bounds)
        sprite.save(OUTPUT / f"{name}.png", optimize=True)
        print(f"{name}: {sprite.width}x{sprite.height}")


if __name__ == "__main__":
    main()
