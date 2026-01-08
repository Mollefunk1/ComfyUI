import pytest
import torch
from comfy_extras.nodes_post_processing import ImageColorAdjust


def test_image_color_adjust_identity():
    img = torch.rand((1, 32, 32, 3))
    out = ImageColorAdjust.execute(img, 1.0)
    assert torch.allclose(img, out[0], atol=1e-6) or torch.isclose(img.mean(), out[0].mean(), atol=1e-3)


def test_image_color_adjust_change():
    img = torch.ones((1, 32, 32, 3)) * 0.5
    out = ImageColorAdjust.execute(img, 1.2)
    # saturation 1.2 on a neutral gray should have minimal change, so use a color test
    img_color = img.clone()
    img_color[0, :, :, 0] = 0.6
    img_color[0, :, :, 1] = 0.4
    out2 = ImageColorAdjust.execute(img_color, 1.5)
    assert not torch.allclose(img_color, out2[0], atol=1e-3)
