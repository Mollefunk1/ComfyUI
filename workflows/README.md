Batch upscaling workflow (4x-UltraSharpV2)

Usage
- Put the images you want to upscale into a subfolder of ComfyUI's `input/` directory. The default subfolder used by the workflow is `to_upscale` (so place your images in `input/to_upscale/`).
- Start ComfyUI normally (the web UI + API must be running).
- To queue the workflow via the script, run:

```powershell
.\.\venv\Scripts\python.exe script_examples\run_batch_upscale.py --input-folder to_upscale --output "C:\Users\Sean\OneDrive\Skrivebord\upscale output"
```

Notes
- The workflow file `batch_upscale_4x_ultrasharp.json` is in this folder and can be loaded from the ComfyUI UI using File -> Load Workflow if you prefer to run it interactively.
- The script posts a prompt to ComfyUI's `/prompt` API; adjust `--model` or `--prefix` as desired.
- The output folder path may be absolute; the Save node will use it directly.
- When running the workflow from the UI, the `SaveImageDataSetToFolder` node now provides an **`append_timestamp`** boolean input (default: **True**) — enable it to append a `YYYY-MM-DD_HHMMSS` timestamp to the `filename_prefix` so repeated runs won't overwrite previous outputs.
- The workflow now includes an **Image Color Adjust** step after sharpening that applies a small default saturation boost (1.08) to help restore vividness after face detailer/upscaling. You can edit or remove this node in the Workflow editor if you prefer no automatic color tweak.
