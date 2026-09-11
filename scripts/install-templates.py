"""Install the pinned official Godot templates after SHA-512 verification."""
import hashlib
from pathlib import Path
import sys
import zipfile

version = Path(__file__).resolve().parents[1].joinpath(".godot-version").read_text().strip()
archive, sums = map(Path, sys.argv[1:3])
official_name = f"Godot_v{version.replace('.stable', '-stable')}_export_templates.tpz"
matches = [line.split()[0] for line in sums.read_text().splitlines()
           if line.split()[-1].lstrip("*") == official_name]
if len(matches) != 1:
    raise SystemExit("Official template checksum was not found")
with archive.open("rb") as source:
    digest = hashlib.file_digest(source, "sha512").hexdigest()
if digest != matches[0]:
    raise SystemExit("Template checksum mismatch")
destination = Path.home() / "Library/Application Support/Godot/export_templates" / version
destination.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(archive) as bundle:
    for entry in bundle.infolist():
        relative = Path(entry.filename)
        if relative.parts[0] != "templates" or ".." in relative.parts:
            raise SystemExit(f"Unexpected template path: {relative}")
        target = destination.joinpath(*relative.parts[1:])
        if entry.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            with bundle.open(entry) as source, target.open("wb") as output:
                import shutil
                shutil.copyfileobj(source, output)
print(f"Verified and installed templates: {destination}")
