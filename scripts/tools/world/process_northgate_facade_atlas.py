"""Cut Northgate facade source art while removing generated fake doors."""

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/world/northgate/source/northgate_facades_source_v1_alpha.png"
OUTPUT = ROOT / "assets/world/northgate/facades"

FACADES = [
    ("cottage_a", (188, 44), "left"),
    ("cottage_b", (188, 44), "left"),
    ("cottage_c", (188, 44), "left"),
    ("cottage_thatch", (188, 44), "left"),
    ("coaching_inn", (316, 62), "left"),
    ("civic_hall", (252, 54), "left"),
    ("smithy", (252, 64), "right"),
    ("stable_store", (220, 74), "full"),
]


def _doorless(source: Image.Image, size: tuple[int, int], side: str) -> Image.Image:
    # Generated doors are not authoritative. Rebuild the strip from a left-side
    # window/timber sample and its mirror, leaving portal placement to Godot.
    sample_width = max(1, round(source.width * 0.38))
    sample = (
        source.crop((source.width - sample_width, 0, source.width, source.height))
        if side == "right"
        else source.crop((0, 0, sample_width, source.height))
    )
    half_width = size[0] // 2
    left = sample.resize((half_width, size[1]), Image.Resampling.LANCZOS)
    output = Image.new("RGBA", size, (0, 0, 0, 0))
    output.alpha_composite(left, (0, 0))
    output.alpha_composite(ImageOps.mirror(left), (size[0] - half_width, 0))
    return output


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for index, (name, size, mode) in enumerate(FACADES):
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
        source = cell.crop(alpha_bounds)
        facade = _doorless(source, size, mode) if mode != "full" else source.resize(size, Image.Resampling.LANCZOS)
        output = Image.new("RGBA", (size[0] + 4, size[1] + 4), (0, 0, 0, 0))
        output.alpha_composite(facade, (2, 2))
        output.save(OUTPUT / f"{name}.png", optimize=True)
        print(f"{name}: {output.width}x{output.height}")


if __name__ == "__main__":
    main()
