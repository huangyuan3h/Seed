"""Generate Seed's fauna and shore kit with headless Blender.

Run:
    blender -b --factory-startup --python tools/blender/build_fauna_assets.py

Outputs:
    assets/models/fauna/*.glb      sheep, ram, lamb, grouse, rabbit
    assets/models/nature/*.glb     shells and a gnarled tree
    docs/art/fauna_preview.png     animal line-up
    docs/art/shells_preview.png    shore collectibles
    docs/art/gnarled_tree_preview.png

The kit is designed for the "primitive Earth exterior" side of the art
direction: warm neutrals, soft silhouettes, no textures. The cold sci-fi ship
interior is generated separately by tools/blender/build_ship_models.py.

Geometry helpers, palette, export, and render setup are shared with
build_seed_assets.py so both scripts follow the same conventions.
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_seed_assets as seed  # noqa: E402

ROOT = seed.ROOT
FAUNA_DIR = os.path.join(ROOT, "assets", "models", "fauna")
NATURE_DIR = os.path.join(ROOT, "assets", "models", "nature")
PREVIEW_DIR = os.path.join(ROOT, "docs", "art")

seed.PALETTE.update({
    "wool": ("#E6DFCF", 0.92, 0.0, 0.0),
    "wool_shadow": ("#CFC6B4", 0.94, 0.0, 0.0),
    "sheep_face": ("#3B3630", 0.85, 0.0, 0.0),
    "horn": ("#8C7A5E", 0.8, 0.0, 0.0),
    "fur": ("#8C7A63", 0.95, 0.0, 0.0),
    "fur_dark": ("#5C4C3C", 0.95, 0.0, 0.0),
    "rabbit_tail": ("#EDE8DC", 0.95, 0.0, 0.0),
    "feather": ("#6B5741", 0.9, 0.0, 0.0),
    "feather_light": ("#8A6E4E", 0.9, 0.0, 0.0),
    "feather_dark": ("#4A3A2C", 0.9, 0.0, 0.0),
    "grouse_comb": ("#B5483F", 0.6, 0.0, 0.0),
    "shell": ("#D9C3B0", 0.55, 0.0, 0.0),
    "shell_band": ("#A87E6E", 0.6, 0.0, 0.0),
    "shell_inner": ("#E8D8C8", 0.35, 0.0, 0.05),
    "eye": ("#141A1A", 0.25, 0.0, 0.0),
    "sand": ("#C9B48E", 0.95, 0.0, 0.0),
})


def ground(obj):
    """Move a joined asset so its lowest vertex sits on z = 0."""
    lowest = min(vert.co.z for vert in obj.data.vertices)
    obj.data.transform(Matrix.Translation((0, 0, -lowest)))
    return obj


def _tapered(name, start, end, radius_start, radius_end, mat, segments=8):
    start, end = Vector(start), Vector(end)
    direction = end - start
    obj = seed.cylinder(name, radius_start, direction.length, (start + end) / 2,
                        mat, segments=segments, radius2=radius_end)
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return obj


def eyes(parts, positions, radius=0.018):
    for index, position in enumerate(positions):
        parts.append(seed.sphere(f"eye_{index}", radius, position, "eye", subdiv=1))


# ---------------------------------------------------------------------------
# Fauna
# ---------------------------------------------------------------------------

def build_sheep(name="fauna_sheep", wool="wool", body_scale=1.0, height=1.02):
    """Ewe: wool cloud, dark face and short legs, about 1 m tall."""
    s = body_scale
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(seed.cylinder(
                "leg", 0.040 * s, 0.38 * s,
                (sx * 0.19 * s, sy * 0.27 * s, 0.19 * s),
                "sheep_face", segments=6,
            ))
            parts.append(seed.box(
                "hoof", (0.075 * s, 0.085 * s, 0.050 * s),
                (sx * 0.19 * s, sy * 0.27 * s, 0.025 * s), "eye",
            ))

    body_z = 0.62 * s
    parts += [
        seed.sphere("wool_body", 0.35 * s, (0, 0.02 * s, body_z), wool,
                    scale=(1.05, 1.42, 0.95), subdiv=2),
        seed.sphere("wool_shoulder", 0.27 * s, (0, -0.27 * s, body_z + 0.02 * s), wool,
                    scale=(1.05, 1.0, 0.95), subdiv=1),
        seed.sphere("wool_rump", 0.29 * s, (0, 0.31 * s, body_z), wool,
                    scale=(1.0, 1.0, 0.95), subdiv=1),
        seed.sphere("wool_tail", 0.10 * s, (0, 0.47 * s, body_z + 0.04 * s), wool,
                    subdiv=1),
        seed.cylinder("neck", 0.105 * s, 0.26 * s,
                      (0, -0.44 * s, body_z + 0.14 * s), "sheep_face",
                      rot=(math.radians(58), 0, 0), segments=8),
        seed.sphere("head", 0.155 * s, (0, -0.57 * s, body_z + 0.24 * s), "sheep_face",
                    scale=(0.82, 1.15, 0.92), subdiv=2),
        seed.sphere("muzzle", 0.085 * s, (0, -0.69 * s, body_z + 0.18 * s), "sheep_face",
                    scale=(0.85, 1.15, 0.8), subdiv=1),
        seed.sphere("forelock", 0.10 * s, (0, -0.53 * s, body_z + 0.36 * s), wool,
                    scale=(1.15, 0.95, 0.75), subdiv=1),
    ]
    for sx in (-1, 1):
        parts.append(seed.box(
            "ear", (0.105 * s, 0.045 * s, 0.055 * s),
            (sx * 0.16 * s, -0.55 * s, body_z + 0.30 * s), "sheep_face",
            rot=(0, sx * math.radians(12), sx * math.radians(28)),
        ))
    eyes(parts, [
        (-0.075 * s, -0.685 * s, body_z + 0.275 * s),
        (0.075 * s, -0.685 * s, body_z + 0.275 * s),
    ], 0.017 * s)
    return seed.scale_to_height(seed.join(parts, name), height)


def build_ram():
    """Ram: heavier body plus curled horns, about 1.12 m tall."""
    s = 1.08
    parts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(seed.cylinder(
                "leg", 0.045 * s, 0.38 * s,
                (sx * 0.20 * s, sy * 0.28 * s, 0.19 * s),
                "sheep_face", segments=6,
            ))
            parts.append(seed.box(
                "hoof", (0.08 * s, 0.09 * s, 0.050 * s),
                (sx * 0.20 * s, sy * 0.28 * s, 0.025 * s), "eye",
            ))

    body_z = 0.64 * s
    parts += [
        seed.sphere("wool_body", 0.38 * s, (0, 0.02 * s, body_z), "wool_shadow",
                    scale=(1.06, 1.40, 0.96), subdiv=2),
        seed.sphere("wool_shoulder", 0.30 * s, (0, -0.27 * s, body_z + 0.02 * s), "wool_shadow",
                    scale=(1.05, 1.0, 0.95), subdiv=1),
        seed.sphere("wool_rump", 0.31 * s, (0, 0.31 * s, body_z), "wool_shadow",
                    subdiv=1),
        seed.cylinder("neck", 0.12 * s, 0.26 * s,
                      (0, -0.44 * s, body_z + 0.15 * s), "sheep_face",
                      rot=(math.radians(58), 0, 0), segments=8),
        seed.sphere("head", 0.17 * s, (0, -0.56 * s, body_z + 0.27 * s), "sheep_face",
                    scale=(0.85, 1.12, 0.95), subdiv=2),
        seed.sphere("muzzle", 0.095 * s, (0, -0.69 * s, body_z + 0.20 * s), "sheep_face",
                    scale=(0.85, 1.1, 0.8), subdiv=1),
        seed.sphere("forelock", 0.11 * s, (0, -0.52 * s, body_z + 0.40 * s), "wool_shadow",
                    scale=(1.15, 0.95, 0.7), subdiv=1),
    ]
    for sx in (-1, 1):
        parts.append(seed.box(
            "ear", (0.11 * s, 0.045 * s, 0.06 * s),
            (sx * 0.17 * s, -0.54 * s, body_z + 0.33 * s), "sheep_face",
            rot=(0, sx * math.radians(14), sx * math.radians(30)),
        ))

        # Ram horn: a C-hook outside the wool, crown -> back -> down -> jaw.
        points = [
            Vector((sx * 0.17 * s, -0.50 * s, body_z + 0.32 * s)),
            Vector((sx * 0.30 * s, -0.40 * s, body_z + 0.30 * s)),
            Vector((sx * 0.37 * s, -0.42 * s, body_z + 0.18 * s)),
            Vector((sx * 0.38 * s, -0.50 * s, body_z + 0.07 * s)),
            Vector((sx * 0.32 * s, -0.60 * s, body_z + 0.02 * s)),
            Vector((sx * 0.24 * s, -0.66 * s, body_z + 0.04 * s)),
        ]
        radii = [0.085, 0.078, 0.068, 0.056, 0.045, 0.034]
        for index in range(len(points) - 1):
            parts.append(_tapered(
                f"horn_{index}", points[index], points[index + 1],
                radii[index] * s, radii[index + 1] * s,
                "horn", segments=6,
            ))

    eyes(parts, [
        (-0.08 * s, -0.68 * s, body_z + 0.30 * s),
        (0.08 * s, -0.68 * s, body_z + 0.30 * s),
    ], 0.018 * s)
    return seed.scale_to_height(seed.join(parts, "fauna_ram"), 1.12)


def build_lamb():
    """Lamb: same silhouette at 0.62 scale, rounder and paler."""
    parts = []
    s = 0.62
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(seed.cylinder(
                "leg", 0.042 * s, 0.38 * s,
                (sx * 0.19 * s, sy * 0.26 * s, 0.19 * s),
                "sheep_face", segments=6,
            ))
    body_z = 0.62 * s
    parts += [
        seed.sphere("wool_body", 0.38 * s, (0, 0.02 * s, body_z), "wool",
                    scale=(1.08, 1.30, 1.0), subdiv=2),
        seed.sphere("wool_shoulder", 0.29 * s, (0, -0.23 * s, body_z + 0.02 * s), "wool",
                    subdiv=1),
        seed.sphere("wool_rump", 0.30 * s, (0, 0.27 * s, body_z), "wool", subdiv=1),
        seed.cylinder("neck", 0.11 * s, 0.23 * s,
                      (0, -0.40 * s, body_z + 0.12 * s), "sheep_face",
                      rot=(math.radians(55), 0, 0), segments=8),
        seed.sphere("head", 0.15 * s, (0, -0.52 * s, body_z + 0.22 * s), "sheep_face",
                    scale=(0.85, 1.1, 1.0), subdiv=2),
        seed.sphere("muzzle", 0.085 * s, (0, -0.63 * s, body_z + 0.16 * s), "sheep_face",
                    scale=(0.9, 1.1, 0.85), subdiv=1),
        seed.sphere("wool_tail", 0.09 * s, (0, 0.44 * s, body_z + 0.04 * s), "wool",
                    subdiv=1),
        seed.sphere("forelock", 0.095 * s, (0, -0.49 * s, body_z + 0.33 * s), "wool",
                    scale=(1.15, 0.95, 0.75), subdiv=1),
    ]
    for sx in (-1, 1):
        parts.append(seed.box(
            "ear", (0.09 * s, 0.04 * s, 0.05 * s),
            (sx * 0.15 * s, -0.50 * s, body_z + 0.28 * s), "sheep_face",
            rot=(0, sx * math.radians(14), sx * math.radians(32)),
        ))
    eyes(parts, [
        (-0.07 * s, -0.62 * s, body_z + 0.25 * s),
        (0.07 * s, -0.62 * s, body_z + 0.25 * s),
    ], 0.017 * s)
    return seed.scale_to_height(seed.join(parts, "fauna_lamb"), 0.64)


def build_grouse():
    """Grouse: plump ground bird with a fan tail, about 0.46 m tall."""
    parts = [
        seed.sphere("body", 0.19, (0, 0.03, 0.24), "feather",
                    scale=(1.0, 1.32, 1.0), subdiv=2),
        seed.sphere("breast", 0.155, (0, -0.14, 0.23), "feather_light",
                    scale=(1.0, 0.95, 1.0), subdiv=1),
        seed.sphere("head", 0.10, (0, -0.27, 0.38), "feather_dark",
                    scale=(0.95, 1.0, 0.95), subdiv=2),
        seed.cylinder("neck", 0.078, 0.13, (0, -0.22, 0.32), "feather_dark",
                      rot=(math.radians(35), 0, 0), segments=8),
        seed.cone("beak", 0.038, 0.10, (0, -0.375, 0.375), "horn",
                  radius2=0.004, segments=8, rot=(math.radians(-90), 0, 0)),
        seed.box("comb", (0.060, 0.032, 0.036), (0, -0.29, 0.465), "grouse_comb"),
    ]
    for sx in (-1, 1):
        parts.append(seed.sphere(
            "wing", 0.125, (sx * 0.165, 0.03, 0.25), "feather_dark",
            scale=(0.38, 1.18, 0.88), subdiv=1,
            rot=(0, 0, sx * math.radians(8)),
        ))
        parts.append(seed.cylinder(
            "leg", 0.018, 0.14, (sx * 0.055, -0.02, 0.070), "horn", segments=5,
        ))
        parts.append(seed.box(
            "foot", (0.080, 0.12, 0.018), (sx * 0.055, -0.065, 0.009), "horn",
        ))
    # Fan tail: five flattened feathers angled up and out.
    for index in range(5):
        angle = math.radians(-40 + 20 * index)
        parts.append(seed.box(
            f"tail_{index}", (0.080, 0.28, 0.020),
            (math.sin(angle) * 0.11, 0.26, 0.31 + math.cos(angle) * 0.02),
            "feather_dark" if index % 2 == 0 else "feather",
            rot=(math.radians(24), 0, angle),
        ))
    eyes(parts, [
        (-0.072, -0.33, 0.415), (0.072, -0.33, 0.415),
    ], 0.018)
    return seed.scale_to_height(seed.join(parts, "fauna_grouse"), 0.47)


def build_rabbit():
    """Rabbit: crouched bean, long ears, white scut, about 0.46 m tall."""
    parts = [
        seed.sphere("body", 0.155, (0, 0.03, 0.19), "fur",
                    scale=(0.92, 1.45, 0.98), subdiv=2),
        seed.sphere("haunch", 0.13, (0, 0.16, 0.17), "fur",
                    scale=(1.05, 1.0, 0.95), subdiv=1),
        seed.sphere("head", 0.105, (0, -0.18, 0.27), "fur",
                    scale=(0.95, 1.05, 0.95), subdiv=2),
        seed.sphere("muzzle", 0.06, (0, -0.26, 0.245), "fur_dark",
                    scale=(0.9, 1.05, 0.8), subdiv=1),
        seed.sphere("scut", 0.055, (0, 0.28, 0.21), "rabbit_tail", subdiv=1),
    ]
    for sx in (-1, 1):
        parts.append(seed.sphere(
            "ear", 0.045, (sx * 0.055, -0.15, 0.39), "fur",
            scale=(0.75, 0.85, 2.25), subdiv=2,
            rot=(math.radians(-17), sx * math.radians(8), 0),
        ))
        parts.append(seed.sphere(
            "ear_inner", 0.026, (sx * 0.055, -0.185, 0.378), "shell_band",
            scale=(0.52, 0.45, 1.75), subdiv=1,
            rot=(math.radians(-17), sx * math.radians(8), 0),
        ))
        parts.append(seed.cylinder(
            "front_leg", 0.022, 0.17, (sx * 0.06, -0.11, 0.085), "fur", segments=5,
        ))
        parts.append(seed.box(
            "hind_foot", (0.075, 0.19, 0.045), (sx * 0.085, 0.10, 0.023), "fur_dark",
        ))
    eyes(parts, [
        (-0.070, -0.245, 0.300), (0.070, -0.245, 0.300),
    ], 0.016)
    return seed.scale_to_height(seed.join(parts, "fauna_rabbit"), 0.47)


# ---------------------------------------------------------------------------
# Shore and trees
# ---------------------------------------------------------------------------

def build_conch():
    """Spiral conch with a flared opening, about 0.40 m long."""
    parts = [
        seed.sphere("body", 0.165, (0, 0.03, 0.13), "shell",
                    scale=(1.0, 1.35, 0.92), subdiv=2),
        seed.sphere("shoulder", 0.125, (0, 0.16, 0.20), "shell",
                    scale=(1.0, 0.95, 0.90), subdiv=1),
        seed.sphere("spire_1", 0.090, (0, 0.24, 0.27), "shell",
                    scale=(1.0, 0.90, 0.90), subdiv=1),
        seed.sphere("spire_2", 0.058, (0, 0.30, 0.33), "shell_band", subdiv=1),
        seed.sphere("spire_3", 0.034, (0, 0.34, 0.38), "shell_band", subdiv=1),
        seed.cone("lip", 0.160, 0.08, (0, -0.18, 0.12), "shell_inner",
                  radius2=0.100, segments=12, rot=(math.radians(-90), 0, 0)),
        seed.sphere("aperture", 0.120, (0, -0.245, 0.12), "shell_band",
                    scale=(0.50, 0.16, 1.00), subdiv=2),
    ]
    # Scalloped lip: a ring of small cream lobes around the aperture.
    for index in range(10):
        angle = math.tau * index / 10
        parts.append(seed.sphere(
            f"lip_lobe_{index}", 0.034,
            (math.cos(angle) * 0.145, -0.235, 0.12 + math.sin(angle) * 0.195),
            "shell_inner", scale=(1.0, 0.60, 1.20), subdiv=1,
        ))
    return ground(seed.join(parts, "env_shell_conch"))


def build_scallop():
    """Fan scallop with radial ribs, about 0.32 m wide."""
    parts = [
        seed.sphere("hinge", 0.055, (0, 0.10, 0.045), "shell_band",
                    scale=(1.2, 0.8, 0.7), subdiv=1),
    ]
    for index in range(7):
        angle = math.radians(-54 + 18 * index)
        direction = Vector((math.sin(angle), -math.cos(angle), 0))
        center = Vector((0, 0.05, 0.035)) + direction * 0.13
        parts.append(seed.box(
            f"rib_{index}", (0.045, 0.25, 0.028), center, "shell",
            rot=(0, 0, angle),
        ))
        parts.append(seed.box(
            f"rib_tip_{index}", (0.030, 0.035, 0.022),
            Vector((0, 0.05, 0.05)) + direction * 0.245, "shell_band",
            rot=(0, 0, angle),
        ))
    parts.append(seed.sphere("membrane", 0.16, (0, -0.02, 0.020), "shell_inner",
                             scale=(1.0, 1.0, 0.12), subdiv=2))
    return ground(seed.join(parts, "env_shell_scallop"))


def build_clam():
    """Half-open clam with a pearl, about 0.32 m wide."""
    parts = [
        seed.sphere("lower", 0.17, (0, 0, 0.050), "shell",
                    scale=(1.0, 1.12, 0.34), subdiv=2),
        seed.sphere("upper", 0.160, (0, 0.015, 0.160), "shell",
                    scale=(0.98, 1.08, 0.33), subdiv=2,
                    rot=(math.radians(-22), 0, 0)),
        seed.cylinder("hinge", 0.050, 0.14, (0, 0.16, 0.100), "shell_band",
                      rot=(math.radians(90), 0, 0), segments=8),
        seed.sphere("flesh", 0.120, (0, -0.01, 0.110), "shell_inner",
                    scale=(1.0, 1.02, 0.16), subdiv=2),
        seed.sphere("pearl", 0.032, (0, -0.105, 0.128), "shell_inner", subdiv=2),
    ]
    for index in range(5):
        angle = math.radians(-50 + 25 * index)
        parts.append(seed.box(
            f"rib_{index}", (0.018, 0.15, 0.012),
            (math.sin(angle) * 0.06, 0.03 - math.cos(angle) * 0.075, 0.186),
            "shell_band", rot=(math.radians(-13), 0, angle),
        ))
    return ground(seed.join(parts, "env_shell_clam"))


def build_gnarled_tree():
    """Sparse, wind-bent tree for the old-growth edge, about 5.4 m tall."""
    p0 = Vector((0.00, 0.00, 0.00))
    p1 = Vector((0.16, 0.05, 1.40))
    p2 = Vector((-0.10, 0.02, 2.65))
    p3 = Vector((0.12, -0.03, 3.75))
    d01 = (p1 - p0).normalized()
    d12 = (p2 - p1).normalized()
    parts = [
        # Overlap the segments so the internal caps stay hidden at the kinks.
        _tapered("trunk_low", p0, p1 + d01 * 0.10, 0.32, 0.24, "bark", segments=10),
        _tapered("trunk_mid", p1 - d01 * 0.10, p2 + d12 * 0.10, 0.24, 0.15,
                 "bark", segments=10),
        _tapered("trunk_high", p2 - d12 * 0.10, p3, 0.15, 0.075, "bark", segments=8),
        _tapered("knot_low", p1 - d01 * 0.07, p1 + d01 * 0.07, 0.275, 0.255,
                 "bark", segments=10),
        _tapered("knot_high", p2 - d12 * 0.06, p2 + d12 * 0.06, 0.175, 0.160,
                 "bark", segments=10),
    ]
    for index in range(5):
        angle = math.tau * index / 5 + 0.3
        parts.append(_tapered(
            f"root_{index}", (0, 0, 0.16),
            (math.cos(angle) * 0.75, math.sin(angle) * 0.65, 0.015),
            0.105, 0.020, "bark", segments=6,
        ))
    branches = [
        (p2, (1.35, 0.25, 3.35), 0.10, 0.045),
        (p2, (-1.20, -0.30, 3.55), 0.09, 0.040),
        (p3, (0.55, 0.70, 4.25), 0.08, 0.035),
        (p3, (-0.65, -0.55, 4.45), 0.07, 0.030),
        (p3, (0.15, -0.55, 4.85), 0.06, 0.025),
        (p3, (0.40, -0.10, 4.60), 0.05, 0.020),
    ]
    for start, end, radius_start, radius_end in branches:
        parts.append(_tapered("branch", start, end, radius_start, radius_end,
                              "bark", segments=6))
    canopy = [
        (1.30, 0.20, 3.55, 0.74, "leaf"),
        (-1.15, -0.25, 3.75, 0.68, "leaf_dark"),
        (0.50, 0.65, 4.40, 0.62, "leaf"),
        (-0.60, -0.50, 4.60, 0.56, "leaf_dark"),
        (0.20, -0.45, 4.95, 0.46, "leaf"),
        (0.20, 0.05, 4.35, 0.82, "leaf_dark"),
    ]
    for x, y, z, radius, mat in canopy:
        parts.append(seed.sphere("canopy", radius, (x, y, z), mat,
                                 scale=(1.0, 1.0, 0.75), subdiv=1))
    return seed.join(parts, "env_tree_gnarled")


# ---------------------------------------------------------------------------
# Previews
# ---------------------------------------------------------------------------

def _ground_plane(size, material_name):
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=size)
    mesh = bpy.data.meshes.new("ground")
    bm.to_mesh(mesh)
    bm.free()
    plane = bpy.data.objects.new("ground", mesh)
    bpy.context.scene.collection.objects.link(plane)
    plane.data.materials.append(seed.material(material_name))
    return plane


def render_fauna_preview():
    seed.reset_scene()
    seed.setup_world("#C9D3CB", 1.0)
    seed.setup_render(1600, 900, samples=48)
    _ground_plane(30.0, "grass")
    seed.add_light("sun", "SUN", (0, 0, 12), 4.2, "#FFE8C8",
                   rotation=(math.radians(62), 0, math.radians(-38)))
    seed.add_light("fill", "AREA", (-9, -8, 7), 1500, "#8FB4C4",
                   rotation=(math.radians(52), 0, math.radians(-40)), size=10.0)

    layout = [
        (build_sheep, (-2.9, 0.9), 0),
        (build_ram, (-0.2, 1.0), 0),
        (build_lamb, (2.3, 1.1), -12),
        (build_grouse, (-1.4, -0.7), 42),
        (build_rabbit, (0.7, -0.6), 15),
    ]
    for builder, (x, y), turn in layout:
        obj = builder()
        obj.location = (x, y, 0)
        obj.rotation_euler.z = math.radians(turn)

    seed.setup_camera((0.0, -6.8, 1.7), (0.0, 0.3, 0.55), lens=38.0)
    path = os.path.join(PREVIEW_DIR, "fauna_preview.png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def render_shells_preview():
    seed.reset_scene()
    seed.setup_world("#C9D3CB", 1.0)
    seed.setup_render(1200, 700, samples=48)
    _ground_plane(20.0, "sand")
    seed.add_light("sun", "SUN", (0, 0, 10), 3.8, "#FFE8C8",
                   rotation=(math.radians(58), 0, math.radians(-40)))
    seed.add_light("fill", "AREA", (-5, -5, 5), 900, "#8FB4C4",
                   rotation=(math.radians(50), 0, math.radians(-40)), size=6.0)
    for builder, x, turn in (
        (build_conch, -0.52, 30),
        (build_scallop, 0.02, -8),
        (build_clam, 0.50, 10),
    ):
        obj = builder()
        obj.location = (x, 0, 0)
        obj.rotation_euler.z = math.radians(turn)
    seed.setup_camera((0.2, -2.7, 1.25), (0.0, 0.0, 0.12), lens=52.0)
    path = os.path.join(PREVIEW_DIR, "shells_preview.png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def render_tree_preview():
    seed.reset_scene()
    seed.setup_world("#C9D3CB", 1.0)
    seed.setup_render(1200, 800, samples=48)
    _ground_plane(30.0, "grass")
    seed.add_light("sun", "SUN", (0, 0, 12), 3.8, "#FFE8C8",
                   rotation=(math.radians(60), 0, math.radians(-35)))
    seed.add_light("fill", "AREA", (-8, -8, 6), 1200, "#8FB4C4",
                   rotation=(math.radians(55), 0, math.radians(-40)), size=8.0)
    build_gnarled_tree()
    seed.setup_camera((6.5, -8.5, 4.4), (0.0, 0.0, 2.2), lens=45.0)
    path = os.path.join(PREVIEW_DIR, "gnarled_tree_preview.png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def render_biome_preview():
    """Hero shot: sheep flock, grouse, rabbit, shells and the old-growth edge."""
    seed.reset_scene()
    seed.setup_world("#C9D3CB", 1.05)
    seed.setup_render(1600, 900, samples=64)
    _ground_plane(60.0, "grass")
    # Shallow sand shelf on the right, where the shells sit.
    seed.sphere("sand_shelf", 3.0, (4.2, -1.9, 0.01), "sand",
                scale=(1.45, 1.0, 0.012), subdiv=2)

    seed.add_light("sun", "SUN", (0, 0, 14), 4.0, "#FFE8C8",
                   rotation=(math.radians(64), 0, math.radians(-42)))
    seed.add_light("fill", "AREA", (-10, -8, 8), 1800, "#8FB4C4",
                   rotation=(math.radians(52), 0, math.radians(-40)), size=12.0)

    for builder, (x, y), turn in (
        (seed.build_tree_a, (-6.5, 6.0), 0),
        (seed.build_tree_b, (5.5, 6.5), 40),
        (build_gnarled_tree, (-3.0, 3.6), -20),
    ):
        obj = builder()
        obj.location = (x, y, 0)
        obj.rotation_euler.z = math.radians(turn)

    for builder, (x, y), turn in (
        (seed.build_rock, (-7.5, 1.5), 25),
        (seed.build_berry_bush, (-5.0, 1.0), 0),
    ):
        obj = builder()
        obj.location = (x, y, 0)
        obj.rotation_euler.z = math.radians(turn)

    for builder, (x, y), turn in (
        (build_sheep, (-2.4, 1.2), 0),
        (build_sheep, (0.0, 1.7), 25),
        (build_ram, (2.2, 1.1), -8),
        (build_lamb, (1.1, 0.2), 15),
        (build_grouse, (-2.4, -1.3), 40),
        (build_rabbit, (2.4, -0.9), 15),
    ):
        obj = builder()
        obj.location = (x, y, 0)
        obj.rotation_euler.z = math.radians(turn)

    for builder, (x, y), turn in (
        (build_conch, (4.7, -1.5), 55),
        (build_scallop, (4.0, -2.3), -10),
        (build_clam, (3.4, -1.6), 20),
    ):
        obj = builder()
        obj.location = (x, y, 0)
        obj.rotation_euler.z = math.radians(turn)

    seed.setup_camera((0.0, -16.0, 4.0), (0.0, 1.0, 1.4), lens=35.0)
    path = os.path.join(PREVIEW_DIR, "fauna_biome_preview.png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    os.makedirs(FAUNA_DIR, exist_ok=True)
    os.makedirs(NATURE_DIR, exist_ok=True)
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    exports = [
        (build_sheep, FAUNA_DIR),
        (build_ram, FAUNA_DIR),
        (build_lamb, FAUNA_DIR),
        (build_grouse, FAUNA_DIR),
        (build_rabbit, FAUNA_DIR),
        (build_conch, NATURE_DIR),
        (build_scallop, NATURE_DIR),
        (build_clam, NATURE_DIR),
        (build_gnarled_tree, NATURE_DIR),
    ]
    for builder, folder in exports:
        seed.reset_scene()
        obj = builder()
        path = os.path.join(folder, f"{obj.name}.glb")
        seed.export_glb(obj, path)
        print(f"EXPORTED {os.path.basename(path)} tris={seed.tri_count(obj)}")

    print("PREVIEW", render_fauna_preview())
    print("PREVIEW", render_shells_preview())
    print("PREVIEW", render_tree_preview())
    print("PREVIEW", render_biome_preview())


if __name__ == "__main__":
    main()
