#!/usr/bin/env python3

import json
import subprocess


class SwaySelectionError(Exception):
    """Exception raised when sway selection fails."""

    pass


def _find_focused(node):
    if node.get("focused"):
        return node
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        result = _find_focused(child)
        if result:
            return result
    return None


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
        return {"type": "area", "geometry": slurp_result.stdout.strip()}

    elif mode == "full":
        outputs = json.loads(
            subprocess.run(
                ["swaymsg", "-t", "get_outputs"], capture_output=True, text=True
            ).stdout
        )
        focused = next((o for o in outputs if o["focused"]), None)
        if not focused:
            raise SwaySelectionError("No focused output")
        return {"type": "full", "output_name": focused["name"]}

    elif mode == "window":
        tree = json.loads(
            subprocess.run(
                ["swaymsg", "-t", "get_tree"], capture_output=True, text=True
            ).stdout
        )
        focused = _find_focused(tree)
        if not focused:
            raise SwaySelectionError("No focused window")
        rect = {
            "x": focused["rect"]["x"],
            "y": focused["rect"]["y"] + crop,
            "width": focused["rect"]["width"],
            "height": focused["rect"]["height"] - crop,
        }
        geometry = f"{rect['x']},{rect['y']} {rect['width']}x{rect['height']}"
        return {"type": "window", "rect": rect, "geometry": geometry}

    else:
        raise ValueError(f"Invalid mode: {mode}")
