"""Package the standalone public mod for a GitHub release."""

import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZIP_STORED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
MOD_FILES = (
    "mod.ff",
    "pmflex.iwd",
    "z_c_r.iwd",
    "ui_style.iwd",
    "standard.cfg",
    "combined.cfg",
    "match-stats-contract.json",
)
DOC_FILES = (
    "LICENSE.md",
    "README.md",
    "CHANGELOG.md",
    "readme.txt",
    "End User License Agreement (Release of Map Tools to the Public for Call of Duty 4-PC).doc",
)
TIMESTAMP = (2026, 10, 12, 0, 0, 0)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="release tag, such as v0.1.0")
    parser.add_argument("--mod-dir", required=True, type=Path, help="built mods/pmflex directory")
    args = parser.parse_args()
    if not args.version.startswith("v") or not all(
        c.isdigit() or c == "." for c in args.version[1:]
    ):
        parser.error("--version must look like v0.1.0")

    mod_dir = args.mod_dir.resolve()
    if mod_dir.name.lower() != "pmflex":
        parser.error("--mod-dir must point to a built mods/pmflex directory")
    members = {f"mods/pmflex/{name}": mod_dir / name for name in MOD_FILES}
    members.update({name: ROOT / name for name in DOC_FILES})
    missing = [str(path) for path in members.values() if not path.is_file()]
    if missing:
        parser.error("missing required files: " + ", ".join(missing))

    contract = json.loads((mod_dir / "match-stats-contract.json").read_text(encoding="utf-8-sig"))
    if contract.get("modFfSha256") != digest((mod_dir / "mod.ff").read_bytes()):
        parser.error("built mod.ff does not match the contract sidecar")
    if contract.get("publicStubSha256") != digest((ROOT / "promod/match_stats.gsc").read_bytes()):
        parser.error("the built mod uses a different public recorder stub")
    for iwd in ("pmflex.iwd", "z_c_r.iwd", "ui_style.iwd"):
        with ZipFile(mod_dir / iwd) as archive:
            private = [
                name for name in archive.namelist()
                if name.lower().endswith((".gsx", ".dll", ".exe"))
                or "cp_platform" in name.lower()
            ]
            if private:
                parser.error(f"{iwd} contains private extension files: {private}")

    output = ROOT / "build" / "releases" / f"pmflex-{args.version}-mod.zip"
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w") as archive:
        for name, path in members.items():
            content = path.read_bytes()
            info = ZipInfo(name, TIMESTAMP)
            info.compress_type = ZIP_STORED if name.endswith((".iwd", ".ff")) else ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, content)

    with ZipFile(output) as archive:
        if set(archive.namelist()) != set(members):
            raise RuntimeError("release archive contains unexpected files")
        for name, path in members.items():
            if digest(archive.read(name)) != digest(path.read_bytes()):
                raise RuntimeError(f"release archive differs from {path}")
    print(f"Created {output}")
    print(f"SHA-256 {digest(output.read_bytes())}")
    for name in members:
        print(name)


if __name__ == "__main__":
    main()
