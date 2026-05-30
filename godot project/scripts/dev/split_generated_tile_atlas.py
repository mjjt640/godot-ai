from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter


PROJECT_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_ROOT = PROJECT_ROOT / "art" / "maps" / "generated_tiles"
TILE_SIZE = 512
INNER_PAD = 3


@dataclass(frozen=True)
class AtlasJob:
    source: Path
    output_name: str
    columns: int
    rows: int


JOBS = [
    AtlasJob(
        Path(r"C:\Users\admin\Desktop\sheet\image-generate-create-a-4x4-atlas-of-seamless-top-down--20260529-171703-2911b8.png"),
        "q_euro_4x4_2911b8",
        4,
        4,
    ),
    AtlasJob(
        Path(r"C:\Users\admin\Desktop\sheet\image-generate-create-a-5x4-atlas-of-seamless-top-down--20260529-173604-a48d92.png"),
        "ancient_arena_5x4_a48d92",
        5,
        4,
    ),
    AtlasJob(
        Path(r"C:\Users\admin\Desktop\sheet\image-generate-create-a-5x4-atlas-of-seamless-top-down--20260529-173604-f36041.png"),
        "ancient_arena_5x4_f36041",
        5,
        4,
    ),
]


def _bounds(size: int, count: int) -> list[int]:
    return [round(index * size / count) for index in range(count + 1)]


def _clean_tile(tile: Image.Image) -> Image.Image:
    tile = tile.convert("RGB")
    tile = tile.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    tile = ImageEnhance.Color(tile).enhance(0.94)
    tile = ImageEnhance.Contrast(tile).enhance(1.04)
    tile = tile.filter(ImageFilter.UnsharpMask(radius=0.9, percent=85, threshold=4))
    return tile


def _split(job: AtlasJob) -> None:
    image = Image.open(job.source).convert("RGB")
    x_bounds = _bounds(image.width, job.columns)
    y_bounds = _bounds(image.height, job.rows)
    output_dir = OUTPUT_ROOT / job.output_name
    output_dir.mkdir(parents=True, exist_ok=True)

    rebuilt = Image.new("RGB", (job.columns * TILE_SIZE, job.rows * TILE_SIZE))
    manifest_lines = []
    tile_index = 1
    for row in range(job.rows):
        for column in range(job.columns):
            left = x_bounds[column] + INNER_PAD
            top = y_bounds[row] + INNER_PAD
            right = x_bounds[column + 1] - INNER_PAD
            bottom = y_bounds[row + 1] - INNER_PAD
            tile = _clean_tile(image.crop((left, top, right, bottom)))
            tile_name = f"tile_{tile_index:02d}_r{row + 1}_c{column + 1}.png"
            tile.save(output_dir / tile_name)
            rebuilt.paste(tile, (column * TILE_SIZE, row * TILE_SIZE))
            manifest_lines.append(tile_name)
            tile_index += 1

    rebuilt.save(output_dir / f"{job.output_name}_atlas_{job.columns}x{job.rows}_{TILE_SIZE}.png")
    (output_dir / "manifest.txt").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")
    print(job.output_name, "tiles=", len(manifest_lines), "output=", output_dir)


def main() -> None:
    for job in JOBS:
        _split(job)


if __name__ == "__main__":
    main()
