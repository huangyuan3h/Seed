"""Generate Seed's first-pass low-poly asset kit with headless Blender.

Run:
    blender -b --factory-startup --python tools/blender/build_seed_assets.py

Outputs:
    assets/models/seed/*.glb          game-ready props and environment pieces
    assets/art/icons/*.png            transparent 256px inventory icons
    docs/art/asset_kit_preview.png    contact sheet for review

Conventions (docs/art-direction.md section 8):
    - 1 Blender unit = 1 metre
    - origin at ground contact, model front faces Blender -Y (glTF +Z)
    - low-poly, flat shaded, palette materials, one mesh per asset
    - triangle budget: props < 2k, trees < 1.5k
"""

import math
import os
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL_DIR = os.path.join(ROOT, "assets", "models", "seed")
ICON_DIR = os.path.join(ROOT, "assets", "art", "icons")
PREVIEW_DIR = os.path.join(ROOT, "docs", "art")

PALETTE = {
    # world
    "grass": ("#6E8B4E", 0.95, 0.0, 0.0),
    "grass_dark": ("#3E5233", 0.95, 0.0, 0.0),
    "fiber": ("#B7A266", 0.9, 0.0, 0.0),
    "soil": ("#6B5741", 0.95, 0.0, 0.0),
    "rock": ("#77746B", 0.95, 0.0, 0.0),
    "bark": ("#4A3A2C", 0.9, 0.0, 0.0),
    "leaf": ("#35553E", 0.9, 0.0, 0.0),
    "leaf_dark": ("#3E5233", 0.9, 0.0, 0.0),
    "water": ("#3E6B72", 0.18, 0.0, 0.25),
    # artificial
    "ceramic": ("#D8D2C2", 0.62, 0.0, 0.0),
    "ceramic_worn": ("#B9B3A3", 0.7, 0.0, 0.0),
    "metal": ("#59645F", 0.5, 0.7, 0.0),
    "dark": ("#2C3333", 0.7, 0.3, 0.0),
    "amber": ("#E08A3C", 0.4, 0.0, 2.2),
    "power": ("#79C7D8", 0.3, 0.0, 1.8),
    "pod_blue": ("#7FB6C9", 0.25, 0.0, 0.7),
    "damage": ("#B5483F", 0.5, 0.0, 0.8),
    "print": ("#9AD6C4", 0.35, 0.0, 1.2),
    "wood": ("#8A6238", 0.9, 0.0, 0.0),
    "berry": ("#A83A56", 0.35, 0.0, 0.45),
    "glass": ("#22302F", 0.12, 0.2, 0.0),
}

MATS = {}


def srgb_to_linear(value):
    value = value / 255.0
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(srgb_to_linear(int(value[i:i + 2], 16)) for i in (0, 2, 4))


def material(name):
    if name in MATS:
        return MATS[name]
    hex_value, roughness, metallic, emission = PALETTE[name]
    rgb = hex_rgb(hex_value)
    mat = bpy.data.materials.new(f"seed_{name}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
    mat.diffuse_color = (*rgb, 1.0)
    mat.roughness = roughness
    mat.metallic = metallic
    MATS[name] = mat
    return mat


def _finish(bm, name, mat_name, loc, rot, scale, bevel):
    if bevel > 0.0 and len(bm.edges):
        bmesh.ops.bevel(
            bm,
            geom=list(bm.verts) + list(bm.edges),
            offset=min(bevel, 0.02),
            offset_type="OFFSET",
            segments=2,
            profile=0.5,
            affect="EDGES",
            clamp_overlap=True,
        )
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = False
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(material(mat_name))
    obj.location = loc
    obj.rotation_euler = rot
    obj.scale = scale
    return obj


def box(name, size, loc, mat, rot=(0, 0, 0), bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    return _finish(bm, name, mat, loc, rot, (1, 1, 1), bevel)


def cylinder(name, radius, depth, loc, mat, rot=(0, 0, 0), segments=16, radius2=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(
        bm,
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=radius,
        radius2=radius if radius2 is None else radius2,
        depth=depth,
    )
    return _finish(bm, name, mat, loc, rot, (1, 1, 1), 0.0)


def sphere(name, radius, loc, mat, scale=(1, 1, 1), subdiv=2, rot=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    return _finish(bm, name, mat, loc, rot, scale, 0.0)


def cone(name, radius, depth, loc, mat, radius2=0.0, segments=16, rot=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cone(
        bm,
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=radius,
        radius2=radius2,
        depth=depth,
    )
    return _finish(bm, name, mat, loc, rot, (1, 1, 1), 0.0)


def tube(name, p1, p2, radius, mat, segments=8):
    p1, p2 = Vector(p1), Vector(p2)
    direction = p2 - p1
    obj = cylinder(name, radius, direction.length, (p1 + p2) / 2, mat, segments=segments)
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return obj


def join(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = name
    joined.data.name = name
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for poly in joined.data.polygons:
        poly.use_smooth = False
    return joined


def scale_to_height(obj, height):
    """Uniformly scale a joined asset so its total height matches the spec."""
    zs = [vert.co.z for vert in obj.data.vertices]
    current = max(zs) - min(zs)
    if current > 0.0:
        obj.data.transform(Matrix.Scale(height / current, 4))
    return obj


# --------------------------------------------------------------------------
# Props
# --------------------------------------------------------------------------

def build_pod_07():
    """Empty, damaged hibernation pod. 2.2 m tall, front faces -Y."""
    parts = [
        box("plinth", (1.32, 1.32, 0.22), (0, 0, 0.11), "metal", bevel=0.02),
        box("plinth_top", (1.12, 1.12, 0.12), (0, 0, 0.27), "dark"),
        cylinder("body", 0.52, 1.34, (0, 0, 1.00), "ceramic", segments=20),
        sphere("crown", 0.52, (0, 0, 1.67), "ceramic", scale=(1, 1, 0.6), subdiv=2),
        cylinder("base_ring", 0.57, 0.14, (0, 0, 0.40), "metal", segments=20),
        cylinder("top_ring", 0.565, 0.10, (0, 0, 1.73), "metal", segments=20),
        box("hatch_frame", (0.74, 0.16, 1.06), (0, -0.48, 1.03), "metal", bevel=0.03),
        box("hatch_glass", (0.56, 0.10, 0.86), (0, -0.55, 1.03), "glass"),
        box("hatch_rim_top", (0.60, 0.03, 0.05), (0, -0.585, 1.48), "damage"),
        box("hatch_rim_bottom", (0.60, 0.03, 0.05), (0, -0.585, 0.58), "damage"),
        box("hatch_rim_left", (0.05, 0.03, 0.90), (-0.30, -0.585, 1.03), "damage"),
        box("hatch_rim_right", (0.05, 0.03, 0.90), (0.30, -0.585, 1.03), "damage"),
        box("hatch_door", (0.62, 0.10, 1.00), (-0.72, -0.28, 1.06), "ceramic_worn",
            rot=(0, 0, math.radians(-24)), bevel=0.03),
        box("hatch_door_face", (0.50, 0.03, 0.82), (-0.80, -0.34, 1.06), "dark",
            rot=(0, 0, math.radians(-24))),
        box("warning_strip", (0.10, 0.05, 0.44), (0.40, -0.47, 1.22), "amber"),
        box("data_port", (0.16, 0.05, 0.12), (-0.30, -0.50, 0.56), "print"),
        box("step", (0.92, 0.38, 0.11), (0, -0.80, 0.055), "metal", bevel=0.02),
        box("console", (0.18, 0.12, 0.28), (0.55, -0.18, 1.12), "dark", bevel=0.02,
            rot=(0, 0, math.radians(14))),
        box("console_screen", (0.12, 0.02, 0.15), (0.61, -0.235, 1.13), "print",
            rot=(0, 0, math.radians(14))),
        box("seam_a", (0.02, 0.07, 1.20), (0.515, 0.05, 1.00), "metal"),
        box("seam_b", (0.02, 0.07, 1.20), (-0.515, -0.05, 1.00), "metal"),
    ]
    for index, z in enumerate((0.62, 0.86, 1.10)):
        parts.append(box(f"vent_{index}", (0.06, 0.30, 0.05), (0.50, 0.05, z), "dark"))
    for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        parts.append(box("foot", (0.18, 0.18, 0.12), (sx * 0.52, sy * 0.52, 0.06), "dark"))
    parts.append(tube("cable", (0.48, 0.42, 0.30), (0.86, 0.70, 0.02), 0.035, "dark"))
    return scale_to_height(join(parts, "prop_pod_07"), 2.20)


def build_thermal_generator():
    """Hand-fed thermal generator. About 2 m tall."""
    parts = [
        box("skid", (1.40, 1.10, 0.16), (0, 0, 0.08), "metal", bevel=0.02),
        box("rail_l", (1.40, 0.12, 0.10), (0, -0.49, 0.05), "dark"),
        box("rail_r", (1.40, 0.12, 0.10), (0, 0.49, 0.05), "dark"),
        box("body", (1.02, 0.84, 0.92), (0, 0, 0.68), "ceramic", bevel=0.04),
        box("front_panel", (0.84, 0.06, 0.64), (0, -0.44, 0.70), "dark"),
        box("ash_door", (0.50, 0.05, 0.26), (0, -0.48, 0.43), "metal", bevel=0.02),
        box("handle", (0.10, 0.06, 0.04), (0.22, -0.52, 0.43), "dark"),
        cylinder("stack", 0.17, 0.92, (0.29, 0.10, 1.60), "metal", segments=14),
        cylinder("stack_cap", 0.21, 0.09, (0.29, 0.10, 2.08), "dark", segments=14),
        sphere("beacon", 0.075, (-0.34, 0.18, 1.86), "amber", subdiv=1),
        box("beacon_mount", (0.12, 0.12, 0.16), (-0.34, 0.18, 1.74), "dark"),
        box("water_tank", (0.26, 0.30, 0.44), (-0.34, 0.18, 1.44), "metal", bevel=0.03),
        tube("pipe_a", (0.10, 0.10, 1.10), (0.29, 0.10, 1.34), 0.05, "metal"),
        tube("pipe_b", (-0.18, 0.10, 1.14), (0.10, 0.10, 1.14), 0.045, "metal"),
    ]
    for index, x in enumerate((-0.36, -0.12, 0.12, 0.36)):
        parts.append(box(f"status_{index}", (0.14, 0.03, 0.07), (x, -0.48, 0.88), "power"))
    for index, z in enumerate((0.66, 0.78, 0.90)):
        parts.append(box(f"fin_{index}", (0.04, 0.56, 0.05), (0.52, 0.05, z), "metal"))
    return join(parts, "prop_thermal_generator")


def build_shelter():
    """Improvised shelter: wood frame, fiber panels, slanted roof. 2.5 m tall."""
    parts = [
        box("floor", (2.80, 2.80, 0.16), (0, 0, 0.08), "wood", bevel=0.02),
    ]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(box("post", (0.14, 0.14, 2.28), (sx * 1.24, sy * 1.24, 1.14), "wood"))
    parts += [
        box("back_wall", (2.48, 0.08, 1.55), (0, 1.22, 0.90), "fiber", bevel=0.01),
        box("side_wall_l", (0.08, 2.40, 1.40), (-1.24, 0, 0.83), "fiber", bevel=0.01),
        box("side_wall_r", (0.08, 1.30, 1.10), (1.24, -0.55, 0.68), "fiber", bevel=0.01),
        box("beam_front", (2.70, 0.14, 0.14), (0, -1.24, 2.30), "wood"),
        box("beam_back", (2.70, 0.14, 0.14), (0, 1.24, 2.42), "wood"),
        box("roof", (3.10, 3.10, 0.09), (0, 0, 2.44), "fiber",
            rot=(math.radians(-7.0), 0, 0), bevel=0.01),
        box("roof_ridge", (3.10, 0.12, 0.12), (0, 1.20, 2.56), "wood"),
        box("crate", (0.52, 0.52, 0.44), (0.72, 0.62, 0.38), "wood", bevel=0.02),
        box("crate_lid", (0.56, 0.56, 0.06), (0.72, 0.62, 0.63), "wood"),
        cylinder("lamp_cord", 0.012, 0.34, (0, -0.10, 2.22), "dark", segments=6),
        sphere("lamp", 0.075, (0, -0.10, 2.02), "amber", subdiv=1),
    ]
    return join(parts, "prop_shelter")


def build_berry_bush():
    """Forageable berry bush, berry-red signal. About 1 m tall."""
    rng = random.Random(21)
    parts = []
    clusters = [
        (0.00, 0.00, 0.55, 0.42),
        (0.34, 0.10, 0.48, 0.32),
        (-0.30, 0.16, 0.44, 0.30),
        (0.10, -0.28, 0.42, 0.30),
        (-0.08, 0.30, 0.36, 0.26),
        (0.28, -0.18, 0.72, 0.30),
        (-0.26, -0.14, 0.68, 0.26),
    ]
    for cx, cy, cz, radius in clusters:
        parts.append(sphere("leaf_cluster", radius, (cx, cy, cz), "leaf", scale=(1, 1, 0.78)))
        parts.append(tube("stem", (cx * 0.35, cy * 0.35, 0.02), (cx, cy, cz - radius * 0.3), 0.035, "bark", segments=6))
    for _ in range(16):
        cx, cy, cz, radius = clusters[rng.randrange(len(clusters))]
        theta = rng.uniform(0, math.tau)
        phi = rng.uniform(-0.5, 0.95)
        px = cx + math.cos(theta) * math.cos(phi) * radius * 0.95
        py = cy + math.sin(theta) * math.cos(phi) * radius * 0.95
        pz = cz + math.sin(phi) * radius * 0.78
        parts.append(sphere("berry", 0.055, (px, py, pz), "berry", subdiv=1))
    return join(parts, "env_berry_bush")


def build_tree_a():
    """Conifer silhouette, about 7.8 m tall."""
    parts = [
        cone("trunk", 0.24, 4.60, (0, 0, 2.30), "bark", radius2=0.14, segments=10),
        cone("canopy_low", 2.20, 2.60, (0, 0, 3.40), "leaf_dark", segments=12),
        cone("canopy_mid", 1.72, 2.30, (0, 0, 4.75), "leaf", segments=12),
        cone("canopy_high", 1.24, 2.00, (0, 0, 5.95), "leaf_dark", segments=12),
        cone("canopy_top", 0.72, 1.55, (0, 0, 7.02), "leaf", segments=10),
        tube("branch_a", (0, 0, 2.60), (0.85, 0.15, 3.10), 0.06, "bark", segments=6),
        tube("branch_b", (0, 0, 3.20), (-0.70, -0.25, 3.70), 0.05, "bark", segments=6),
    ]
    return join(parts, "env_tree_a")


def build_tree_b():
    """Broadleaf silhouette, about 6 m tall."""
    parts = [
        cone("trunk", 0.30, 3.30, (0, 0, 1.65), "bark", radius2=0.18, segments=10),
        sphere("canopy_a", 1.65, (0.20, 0.10, 4.10), "leaf", scale=(1, 1, 1.05)),
        sphere("canopy_b", 1.30, (-1.05, -0.25, 3.85), "leaf_dark", scale=(1, 1, 0.95)),
        sphere("canopy_c", 1.25, (1.15, -0.30, 3.80), "leaf_dark", scale=(1, 1, 0.92)),
        sphere("canopy_d", 1.15, (0.05, 0.85, 4.55), "leaf", scale=(1, 1, 0.9)),
        tube("branch_a", (0, 0, 2.30), (0.95, -0.10, 3.30), 0.09, "bark", segments=6),
        tube("branch_b", (0, 0, 2.50), (-0.90, -0.20, 3.20), 0.08, "bark", segments=6),
    ]
    return join(parts, "env_tree_b")


def build_rock():
    """Faceted rock with a moss cap. About 1.6 m wide."""
    rng = random.Random(5)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
    for vert in bm.verts:
        direction = vert.co.normalized()
        vert.co += direction * rng.uniform(-0.16, 0.12)
        vert.co.x *= 0.90
        vert.co.y *= 0.72
        vert.co.z *= 0.52
    lowest = min(vert.co.z for vert in bm.verts)
    for vert in bm.verts:
        vert.co.z -= lowest
    mesh = bpy.data.meshes.new("env_rock_a")
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = False
    rock = bpy.data.objects.new("env_rock_a", mesh)
    bpy.context.scene.collection.objects.link(rock)
    rock.data.materials.append(material("rock"))
    moss = sphere("moss", 0.55, (0.10, -0.05, 0.74), "leaf_dark", scale=(1.0, 0.8, 0.14), subdiv=2)
    return join([rock, moss], "env_rock_a")


def build_ship_rib():
    """Broken hull rib from the seed ship. 10 m span, half-buried feet."""
    parts = []
    radius = 5.0
    segments = 9
    start = math.radians(168)
    end = math.radians(12)
    for index in range(segments):
        if index == 4:
            continue  # broken gap near the crown
        a0 = start + (end - start) * index / segments
        a1 = start + (end - start) * (index + 1) / segments
        p0 = Vector((math.cos(a0) * radius, 0, math.sin(a0) * radius))
        p1 = Vector((math.cos(a1) * radius, 0, math.sin(a1) * radius))
        mid = (p0 + p1) / 2
        length = (p1 - p0).length * 1.10
        angle = math.atan2(p1.z - p0.z, p1.x - p0.x)
        mat = "ceramic" if index % 2 == 0 else "ceramic_worn"
        parts.append(box(f"rib_{index}", (length, 1.70, 0.55), mid, mat,
                         rot=(0, -angle, 0), bevel=0.04))
        parts.append(box(f"rib_seam_{index}", (0.10, 1.76, 0.58), mid, "metal",
                         rot=(0, -angle, 0)))
    for sx in (-1, 1):
        parts += [
            box("foot", (1.90, 2.10, 0.80), (sx * 5.0, 0, 0.40), "metal", bevel=0.04),
            sphere("soil_mound", 1.30, (sx * 5.0, 0, 0.22), "soil", scale=(1.5, 1.2, 0.36)),
        ]
    parts += [
        box("fallen_panel", (2.60, 1.40, 0.14), (-6.10, 0.60, 0.62), "ceramic_worn",
            rot=(0, math.radians(-16), math.radians(8)), bevel=0.02),
        box("panel_b", (2.20, 0.90, 0.16), (3.10, -0.50, 3.20), "ceramic_worn",
            rot=(0, math.radians(26), 0)),
        tube("cable", (4.60, 0.60, 1.20), (3.80, 0.80, 2.80), 0.05, "dark"),
        sphere("lamp", 0.09, (-4.20, 0.90, 2.60), "amber", subdiv=1),
    ]
    return join(parts, "env_ship_rib")


# --------------------------------------------------------------------------
# Icons
# --------------------------------------------------------------------------

def build_icon_wood():
    parts = []
    for index, (x, y, z, angle) in enumerate(((-0.05, -0.11, 0.10, 0), (0.03, 0.10, 0.10, 3), (0.0, 0.0, 0.28, 1))):
        rot = (0, math.radians(90), math.radians(angle))
        parts.append(cylinder("log", 0.095, 0.62, (x, y, z), "bark", rot=rot, segments=12))
        for side in (-1, 1):
            parts.append(cylinder("log_end", 0.075, 0.02,
                                  (x + side * 0.315, y, z), "wood", rot=rot, segments=12))
    return join(parts, "icon_wood")


def build_icon_fiber():
    rng = random.Random(3)
    parts = []
    for index in range(9):
        theta = math.tau * index / 9
        lean = rng.uniform(0.10, 0.26)
        loc = (math.cos(theta) * 0.055, math.sin(theta) * 0.055, 0.30)
        rot = (math.sin(theta) * lean, math.cos(theta) * lean, 0)
        parts.append(cone("blade", 0.030, 0.58, loc, "fiber", radius2=0.003, segments=5, rot=rot))
    parts.append(cylinder("band", 0.085, 0.055, (0, 0, 0.24), "wood", segments=12))
    return join(parts, "icon_fiber")


def build_icon_berry():
    parts = [
        sphere("berry_a", 0.115, (0.00, 0.00, 0.15), "berry", subdiv=2),
        sphere("berry_b", 0.100, (0.14, 0.05, 0.12), "berry", subdiv=2),
        sphere("berry_c", 0.095, (-0.10, -0.09, 0.11), "berry", subdiv=2),
        sphere("leaf", 0.13, (0.01, 0.0, 0.28), "leaf", scale=(1.15, 0.65, 0.20), subdiv=2,
               rot=(0, 0, math.radians(20))),
        cylinder("stem", 0.014, 0.13, (0, 0, 0.31), "bark", segments=6),
    ]
    return join(parts, "icon_berry")


def build_icon_chip():
    parts = [
        box("chip_body", (0.36, 0.26, 0.055), (0, 0, 0.035), "dark", bevel=0.012),
        box("chip_face", (0.28, 0.18, 0.012), (0, 0, 0.068), "print"),
        box("chip_stripe", (0.20, 0.020, 0.010), (0, 0.045, 0.076), "dark"),
        box("chip_core", (0.055, 0.055, 0.012), (0.06, -0.035, 0.076), "amber"),
    ]
    for index in range(4):
        parts.append(box(f"pin_{index}", (0.035, 0.020, 0.020), (-0.12 + index * 0.08, -0.145, 0.035), "metal"))
    return join(parts, "icon_chip")


def build_icon_water():
    parts = [
        sphere("drop_body", 0.135, (0, 0, 0.15), "water", scale=(1.0, 1.0, 0.92), subdiv=2),
        cone("drop_tip", 0.090, 0.19, (0, 0, 0.30), "water", radius2=0.006, segments=12),
    ]
    return join(parts, "icon_water")


ICONS = {
    "icon_wood": build_icon_wood,
    "icon_fiber": build_icon_fiber,
    "icon_berry": build_icon_berry,
    "icon_chip": build_icon_chip,
    "icon_water": build_icon_water,
}


# --------------------------------------------------------------------------
# Scene, export, render
# --------------------------------------------------------------------------

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MATS.clear()


def setup_world(color="#C9D3CB", strength=0.9):
    world = bpy.data.worlds.new("SeedWorld")
    world.use_nodes = True
    background = world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = (*hex_rgb(color), 1.0)
    background.inputs["Strength"].default_value = strength
    bpy.context.scene.world = world


def add_light(name, light_type, location, energy, color, rotation=(0, 0, 0), size=3.0):
    data = bpy.data.lights.new(name, type=light_type)
    data.energy = energy
    data.color = hex_rgb(color)
    if light_type == "AREA":
        data.size = size
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = rotation
    return obj


def look_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_camera(location, target, lens=55.0, ortho=None):
    data = bpy.data.cameras.new("Camera")
    data.lens = lens
    if ortho is not None:
        data.type = "ORTHO"
        data.ortho_scale = ortho
    cam = bpy.data.objects.new("Camera", data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = location
    look_at(cam, target)
    bpy.context.scene.camera = cam
    return cam


def setup_render(width, height, transparent=False, samples=32):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = samples
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = transparent
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA" if transparent else "RGB"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"


def export_glb(obj, filepath):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    kwargs = dict(
        filepath=filepath,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
    try:
        bpy.ops.export_scene.gltf(**kwargs)
    except TypeError:
        for key in ("export_yup", "export_cameras", "export_lights"):
            kwargs.pop(key, None)
        bpy.ops.export_scene.gltf(**kwargs)


def tri_count(obj):
    return sum(len(poly.vertices) - 2 for poly in obj.data.polygons)


def render_contact_sheet():
    reset_scene()
    setup_world("#C9D3CB", 1.05)
    setup_render(1600, 920, transparent=False, samples=48)

    ground_mat = material("grass")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=30.0)
    mesh = bpy.data.meshes.new("ground")
    bm.to_mesh(mesh)
    bm.free()
    ground = bpy.data.objects.new("ground", mesh)
    bpy.context.scene.collection.objects.link(ground)
    ground.location = (0, 4, -0.01)
    ground.data.materials.append(ground_mat)

    add_light("sun", "SUN", (0, 0, 12), 4.2, "#FFE8C8",
              rotation=(math.radians(62), 0, math.radians(-38)))
    add_light("fill", "AREA", (-9, -8, 7), 1500, "#8FB4C4",
              rotation=(math.radians(52), 0, math.radians(-40)), size=10.0)

    # Rebuild the assets into the preview scene (fresh materials after reset).
    builders = [
        ("prop_pod_07", build_pod_07, (-5.0, 0.0)),
        ("prop_thermal_generator", build_thermal_generator, (-2.2, 0.0)),
        ("prop_shelter", build_shelter, (2.2, 0.0)),
        ("env_berry_bush", build_berry_bush, (5.3, 0.0)),
        ("env_rock_a", build_rock, (7.2, 0.0)),
        ("env_tree_a", build_tree_a, (-3.6, 5.2)),
        ("env_tree_b", build_tree_b, (1.0, 5.6)),
    ]
    for name, builder, (x, y) in builders:
        obj = builder()
        obj.location = (x, y, 0)

    setup_camera((1.0, -23.0, 8.6), (0.8, 2.2, 2.2), lens=42.0)
    path = os.path.join(PREVIEW_DIR, "asset_kit_preview.png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def render_ship_rib_preview():
    reset_scene()
    setup_world("#AEBDB4", 0.7)
    setup_render(1200, 800, transparent=False, samples=48)
    add_light("sun", "SUN", (0, 0, 12), 3.0, "#FFE8C8",
              rotation=(math.radians(60), 0, math.radians(-35)))
    add_light("fill", "AREA", (-8, -8, 6), 800, "#8FB4C4",
              rotation=(math.radians(55), 0, math.radians(-40)), size=8.0)
    ground_mat = material("grass_dark")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=30.0)
    mesh = bpy.data.meshes.new("ground")
    bm.to_mesh(mesh)
    bm.free()
    ground = bpy.data.objects.new("ground", mesh)
    bpy.context.scene.collection.objects.link(ground)
    ground.data.materials.append(ground_mat)
    build_ship_rib()
    setup_camera((11.0, -15.0, 6.0), (0.0, 0.0, 2.6), lens=45.0)
    path = os.path.join(PREVIEW_DIR, "ship_rib_preview.png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def render_icons():
    paths = []
    for name, builder in ICONS.items():
        reset_scene()
        setup_world("#C9D3CB", 0.6)
        setup_render(256, 256, transparent=True, samples=48)
        add_light("key", "AREA", (2.2, -2.6, 3.2), 260, "#FFE8C8", size=3.0)
        look_at(bpy.context.scene.objects["key"], (0, 0, 0.2))
        add_light("rim", "AREA", (-2.4, 1.8, 2.0), 150, "#8FB4C4", size=2.5)
        look_at(bpy.context.scene.objects["rim"], (0, 0, 0.2))
        icon = builder()
        bpy.context.view_layer.update()
        corners = [icon.matrix_world @ Vector(corner) for corner in icon.bound_box]
        center = sum(corners, Vector()) / len(corners)
        cam = setup_camera(center + Vector((2.0, -2.6, 2.0)), center, ortho=1.0)
        bpy.context.view_layer.update()
        inverse = cam.matrix_world.inverted()
        xs = [(inverse @ corner).x for corner in corners]
        ys = [(inverse @ corner).y for corner in corners]
        cam.data.ortho_scale = max(max(xs) - min(xs), max(ys) - min(ys)) * 1.36
        path = os.path.join(ICON_DIR, f"{name}.png")
        bpy.context.scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        paths.append(path)
    return paths


def main():
    os.makedirs(MODEL_DIR, exist_ok=True)
    os.makedirs(ICON_DIR, exist_ok=True)
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    # 1. Build + export each model in a clean scene.
    reset_scene()
    builders = [
        build_pod_07,
        build_thermal_generator,
        build_shelter,
        build_berry_bush,
        build_tree_a,
        build_tree_b,
        build_rock,
        build_ship_rib,
    ]
    for builder in builders:
        reset_scene()
        obj = builder()
        path = os.path.join(MODEL_DIR, f"{obj.name}.glb")
        export_glb(obj, path)
        print(f"EXPORTED {os.path.basename(path)} tris={tri_count(obj)}")

    # 2. Contact sheet and hero preview.
    print("PREVIEW", render_contact_sheet())
    print("PREVIEW", render_ship_rib_preview())

    # 3. Icons.
    for path in render_icons():
        print("ICON", path)


if __name__ == "__main__":
    main()
