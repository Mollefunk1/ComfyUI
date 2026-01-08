"""Queue the batch upscaling workflow via ComfyUI API.

Usage:
  python run_batch_upscale.py --input-folder to_upscale --model "4x-UltraSharpV2.safetensors" --output "C:\\Users\\Sean\\OneDrive\\Skrivebord\\upscale output" --prefix upscaled

Notes:
 - Place your images inside ComfyUI's input subfolder (e.g., <ComfyUI>/input/to_upscale/).
 - Start ComfyUI (default API port 8188) before running this script.
"""

import json
import argparse
from urllib import request


def queue_workflow(input_folder: str, model_name: str, output_path: str, filename_prefix: str, host: str = "http://127.0.0.1:8188"):
    # Build prompt following ComfyUI API export format
    prompt = {
        "1": {"class_type": "LoadImageDataSetFromFolder", "inputs": {"folder": input_folder}},
        "2": {"class_type": "UpscaleModelLoader", "inputs": {"model_name": model_name}},
        "3": {"class_type": "ImageUpscaleWithModel", "inputs": {"upscale_model": ["2", 0], "image": ["1", 0]}},
        "4": {"class_type": "SaveImageDataSetToFolder", "inputs": {"images": ["3", 0], "folder_name": output_path, "filename_prefix": filename_prefix}},
    }

    payload = {"prompt": prompt}
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(host + "/prompt", data=data, headers={"Content-Type": "application/json"})
    try:
        with request.urlopen(req, timeout=30) as resp:
            print("Queued workflow, server replied:", resp.read().decode("utf-8"))
    except Exception as e:
        print("Failed to queue workflow:", e)


def main():
    parser = argparse.ArgumentParser(description="Queue batch upscaling workflow in ComfyUI")
    parser.add_argument("--input-folder", default="to_upscale", help="Input subfolder name under ComfyUI input/")
    parser.add_argument("--model", default="4x-UltraSharpV2.safetensors", help="Upscale model filename in upscale_models/")
    parser.add_argument("--output", required=True, help="Absolute output folder path (e.g., C:\\...\\upscale output)")
    parser.add_argument("--prefix", default="upscaled", help="Filename prefix for saved images")
    parser.add_argument("--host", default="http://127.0.0.1:8188", help="ComfyUI host URL")

    args = parser.parse_args()

    queue_workflow(args.input_folder, args.model, args.output, args.prefix, host=args.host)


if __name__ == "__main__":
    main()
