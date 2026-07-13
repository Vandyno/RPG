"""Cut and normalize the reviewed Northgate roof-source sheet."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/world/northgate/source/northgate_roofs_source_v1_alpha.png"
OUTPUT = ROOT / "assets/world/northgate/roofs"

ROOFS = [
    ("cottage_shingle_a", (188, 68)),
    ("cottage_shingle_b", (188, 68)),
    ("cottage_shingle_c", (188, 68)),
    ("cottage_thatch", (188, 68)),
    ("coaching_inn", (316, 78)),
    ("smithy", (252, 74)),
    ("civic_hall", (252, 78)),
    ("stable_store", (220, 72)),
]


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for index, (name, size) in enumerate(ROOFS):
        column = index % 4
        row = index // 4
        cell = atlas.crop(
            (
                round(column * atlas.width / 4),
                round(row * atlas.height / 2),
                round((column + 1) * atlas.width / 4),
                round((row + 1) * atlas.height / 2),
            )
        )
        alpha_bounds = cell.getchannel("A").getbbox()
        if alpha_bounds is None:
            raise RuntimeError(f"No opaque pixels in source cell for {name}")
        roof = cell.crop(alpha_bounds).resize(size, Image.Resampling.LANCZOS)
        output = Image.new("RGBA", (size[0] + 4, size[1] + 4), (0, 0, 0, 0))
        output.alpha_composite(roof, (2, 2))
        output.save(OUTPUT / f"{name}.png", optimize=True)
        print(f"{name}: {output.width}x{output.height}")


if __name__ == "__main__":
    main()
