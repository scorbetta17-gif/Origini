#!/usr/bin/env python3
"""ORIGIN: Blender 4.x -> glTF 2.0 / .glb cell asset library.

Run: blender --background --factory-startup --python tools/blender/create_cell_assets.py
Every output is modeled (not image-generated) in actual Blender and exports
as a reusable runtime glTF scene. No copyrighted third-party assets.
"""
import math
from pathlib import Path

import bpy
from mathutils import Vector, noise

OUT = Path(__file__).resolve().parents[2] / "assets" / "models"
OUT.mkdir(parents=True, exist_ok=True)


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name, rgb, roughness=0.58, alpha=1.0, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (rgb[0], rgb[1], rgb[2], alpha)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], alpha)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Alpha"].default_value = alpha
    if alpha < 1.0:
        if hasattr(mat, "surface_render_method"):
            mat.surface_render_method = "DITHERED"
        elif hasattr(mat, "blend_method"):
            mat.blend_method = "BLEND"
    return mat


MEMBRANE = material("Membrane_Lipids", (.34, .66, .59), .40, .23)
WATER = material("Cytosol_Water", (.27, .50, .51), .73, .055)
RNA = material("RNA_ss_Amber", (.82, .43, .30), .48)
ENZYME = material("Autocatalytic_Complex", (.72, .66, .42), .65)
ENZYME_DETAIL = material("Autocatalytic_Inner", (.46, .51, .39), .74)
SURFACE = material("Surface_Protein", (.55, .74, .62), .56)
SURFACE_DARK = material("Surface_Core", (.34, .56, .51), .75)
VESICLE = material("Secretion_Vesicle", (.48, .64, .58), .51, .37)


def uv_sphere(name, location, scale, mat, organic=0.0, resolution=32):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=resolution, ring_count=max(12, resolution // 2),
        radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    if organic:
        for vert in obj.data.vertices:
            p = vert.co.copy()
            d = noise.noise_vector(p * 2.1)
            f = 1.0 + organic * (d.x * .5 + d.z * .22)
            vert.co *= f
    obj.scale = scale
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.data.materials.append(mat)
    return obj


def polymer(name, points, radius, mat, resolution=3):
    curve = bpy.data.curves.new(name, type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 20
    curve.bevel_resolution = resolution
    curve.bevel_depth = radius
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for pt, xyz in zip(spline.points, points):
        pt.co = (xyz[0], xyz[1], xyz[2], 1.0)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    # glTF safely serializes mesh geometry; converts the curve in Blender.
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.object
    obj.name = name
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def cyl(name, location, scale, mat, vertices=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=1, depth=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def export(name):
    bpy.ops.object.select_all(action="SELECT")
    output = OUT / f"{name}.glb"
    bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB",
                              use_selection=True, export_apply=True)
    if not output.is_file() or output.stat().st_size < 1024:
        raise RuntimeError(f"Bad GLB: {output}")
    print(f"ORIGIN_GLB={output} bytes={output.stat().st_size}")


def build_core():
    clear()
    # Mesh is a closed continuous shell: slight noise only, never cartoon faceting.
    uv_sphere("Membrane_Outer", (0, 0, 0), (1.0, 1.0, 1.0),
              MEMBRANE, organic=.023, resolution=64)
    uv_sphere("Cytosol", (0, 0, 0), (.956, .956, .956),
              WATER, organic=.007, resolution=48)
    interior = bpy.data.objects.new("InteriorAssembly", None)
    bpy.context.collection.objects.link(interior)
    # One ssRNA polymer. Spatial looping with bends, NOT a DNA double helix.
    points = []
    for i in range(120):
        t = i / 119.0
        points.append((
            (t - .5) * .96 + .10 * math.sin(t * math.tau * 3.05),
            .19 * math.sin(t * math.tau * 1.70) + .076 * math.cos(t * math.tau * 3.2),
            .21 * math.cos(t * math.tau * 1.37) + .09 * math.sin(t * math.tau * 2.4),
        ))
    strand = polymer("SingleStrand_RNA", points, .019, RNA)
    strand.parent = interior
    # Exactly three low-complexity autocatalytic/ribozyme complexes at gen 0.
    coords = [(-.31,.15,.12), (.29,-.13,-.12), (.08,.12,-.31)]
    for idx, p in enumerate(coords):
        blobs = [
            ((0,0,0),(.064,.047,.055),ENZYME),
            ((.052,.02,-.026),(.039,.035,.040),ENZYME_DETAIL),
            ((-.040,-.023,.031),(.036,.028,.035),ENZYME),
        ]
        for j,(shift,dimensions,mat) in enumerate(blobs):
            pt = tuple(p[k]+shift[k] for k in range(3))
            node = uv_sphere(f"Autocatalytic_{idx+1:02d}_{j+1:02d}",pt,
                             dimensions,mat,organic=.10,resolution=20)
            node.parent = interior
    export("primordial_core")


def build_pilus():
    clear()
    points=[]
    for i in range(40):
        t=i/39
        points.append((.035*math.sin(t*math.tau*.85),
                       t*.77,
                       .046*math.sin(t*math.tau*1.55)))
    polymer("Pilus_Flexible",points,.013,SURFACE)
    uv_sphere("Pilus_Anchor",(0,.018,0),(.049,.036,.049),SURFACE_DARK,resolution=20)
    export("pili_module")


def build_receptor():
    clear()
    cyl("Receptor_Stalk",(0,.055,0),(.026,.13,.026),SURFACE_DARK,vertices=18)
    uv_sphere("Receptor_BindingHead",(0,.135,0),(.076,.041,.064),SURFACE,
              organic=.08,resolution=28)
    export("receptor_module")


def build_protease():
    clear()
    uv_sphere("Protease_Anchor",(0,.025,0),(.079,.048,.067),SURFACE_DARK,
              organic=.06,resolution=24)
    uv_sphere("Protease_CatalyticLobe",(.033,.095,0),(.062,.065,.055),ENZYME,
              organic=.07,resolution=24)
    uv_sphere("Protease_SubstrateGroove",(-.019,.128,.038),(.031,.036,.03),ENZYME_DETAIL,resolution=18)
    export("protease_module")


def build_transporter():
    clear()
    # A ring-like protein barrel protruding from the phospholipid membrane.
    bpy.ops.mesh.primitive_torus_add(
        major_segments=28, minor_segments=9,
        location=(0,.017,0), major_radius=.056, minor_radius=.019)
    o=bpy.context.object
    o.name="Transporter_ProteinRing"
    o.data.materials.append(SURFACE)
    o.rotation_euler[0]=math.pi/2.0  # axis Y = membrane normal
    cyl("Transporter_CentralPore",(0,.009,0),(.021,.049,.021),SURFACE_DARK,vertices=18)
    export("transporter_module")


def build_vesicle():
    clear()
    uv_sphere("Vesicle_Bilayer",(0,0,0),(.082,.082,.082),VESICLE,organic=.018,resolution=32)
    uv_sphere("Vesicle_Core",(0,0,0),(.057,.057,.057),WATER,resolution=24)
    export("vesicle_module")


if __name__ == "__main__":
    for builder in [build_core, build_pilus, build_receptor,
                    build_protease, build_transporter, build_vesicle]:
        builder()
    print("ORIGIN: Blender cell asset library finished.")
