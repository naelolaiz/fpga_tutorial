#!/usr/bin/env python3
"""Headless GTKWave screenshot generator.

Given a VCD file, this script launches GTKWave inside a virtual X server
(Xvfb), waits for the window to settle, captures the rendered waveform,
crops it to the non-empty region and writes a PNG to disk.

It is intentionally I/O-explicit (every path is passed in, nothing is
written relative to the current working directory) so that it can be
driven from a Makefile or a CI job without surprises.

Originally adapted from sphinxcontrib-gtkwave
(https://github.com/ponty/sphinxcontrib-gtkwave), rewritten to remove
globals, replace `path.py` with `pathlib`, and add CLI + logging.
"""

from __future__ import annotations

import argparse
import logging
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Tuple

from easyprocess import EasyProcess
from PIL import Image, ImageFilter
from pyvirtualdisplay.smartdisplay import DisplayTimeoutError, SmartDisplay

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------

#: Tcl script that asks GTKWave to load every signal in the dump and zoom
#: to the full simulation range. Kept as a raw triple-quoted string so the
#: backslashes inside Tcl's `split` calls survive untouched.
_GTKWAVE_TCL = r"""
set all_signals [list]
set nfacs [ gtkwave::getNumFacs ]
for {set i 0} {$i < $nfacs} {incr i} {
    set facname [ gtkwave::getFacName $i ]
    set fields  [split $facname "\\"]
    set sig1    [ lindex $fields 0 ]
    set sig2    [ lindex $fields 1 ]
    if {[llength $fields] == 2} {
        set sig "$sig2"
    } else {
        set sig "$sig1"
    }
    lappend all_signals "$sig"
}
gtkwave::addSignalsFromList $all_signals
set min_time [ gtkwave::getMinTime ]
set max_time [ gtkwave::getMaxTime ]
gtkwave::setZoomRangeTimes $min_time $max_time
"""

#: GTKWave runtime config: hide the SST pane, skip the splash screen,
#: turn off the vertical grid for a cleaner screenshot.
_GTKWAVE_RC = """
hide_sst 1
splash_disable 1
enable_vert_grid 0
"""

#: Default screen size for the virtual display (width, height in px).
_DEFAULT_SCREEN_SIZE: Tuple[int, int] = (1024, 768)

#: The screenshot is rejected if the non-empty region is shorter than this
#: (in pixels). Prevents us from saving a half-rendered GTKWave window.
_MIN_WAVEFORM_HEIGHT_PX = 30

logger = logging.getLogger("gtkwave_export")


# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class ScreenshotConfig:
    """Static configuration for a single screenshot run."""

    input_vcd: Path
    output_png: Path
    screen_size: Tuple[int, int] = _DEFAULT_SCREEN_SIZE
    timeout_seconds: int = 12
    settle_seconds: int = 0
    background: str = "white"


# --------------------------------------------------------------------------
# Image helpers
# --------------------------------------------------------------------------


def _compute_content_bbox(image: Image.Image) -> Optional[Tuple[int, int, int, int]]:
    """Return the bounding box of the non-background content, or None."""
    # Binarise, dilate slightly to fuse neighbouring strokes, then invert
    # so `getbbox` finds the drawn area.
    binary = image.point(lambda x: 255 * bool(x))
    dilated = binary.filter(ImageFilter.MaxFilter(3))
    inverted = dilated.point(lambda x: 255 * (not x))

    outer = inverted.getbbox()
    if outer is None:
        return None

    # Crop once, then recompute to strip any residual black border from
    # GTKWave's chrome.
    cropped = image.crop(outer)
    inner = cropped.getbbox()
    if inner is None:
        return None

    return (
        outer[0] + inner[0],
        outer[1] + inner[1],
        outer[0] + inner[2],
        outer[1] + inner[3],
    )


def _looks_rendered(image: Image.Image) -> bool:
    """Return True once the captured frame contains enough waveform."""
    bbox = _compute_content_bbox(image)
    if bbox is None:
        return False
    _, top, _, bottom = bbox
    rendered = (bottom - top) > _MIN_WAVEFORM_HEIGHT_PX
    logger.debug("bbox=%s rendered=%s", bbox, rendered)
    return rendered


# --------------------------------------------------------------------------
# GTKWave driver
# --------------------------------------------------------------------------


def _write_gtkwave_control_files(work_dir: Path) -> Tuple[Path, Path]:
    """Drop the Tcl and rc scripts GTKWave needs into `work_dir`."""
    tcl_path = work_dir / "gtkwave.tcl"
    rc_path = work_dir / "gtkwave.rc"
    tcl_path.write_text(_GTKWAVE_TCL)
    rc_path.write_text(_GTKWAVE_RC)
    return tcl_path, rc_path


def _capture_screenshot(cfg: ScreenshotConfig, tcl_path: Path, rc_path: Path) -> None:
    """Run GTKWave headlessly and save the trimmed PNG to `cfg.output_png`."""
    command = [
        "gtkwave",
        "--nomenu",
        "--script", str(tcl_path),
        str(cfg.input_vcd),
        str(rc_path),
    ]
    logger.debug("gtkwave command: %s", " ".join(command))

    with SmartDisplay(
        visible=False,
        size=cfg.screen_size,
        bgcolor=cfg.background,
        backend="xvfb",
    ) as display:
        with EasyProcess(command) as proc:
            if cfg.settle_seconds:
                proc.sleep(cfg.settle_seconds)
            try:
                frame = display.waitgrab(
                    timeout=cfg.timeout_seconds,
                    cb_imgcheck=_looks_rendered,
                )
            except DisplayTimeoutError as exc:
                raise DisplayTimeoutError(f"{exc} (gtkwave stderr: {proc.stderr})") from exc

    bbox = _compute_content_bbox(frame)
    if bbox is None:
        raise RuntimeError(
            f"GTKWave rendered an empty frame for {cfg.input_vcd}; "
            "the VCD may be empty or corrupt."
        )
    # Widen to the left edge so signal names are always visible.
    _, top, right, bottom = bbox
    trimmed = frame.crop((0, top, right, bottom))

    cfg.output_png.parent.mkdir(parents=True, exist_ok=True)
    trimmed.save(cfg.output_png)
    logger.info("Saved %s (%dx%d)", cfg.output_png, trimmed.width, trimmed.height)


def render(cfg: ScreenshotConfig) -> None:
    """Top-level entry: validate inputs and drive GTKWave once."""
    if not cfg.input_vcd.is_file():
        raise FileNotFoundError(f"VCD not found: {cfg.input_vcd}")

    with tempfile.TemporaryDirectory(prefix="gtkwave_") as tmp:
        tcl_path, rc_path = _write_gtkwave_control_files(Path(tmp))
        _capture_screenshot(cfg, tcl_path, rc_path)


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def _parse_args(argv: Optional[list[str]] = None) -> ScreenshotConfig:
    parser = argparse.ArgumentParser(
        description=(
            "Render a waveform PNG from a VCD file by driving GTKWave "
            "inside a virtual X server."
        ),
    )
    parser.add_argument(
        "--input", "-i", required=True, type=Path,
        help="Input .vcd file.",
    )
    parser.add_argument(
        "--output", "-o", required=True, type=Path,
        help="Output .png file.",
    )
    parser.add_argument(
        "--timeout", type=int, default=12,
        help="Seconds to wait for GTKWave to render before giving up (default: 12).",
    )
    parser.add_argument(
        "--settle", type=int, default=0,
        help="Extra seconds to sleep after launch, useful for slow splash screens.",
    )
    parser.add_argument(
        "--screen-size", type=str, default="1024x768",
        help="Virtual display size, WIDTHxHEIGHT (default: 1024x768).",
    )
    parser.add_argument(
        "--background", type=str, default="white",
        help="Virtual display background colour (default: white).",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true",
        help="Enable debug logging.",
    )

    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(name)s %(levelname)s %(message)s",
    )

    try:
        width, height = (int(dim) for dim in args.screen_size.lower().split("x"))
    except ValueError:
        parser.error(f"--screen-size must be WIDTHxHEIGHT, got {args.screen_size!r}")

    return ScreenshotConfig(
        input_vcd=args.input,
        output_png=args.output,
        screen_size=(width, height),
        timeout_seconds=args.timeout,
        settle_seconds=args.settle,
        background=args.background,
    )


def main(argv: Optional[list[str]] = None) -> int:
    cfg = _parse_args(argv)
    try:
        render(cfg)
    except (FileNotFoundError, DisplayTimeoutError, RuntimeError) as exc:
        logger.error("%s", exc)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
