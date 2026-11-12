#!/usr/bin/env python3
"""Validate native Android Godot APK shipping, not just presence of ZIP entries.

Run AFTER zipalign and apksigner. Requires arm64 libs to be raw STORED and
16KiB page aligned, native loader compatibility on Android 16.
"""
import sys
import zipfile
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit("usage: verify_apk_native.py SIGNED.apk")

path = Path(sys.argv[1])
assert path.stat().st_size > 1000000
with zipfile.ZipFile(path, "r") as apk:
    names = apk.namelist()
    assert len(names) == len(set(names)), "duplicate APK entries"
    assert "AndroidManifest.xml" in names
    assert "classes.dex" in names
    native = [name for name in names if name.startswith("lib/") and name.endswith(".so")]
    assert "lib/arm64-v8a/libgodot_android.so" in native, "ARM64 Godot engine missing"
    assert "lib/arm64-v8a/libc++_shared.so" in native, "ARM64 C++ runtime missing"
    for lib in native:
        info = apk.getinfo(lib)
        assert info.compress_type == zipfile.ZIP_STORED, f"Library compressed: {lib}"
        with path.open("rb") as fh:
            fh.seek(info.header_offset)
            header = fh.read(30)
        assert header[:4] == bytes([0x50, 0x4B, 0x03, 0x04]), "Invalid local ZIP header"
        filename_length = int.from_bytes(header[26:28], "little")
        extra_length = int.from_bytes(header[28:30], "little")
        data_offset = info.header_offset + 30 + filename_length + extra_length
        assert data_offset % 16384 == 0, f"Native library unaligned: {lib}: {data_offset}"
        contents = apk.read(lib)
        assert contents[:4] == bytes([0x7F, 0x45, 0x4C, 0x46]), f"Bad ELF: {lib}"
        print(f"PASS native {lib}, offset={data_offset}, bytes={len(contents)}, 16KiB aligned")
print("PASS: Android APK has accessible uncompressed 16KiB-aligned Godot ARM64 libraries")
