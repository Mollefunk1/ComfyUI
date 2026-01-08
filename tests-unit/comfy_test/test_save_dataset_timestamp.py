import os
import pytest


def test_save_dataset_append_timestamp(tmp_path):
    torch = pytest.importorskip("torch")
    from comfy_extras.nodes_dataset import SaveImageDataSetToFolderNode
    import folder_paths

    images = [torch.rand((1, 64, 64, 3)), torch.rand((1, 64, 64, 3))]

    # Monkeypatch output directory to a temporary path
    orig_get_output = folder_paths.get_output_directory
    folder_paths.get_output_directory = lambda: str(tmp_path)
    try:
        # Run twice with append_timestamp=True
        SaveImageDataSetToFolderNode.execute(images, ["out"], ["upscaled_test"], [True])
        SaveImageDataSetToFolderNode.execute(images, ["out"], ["upscaled_test"], [True])

        outdir = tmp_path / "out"
        files = list(outdir.iterdir())
        # Expect two images saved from each run (total 4 files)
        assert len(files) == 4
    finally:
        folder_paths.get_output_directory = orig_get_output
