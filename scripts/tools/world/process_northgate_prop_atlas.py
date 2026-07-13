"""Cut the reviewed Northgate prop source sheet into tile-scaled PNG sprites."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/world/northgate/source/northgate_props_source_v1_alpha.png"
OUTPUT = ROOT / "assets/world/northgate/props"

PROPS = [
    ("barrel", (26, 26)),
    ("barrel_stack", (44, 34)),
    ("crate", (28, 28)),
    ("crate_stack", (44, 36)),
    ("woodpile", (48, 28)),
    ("hay_bale", (44, 28)),
    ("basket", (28, 28)),
    ("bench", (48, 24)),
    ("hitching_post", (48, 32)),
    ("water_trough", (48, 28)),
    ("cart", (56, 40)),
    ("market_stall", (64, 48)),
    ("hanging_sign", (36, 44)),
    ("lantern_post", (28, 52)),
    ("well", (44, 44)),
    ("rain_barrel", (28, 32)),
    ("planter", (48, 28)),
    ("fence", (48, 32)),
    ("anvil", (40, 32)),
    ("wash_line", (64, 40)),
]


def _fit(image: Image.Image, bounds: tuple[int, int]) -> Image.Image:
    scale = min(bounds[0] / image.width, bounds[1] / image.height)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    resized = image.resize(size, Image.Resampling.LANCZOS)
    output = Image.new("RGBA", (size[0] + 4, size[1] + 4), (0, 0, 0, 0))
    output.alpha_composite(resized, (2, 2))
    return output


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    columns = 4
    rows = 5
    for index, (name, bounds) in enumerate(PROPS):
        column = index % columns
        row = index // columns
        left = round(column * atlas.width / columns)
        right = round((column + 1) * atlas.width / columns)
        top = round(row * atlas.height / rows)
        bottom = round((row + 1) * atlas.height / rows)
        cell = atlas.crop((left, top, right, bottom))
        alpha_bounds = cell.getchannel("A").getbbox()
        if alpha_bounds is None:
            raise RuntimeError(f"No opaque pixels in source cell for {name}")
        sprite = _fit(cell.crop(alpha_bounds), bounds)
        sprite.save(OUTPUT / f"{name}.png", optimize=True)
        print(f"{name}: {sprite.width}x{sprite.height}")


if __name__ == "__main__":
    main()
