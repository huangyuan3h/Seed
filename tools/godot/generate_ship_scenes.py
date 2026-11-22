"""Generate the first ship blockout scenes from the Blender assets.

Run from the repo root:

    python3 tools/godot/generate_ship_scenes.py

This writes:
    scenes/ship/sections/cryo_bay.tscn
    scenes/ship/sections/med_bay.tscn
    scenes/ship/sections/spine_corridor.tscn
    scenes/ship/ship_interior.tscn
    scenes/ship/ship_preview.tscn
    scenes/ship/ship_exterior.tscn
    scenes/ship/ship_exterior_preview.tscn

The .tscn files are ordinary Godot scenes; this script only keeps the repeated
prop placement (24 cryo pods, corridor dressing) maintainable.
"""

from __future__ import annotations

import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHIP = os.path.join(ROOT, "scenes", "ship")


def q(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def xform(pos=(0, 0, 0), yaw_deg: float = 0.0, scale: float = 1.0) -> str:
    yaw = math.radians(yaw_deg)
    c = math.cos(yaw) * scale
    s = math.sin(yaw) * scale
    return (
        "Transform3D("
        f"{c:.6f}, 0, {-s:.6f}, "
        f"0, {scale:.6f}, 0, "
        f"{s:.6f}, 0, {c:.6f}, "
        f"{pos[0]:.6f}, {pos[1]:.6f}, {pos[2]:.6f})"
    )


class Tscn:
    def __init__(self) -> None:
        self.exts: list[tuple[str, str, str]] = []
        self.subs: list[tuple[str, str, dict]] = []
        self.nodes: list[str] = []
        self._ext_index = 0
        self._sub_index = 0

    def ext(self, path: str, type_: str = "PackedScene") -> str:
        self._ext_index += 1
        id_ = str(self._ext_index)
        self.exts.append((id_, type_, path))
        return id_

    def sub(self, type_: str, props: dict) -> str:
        self._sub_index += 1
        id_ = f"{type_}_{self._sub_index}"
        self.subs.append((id_, type_, props))
        return id_

    def node(
        self,
        name: str,
        type_: str | None = None,
        parent: str | None = None,
        props: dict | None = None,
        instance: str | None = None,
        transform: str | None = None,
    ) -> None:
        head = f'[node name="{name}"'
        if type_ is not None:
            head += f' type="{type_}"'
        if parent is not None:
            head += f' parent="{parent}"'
        if instance is not None:
            head += f' instance=ExtResource("{instance}")'
        head += "]"
        lines = [head]
        if transform is not None:
            lines.append(f"transform = {transform}")
        for key, value in (props or {}).items():
            lines.append(f"{key} = {value}")
        self.nodes.append("\n".join(lines))

    def save(self, path: str) -> None:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        out = [f"[gd_scene load_steps={len(self.exts) + len(self.subs) + 1} format=3]", ""]
        for id_, type_, path_ in self.exts:
            out.append(f'[ext_resource type="{type_}" path="{path_}" id="{id_}"]')
        out.append("")
        for id_, type_, props in self.subs:
            out.append(f'[sub_resource type="{type_}" id="{id_}"]')
            for key, value in props.items():
                out.append(f"{key} = {value}")
            out.append("")
        out.extend(self.nodes)
        path = os.path.join(ROOT, path)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write("\n\n".join(out) + "\n")
        print(f"[ship-scenes] wrote {path}")


def add_light(
    scene: Tscn,
    name: str,
    pos,
    color: str,
    energy: float,
    range_: float,
    shadow: bool = False,
) -> None:
    scene.node(
        name,
        "OmniLight3D",
        ".",
        {
            "light_color": color,
            "light_energy": f"{energy:.2f}",
            "omni_range": f"{range_:.1f}",
            "shadow_enabled": "true" if shadow else "false",
        },
        transform=xform(pos),
    )


def add_interactable(
    scene: Tscn,
    name: str,
    script_id: str,
    pos,
    prompt: str,
    message: str,
    priority: int = 1,
) -> None:
    scene.node(
        name,
        "Area3D",
        ".",
        {
            "script": f'ExtResource("{script_id}")',
            "interaction_id": q(name.lower()),
            "prompt_text": q(prompt),
            "message": q(message),
            "interaction_priority": str(priority),
        },
        transform=xform(pos),
    )


def add_label(scene: Tscn, name: str, pos, text: str, color: str, size: int = 32) -> None:
    scene.node(
        name,
        "Label3D",
        ".",
        {
            "text": q(text),
            "font_size": str(size),
            "modulate": color,
            "billboard": "1",
            "no_depth_test": "true",
            "outline_size": "8",
        },
        transform=xform(pos),
    )


# ---------------------------------------------------------------------------
# S1 — Cryo bay
# ---------------------------------------------------------------------------


def build_cryo_bay() -> None:
    scene = Tscn()
    shell = scene.ext("res://assets/models/ship/sections/env_ship_cryo_bay_shell.glb")
    pod = scene.ext("res://assets/models/ship/props/prop_cryo_pod_a.glb")
    broken = scene.ext("res://assets/models/ship/props/prop_cryo_pod_broken.glb")
    suit = scene.ext("res://assets/models/ship/props/prop_suit_rack.glb")
    locker = scene.ext("res://assets/models/ship/props/prop_tool_locker.glb")
    console = scene.ext("res://assets/models/ship/props/prop_console.glb")
    crate = scene.ext("res://assets/models/ship/props/prop_crate_a.glb")
    inspect = scene.ext("res://scripts/ship/ship_interactable.gd", "Script")
    pod_dialogue = scene.ext("res://scripts/ship/ship_pod07_dialogue.gd", "Script")

    scene.node("CryoBay", "Node3D")
    scene.node("Shell", parent=".", instance=shell)
    scene.node("SpawnPoint", "Marker3D", ".", transform=xform((0, 0.1, 10)))
    scene.node("SuitRack", parent=".", instance=suit, transform=xform((-26, 0, 10), 180))
    scene.node("ToolLocker", parent=".", instance=locker, transform=xform((-28, 0, 8), 90))
    scene.node("Console", parent=".", instance=console, transform=xform((26, 0, 10), -90))
    scene.node("CrateA", parent=".", instance=crate, transform=xform((24, 0, 2), 18))
    scene.node("CrateB", parent=".", instance=crate, transform=xform((25, 0, 4), -24))

    xs = [-22, -18, -14, -10, -6, -2, 2, 6, 10, 14, 18, 22]
    for row, z in (("A", 5.0), ("B", -5.0)):
        for x in xs:
            if row == "A" and x == 0:
                continue
            scene.node(f"Pod{row}{x:+03d}", parent=".", instance=pod, transform=xform((x, 0, z)))
    scene.node("Pod07", parent=".", instance=broken, transform=xform((0, 0, 5)))
    add_label(scene, "Pod07Label", (0, 1.65, 5), "07 // OCCUPIED", "Color(0.85, 0.18, 0.12, 1)", 40)
    add_light(scene, "Pod07Light", (0, 1.1, 6.0), "Color(1.0, 0.12, 0.08, 1)", 0.9, 4.5, False)
    add_interactable(
        scene,
        "Pod07Interact",
        inspect,
        (0, 1.0, 5),
        "Inspect Pod 07",
        "07 // OCCUPIED. The lid is half open. There is no one inside.",
        5,
    )
    add_interactable(
        scene,
        "SuitRackInteract",
        inspect,
        (-26, 1.0, 10),
        "Inspect suit rack",
        "Power suit rack. Battery 62%. Temperature and HUD are online.",
        3,
    )
    add_interactable(
        scene,
        "LockerInteract",
        inspect,
        (-28, 1.0, 8),
        "Inspect locker",
        "Emergency tool locker. Most of the tools are already gone.",
        2,
    )

    add_light(scene, "CryoLightA", (-20, 6.4, 5), "Color(0.35, 0.75, 0.92, 1)", 4.0, 30.0, True)
    add_light(scene, "CryoLightB", (20, 6.4, 5), "Color(0.35, 0.75, 0.92, 1)", 4.0, 30.0, True)
    add_light(scene, "CryoLightC", (-20, 6.4, -5), "Color(0.30, 0.65, 0.82, 1)", 3.2, 28.0, True)
    add_light(scene, "CryoLightD", (20, 6.4, -5), "Color(0.30, 0.65, 0.82, 1)", 3.2, 28.0, True)
    add_light(scene, "CryoLightE", (0, 6.4, -12), "Color(0.35, 0.75, 0.92, 1)", 2.4, 24.0, False)
    add_light(scene, "CryoDoorLight", (0, 5.2, 13.5), "Color(1.0, 0.45, 0.12, 1)", 0.8, 8.0, False)
    scene.save("scenes/ship/sections/cryo_bay.tscn")


# ---------------------------------------------------------------------------
# S2 — Med bay
# ---------------------------------------------------------------------------


def build_med_bay() -> None:
    scene = Tscn()
    shell = scene.ext("res://assets/models/ship/sections/env_ship_med_bay_shell.glb")
    autodoc = scene.ext("res://assets/models/ship/props/prop_autodoc.glb")
    screen = scene.ext("res://assets/models/ship/props/prop_med_screen.glb")
    locker = scene.ext("res://assets/models/ship/props/prop_tool_locker.glb")
    console = scene.ext("res://assets/models/ship/props/prop_console.glb")
    crate = scene.ext("res://assets/models/ship/props/prop_crate_a.glb")
    vent = scene.ext("res://assets/models/ship/props/prop_vent_1m.glb")
    inspect = scene.ext("res://scripts/ship/ship_interactable.gd", "Script")

    scene.node("MedBay", "Node3D")
    scene.node("Shell", parent=".", instance=shell)
    scene.node("RespawnPoint", "Marker3D", ".", transform=xform((0, 0.1, 0)))
    scene.node("Autodoc", parent=".", instance=autodoc, transform=xform((0, 0, 0)))
    scene.node("MedScreen", parent=".", instance=screen, transform=xform((0, 2.2, 5.82), 180))
    scene.node("ToolLocker", parent=".", instance=locker, transform=xform((-6, 0, 4.4), 90))
    scene.node("Console", parent=".", instance=console, transform=xform((6, 0, 4.4), -90))
    scene.node("CrateA", parent=".", instance=crate, transform=xform((-5.5, 0, -4.6), 12))
    scene.node("CrateB", parent=".", instance=crate, transform=xform((-4.2, 0, -4.2), -8))
    scene.node("Vent", parent=".", instance=vent, transform=xform((4.5, 1.2, 5.8), 180))
    add_interactable(
        scene,
        "MedScreenInteract",
        inspect,
        (0, 2.0, 5.6),
        "Inspect medical screen",
        "EDEN // WAKE. The identity record is damaged.",
        3,
    )
    add_interactable(
        scene,
        "AutodocInteract",
        inspect,
        (0, 1.0, 0),
        "Inspect autodoc",
        "Autodoc: standby. It can still bring you back.",
        2,
    )

    add_light(scene, "MedLightA", (0, 4.1, 0), "Color(1.0, 0.92, 0.78, 1)", 2.0, 11.0, True)
    add_light(scene, "MedLightB", (0, 4.1, 4), "Color(0.95, 0.90, 0.80, 1)", 1.3, 9.0, False)
    add_light(scene, "MedDoorLight", (0, 3.2, -5.6), "Color(1.0, 0.45, 0.12, 1)", 0.8, 7.0, False)
    scene.save("scenes/ship/sections/med_bay.tscn")


# ---------------------------------------------------------------------------
# S3 — Junction, corridors, airlock, sealed door
# ---------------------------------------------------------------------------


def build_spine_corridor() -> None:
    scene = Tscn()
    junction = scene.ext("res://assets/models/ship/kit/env_ship_junction_12m.glb")
    corridor = scene.ext("res://assets/models/ship/kit/env_ship_corridor_8m.glb")
    airlock = scene.ext("res://assets/models/ship/kit/env_ship_airlock_8x6.glb")
    sealed = scene.ext("res://assets/models/ship/props/prop_sealed_door.glb")
    door = scene.ext("res://assets/models/ship/props/prop_bulkhead_door.glb")
    console = scene.ext("res://assets/models/ship/props/prop_console.glb")
    crate = scene.ext("res://assets/models/ship/props/prop_crate_a.glb")
    pipe = scene.ext("res://assets/models/ship/props/prop_pipe_run_4m.glb")
    tray = scene.ext("res://assets/models/ship/props/prop_cable_tray_4m.glb")
    vent = scene.ext("res://assets/models/ship/props/prop_vent_1m.glb")
    inspect = scene.ext("res://scripts/ship/ship_interactable.gd", "Script")
    transition = scene.ext("res://scripts/ship/ship_transition.gd", "Script")
    sealed_box = scene.sub("BoxShape3D", {"size": "Vector3(0.4, 3.2, 2.4)"})

    scene.node("SpineCorridor", "Node3D")
    scene.node("Junction", parent=".", instance=junction, transform=xform((0, 0, 0)))
    scene.node("CorridorSouth", parent=".", instance=corridor, transform=xform((0, 0, -10)))
    scene.node("CorridorNorth", parent=".", instance=corridor, transform=xform((0, 0, 10)))
    scene.node("CorridorEast", parent=".", instance=corridor, transform=xform((10, 0, 0), 90))
    scene.node("Airlock", parent=".", instance=airlock, transform=xform((18, 0, 0)))
    scene.node("SealedDoor", parent=".", instance=sealed, transform=xform((-6.05, 0, 0), 90))

    scene.node("SealedDoorBlock", "StaticBody3D", ".")
    scene.node(
        "CollisionShape3D",
        "CollisionShape3D",
        "SealedDoorBlock",
        {"shape": f'SubResource("{sealed_box}")'},
        transform=xform((-6.0, 1.6, 0)),
    )

    # Open door leaves parked against the wall.
    scene.node("CryoDoorOpen", parent=".", instance=door, transform=xform((1.4, 0, -14.0), 90))
    scene.node("MedDoorOpen", parent=".", instance=door, transform=xform((-1.4, 0, 14.0), 90))
    scene.node("AirlockDoorOpen", parent=".", instance=door, transform=xform((22.1, 0, 1.7), 90))

    scene.node("Console", parent=".", instance=console, transform=xform((4, 0, 4), 180))
    scene.node("CrateA", parent=".", instance=crate, transform=xform((-4.2, 0, 3.8), 20))
    scene.node("CrateB", parent=".", instance=crate, transform=xform((-3.0, 0, 4.6), -14))
    scene.node("PipeRun", parent=".", instance=pipe, transform=xform((2.1, 2.6, -10), 90))
    scene.node("CableTray", parent=".", instance=tray, transform=xform((0, 3.3, -10), 90))
    scene.node("Vent", parent=".", instance=vent, transform=xform((5.8, 2.2, 0), 90))

    add_label(scene, "NoPowerLabel", (-5.55, 2.4, 0), "NO POWER", "Color(0.9, 0.2, 0.15, 1)", 34)
    add_label(scene, "AirlockLabel", (20.5, 2.8, 0), "AIRLOCK // D3", "Color(1.0, 0.65, 0.25, 1)", 28)

    add_light(scene, "JunctionLight", (0, 3.7, 0), "Color(1.0, 0.45, 0.12, 1)", 2.4, 15.0, True)
    add_light(scene, "SouthCorridorLight", (0, 3.0, -10), "Color(1.0, 0.45, 0.12, 1)", 1.6, 11.0, False)
    add_light(scene, "NorthCorridorLight", (0, 3.0, 10), "Color(1.0, 0.45, 0.12, 1)", 1.6, 11.0, False)
    add_light(scene, "EastCorridorLight", (10, 3.0, 0), "Color(1.0, 0.45, 0.12, 1)", 1.8, 11.0, False)
    add_light(scene, "AirlockLight", (18, 3.0, 0), "Color(1.0, 0.52, 0.18, 1)", 2.2, 12.0, True)

    add_interactable(
        scene,
        "SealedDoorInteract",
        inspect,
        (-5.8, 1.6, 0),
        "Inspect sealed door",
        "Energy bay: no power. Restore the basic grid first.",
        4,
    )
    scene.node(
        "AirlockInteract",
        "Area3D",
        ".",
        {
            "script": f'ExtResource("{transition}")',
            "interaction_id": q("airlock_exit"),
            "prompt_text": q("Enter the breach"),
            "target_scene": q("res://scenes/ship/ship_exterior_preview.tscn"),
            "transition_message": q("Opening the D3 airlock..."),
            "interaction_priority": "6",
        },
        transform=xform((20, 1.2, 0)),
    )

    scene.node("ExteriorExit", "Marker3D", ".", transform=xform((22, 0.1, 0)))
    scene.save("scenes/ship/sections/spine_corridor.tscn")


# ---------------------------------------------------------------------------
# Master interior + preview
# ---------------------------------------------------------------------------


def build_ship_interior() -> None:
    scene = Tscn()
    cryo = scene.ext("res://scenes/ship/sections/cryo_bay.tscn")
    med = scene.ext("res://scenes/ship/sections/med_bay.tscn")
    spine = scene.ext("res://scenes/ship/sections/spine_corridor.tscn")
    env = scene.sub(
        "Environment",
        {
            "background_mode": "1",
            "background_color": "Color(0.015, 0.02, 0.025, 1)",
            "ambient_light_source": "2",
            "ambient_light_color": "Color(0.18, 0.22, 0.25, 1)",
            "ambient_light_energy": "0.50",
            "tonemap_mode": "3",
            "glow_enabled": "true",
            "glow_intensity": "0.45",
            "glow_strength": "0.9",
            "glow_bloom": "0.05",
            "glow_blend_mode": "1",
            "glow_hdr_threshold": "0.9",
            "fog_enabled": "true",
            "fog_light_color": "Color(0.06, 0.08, 0.09, 1)",
            "fog_light_energy": "0.4",
            "fog_density": "0.01",
            "ssao_enabled": "true",
            "ssao_radius": "1.0",
            "ssao_intensity": "1.2",
        },
    )

    scene.node("ShipInterior", "Node3D")
    scene.node("CryoBay", parent=".", instance=cryo, transform=xform((0, 0, -29)))
    scene.node("MedBay", parent=".", instance=med, transform=xform((0, 0, 20)))
    scene.node("SpineCorridor", parent=".", instance=spine, transform=xform((0, 0, 0)))

    scene.node("WorldEnvironment", "WorldEnvironment", ".", {"environment": f'SubResource("{env}")'})
    scene.node(
        "AmbientFill",
        "DirectionalLight3D",
        ".",
        {
            "light_color": "Color(0.55, 0.68, 0.85, 1)",
            "light_energy": "0.18",
            "shadow_enabled": "false",
        },
        transform=xform((0, 8, 0), 35),
    )
    scene.node("CryoSpawn", "Marker3D", ".", transform=xform((0, 0.1, -19)))
    scene.node("MedSpawn", "Marker3D", ".", transform=xform((0, 0.1, 20)))
    scene.node("ExteriorExit", "Marker3D", ".", transform=xform((22, 0.1, 0)))
    scene.save("scenes/ship/ship_interior.tscn")


def add_player_and_camera(
    scene: Tscn,
    player_script: str,
    camera_script: str,
    spawn,
    yaw: float,
    indoor: bool = True,
    session_key: str = "",
) -> None:
    capsule = scene.sub("CapsuleShape3D", {"radius": "0.28", "height": "1.5"})
    scene.node(
        "Player",
        "CharacterBody3D",
        ".",
        {
            "script": f'ExtResource("{player_script}")',
            "start_yaw": f"{yaw:.6f}",
            "session_key": q(session_key),
        },
        transform=xform(spawn),
    )
    scene.node(
        "CollisionShape3D",
        "CollisionShape3D",
        "Player",
        {"shape": f'SubResource("{capsule}")'},
        transform=xform((0, 0.75, 0)),
    )
    cam_offset = "(0, 2.2, 4.0)" if indoor else "(0, 3.5, 7.0)"
    scene.node(
        "CameraPivot",
        "Node3D",
        ".",
        {
            "script": f'ExtResource("{camera_script}")',
            "cam_offset": f"Vector3{cam_offset}",
            "look_height": "1.0",
        },
    )
    scene.node(
        "Camera3D",
        "Camera3D",
        "CameraPivot",
        {"current": "true"},
        transform=xform((0, 0, 0)),
    )


def add_preview_hint(scene: Tscn, text: str) -> None:
    scene.node("UI", "CanvasLayer", ".")
    scene.node(
        "Hint",
        "Label",
        "UI",
        {
            "offset_left": "16.0",
            "offset_top": "16.0",
            "offset_right": "900.0",
            "offset_bottom": "52.0",
            "text": q(text),
            "theme_override_colors/font_color": "Color(1.0, 0.78, 0.42, 1)",
            "theme_override_colors/font_shadow_color": "Color(0, 0, 0, 0.8)",
            "theme_override_constants/shadow_offset_x": "2",
            "theme_override_constants/shadow_offset_y": "2",
            "theme_override_font_sizes/font_size": "18",
        },
    )
    scene.node(
        "InteractPrompt",
        "Label",
        "UI",
        {
            "offset_left": "16.0",
            "offset_top": "52.0",
            "offset_right": "900.0",
            "offset_bottom": "88.0",
            "text": q(""),
            "theme_override_colors/font_color": "Color(0.96, 0.92, 0.78, 1)",
            "theme_override_colors/font_shadow_color": "Color(0, 0, 0, 0.9)",
            "theme_override_constants/shadow_offset_x": "2",
            "theme_override_constants/shadow_offset_y": "2",
            "theme_override_font_sizes/font_size": "20",
        },
    )


def build_preview() -> None:
    scene = Tscn()
    interior = scene.ext("res://scenes/ship/ship_interior.tscn")
    player_script = scene.ext("res://scripts/ship/ship_preview_player.gd", "Script")
    camera_script = scene.ext("res://addons/gu_gameplay/camera/camera_rig.gd", "Script")

    scene.node("ShipPreview", "Node3D")
    scene.node("ShipInterior", parent=".", instance=interior)
    add_player_and_camera(scene, player_script, camera_script, (0, 0.1, -19), 0.0, True, "ship_interior")
    add_preview_hint(scene, "SHIP INTERIOR BLOCKOUT  |  WASD move  ·  right-drag look  ·  wheel zoom  ·  E interact  ·  ESC quit")
    scene.save("scenes/ship/ship_preview.tscn")


# ---------------------------------------------------------------------------
# Exterior + preview
# ---------------------------------------------------------------------------


def build_exterior() -> None:
    scene = Tscn()
    hull = scene.ext("res://assets/models/ship/exterior/env_ship_exterior_hull.glb")
    ramp = scene.ext("res://assets/models/ship/exterior/env_ship_breach_ramp.glb")
    env = scene.ext("res://scenes/world/seed_environment.tscn")
    crate = scene.ext("res://assets/models/ship/props/prop_crate_a.glb")
    transition = scene.ext("res://scripts/ship/ship_transition.gd", "Script")

    ground_mat = scene.sub(
        "StandardMaterial3D",
        {
            "albedo_color": "Color(0.24, 0.30, 0.18, 1)",
            "roughness": "0.95",
        },
    )
    plane = scene.sub("PlaneMesh", {"size": "Vector2(2000, 2000)"})
    ground_box = scene.sub("BoxShape3D", {"size": "Vector3(2000, 1, 2000)"})
    ramp_box = scene.sub("BoxShape3D", {"size": "Vector3(20, 0.5, 8)"})
    shapes = {
        "far_a": scene.sub("BoxShape3D", {"size": "Vector3(85, 140, 420)"}),
        "far_b": scene.sub("BoxShape3D", {"size": "Vector3(85, 140, 420)"}),
        "bow": scene.sub("BoxShape3D", {"size": "Vector3(90, 140, 250)"}),
        "stern": scene.sub("BoxShape3D", {"size": "Vector3(90, 140, 180)"}),
        "mid_left": scene.sub("BoxShape3D", {"size": "Vector3(43, 140, 60)"}),
        "mid_top": scene.sub("BoxShape3D", {"size": "Vector3(43, 46, 60)"}),
        "mid_bottom": scene.sub("BoxShape3D", {"size": "Vector3(43, 73, 60)"}),
    }

    scene.node("ShipExterior", "Node3D")
    scene.node("Hull", parent=".", instance=hull, transform=xform((0, 0, 0)))
    scene.node("BreachRamp", parent=".", instance=ramp, transform=xform((43.5, 0, 0), -90))
    scene.node("SeedEnvironment", parent=".", instance=env)

    scene.node(
        "Ground",
        "MeshInstance3D",
        ".",
        {"mesh": f'SubResource("{plane}")', "material_override": f'SubResource("{ground_mat}")'},
    )
    scene.node("GroundBody", "StaticBody3D", ".")
    scene.node(
        "CollisionShape3D",
        "CollisionShape3D",
        "GroundBody",
        {"shape": f'SubResource("{ground_box}")'},
        transform=xform((0, -0.5, 0)),
    )

    # Coarse ramp collision: a 12-degree slope from the ground up to the breach.
    scene.node("RampBody", "StaticBody3D", ".")
    scene.node(
        "CollisionShape3D",
        "CollisionShape3D",
        "RampBody",
        {"shape": f'SubResource("{ramp_box}")'},
        transform="Transform3D(0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1, 48, 1.8, 0)",
    )

    scene.node("HullBody", "StaticBody3D", ".")
    collisions = [
        ("FarA", "far_a", (0, -11, -240)),
        ("FarB", "far_b", (0, -11, 240)),
        ("Bow", "bow", (0, -11, -575)),
        ("Stern", "stern", (0, -11, 540)),
        ("MidLeft", "mid_left", (-21, -11, 0)),
        ("MidTop", "mid_top", (21, 33, 0)),
        ("MidBottom", "mid_bottom", (21, -46, 0)),
    ]
    for name, shape, pos in collisions:
        scene.node(
            f"Collision{name}",
            "CollisionShape3D",
            "HullBody",
            {"shape": f'SubResource("{shapes[shape]}")'},
            transform=xform(pos),
        )

    scene.node("InteriorEntry", "Marker3D", ".", transform=xform((0, 1.5, 0)))
    scene.node(
        "InteriorEntryInteract",
        "Area3D",
        ".",
        {
            "script": f'ExtResource("{transition}")',
            "interaction_id": q("breach_enter"),
            "prompt_text": q("Enter the ship"),
            "target_scene": q("res://scenes/ship/ship_preview.tscn"),
            "transition_message": q("Entering the D3 breach..."),
            "interaction_priority": "6",
        },
        transform=xform((0, 1.2, 0)),
    )
    scene.node("CrateA", parent=".", instance=crate, transform=xform((52, 0, 8), 24))
    scene.node("CrateB", parent=".", instance=crate, transform=xform((55, 0, 4), -18))
    add_light(scene, "BreachLight", (45, 4.5, 0), "Color(1.0, 0.42, 0.10, 1)", 2.2, 22.0, True)
    add_label(scene, "BreachLabel", (48, 6.5, 0), "D3 // BREACH", "Color(1.0, 0.62, 0.24, 1)", 36)
    scene.save("scenes/ship/ship_exterior.tscn")

    scene = Tscn()
    exterior = scene.ext("res://scenes/ship/ship_exterior.tscn")
    player_script = scene.ext("res://scripts/ship/ship_preview_player.gd", "Script")
    camera_script = scene.ext("res://addons/gu_gameplay/camera/camera_rig.gd", "Script")

    scene.node("ShipExteriorPreview", "Node3D")
    scene.node("ShipExterior", parent=".", instance=exterior)
    add_player_and_camera(scene, player_script, camera_script, (62, 0.1, 0), math.pi / 2.0, False, "ship_exterior")
    add_preview_hint(scene, "SHIP EXTERIOR BLOCKOUT  |  WASD move  ·  right-drag look  ·  wheel zoom  ·  E interact  ·  ESC quit")
    scene.save("scenes/ship/ship_exterior_preview.tscn")


def main() -> None:
    build_cryo_bay()
    build_med_bay()
    build_spine_corridor()
    build_ship_interior()
    build_preview()
    build_exterior()


if __name__ == "__main__":
    main()
