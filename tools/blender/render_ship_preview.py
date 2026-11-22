"""Quick visual check render for the exterior ship model."""
import math
import os
import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GLB = os.path.join(ROOT, "assets", "models", "ship", "exterior", "env_ship_exterior_hull.glb")
OUT = os.environ.get("SHIP_RENDER_OUT", "/tmp/ship_exterior_render.png")

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.film_transparent = False
if scene.world is None:
    scene.world = bpy.data.worlds.new("World")
scene.world.color = (0.05, 0.06, 0.07)

bpy.ops.object.empty_add(location=(0, 0, 20))
target = bpy.context.object
bpy.ops.object.camera_add(location=(900, -1250, 460))
cam = bpy.context.object
scene.camera = cam
constraint = cam.constraints.new(type="TRACK_TO")
constraint.target = target
constraint.track_axis = "TRACK_NEGATIVE_Z"
constraint.up_axis = "UP_Y"
cam.data.lens = 35
cam.data.clip_start = 1.0
cam.data.clip_end = 6000.0

bpy.ops.object.light_add(type="SUN", location=(200, -300, 400))
sun = bpy.context.object
sun.data.energy = 4.0
sun.rotation_euler = (math.radians(35), math.radians(10), math.radians(30))

scene.render.filepath = OUT
bpy.ops.render.render(write_still=True)
print("[ship] render", OUT)
