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

## Usage with Docker Compose

### 1. Mount the patch directory

```yaml
services:
  openwebrx:
    image: slechev/openwebrxplus:latest
    volumes:
      - ./patch:/opt/patch:ro
    command: >
      sh -c "/opt/patch/apply-patch.sh && /init"
```

### 2. Alternative: Use entrypoint wrapper

Create `entrypoint.sh`:
```bash
#!/bin/bash
/opt/patch/apply-patch.sh
exec "$@"
```

Then in docker-compose.yml:
```yaml
services:
  openwebrx:
    image: slechev/openwebrxplus:latest
    volumes:
      - ./patch:/opt/patch:ro
      - ./entrypoint.sh:/entrypoint.sh:ro
    entrypoint: ["/entrypoint.sh"]
    command: ["/init"]
```

## Manual Application

Inside the container:

```bash
# Navigate to Python packages directory
cd /usr/lib/python3/dist-packages

# Initialize git (required for patch)
git init
git add -A
git commit -m "Initial state"

# Apply patch
git apply /opt/patch/audio-recorder-timestamp.patch
```

## Notes

- The target directory is typically `/usr/lib/python3/dist-packages` in Debian-based images
- Git initialization is required because the installed packages don't have a git repository
- Patches are idempotent - running the script multiple times is safe
