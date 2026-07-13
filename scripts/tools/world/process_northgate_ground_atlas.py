"""Cut the Northgate ground-detail source sheet into small walkable decals."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/world/northgate/source/northgate_ground_source_v1_alpha.png"
OUTPUT = ROOT / "assets/world/northgate/ground"

DECALS = [
    ("mud_puddle", (40, 32)),
    ("wheel_ruts", (40, 32)),
    ("flat_stones", (34, 28)),
    ("grass_tuft", (24, 24)),
    ("weeds", (26, 24)),
    ("clover", (26, 24)),
    ("wildflowers", (26, 24)),
    ("herbs", (28, 26)),
    ("straw_scatter", (32, 24)),
    ("leaf_scatter", (28, 24)),
    ("ash_scatter", (30, 26)),
    ("moss_patch", (30, 26)),
    ("broken_plank", (34, 24)),
    ("bootprints", (28, 26)),
    ("grain_scatter", (24, 22)),
    ("drainage_stones", (34, 28)),
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
    for index, (name, bounds) in enumerate(DECALS):
        column = index % 4
        row = index // 4
        cell = atlas.crop(
            (
                round(column * atlas.width / 4),
                round(row * atlas.height / 4),
                round((column + 1) * atlas.width / 4),
                round((row + 1) * atlas.height / 4),
            )
        )
        alpha_bounds = cell.getchannel("A").getbbox()
        if alpha_bounds is None:
            raise RuntimeError(f"No opaque pixels in source cell for {name}")
        decal = _fit(cell.crop(alpha_bounds), bounds)
        decal.save(OUTPUT / f"{name}.png", optimize=True)
        print(f"{name}: {decal.width}x{decal.height}")


if __name__ == "__main__":
    main()
