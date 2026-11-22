"""Procedural ship models for Seed.

Run with Blender headless:

    blender -b --python tools/blender/build_ship_models.py -- kit
    blender -b --python tools/blender/build_ship_models.py -- shells
    blender -b --python tools/blender/build_ship_models.py -- exterior
    blender -b --python tools/blender/build_ship_models.py -- all

Outputs glTF 2.0 (.glb) under assets/models/ship/.
The script is intentionally data-light: primitives, flat shading, simple PBR.
"""

from __future__ import annotations

import math
import os
import sys

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "models", "ship")
TAU = math.tau
R = math.radians


# ---------------------------------------------------------------------------
# Scene / material helpers
# ---------------------------------------------------------------------------


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.engine = "BLENDER_EEVEE"


def mat(
    name: str,
    color: tuple[float, float, float],
    metallic: float = 0.0,
    roughness: float = 0.65,
    emission: tuple[float, float, float] | None = None,
    strength: float = 2.0,
    alpha: float = 1.0,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission is not None:
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
            bsdf.inputs["Emission Strength"].default_value = strength
        else:
            bsdf.inputs["Emission"].default_value = (*emission, 1.0)
            bsdf.inputs["Emission Strength"].default_value = strength
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        try:
            material.blend_method = "BLEND"
        except Exception:
            pass
        try:
            material.surface_render_method = "BLENDED"
        except Exception:
            pass
    return material


def palette() -> dict[str, bpy.types.Material]:
    return {
        "ceramic": mat("M_ceramic", (0.72, 0.69, 0.62), 0.05, 0.62),
        "panel": mat("M_panel", (0.55, 0.57, 0.53), 0.15, 0.68),
        "metal": mat("M_metal", (0.26, 0.30, 0.29), 0.70, 0.46),
        "dark": mat("M_dark", (0.07, 0.09, 0.09), 0.35, 0.72),
        "floor": mat("M_floor", (0.34, 0.36, 0.35), 0.35, 0.78),
        "grating": mat("M_grating", (0.20, 0.23, 0.22), 0.55, 0.62),
        "amber": mat("M_amber", (0.88, 0.42, 0.14), 0.0, 0.45, (1.0, 0.42, 0.10), 1.4),
        "cyan": mat("M_cyan", (0.22, 0.62, 0.72), 0.0, 0.35, (0.32, 0.78, 0.92), 1.6),
        "med": mat("M_med", (0.82, 0.81, 0.74), 0.0, 0.55),
        "red": mat("M_red", (0.55, 0.10, 0.08), 0.0, 0.5, (0.95, 0.12, 0.08), 2.4),
        "green": mat("M_green", (0.24, 0.42, 0.24), 0.0, 0.8),
        "rubber": mat("M_rubber", (0.06, 0.07, 0.07), 0.0, 0.92),
        "glass": mat("M_glass", (0.10, 0.24, 0.28), 0.0, 0.12, (0.18, 0.55, 0.65), 1.2, 0.42),
        "hazard": mat("M_hazard", (0.82, 0.42, 0.10), 0.0, 0.62),
    }


# ---------------------------------------------------------------------------
# Primitive helpers
# ---------------------------------------------------------------------------


def box(
    name: str,
    size: tuple[float, float, float],
    loc: tuple[float, float, float],
    material: bpy.types.Material | None,
    rot: tuple[float, float, float] = (0.0, 0.0, 0.0),
    bevel: float = 0.0,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    obj = bpy.context.object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material is not None:
        obj.data.materials.append(material)
    if bevel > 0.0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_flat()
    return obj


def cylinder(
    name: str,
    radius: float,
    depth: float,
    loc: tuple[float, float, float],
    material: bpy.types.Material | None,
    rot: tuple[float, float, float] = (0.0, 0.0, 0.0),
    verts: int = 12,
    bevel: float = 0.0,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=radius, depth=depth, location=loc, rotation=rot
    )
    obj = bpy.context.object
    obj.name = name
    if material is not None:
        obj.data.materials.append(material)
    if bevel > 0.0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_flat()
    return obj


def cone(
    name: str,
    r1: float,
    r2: float,
    depth: float,
    loc: tuple[float, float, float],
    material: bpy.types.Material | None,
    rot: tuple[float, float, float] = (0.0, 0.0, 0.0),
    verts: int = 16,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(
        vertices=verts, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot
    )
    obj = bpy.context.object
    obj.name = name
    if material is not None:
        obj.data.materials.append(material)
    bpy.ops.object.shade_flat()
    return obj


def torus(
    name: str,
    major: float,
    minor: float,
    loc: tuple[float, float, float],
    material: bpy.types.Material | None,
    rot: tuple[float, float, float] = (0.0, 0.0, 0.0),
    major_segments: int = 32,
    minor_segments: int = 8,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major,
        minor_radius=minor,
        major_segments=major_segments,
        minor_segments=minor_segments,
        location=loc,
        rotation=rot,
    )
    obj = bpy.context.object
    obj.name = name
    if material is not None:
        obj.data.materials.append(material)
    bpy.ops.object.shade_flat()
    return obj


def join(objs: list[bpy.types.Object], name: str, origin=(0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    result = bpy.context.object
    result.name = name
    bpy.context.scene.cursor.location = origin
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return result


def export(name: str, objs: list[bpy.types.Object], folder: str = "misc") -> None:
    target_dir = os.path.join(OUT, folder)
    os.makedirs(target_dir, exist_ok=True)
    path = os.path.join(target_dir, name + ".glb")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objs:
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_texcoords=False,
        export_normals=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
    print(f"[ship] wrote {path}")


def collision_object(name: str, boxes: list[tuple[tuple[float, float, float], tuple[float, float, float]]]):
    """Build a collision mesh. Godot imports a node named *-col as StaticBody3D."""
    parts = []
    for index, (size, loc) in enumerate(boxes):
        parts.append(box(f"{name}_part{index}", size, loc, None))
    obj = join(parts, name + "-colonly")
    obj.data.materials.clear()
    return obj


# ---------------------------------------------------------------------------
# Shared room / corridor shells
# ---------------------------------------------------------------------------


def wall_segments(
    wall: str,
    sx: float,
    sy: float,
    sz: float,
    thickness: float,
    doors: list[dict],
    material: bpy.types.Material,
    prefix: str,
    collision: bool = False,
) -> list[bpy.types.Object]:
    """Build one wall with rectangular door openings, no booleans."""
    specs = [d for d in doors if d.get("wall") == wall]
    horizontal = wall in ("n", "s")
    length = sx if horizontal else sy
    if wall == "n":
        wall_y = -sy / 2.0 - thickness / 2.0
    elif wall == "s":
        wall_y = sy / 2.0 + thickness / 2.0
    elif wall == "w":
        wall_x = -sx / 2.0 - thickness / 2.0
    else:
        wall_x = sx / 2.0 + thickness / 2.0

    objs: list[bpy.types.Object] = []
    cursor = -length / 2.0
    sorted_specs = sorted(specs, key=lambda d: float(d.get("offset", 0.0)))
    for spec in sorted_specs:
        off = float(spec.get("offset", 0.0))
        width = float(spec.get("width", 2.4))
        height = float(spec.get("height", 3.2))
        start = off - width / 2.0
        end = off + width / 2.0
        if start > cursor:
            seg_len = start - cursor
            mid = cursor + seg_len / 2.0
            if horizontal:
                objs.append(
                    box(f"{prefix}_{wall}_seg", (seg_len, thickness, sz), (mid, wall_y, sz / 2.0), material)
                )
            else:
                objs.append(
                    box(f"{prefix}_{wall}_seg", (thickness, seg_len, sz), (wall_x, mid, sz / 2.0), material)
                )
        if sz > height:
            lintel_h = sz - height
            if horizontal:
                objs.append(
                    box(
                        f"{prefix}_{wall}_lintel",
                        (width, thickness, lintel_h),
                        (off, wall_y, height + lintel_h / 2.0),
                        material,
                    )
                )
            else:
                objs.append(
                    box(
                        f"{prefix}_{wall}_lintel",
                        (thickness, width, lintel_h),
                        (wall_x, off, height + lintel_h / 2.0),
                        material,
                    )
                )
        cursor = end
    if cursor < length / 2.0:
        seg_len = length / 2.0 - cursor
        mid = cursor + seg_len / 2.0
        if horizontal:
            objs.append(
                box(f"{prefix}_{wall}_seg", (seg_len, thickness, sz), (mid, wall_y, sz / 2.0), material)
            )
        else:
            objs.append(
                box(f"{prefix}_{wall}_seg", (thickness, seg_len, sz), (wall_x, mid, sz / 2.0), material)
            )
    return objs


def room_shell(
    name: str,
    sx: float,
    sy: float,
    sz: float,
    doors: list[dict],
    accent_key: str,
    wall_key: str,
    floor_key: str,
    rib_key: str,
    seam_key: str,
    window: dict | None = None,
) -> tuple[bpy.types.Object, bpy.types.Object]:
    reset()
    M = palette()
    accent = M[accent_key]
    wall_material = M[wall_key]
    floor_material = M[floor_key]
    rib_material = M[rib_key]
    seam_material = M[seam_key]
    thickness = 0.25
    objs: list[bpy.types.Object] = []
    coll: list[tuple[tuple[float, float, float], tuple[float, float, float]]] = []

    # Floor and ceiling.
    objs.append(box(f"{name}_floor", (sx, sy, 0.2), (0, 0, -0.1), floor_material))
    objs.append(box(f"{name}_ceiling", (sx, sy, 0.2), (0, 0, sz + 0.1), M["panel"]))
    coll.append(((sx, sy, 0.2), (0, 0, -0.1)))
    coll.append(((sx, sy, 0.2), (0, 0, sz + 0.1)))

    # Walls with door gaps.
    for wall in ("n", "s", "e", "w"):
        wall_objs = wall_segments(wall, sx, sy, sz, thickness, doors, wall_material, name)
        objs.extend(wall_objs)
        for obj in wall_objs:
            coll.append((tuple(obj.dimensions), tuple(obj.location)))

    # Door frames.
    for door in doors:
        wall = door.get("wall", "n")
        off = float(door.get("offset", 0.0))
        width = float(door.get("width", 2.4))
        height = float(door.get("height", 3.2))
        if wall in ("n", "s"):
            y = (-sy / 2.0 - thickness) if wall == "n" else (sy / 2.0 + thickness)
            objs.append(box(f"{name}_{wall}_frame_l", (0.16, 0.35, height + 0.16), (off - width / 2.0 - 0.08, y, (height + 0.16) / 2.0), rib_material))
            objs.append(box(f"{name}_{wall}_frame_r", (0.16, 0.35, height + 0.16), (off + width / 2.0 + 0.08, y, (height + 0.16) / 2.0), rib_material))
            objs.append(box(f"{name}_{wall}_frame_t", (width + 0.32, 0.35, 0.16), (off, y, height + 0.08), rib_material))
        else:
            x = (-sx / 2.0 - thickness) if wall == "w" else (sx / 2.0 + thickness)
            objs.append(box(f"{name}_{wall}_frame_l", (0.35, 0.16, height + 0.16), (x, off - width / 2.0 - 0.08, (height + 0.16) / 2.0), rib_material))
            objs.append(box(f"{name}_{wall}_frame_r", (0.35, 0.16, height + 0.16), (x, off + width / 2.0 + 0.08, (height + 0.16) / 2.0), rib_material))
            objs.append(box(f"{name}_{wall}_frame_t", (0.35, width + 0.32, 0.16), (x, off, height + 0.08), rib_material))

    # Structural ribs every 4 m.
    step = 4.0
    x = -sx / 2.0 + step
    while x < sx / 2.0 - 0.1:
        objs.append(box(f"{name}_rib_n", (0.18, 0.16, sz), (x, -sy / 2.0 + 0.08, sz / 2.0), rib_material))
        objs.append(box(f"{name}_rib_s", (0.18, 0.16, sz), (x, sy / 2.0 - 0.08, sz / 2.0), rib_material))
        x += step
    y = -sy / 2.0 + step
    while y < sy / 2.0 - 0.1:
        objs.append(box(f"{name}_rib_w", (0.16, 0.18, sz), (-sx / 2.0 + 0.08, y, sz / 2.0), rib_material))
        objs.append(box(f"{name}_rib_e", (0.16, 0.18, sz), (sx / 2.0 - 0.08, y, sz / 2.0), rib_material))
        y += step

    # Floor seams.
    x = -sx / 2.0 + step
    while x < sx / 2.0 - 0.1:
        objs.append(box(f"{name}_seam_x", (0.035, sy, 0.018), (x, 0, 0.011), seam_material))
        x += step
    y = -sy / 2.0 + step
    while y < sy / 2.0 - 0.1:
        objs.append(box(f"{name}_seam_y", (sx, 0.035, 0.018), (0, y, 0.011), seam_material))
        y += step

    # Accent light strips at knee and shoulder height.
    objs.append(box(f"{name}_light_n", (sx - 0.6, 0.05, 0.05), (0, -sy / 2.0 + 0.11, 2.55), accent))
    objs.append(box(f"{name}_light_s", (sx - 0.6, 0.05, 0.05), (0, sy / 2.0 - 0.11, 2.55), accent))
    objs.append(box(f"{name}_light_w", (0.05, sy - 0.6, 0.05), (-sx / 2.0 + 0.11, 0, 2.55), accent))
    objs.append(box(f"{name}_light_e", (0.05, sy - 0.6, 0.05), (sx / 2.0 - 0.11, 0, 2.55), accent))
    objs.append(box(f"{name}_base_n", (sx - 0.4, 0.08, 0.09), (0, -sy / 2.0 + 0.12, 0.05), accent))
    objs.append(box(f"{name}_base_s", (sx - 0.4, 0.08, 0.09), (0, sy / 2.0 - 0.12, 0.05), accent))

    # Optional window dressing (no actual hole).
    if window:
        wx = window.get("x", -sx / 2.0 + 0.13)
        wy = window.get("y", 0.0)
        ww = window.get("width", 8.0)
        wh = window.get("height", 2.2)
        wz = window.get("z", 3.2)
        objs.append(box(f"{name}_window_frame", (0.10, ww + 0.4, wh + 0.4), (wx, wy, wz), rib_material))
        objs.append(box(f"{name}_window_glass", (0.06, ww, wh), (wx + 0.04, wy, wz), M["glass"]))

    shell = join(objs, name)
    collision = collision_object(name + "_collision", coll)
    return shell, collision


def tunnel_shell(name: str, length: float, width: float, height: float, accent_key: str) -> tuple[bpy.types.Object, bpy.types.Object]:
    reset()
    M = palette()
    accent = M[accent_key]
    objs: list[bpy.types.Object] = []
    coll: list[tuple[tuple[float, float, float], tuple[float, float, float]]] = []
    objs.append(box(f"{name}_floor", (width, length, 0.2), (0, 0, -0.1), M["floor"]))
    objs.append(box(f"{name}_ceil", (width, length, 0.2), (0, 0, height + 0.1), M["panel"]))
    coll.append(((width, length, 0.2), (0, 0, -0.1)))
    coll.append(((width, length, 0.2), (0, 0, height + 0.1)))
    for side in (-1, 1):
        x = side * (width / 2.0 + 0.125)
        objs.append(box(f"{name}_wall", (0.25, length, height), (x, 0, height / 2.0), M["ceramic"]))
        coll.append(((0.25, length, height), (x, 0, height / 2.0)))
        objs.append(box(f"{name}_trim", (0.30, length, 0.12), (side * (width / 2.0 - 0.02), 0, 2.55), M["metal"]))
    step = 4.0
    y = -length / 2.0 + step
    while y < length / 2.0 - 0.1:
        objs.append(box(f"{name}_rib_l", (0.18, 0.18, height), (-width / 2.0 + 0.09, y, height / 2.0), M["metal"]))
        objs.append(box(f"{name}_rib_r", (0.18, 0.18, height), (width / 2.0 - 0.09, y, height / 2.0), M["metal"]))
        objs.append(box(f"{name}_seam", (width, 0.035, 0.018), (0, y, 0.011), M["dark"]))
        y += step
    for side in (-1, 1):
        x = side * (width / 2.0 - 0.12)
        objs.append(box(f"{name}_light", (0.05, length - 0.4, 0.05), (x, 0, 2.45), accent))
        objs.append(box(f"{name}_base", (0.08, length - 0.4, 0.09), (x, 0, 0.05), accent))
    shell = join(objs, name)
    collision = collision_object(name + "_collision", coll)
    return shell, collision


def junction_shell(name: str = "env_ship_junction_12m") -> tuple[bpy.types.Object, bpy.types.Object]:
    doors = [
        {"wall": "n", "offset": 0.0, "width": 4.5, "height": 3.6},
        {"wall": "s", "offset": 0.0, "width": 4.5, "height": 3.6},
        {"wall": "e", "offset": 0.0, "width": 4.5, "height": 3.6},
        {"wall": "w", "offset": 0.0, "width": 2.4, "height": 3.2},
    ]
    return room_shell(
        name,
        12.0,
        12.0,
        4.2,
        doors,
        "amber",
        "ceramic",
        "floor",
        "metal",
        "dark",
    )


# ---------------------------------------------------------------------------
# Kit assets
# ---------------------------------------------------------------------------


def build_kit() -> None:
    reset()
    M = palette()
    export(
        "env_ship_floor_4x4",
        [join([
            box("Slab", (4, 4, 0.2), (0, 0, -0.1), M["floor"]),
            box("SeamX", (4, 0.05, 0.02), (0, 0, 0.011), M["dark"]),
            box("SeamY", (0.05, 4, 0.02), (0, 0, 0.011), M["dark"]),
            box("TrimA", (4, 0.12, 0.05), (0, 1.92, 0.025), M["metal"]),
            box("TrimB", (4, 0.12, 0.05), (0, -1.92, 0.025), M["metal"]),
        ], "env_ship_floor_4x4")],
        "kit",
    )

    reset()
    M = palette()
    export(
        "env_ship_wall_4x3",
        [join([
            box("Panel", (4, 0.25, 3.2), (0, 0, 1.6), M["ceramic"]),
            box("Inset", (3.3, 0.06, 2.1), (0, -0.155, 1.55), M["panel"]),
            box("RibL", (0.20, 0.36, 3.2), (-1.9, -0.03, 1.6), M["metal"]),
            box("RibR", (0.20, 0.36, 3.2), (1.9, -0.03, 1.6), M["metal"]),
            box("Base", (4, 0.36, 0.16), (0, -0.03, 0.08), M["dark"]),
            box("Top", (4, 0.36, 0.12), (0, -0.03, 3.08), M["metal"]),
            box("Light", (3.0, 0.05, 0.04), (0, -0.20, 2.55), M["amber"]),
        ], "env_ship_wall_4x3")],
        "kit",
    )

    reset()
    M = palette()
    export(
        "env_ship_ceiling_4x4",
        [join([
            box("Slab", (4, 4, 0.2), (0, 0, 0.1), M["panel"]),
            box("Housing", (3.2, 0.30, 0.10), (0, 0, 0.05), M["metal"]),
            box("Light", (2.7, 0.14, 0.03), (0, 0, -0.015), M["amber"]),
            box("Seam", (4, 0.05, 0.02), (0, 0, -0.01), M["dark"]),
        ], "env_ship_ceiling_4x4")],
        "kit",
    )

    shell, collision = tunnel_shell("env_ship_corridor_8m", 8.0, 4.5, 3.6, "amber")
    export("env_ship_corridor_8m", [shell, collision], "kit")

    shell, collision = junction_shell()
    export("env_ship_junction_12m", [shell, collision], "kit")

    shell, collision = room_shell(
        "env_ship_airlock_8x6",
        8.0,
        6.0,
        3.6,
        [
            {"wall": "w", "offset": 0.0, "width": 2.4, "height": 3.2},
            {"wall": "e", "offset": 0.0, "width": 3.0, "height": 3.2},
        ],
        "amber",
        "ceramic",
        "floor",
        "metal",
        "dark",
    )
    export("env_ship_airlock_8x6", [shell, collision], "kit")

    # Door props.
    reset()
    M = palette()
    door = join([
        box("FrameL", (0.18, 0.4, 3.36), (-1.29, 0, 1.68), M["metal"]),
        box("FrameR", (0.18, 0.4, 3.36), (1.29, 0, 1.68), M["metal"]),
        box("FrameT", (2.76, 0.4, 0.18), (0, 0, 3.27), M["metal"]),
        box("Panel", (2.4, 0.16, 3.2), (0, 0.02, 1.6), M["ceramic"]),
        box("Brace", (2.0, 0.04, 0.12), (0, -0.07, 2.0), M["hazard"]),
        box("Brace2", (2.0, 0.04, 0.12), (0, -0.07, 1.1), M["hazard"]),
        box("Handle", (0.12, 0.22, 0.5), (0.9, -0.14, 1.3), M["metal"]),
        box("Screen", (0.34, 0.03, 0.24), (-0.9, -0.10, 1.5), M["cyan"]),
    ], "prop_bulkhead_door")
    export("prop_bulkhead_door", [door], "props")

    reset()
    M = palette()
    sealed = join([
        box("FrameL", (0.22, 0.5, 3.4), (-1.32, 0, 1.7), M["metal"]),
        box("FrameR", (0.22, 0.5, 3.4), (1.32, 0, 1.7), M["metal"]),
        box("FrameT", (2.86, 0.5, 0.22), (0, 0, 3.3), M["metal"]),
        box("Panel", (2.4, 0.22, 3.2), (0, 0.02, 1.6), M["dark"]),
        box("BraceA", (2.7, 0.08, 0.22), (0, -0.14, 1.0), M["hazard"]),
        box("BraceB", (2.7, 0.08, 0.22), (0, -0.14, 2.2), M["hazard"]),
        box("Lock", (0.5, 0.16, 0.5), (0.8, -0.18, 1.55), M["metal"]),
        box("Status", (0.34, 0.06, 0.16), (0.8, -0.27, 1.55), M["red"]),
    ], "prop_sealed_door")
    export("prop_sealed_door", [sealed], "props")

    # Small reusable props.
    reset()
    M = palette()
    crate = join([
        box("Body", (1.2, 0.8, 0.8), (0, 0, 0.4), M["panel"], bevel=0.03),
        box("BandA", (1.22, 0.08, 0.08), (0, -0.35, 0.65), M["metal"]),
        box("BandB", (1.22, 0.08, 0.08), (0, 0.35, 0.65), M["metal"]),
        box("Stripe", (1.0, 0.02, 0.12), (0, -0.41, 0.25), M["hazard"]),
    ], "prop_crate_a")
    export("prop_crate_a", [crate], "props")

    reset()
    M = palette()
    console = join([
        box("Base", (1.2, 0.8, 0.9), (0, 0, 0.45), M["dark"]),
        box("Top", (1.3, 0.9, 0.12), (0, 0, 0.94), M["metal"], bevel=0.02),
        box("Screen", (0.9, 0.06, 0.5), (0, -0.28, 1.15), M["cyan"], rot=(R(-18), 0, 0)),
        box("Key", (0.7, 0.3, 0.04), (0, 0.15, 1.02), M["panel"]),
    ], "prop_console")
    export("prop_console", [console], "props")

    reset()
    M = palette()
    shelf = join([
        box("UprightL", (0.12, 1.2, 2.4), (-1.94, 0, 1.2), M["metal"]),
        box("UprightR", (0.12, 1.2, 2.4), (1.94, 0, 1.2), M["metal"]),
        box("ShelfA", (4.0, 1.2, 0.1), (0, 0, 0.45), M["panel"]),
        box("ShelfB", (4.0, 1.2, 0.1), (0, 0, 1.25), M["panel"]),
        box("ShelfC", (4.0, 1.2, 0.1), (0, 0, 2.05), M["panel"]),
        box("ShelfD", (4.0, 1.2, 0.1), (0, 0, 2.35), M["panel"]),
    ], "prop_shelf_4m")
    export("prop_shelf_4m", [shelf], "props")

    reset()
    M = palette()
    tray = join([
        box("Tray", (4.0, 0.34, 0.10), (0, 0, 0), M["metal"]),
        box("LipA", (4.0, 0.04, 0.12), (0, -0.17, 0.05), M["metal"]),
        box("LipB", (4.0, 0.04, 0.12), (0, 0.17, 0.05), M["metal"]),
        cylinder("CableA", 0.05, 3.8, (0, -0.05, 0.10), M["dark"], rot=(0, R(90), 0), verts=6),
        cylinder("CableB", 0.035, 3.8, (0, 0.05, 0.12), M["rubber"], rot=(0, R(90), 0), verts=6),
    ], "prop_cable_tray_4m")
    export("prop_cable_tray_4m", [tray], "props")

    reset()
    M = palette()
    pipes = join([
        cylinder("PipeA", 0.10, 4.0, (0, 0, 0), M["metal"], rot=(0, R(90), 0), verts=10),
        cylinder("PipeB", 0.07, 4.0, (0, 0.24, 0.05), M["panel"], rot=(0, R(90), 0), verts=10),
        box("ClampA", (0.12, 0.36, 0.28), (-1.8, 0.12, 0.02), M["dark"]),
        box("ClampB", (0.12, 0.36, 0.28), (1.8, 0.12, 0.02), M["dark"]),
    ], "prop_pipe_run_4m")
    export("prop_pipe_run_4m", [pipes], "props")

    reset()
    M = palette()
    strip = join([
        box("Housing", (2.0, 0.12, 0.10), (0, 0, 0), M["metal"]),
        box("Glow", (1.85, 0.07, 0.04), (0, -0.03, -0.06), M["amber"]),
    ], "prop_light_strip_2m")
    export("prop_light_strip_2m", [strip], "props")

    reset()
    M = palette()
    rail = join([
        cylinder("PostA", 0.05, 1.1, (-0.9, 0, 0.55), M["metal"], verts=8),
        cylinder("PostB", 0.05, 1.1, (0.9, 0, 0.55), M["metal"], verts=8),
        cylinder("Top", 0.05, 2.0, (0, 0, 1.08), M["hazard"], rot=(0, R(90), 0), verts=8),
        cylinder("Mid", 0.035, 2.0, (0, 0, 0.6), M["metal"], rot=(0, R(90), 0), verts=8),
    ], "prop_railing_2m")
    export("prop_railing_2m", [rail], "props")

    reset()
    M = palette()
    vent = join([
        box("Frame", (1.0, 0.1, 1.0), (0, 0, 0.5), M["metal"]),
        box("SlatA", (0.9, 0.03, 0.06), (0, -0.07, 0.22), M["dark"]),
        box("SlatB", (0.9, 0.03, 0.06), (0, -0.07, 0.36), M["dark"]),
        box("SlatC", (0.9, 0.03, 0.06), (0, -0.07, 0.50), M["dark"]),
        box("SlatD", (0.9, 0.03, 0.06), (0, -0.07, 0.64), M["dark"]),
        box("SlatE", (0.9, 0.03, 0.06), (0, -0.07, 0.78), M["dark"]),
    ], "prop_vent_1m")
    export("prop_vent_1m", [vent], "props")


# ---------------------------------------------------------------------------
# Hero props
# ---------------------------------------------------------------------------


def build_props() -> None:
    # Cryo pod.
    reset()
    M = palette()
    pod = join([
        box("Base", (2.2, 1.2, 0.22), (0, 0, 0.11), M["metal"], bevel=0.03),
        box("Body", (2.2, 1.2, 0.62), (0, 0, 0.53), M["ceramic"], bevel=0.09),
        box("Well", (1.8, 0.9, 0.10), (0, 0, 0.88), M["dark"]),
        box("Lid", (2.1, 1.1, 0.18), (0, 0, 1.06), M["metal"], bevel=0.05),
        box("Glass", (1.7, 0.85, 0.08), (0, 0, 1.16), M["glass"], bevel=0.03),
        box("Screen", (0.36, 0.04, 0.26), (0.82, -0.62, 0.72), M["cyan"]),
        box("StripA", (0.04, 1.02, 0.04), (-1.06, 0, 0.72), M["cyan"]),
        box("StripB", (0.04, 1.02, 0.04), (1.06, 0, 0.72), M["cyan"]),
        box("Foot", (0.2, 0.9, 0.16), (-1.0, 0, 0.08), M["dark"]),
    ], "prop_cryo_pod_a")
    export("prop_cryo_pod_a", [pod], "props")

    reset()
    M = palette()
    broken = join([
        box("Base", (2.2, 1.2, 0.22), (0, 0, 0.11), M["metal"], bevel=0.03),
        box("Body", (2.2, 1.2, 0.62), (0, 0, 0.53), M["dark"], bevel=0.09),
        box("Well", (1.8, 0.9, 0.10), (0, 0, 0.88), M["rubber"]),
        box("Lid", (2.1, 1.1, 0.18), (0.25, 0, 1.06), M["metal"], rot=(0, 0, R(12)), bevel=0.05),
        box("Crack", (0.04, 0.8, 0.02), (-0.3, 0, 1.16), M["red"], rot=(0, 0, R(18))),
        box("Screen", (0.36, 0.04, 0.26), (0.82, -0.62, 0.72), M["red"]),
        box("StripA", (0.04, 1.02, 0.04), (-1.06, 0, 0.72), M["red"]),
    ], "prop_cryo_pod_broken")
    export("prop_cryo_pod_broken", [broken], "props")

    # Power suit rack.
    reset()
    M = palette()
    rack = join([
        box("Base", (2.2, 1.2, 0.16), (0, 0, 0.08), M["metal"], bevel=0.03),
        box("Back", (2.0, 0.18, 2.1), (0, 0.5, 1.1), M["dark"]),
        box("PostL", (0.12, 0.12, 2.2), (-0.95, 0.45, 1.1), M["metal"]),
        box("PostR", (0.12, 0.12, 2.2), (0.95, 0.45, 1.1), M["metal"]),
        box("Torso", (0.9, 0.45, 0.8), (0, 0.15, 1.35), M["ceramic"], bevel=0.08),
        box("Chest", (0.5, 0.12, 0.3), (0, -0.10, 1.45), M["amber"]),
        cylinder("ArmL", 0.14, 0.8, (-0.55, 0.15, 1.35), M["metal"], rot=(0, 0, R(18)), verts=8),
        cylinder("ArmR", 0.14, 0.8, (0.55, 0.15, 1.35), M["metal"], rot=(0, 0, R(-18)), verts=8),
        cylinder("LegL", 0.16, 0.9, (-0.25, 0.15, 0.65), M["metal"], verts=8),
        cylinder("LegR", 0.16, 0.9, (0.25, 0.15, 0.65), M["metal"], verts=8),
    ], "prop_suit_rack")
    export("prop_suit_rack", [rack], "props")

    # Autodoc bed.
    reset()
    M = palette()
    bed = join([
        box("Base", (2.2, 1.2, 0.35), (0, 0, 0.175), M["metal"], bevel=0.04),
        box("Mattress", (2.0, 1.0, 0.22), (0, 0, 0.46), M["med"], bevel=0.06),
        box("Head", (0.7, 0.9, 0.16), (-0.65, 0, 0.63), M["panel"], rot=(0, R(-12), 0)),
        box("Screen", (0.8, 0.08, 0.5), (0.55, -0.5, 1.05), M["cyan"], rot=(R(-18), 0, 0)),
        cylinder("Arm", 0.06, 1.0, (0, 0.45, 1.0), M["metal"], rot=(0, R(90), 0), verts=8),
        cylinder("Lamp", 0.22, 0.12, (0, 0, 1.48), M["med"], verts=12),
        box("RailL", (2.0, 0.05, 0.08), (0, -0.58, 0.62), M["metal"]),
        box("RailR", (2.0, 0.05, 0.08), (0, 0.58, 0.62), M["metal"]),
    ], "prop_autodoc")
    export("prop_autodoc", [bed], "props")

    # Medical wall screen.
    reset()
    M = palette()
    screen = join([
        box("Frame", (1.1, 0.08, 0.7), (0, 0, 0), M["metal"]),
        box("Glass", (0.98, 0.04, 0.58), (0, -0.06, 0), M["cyan"]),
        box("CrossA", (0.38, 0.02, 0.10), (0, -0.09, 0), M["red"]),
        box("CrossB", (0.10, 0.02, 0.38), (0, -0.09, 0), M["red"]),
    ], "prop_med_screen")
    export("prop_med_screen", [screen], "props")

    # Tool locker.
    reset()
    M = palette()
    locker = join([
        box("Body", (1.2, 0.7, 2.0), (0, 0, 1.0), M["panel"], bevel=0.03),
        box("Door", (0.55, 0.05, 1.85), (-0.30, -0.37, 1.0), M["ceramic"]),
        box("Door2", (0.55, 0.05, 1.85), (0.30, -0.37, 1.0), M["ceramic"]),
        box("HandleA", (0.05, 0.06, 0.3), (-0.08, -0.43, 1.0), M["metal"]),
        box("HandleB", (0.05, 0.06, 0.3), (0.08, -0.43, 1.0), M["metal"]),
        box("Label", (0.4, 0.02, 0.12), (0, -0.40, 1.65), M["hazard"]),
    ], "prop_tool_locker")
    export("prop_tool_locker", [locker], "props")

    # Battery rack.
    reset()
    M = palette()
    battery = join([
        box("Frame", (4.0, 1.0, 2.4), (0, 0, 1.2), M["metal"], bevel=0.03),
        box("Back", (3.8, 0.08, 2.2), (0, 0.45, 1.2), M["dark"]),
        box("CellA", (1.1, 0.7, 0.55), (-1.2, 0, 0.55), M["panel"], bevel=0.02),
        box("CellB", (1.1, 0.7, 0.55), (0, 0, 0.55), M["panel"], bevel=0.02),
        box("CellC", (1.1, 0.7, 0.55), (1.2, 0, 0.55), M["panel"], bevel=0.02),
        box("CellD", (1.1, 0.7, 0.55), (-1.2, 0, 1.35), M["panel"], bevel=0.02),
        box("CellE", (1.1, 0.7, 0.55), (0, 0, 1.35), M["panel"], bevel=0.02),
        box("CellF", (1.1, 0.7, 0.55), (1.2, 0, 1.35), M["panel"], bevel=0.02),
        box("Status", (3.6, 0.04, 0.08), (0, -0.53, 2.0), M["cyan"]),
        box("Warn", (0.8, 0.03, 0.2), (-1.4, -0.54, 1.8), M["hazard"]),
    ], "prop_battery_rack")
    export("prop_battery_rack", [battery], "props")

    # Stairs.
    reset()
    M = palette()
    steps = []
    for i in range(10):
        steps.append(box(f"Step{i}", (1.2, 0.34, 0.18), (0, i * 0.32 - 1.44, 0.09 + i * 0.34), M["floor"]))
    steps.append(box("StringerL", (0.12, 3.4, 3.6), (-0.62, 0, 1.8), M["metal"], rot=(R(-42), 0, 0)))
    steps.append(box("StringerR", (0.12, 3.4, 3.6), (0.62, 0, 1.8), M["metal"], rot=(R(-42), 0, 0)))
    stairs = join(steps, "prop_stairs_4m")
    export("prop_stairs_4m", [stairs], "props")


# ---------------------------------------------------------------------------
# Room shells for the first slice
# ---------------------------------------------------------------------------


def build_shells() -> None:
    shell, collision = room_shell(
        "env_ship_cryo_bay_shell",
        64.0,
        30.0,
        7.5,
        [{"wall": "n", "offset": 0.0, "width": 2.4, "height": 3.2}],
        "cyan",
        "ceramic",
        "floor",
        "metal",
        "dark",
        window={"x": -31.8, "y": -2.0, "width": 8.0, "height": 2.4, "z": 3.8},
    )
    export("env_ship_cryo_bay_shell", [shell, collision], "sections")

    shell, collision = room_shell(
        "env_ship_med_bay_shell",
        16.0,
        12.0,
        4.5,
        [{"wall": "s", "offset": 0.0, "width": 2.4, "height": 3.2}],
        "med",
        "ceramic",
        "floor",
        "metal",
        "dark",
    )
    export("env_ship_med_bay_shell", [shell, collision], "sections")


# ---------------------------------------------------------------------------
# Exterior hull
# ---------------------------------------------------------------------------


def build_exterior() -> None:
    reset()
    M = palette()
    parts: list[bpy.types.Object] = []

    # Main spine: 1,050 m, 84 m diameter. Bow is -Y (Godot +Z).
    parts.append(cylinder("HullMain", 42.0, 1050.0, (0, 0, 0), M["ceramic"], rot=(R(90), 0, 0), verts=16))
    parts.append(cylinder("HullBelly", 43.0, 900.0, (0, 0, -10), M["metal"], rot=(R(90), 0, 0), verts=16))
    parts.append(cylinder("HullBandA", 43.0, 12.0, (0, -350, 0), M["dark"], rot=(R(90), 0, 0), verts=16))
    parts.append(cylinder("HullBandB", 43.0, 12.0, (0, 0, 0), M["dark"], rot=(R(90), 0, 0), verts=16))
    parts.append(cylinder("HullBandC", 43.0, 12.0, (0, 350, 0), M["dark"], rot=(R(90), 0, 0), verts=16))

    # Bow command bulb and nose.
    parts.append(cylinder("CommandBulb", 52.0, 130.0, (0, -540, 4), M["ceramic"], rot=(R(90), 0, 0), verts=16))
    parts.append(cone("Nose", 52.0, 14.0, 120.0, (0, -665, 4), M["ceramic"], rot=(R(-90), 0, 0), verts=16))
    parts.append(cylinder("NoseCap", 14.0, 8.0, (0, -730, 4), M["metal"], rot=(R(90), 0, 0), verts=12))

    # 80 m light-sail ring near the bow.
    parts.append(torus("SailRing", 40.0, 3.0, (0, -560, 4), M["ceramic"], rot=(R(90), 0, 0), major_segments=32, minor_segments=6))
    for angle in (0, 90, 180, 270):
        x = 40.0 * math.cos(R(angle))
        z = 4.0 + 40.0 * math.sin(R(angle))
        parts.append(cylinder(f"RingSpoke{angle}", 0.8, 52.0, (x * 0.75, -560, z * 0.75), M["metal"], rot=(R(90), 0, 0), verts=6))

    # Radiator wings.
    for side in (-1, 1):
        parts.append(box(f"RadiatorA{side}", (170, 240, 2.2), (side * 120, 80, 28), M["metal"], rot=(0, R(side * -8), 0)))
        parts.append(box(f"RadiatorB{side}", (150, 210, 2.2), (side * 105, 330, 30), M["panel"], rot=(0, R(side * 10), 0)))
        parts.append(box(f"RadiatorEdge{side}", (4, 240, 4), (side * 202, 80, 28), M["dark"]))

    # Cargo pods.
    for index, y in enumerate((-180, 0, 180)):
        side = -1 if index % 2 == 0 else 1
        parts.append(cylinder(f"CargoPod{index}", 21.0, 92.0, (side * 48, y, -8), M["panel"], rot=(R(90), 0, 0), verts=12))
        parts.append(cylinder(f"CargoCap{index}", 22.0, 8.0, (side * 48, y + 48, -8), M["dark"], rot=(R(90), 0, 0), verts=12))

    # Landing legs: three down, three broken.
    for index, (x, y) in enumerate(((-52, -210), (52, -210), (-52, 120), (52, 120), (-52, 360), (52, 360))):
        length = 54.0 if index < 3 else 34.0
        parts.append(cylinder(f"Leg{index}", 3.2, length, (x, y, -52), M["metal"], rot=(R(8 if index % 2 else -8), 0, 0), verts=8))
        parts.append(box(f"Foot{index}", (14, 16, 4), (x, y, -80), M["dark"], rot=(0, 0, R(12 if index == 2 else 0))))

    # Breach on +X side, around y = 0, z ~ 0. Dark recess + jagged plates.
    # The dark box sits slightly proud of the hull so it reads from outside.
    parts.append(box("BreachDark", (2.5, 26, 13), (43.0, 0, 2), M["dark"]))
    parts.append(box("BreachFrameA", (2.4, 2, 15), (43.6, -13, 2), M["metal"], rot=(0, 0, R(10))))
    parts.append(box("BreachFrameB", (2.4, 2, 15), (43.6, 13, 2), M["metal"], rot=(0, 0, R(-10))))
    parts.append(box("BreachHoodTop", (3.0, 28, 2), (43.2, 0, 9.2), M["metal"]))
    parts.append(box("BreachHoodBottom", (3.0, 28, 2), (43.2, 0, -5.2), M["metal"]))
    parts.append(box("BreachPlateA", (2, 9, 6), (45, -16, -4), M["metal"], rot=(R(18), 0, R(28))))
    parts.append(box("BreachPlateB", (2, 7, 5), (46, 17, 6), M["ceramic"], rot=(R(-22), 0, R(-34))))
    parts.append(box("BreachGlow", (0.6, 10, 0.5), (44.6, 0, -2.0), M["amber"]))

    # Stern break: jagged dark cap and torn plates.
    parts.append(cylinder("SternCap", 43.0, 6.0, (0, 527, 0), M["dark"], rot=(R(90), 0, 0), verts=16))
    for index, angle in enumerate((15, 85, 160, 240, 310)):
        x = 44.0 * math.cos(R(angle))
        z = 44.0 * math.sin(R(angle))
        parts.append(box(f"SternTear{index}", (10, 3, 26), (x, 540, z), M["metal"], rot=(R(12), R(angle), 0)))

    # A few vines and debris on the hull.
    for index, (x, y, z) in enumerate(((-42, -120, 10), (40, 80, -20), (-38, 240, 28), (30, -330, 2))):
        parts.append(cylinder(f"Vine{index}", 0.7, 34.0, (x, y, z), M["green"], rot=(R(12), 0, R(15 * index)), verts=5))

    if os.environ.get("SHIP_DEBUG_BOUNDS"):
        for part in parts:
            print("[bounds]", part.name, tuple(round(v, 1) for v in part.location), tuple(round(v, 1) for v in part.dimensions))

    hull = join(parts, "env_ship_exterior_hull")
    if os.environ.get("SHIP_DEBUG_BOUNDS"):
        corners = [hull.matrix_world @ Vector(c) for c in hull.bound_box]
        mins = tuple(round(min(c[i] for c in corners), 1) for i in range(3))
        maxs = tuple(round(max(c[i] for c in corners), 1) for i in range(3))
        print("[bounds] joined", tuple(round(v, 1) for v in hull.dimensions), "world", mins, maxs)
    export("env_ship_exterior_hull", [hull], "exterior")

    # Breach ramp and airlock mouth.
    reset()
    M = palette()
    ramp_parts = [
        box("Ramp", (8, 14, 0.5), (0, 7, 1.8), M["metal"], rot=(R(-14), 0, 0)),
        box("RampLip", (8, 1.0, 0.3), (0, 0.2, 3.1), M["hazard"]),
        box("RailL", (0.25, 14, 0.9), (-4.0, 7, 2.4), M["metal"], rot=(R(-14), 0, 0)),
        box("RailR", (0.25, 14, 0.9), (4.0, 7, 2.4), M["metal"], rot=(R(-14), 0, 0)),
        box("Airlock", (9, 4, 4.2), (0, -2, 4.4), M["dark"]),
        box("AirlockFrame", (9.4, 0.6, 4.6), (0, -4.1, 4.5), M["metal"]),
        box("AirlockGlow", (0.5, 3.2, 0.35), (3.8, -2, 4.2), M["amber"]),
        box("DebrisA", (5, 3, 0.4), (-6, 10, 0.3), M["metal"], rot=(0, 0, R(24))),
        box("DebrisB", (3, 2, 0.3), (6, 13, 0.2), M["panel"], rot=(0, 0, R(-18))),
    ]
    ramp = join(ramp_parts, "env_ship_breach_ramp")
    export("env_ship_breach_ramp", [ramp], "exterior")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else ["all"]
    mode = args[0] if args else "all"
    if mode in ("kit", "all"):
        build_kit()
    if mode in ("props", "all"):
        build_props()
    if mode in ("shells", "all"):
        build_shells()
    if mode in ("exterior", "all"):
        build_exterior()
    print("[ship] done:", mode)


if __name__ == "__main__":
    main()
