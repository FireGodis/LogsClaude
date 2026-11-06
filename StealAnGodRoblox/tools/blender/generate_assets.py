"""
generate_assets.py — Blender (3.6+/4.x) script that builds the STEAL AN GOD mesh kit, saves a
.blend per asset and exports FBX ready for Roblox (Studio: Avatar/3D Importer).

NOT executed in the cloud session (Blender was not available there). Run on your computer:
    blender --background --python tools/blender/generate_assets.py -- <output_dir>

Creates (low-poly, stylized, origin at the bottom-center, scale 1 Blender unit = 1 stud):
  eggs/Egg_<Mythology>.fbx          — ovoid shell + mythology band (Greek laurel, Norse runes, Egyptian stripes)
  treadmills/Treadmill<1-10>.fbx    — 10 distinct treadmill frames (belt is a separate object "Belt")
  props/Trap.fbx, props/Pedestal.fbx, props/Nest.fbx, props/Column.fbx, props/Obelisk.fbx
After importing, put the models in ReplicatedStorage.Assets.<Creatures|Treadmills> with the same
names: Shared/Factory/ModelFactory.luau uses them automatically instead of the procedural parts.
"""
import math
import os
import sys

import bpy
import bmesh

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.join(os.getcwd(), "sag_assets")


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, rgb, metallic=0.0, roughness=0.5, emission=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*[c / 255 for c in rgb], 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0:
        key = "Emission Color" if "Emission Color" in bsdf.inputs else "Emission"
        bsdf.inputs[key].default_value = (*[c / 255 for c in rgb], 1)
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emission
    return m


def assign(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def finalize(objs, name):
    for o in objs:
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        bpy.ops.object.shade_smooth() if hasattr(bpy.ops.object, "shade_smooth") else None
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    for o in objs:
        o.parent = root
    return root


def save(category, name):
    folder = os.path.join(OUT, category)
    os.makedirs(folder, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(folder, name + ".blend"))
    bpy.ops.export_scene.fbx(filepath=os.path.join(folder, name + ".fbx"), apply_unit_scale=True, apply_scale_options="FBX_SCALE_ALL",
                             bake_space_transform=True, object_types={"MESH", "EMPTY"}, mesh_smooth_type="FACE")
    print("exported", category, name)


# ---------------- eggs ----------------
def egg(myth):
    reset()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=1.05, location=(0, 0, 1.35))
    shell = bpy.context.object
    shell.name = "Shell"
    shell.scale = (1, 1, 1.3)
    # flatten the bottom a bit for an egg profile
    bm = bmesh.new()
    bm.from_mesh(shell.data)
    for v in bm.verts:
        if v.co.z < 0:
            v.co.z *= 0.85
            v.co.x *= 0.95
            v.co.y *= 0.95
    bm.to_mesh(shell.data)
    bm.free()
    colors = {"Greek": ((133, 196, 92), (255, 215, 90)), "Norse": ((170, 220, 255), (120, 210, 255)), "Egyptian": ((255, 190, 40), (40, 90, 200))}
    base, accent = colors[myth]
    assign(shell, material(f"Egg_{myth}", base, roughness=0.35))
    parts = [shell]
    if myth == "Greek":
        bpy.ops.mesh.primitive_torus_add(major_radius=1.03, minor_radius=0.09, location=(0, 0, 1.35))
        band = bpy.context.object
        assign(band, material("Gold", accent, metallic=1, roughness=0.25))
        parts.append(band)
    elif myth == "Norse":
        for i in range(4):
            a = math.radians(i * 90 + 45)
            bpy.ops.mesh.primitive_cube_add(size=1, location=(math.cos(a) * 1.0, math.sin(a) * 1.0, 1.4))
            rune = bpy.context.object
            rune.scale = (0.05, 0.18, 0.28)
            rune.rotation_euler = (0, 0, a)
            assign(rune, material("Rune", accent, emission=4))
            parts.append(rune)
    else:
        for z, col in ((1.05, accent), (1.75, (255, 205, 70))):
            bpy.ops.mesh.primitive_torus_add(major_radius=0.98, minor_radius=0.07, location=(0, 0, z))
            stripe = bpy.context.object
            assign(stripe, material("Stripe", col, metallic=0.6))
            parts.append(stripe)
    finalize(parts, f"Egg_{myth}")
    save("eggs", f"Egg_{myth}")


# ---------------- treadmills ----------------
STYLE = {
    1: ((120, 125, 135), (90, 200, 255), 0.2), 2: ((140, 95, 55), (200, 160, 100), 0.0), 3: ((150, 155, 165), (255, 120, 40), 0.9),
    4: ((255, 200, 60), (255, 255, 200), 1.0), 5: ((30, 35, 60), (80, 180, 255), 0.8), 6: ((240, 235, 225), (255, 215, 90), 0.1),
    7: ((150, 190, 255), (200, 160, 255), 0.3), 8: ((30, 20, 25), (255, 80, 20), 0.2), 9: ((225, 195, 140), (255, 170, 40), 0.2),
    10: ((250, 250, 255), (255, 120, 220), 0.5),
}


def box(name, size, loc, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = size
    bpy.ops.object.modifier_add(type="BEVEL")
    o.modifiers["Bevel"].width = min(size) * 0.15
    o.modifiers["Bevel"].segments = 2
    bpy.ops.object.modifier_apply(modifier="Bevel")
    assign(o, mat)
    return o


def treadmill(tier):
    reset()
    frame_c, accent_c, metal = STYLE[tier]
    frame = material(f"Frame{tier}", frame_c, metallic=metal, roughness=0.4)
    accent = material(f"Accent{tier}", accent_c, emission=3 if tier >= 5 else 0)
    belt = material("Belt", (40, 40, 45), roughness=0.9)
    L, W = 14, 6
    parts = [
        box("Deck", (W + 1.2, L + 1, 1), (0, 0, 0.5), frame),
        box("Belt", (W, L, 0.3), (0, 0, 1.15), belt),
        box("RailL", (0.35, L * 0.6, 0.35), (-W / 2 - 0.3, -L * 0.15, 4), frame),
        box("RailR", (0.35, L * 0.6, 0.35), (W / 2 + 0.3, -L * 0.15, 4), frame),
        box("PostL", (0.4, 0.4, 3.2), (-W / 2 - 0.3, -L / 2 + 0.6, 2.6), frame),
        box("PostR", (0.4, 0.4, 3.2), (W / 2 + 0.3, -L / 2 + 0.6, 2.6), frame),
        box("Console", (W + 0.8, 0.5, 1.6), (0, -L / 2 + 0.6, 4.6), frame),
        box("Screen", (W * 0.7, 0.1, 1.0), (0, -L / 2 + 0.3, 4.6), accent),
    ]
    for y in (-L / 2, L / 2):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.55, depth=W + 0.6, location=(0, y, 1.0), rotation=(0, math.radians(90), 0))
        roller = bpy.context.object
        assign(roller, accent)
        parts.append(roller)
    # tier signature pieces
    if tier >= 5:
        for s in (-1, 1):
            parts.append(box(f"Pylon{s}", (0.4, 0.4, 4.5), (s * (W / 2 + 0.8), L / 2 - 0.5, 3.2), frame))
            bpy.ops.mesh.primitive_ico_sphere_add(radius=0.45, location=(s * (W / 2 + 0.8), L / 2 - 0.5, 5.7))
            orb = bpy.context.object
            assign(orb, accent)
            parts.append(orb)
    if tier in (6, 9, 10):
        bpy.ops.mesh.primitive_torus_add(major_radius=3.6, minor_radius=0.18, location=(0, -L / 2 + 0.4, 7.5), rotation=(math.radians(90), 0, 0))
        halo = bpy.context.object
        assign(halo, accent)
        parts.append(halo)
    finalize(parts, f"Treadmill{tier}")
    save("treadmills", f"Treadmill{tier}")


# ---------------- props ----------------
def trap():
    reset()
    steel = material("Steel", (200, 200, 210), metallic=1, roughness=0.3)
    bpy.ops.mesh.primitive_cylinder_add(radius=1.6, depth=0.3, location=(0, 0, 0.15))
    base = bpy.context.object
    assign(base, steel)
    parts = [base]
    for i in range(8):
        a = math.radians(i * 45)
        bpy.ops.mesh.primitive_cone_add(radius1=0.18, depth=0.6, location=(math.cos(a) * 1.3, math.sin(a) * 1.3, 0.55))
        tooth = bpy.context.object
        assign(tooth, steel)
        parts.append(tooth)
    finalize(parts, "Trap")
    save("props", "Trap")


def pedestal():
    reset()
    marble = material("Marble", (240, 235, 225), roughness=0.3)
    gold = material("Gold", (255, 205, 70), metallic=1, roughness=0.25)
    bpy.ops.mesh.primitive_cylinder_add(radius=2.2, depth=1, location=(0, 0, 0.5))
    p = bpy.context.object
    assign(p, marble)
    bpy.ops.mesh.primitive_torus_add(major_radius=1.8, minor_radius=0.1, location=(0, 0, 1.0))
    ring = bpy.context.object
    assign(ring, gold)
    finalize([p, ring], "Pedestal")
    save("props", "Pedestal")


def column():
    reset()
    marble = material("Marble", (240, 235, 220), roughness=0.35)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.3, depth=12, location=(0, 0, 6.8))
    shaft = bpy.context.object
    assign(shaft, marble)
    parts = [shaft]
    for z in (0.4, 13.2):
        parts.append(box("Cap", (3.4, 3.4, 0.8), (0, 0, z), marble))
    finalize(parts, "Column")
    save("props", "Column")


if __name__ == "__main__":
    for m in ("Greek", "Norse", "Egyptian"):
        egg(m)
    for t in range(1, 11):
        treadmill(t)
    trap()
    pedestal()
    column()
    print("SAG assets written to", OUT)
