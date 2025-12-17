# OpenWebRX Patches

This directory contains patches for OpenWebRX that can be applied to Docker containers.

## Patches

### audio-recorder-timestamp.patch

Adds JSON timestamp file generation for audio recordings. When recording with squelch enabled, creates a companion `.json` file that maps audio segments to real UTC timestamps.

**JSON format:**
```json
[
  {
    "start_byte": 0,
    "start_time_ms": 0,
    "duration_ms": 5230,
    "start_utc": "2025-01-15T08:30:15.123456Z"
  }
]
```

### modes-ifrate-fix.patch

Fixes a bug in `DigitalMode.for_underlying()` method where the `ifRate` parameter is missing, causing `TypeError` when using background services with underlying modulation specified.

**Bug location:** `owrx/modes.py` line 93

### files-audio-duration.patch

Displays actual audio duration for MP3 files on the `/files` page. Parses MP3 frame headers to calculate duration without external dependencies.

**Modified files:**
- `owrx/controllers/file.py` - Adds `get_mp3_duration()` function and duration display logic
- `htdocs/css/files.css` - Adds `.file-duration` style

**Display format:** Duration shown as `MM:SS` (or `H:MM:SS` for files over 1 hour) below the file size

## Usage with Docker Compose (Recommended)

Mount the patch directory and register the apply script as an s6-overlay init script:

```yaml
services:
  openwebrx:
    image: slechev/openwebrxplus-softmbe:latest
    volumes:
      # BG5DRB patch (audio-recorder-timestamp, etc.)
      - ./patch:/opt/patch:ro
      - ./patch/apply-patch.sh:/etc/cont-init.d/97-apply-bg5drb-patch.sh:ro
```

The script will automatically run at container startup before the main service starts.

## Manual Application

Inside the container:

```bash
/opt/patch/apply-patch.sh
```

## Notes

- The target directory is typically `/usr/lib/python3/dist-packages` in Debian-based images
- Uses the `patch` command (no git required)
- Patches are idempotent - running the script multiple times is safe
- To update patches: `git pull` in the patch directory, then restart the container
