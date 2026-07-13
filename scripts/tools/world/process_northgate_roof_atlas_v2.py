"""Cut the second reviewed Northgate roof sheet into modular runtime PNGs."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/world/northgate/source/northgate_roofs_source_v2_alpha.png"
OUTPUT = ROOT / "assets/world/northgate/roofs"

MODULES = [
    ("crooked_shingle_a", (188, 84)),
    ("crooked_shingle_b", (188, 84)),
    ("crooked_shingle_c", (188, 84)),
    ("patched_thatch_a", (188, 82)),
    ("patched_thatch_b", (188, 82)),
    ("joined_l_a", (220, 126)),
    ("joined_l_b", (220, 126)),
    ("lean_to_a", (96, 146)),
    ("lean_to_b", (96, 146)),
    ("civic_hipped_v2", (252, 126)),
    ("smith_soot_v2", (252, 104)),
    ("stable_hayloft_v2", (252, 108)),
]


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for index, (name, size) in enumerate(MODULES):
        column = index % 4
        row = index // 4
        cell = atlas.crop(
            (
                round(column * atlas.width / 4),
                round(row * atlas.height / 3),
                round((column + 1) * atlas.width / 4),
                round((row + 1) * atlas.height / 3),
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
