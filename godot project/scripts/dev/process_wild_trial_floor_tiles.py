from __future__ import annotations

from pathlib import Path

import numpy as np
import onnxruntime as ort
from PIL import Image, ImageFilter, ImageStat


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = PROJECT_ROOT / "art" / "maps" / "wild_trial" / "tiles"
OUTPUT_DIR = PROJECT_ROOT / "art" / "maps" / "wild_trial" / "tiles_square_4x"
OUTPUT_SIZE = 512
MODEL_INPUT_SIZE = 128
INNER_TRIM_RATIO = 0.12
MIN_OPAQUE_RATIO = 0.65
REALESRGAN_MODEL_PATH = Path(r"C:\tmp\hf_lightweight_realesrgan_anime\RealESRGAN_x4plus_anime_4B32F.onnx")


def _alpha_bounds(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    return alpha.getbbox()


def _average_opaque_color(image: Image.Image) -> tuple[int, int, int]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    mask = alpha.point(lambda value: 255 if value >= 128 else 0)
    rgb = Image.new("RGB", rgba.size, (0, 0, 0))
    rgb.paste(rgba.convert("RGB"), mask=mask)
    stat = ImageStat.Stat(rgb, mask)
    if not stat.count[0]:
        return (92, 96, 78)
    return tuple(max(0, min(255, int(round(value)))) for value in stat.mean)


def _opaque_ratio(image: Image.Image) -> float:
    alpha = image.getchannel("A")
    histogram = alpha.histogram()
    opaque = sum(histogram[128:])
    return opaque / float(image.width * image.height)


def _upscale_with_model(image: Image.Image, session: ort.InferenceSession | None) -> Image.Image:
    if session is None:
        return image.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.Resampling.LANCZOS)

    model_input = image.resize((MODEL_INPUT_SIZE, MODEL_INPUT_SIZE), Image.Resampling.LANCZOS).convert("RGB")
    array = np.asarray(model_input).astype(np.float32) / 255.0
    array = np.transpose(array, (2, 0, 1))[np.newaxis, :, :, :]
    output = session.run(None, {session.get_inputs()[0].name: array})[0][0]
    output = np.transpose(output, (1, 2, 0))
    output = np.clip(output * 255.0, 0.0, 255.0).astype(np.uint8)
    return Image.fromarray(output, "RGB").convert("RGBA")


def _process_tile(source_path: Path, output_path: Path, session: ort.InferenceSession | None) -> bool:
    image = Image.open(source_path).convert("RGBA")
    if _opaque_ratio(image) < MIN_OPAQUE_RATIO:
        return False

    bounds = _alpha_bounds(image)
    if bounds is None:
        return False

    cropped = image.crop(bounds)
    trim = max(8, int(round(min(cropped.size) * INNER_TRIM_RATIO)))
    if cropped.width - trim * 2 < 32 or cropped.height - trim * 2 < 32:
        return False
    cropped = cropped.crop((trim, trim, cropped.width - trim, cropped.height - trim))

    side = min(cropped.size)
    left = (cropped.width - side) // 2
    top = (cropped.height - side) // 2
    square = cropped.crop((left, top, left + side, top + side))

    fill = _average_opaque_color(square)
    opaque = Image.new("RGBA", square.size, (*fill, 255))
    opaque.alpha_composite(square)

    upscaled = _upscale_with_model(opaque, session)
    upscaled = upscaled.filter(ImageFilter.UnsharpMask(radius=1.15, percent=125, threshold=3))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    upscaled.save(output_path)
    return True


def main() -> None:
    session = None
    if REALESRGAN_MODEL_PATH.exists():
        session = ort.InferenceSession(str(REALESRGAN_MODEL_PATH), providers=["CPUExecutionProvider"])
        print("using_model=", REALESRGAN_MODEL_PATH)
    else:
        print("using_model= none")

    written: list[str] = []
    skipped: list[str] = []

    for source_path in sorted(SOURCE_DIR.glob("*.png")):
        resource_path = "res://" + source_path.relative_to(PROJECT_ROOT).as_posix()
        output_name = source_path.stem + "_square_4x.png"
        output_path = OUTPUT_DIR / output_name
        if _process_tile(source_path, output_path, session):
            written.append("res://art/maps/wild_trial/tiles_square_4x/" + output_name)
        else:
            skipped.append(resource_path)

    print("written=", len(written))
    for path in written:
        print(path)
    print("skipped=", len(skipped))
    for path in skipped:
        print(path)


if __name__ == "__main__":
    main()
