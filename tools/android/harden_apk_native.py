#!/usr/bin/env python3
"""Repack Godot Android APK so all native .so libraries are STORED, not deflated.

This intentionally removes pre-existing APK signature entries. Run zipalign
-P 16 next, then sign with apksigner; NEVER use this file without re-signing.
"""
import sys
import zipfile
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: harden_apk_native.py ORIGINAL.apk UNSIGNED-REPACKED.apk")

src, dest = map(Path, sys.argv[1:])
native = []
with zipfile.ZipFile(src, "r") as original, zipfile.ZipFile(dest, "w", allowZip64=True) as out:
    filenames = original.namelist()
    assert len(filenames) == len(set(filenames)), "duplicate ZIP entries in APK"
    for item in original.infolist():
        path = item.filename
        if path.startswith("META-INF/") and path.upper().endswith((".RSA", ".DSA", ".EC", ".SF", ".MF")):
            continue
        data = original.read(path)
        info = zipfile.ZipInfo(path, date_time=item.date_time)
        info.comment = item.comment
        info.external_attr = item.external_attr
        info.create_system = item.create_system
        info.compress_type = zipfile.ZIP_STORED if path.startswith("lib/") and path.endswith(".so") else item.compress_type
        # Drop ZIP local-header extras; zipalign will add appropriate padding.
        info.extra = b""
        out.writestr(info, data)
        if path.startswith("lib/") and path.endswith(".so"):
            native.append(path)
assert "lib/arm64-v8a/libgodot_android.so" in native, f"Missing arm64 Godot engine: {native}"
assert "lib/arm64-v8a/libc++_shared.so" in native, f"Missing ARM64 standard library: {native}"
print(f"ORIGINI native hardening: {len(native)} libraries set to STORED / ready for zipalign and re-signing")
print(*native, sep="\n")


def verify(path: Path, expected_align: int = 16384) -> None:
    with zipfile.ZipFile(path, "r") as z:
        allnames = z.namelist()
        assert len(allnames) == len(set(allnames)), "Duplicated entries in APK"
        for lib in native:
            info = z.getinfo(lib)
            assert info.compress_type == zipfile.ZIP_STORED, f"{lib} was compressed"
            # For a stored entry, Android's memory-mapped reader sees the
            # *data* offset, not ZIP's local-file header offset.
            with path.open("rb") as fp:
                fp.seek(info.header_offset)
                header = fp.read(30)
            assert header[:4] == b"PK\\x03\\x04", "Invalid local header"
            name_len = int.from_bytes(header[26:28], "little")
            extra_len = int.from_bytes(header[28:30], "little")
            data_offset = info.header_offset + 30 + name_len + extra_len
            assert data_offset % expected_align == 0, (
                f"{lib} data unaligned: {data_offset} mod {expected_align}"
            )
            print(f"PASS_ANDROID_NATIVE={lib}, 16KiB alignment at {data_offset}, bytes={info.file_size}")


if __name__ == "__main__" and len(sys.argv) == 4 and sys.argv[1] == "--verify":
    verify(Path(sys.argv[2]))
