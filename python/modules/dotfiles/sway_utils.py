#!/usr/bin/env python3

import subprocess
from i3ipc import Connection


class SwaySelectionError(Exception):
    """Exception raised when sway selection fails."""

    pass


def get_sway_selection(mode: str, crop: int = 0) -> dict:
    """Get sway selection geometry based on mode.

    Args:
        mode: Selection mode - "area", "full", or "window"
        crop: Optional crop value for window mode (default: 0)

    Returns:
        Dictionary with selection data:
        - For "area": {"type": "area", "geometry": str}
        - For "full": {"type": "full", "output_name": str}
        - For "window": {"type": "window", "rect": dict, "geometry": str}
          where rect contains: {"x": int, "y": int, "width": int, "height": int}

    Raises:
        SwaySelectionError: If selection fails (no area/output/window)
    """
    if mode == "area":
        slurp_result = subprocess.run(
            "slurp", shell=True, capture_output=True, text=True
        )
        if not slurp_result.stdout:
            raise SwaySelectionError("No area selected")
        geometry = slurp_result.stdout.strip()
        return {"type": "area", "geometry": geometry}

    elif mode == "full":
        sway = Connection()
        outputs = sway.get_outputs()
        focused_output = [o for o in outputs if o.focused]
        if not focused_output:
            raise SwaySelectionError("No focused output")
        return {"type": "full", "output_name": focused_output[0].name}

    elif mode == "window":
        sway = Connection()
        focused = sway.get_tree().find_focused()
        if not focused:
            raise SwaySelectionError("No focused window")
        rect = {
            "x": focused.rect.x,
            "y": focused.rect.y + crop,
            "width": focused.rect.width,
            "height": focused.rect.height - crop,
        }
        geometry = f"{rect['x']},{rect['y']} {rect['width']}x{rect['height']}"
        return {"type": "window", "rect": rect, "geometry": geometry}

    else:
        raise ValueError(f"Invalid mode: {mode}")
