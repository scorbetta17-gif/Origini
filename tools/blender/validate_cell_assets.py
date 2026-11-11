#!/usr/bin/env python3
"""Verify actual Blender-generated glTF 2.0 binary asset library."""
import json
import struct
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
NAMES = ["primordial_core", "pili_module", "receptor_module",
         "protease_module", "transporter_module", "vesicle_module"]
REQUIRED = {
    "primordial_core": ["Membrane_Outer", "Cytosol", "SingleStrand_RNA",
                        "Autocatalytic_01", "Autocatalytic_02", "Autocatalytic_03"],
    "pili_module": ["Pilus_Flexible"],
    "receptor_module": ["Receptor_BindingHead"],
    "protease_module": ["Protease_CatalyticLobe"],
    "transporter_module": ["Transporter_ProteinRing"],
    "vesicle_module": ["Vesicle_Bilayer"],
}

def inspect(name):
    path = ROOT / "assets" / "models" / (name + ".glb")
    raw = path.read_bytes()
    assert len(raw) >= 2048, f"Missing or truncated asset: {path}"
    magic, version, length = struct.unpack_from("<4sII", raw)
    assert magic == b"glTF" and version == 2 and length == len(raw), name
    chunk_len, chunk_type = struct.unpack_from("<II", raw, 12)
    assert chunk_type == 0x4E4F534A, f"Missing glTF JSON chunk: {name}"
    doc = json.loads(raw[20:20+chunk_len].decode("utf8"))
    assert int(doc["asset"]["version"].split(".")[0]) == 2
    nodes = [str(node.get("name", "")) for node in doc.get("nodes",[])]
    for expected in REQUIRED[name]:
        assert any(node.startswith(expected) for node in nodes), f"{name}: {expected} not present"
    meshes = doc.get("meshes",[])
    assert len(meshes) >= 1, f"{name} no meshes"
    assert doc.get("materials"), f"{name}: no material"
    print(f"PASS_GLTF {name}: {len(raw)} bytes; {len(meshes)} meshes; {len(nodes)} nodes")

for item in NAMES:
    inspect(item)
print("PASS: all six original Blender-generated 3D model assets")
