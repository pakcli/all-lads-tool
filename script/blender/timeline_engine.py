"""
Procedural 3D Timeline Engine for Blender
Supports:
- Two-State Camera (Value-to-Value Tour -> Whole-Value Overview)
- Multi-Row Parallel Linear Layout (Row per Row LTR)
- Dynamic Sorting: By Date, Investment USD, or Copies/Users
- Direction Swap (LTR vs RTL)
- 3D Cash Stacks, Humanoid Crowds, and Floating Inventor Badges
"""

import bpy
import math
import csv
import os

DEFAULT_CSV = r"E:\proj\all-lads-tool\data\softwares_timeline.csv"

def get_or_create_mat(name, color_rgba):
    if name in bpy.data.materials:
        mat = bpy.data.materials[name]
    else:
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        nodes.clear()
        emission = nodes.new(type="ShaderNodeEmission")
        emission.inputs["Color"].default_value = color_rgba
        output = nodes.new(type="ShaderNodeOutputMaterial")
        mat.node_tree.links.new(emission.outputs["Emission"], output.inputs["Surface"])
    return mat

def load_data(csv_path=DEFAULT_CSV):
    items = []
    if not os.path.exists(csv_path):
        print(f"[WARN] CSV not found: {csv_path}")
        return items
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            items.append({
                "id": row.get("id", ""),
                "title": row.get("title", ""),
                "date_release": row.get("date_release", ""),
                "who_invented": row.get("who_invented", ""),
                "investment_usd": float(row.get("investment_usd", 0) or 0),
                "copies": float(row.get("copies", 0) or 0),
                "desc": row.get("desc", "")
            })
    return items

def sort_items(items, sort_key="date_release", reverse=False):
    if sort_key == "date_release":
        return sorted(items, key=lambda x: x["date_release"], reverse=reverse)
    elif sort_key in ["price", "investment_usd", "cost"]:
        return sorted(items, key=lambda x: x["investment_usd"], reverse=reverse)
    elif sort_key in ["popularity", "copies", "users"]:
        return sorted(items, key=lambda x: x["copies"], reverse=reverse)
    return items

def format_currency(val):
    if val >= 1_000_000_000:
        return f"${val/1_000_000_000:.1f}B"
    elif val >= 1_000_000:
        return f"${val/1_000_000:.1f}M"
    elif val >= 1_000:
        return f"${val/1_000:.0f}K"
    return f"${val:.0f}"

def format_users(val):
    if val >= 1_000_000_000:
        return f"{val/1_000_000_000:.1f}B Users"
    elif val >= 1_000_000:
        return f"{val/1_000_000:.0f}M Users"
    elif val >= 1_000:
        return f"{val/1_000:.0f}K Users"
    return f"{val:.0f} Users"

def build_scene(config=None):
    cfg = {
        "csv_path": DEFAULT_CSV,
        "sort_by": "date_release",      # "date_release" | "investment_usd" | "copies"
        "sort_reverse": False,
        "layout_mode": "row_per_row",    # "row_per_row" | "grid_arena"
        "items_per_row": 4,
        "panning_direction": "LTR",      # "LTR" | "RTL"
        "spacing_x": 2.6,
        "row_gap_y": 3.8
    }
    if config:
        cfg.update(config)

    # 1. Clean old objects
    to_remove = [obj for obj in bpy.data.objects if obj.name.startswith("TL_") or obj.name.startswith("Monkee_")]
    for obj in to_remove:
        bpy.data.objects.remove(obj, do_unlink=True)

    # 2. Materials
    mat_chassis  = get_or_create_mat("TL_Mat_Chassis",  (0.06, 0.06, 0.08, 1.0))
    mat_gold     = get_or_create_mat("TL_Mat_Gold",     (0.92, 0.72, 0.22, 1.0))
    mat_parch    = get_or_create_mat("TL_Mat_Parch",    (0.93, 0.90, 0.82, 1.0))
    mat_muted    = get_or_create_mat("TL_Mat_Muted",    (0.50, 0.50, 0.55, 1.0))
    mat_stem     = get_or_create_mat("TL_Mat_Stem",     (0.40, 0.40, 0.45, 1.0))
    mat_ruby     = get_or_create_mat("TL_Mat_Ruby",     (0.88, 0.22, 0.22, 1.0))
    mat_emerald  = get_or_create_mat("TL_Mat_Emerald",  (0.18, 0.72, 0.45, 1.0))
    mat_humanoid = get_or_create_mat("TL_Mat_Humanoid", (0.30, 0.80, 0.95, 1.0)) # Cyan crowd
    mat_coin     = get_or_create_mat("TL_Mat_Coin",     (0.96, 0.85, 0.35, 1.0))

    # 3. Load & Sort
    raw_items = load_data(cfg["csv_path"])
    items = sort_items(raw_items, cfg["sort_by"], cfg["sort_reverse"])

    if cfg["panning_direction"] == "RTL":
        items = list(reversed(items))

    # 4. Build Layout
    bpy.context.preferences.edit.keyframe_new_interpolation_type = 'BACK'
    station_locations = []

    items_per_row = cfg["items_per_row"]
    row_count = math.ceil(len(items) / items_per_row)

    max_cost = max([x["investment_usd"] for x in items] or [1])
    max_users = max([x["copies"] for x in items] or [1])

    for idx, item in enumerate(items):
        row_idx = idx // items_per_row
        col_idx = idx % items_per_row

        # Center columns in row
        x_center = (col_idx - (items_per_row - 1) / 2.0) * cfg["spacing_x"]
        
        # Row 1 is further back (Y > 0), Row 2 in front (Y <= 0)
        y_center = ((row_count - 1) / 2.0 - row_idx) * cfg["row_gap_y"]
        z_base = 0.6 if row_idx == 0 else 0.4

        # Station Root Empty
        bpy.ops.object.empty_add(type='PLAIN_AXES', location=(x_center, y_center, z_base))
        st_root = bpy.context.active_object
        st_root.name = f"TL_Station_{idx+1}_{item['id']}"
        station_locations.append((x_center, y_center, z_base))

        # Anchor Joint
        bpy.ops.mesh.primitive_uv_sphere_add(location=(0, 0, 0), radius=0.065)
        anchor = bpy.context.active_object
        anchor.name = f"TL_Anchor_{idx+1}"
        anchor.data.materials.append(mat_gold)
        anchor.parent = st_root

        # Stem
        stem_h = 1.3
        bpy.ops.mesh.primitive_cylinder_add(location=(0, 0, stem_h / 2), radius=0.015, depth=stem_h)
        stem = bpy.context.active_object
        stem.name = f"TL_Stem_{idx+1}"
        stem.data.materials.append(mat_stem)
        stem.parent = st_root

        # Badge Box
        title_text = f"{item['title']} [{item['date_release'][:4]}]"
        badge_w = len(title_text) * 0.075 + 0.25
        badge_h = 0.22
        bpy.ops.mesh.primitive_cube_add(location=(0, 0.02, stem_h), size=1.0)
        badge = bpy.context.active_object
        badge.name = f"TL_Badge_{idx+1}"
        badge.scale = (badge_w, 0.03, badge_h)
        badge.data.materials.append(mat_gold if item["investment_usd"] > 100_000_000 else mat_emerald)
        bev = badge.modifiers.new(name="Bevel", type='BEVEL')
        bev.width = 0.03
        badge.parent = st_root

        # Badge Text
        bpy.ops.object.text_add(location=(0, -0.01, stem_h - 0.04))
        t_title = bpy.context.active_object
        t_title.name = f"TL_Title_{idx+1}"
        t_title.data.body = title_text
        t_title.data.size = 0.11
        t_title.data.extrude = 0.015
        t_title.data.align_x = 'CENTER'
        t_title.rotation_euler = (math.radians(90), 0, 0)
        t_title.data.materials.append(mat_chassis)
        t_title.parent = st_root

        # Inventor Avatar Coin (who_invented badge floating above stem)
        if item["who_invented"]:
            coin_z = stem_h + 0.32
            bpy.ops.mesh.primitive_cylinder_add(location=(0, 0, coin_z), radius=0.15, depth=0.04)
            coin = bpy.context.active_object
            coin.name = f"TL_InventorCoin_{idx+1}"
            coin.rotation_euler = (math.radians(90), 0, 0)
            coin.data.materials.append(mat_coin)
            coin.parent = st_root

            # Inventor Name Label
            bpy.ops.object.text_add(location=(0, -0.04, coin_z + 0.18))
            t_inv = bpy.context.active_object
            t_inv.name = f"TL_InventorName_{idx+1}"
            t_inv.data.body = item["who_invented"].split(" (")[0]
            t_inv.data.size = 0.09
            t_inv.data.align_x = 'CENTER'
            t_inv.rotation_euler = (math.radians(90), 0, 0)
            t_inv.data.materials.append(mat_parch)
            t_inv.parent = st_root

        # 3D Cash Stack (Left side of stem, height proportional to investment)
        cost_ratio = (item["investment_usd"] / max_cost) if max_cost > 0 else 0.1
        cash_h = max(0.15, cost_ratio * 1.8)
        cash_mat = mat_ruby if item["investment_usd"] >= 200_000_000 else mat_emerald
        
        bpy.ops.mesh.primitive_cube_add(location=(-0.35, -0.15, cash_h / 2), size=1.0)
        cash_stack = bpy.context.active_object
        cash_stack.name = f"TL_CashStack_{idx+1}"
        cash_stack.scale = (0.35, 0.25, cash_h)
        cash_stack.data.materials.append(cash_mat)
        cash_stack.parent = st_root

        # Cost Label
        bpy.ops.object.text_add(location=(-0.35, -0.22, cash_h + 0.05))
        t_cost = bpy.context.active_object
        t_cost.name = f"TL_CostLabel_{idx+1}"
        t_cost.data.body = format_currency(item["investment_usd"])
        t_cost.data.size = 0.10
        t_cost.data.extrude = 0.01
        t_cost.data.align_x = 'CENTER'
        t_cost.rotation_euler = (math.radians(90), 0, 0)
        t_cost.data.materials.append(cash_mat)
        t_cost.parent = st_root

        # 3D Humanoid Crowd (Right side, clusters of miniature human pawns)
        user_ratio = (item["copies"] / max_users) if max_users > 0 else 0
        num_pawns = max(1, min(12, int(user_ratio * 12)))

        for p_idx in range(num_pawns):
            px = 0.30 + (p_idx % 3) * 0.16
            py = -0.10 - (p_idx // 3) * 0.16
            # Simple pawn capsule (head + body)
            bpy.ops.mesh.primitive_cylinder_add(location=(px, py, 0.12), radius=0.035, depth=0.18)
            pawn = bpy.context.active_object
            pawn.name = f"TL_Pawn_{idx+1}_{p_idx}"
            pawn.data.materials.append(mat_humanoid)
            pawn.parent = st_root

        # Userbase Label
        bpy.ops.object.text_add(location=(0.45, -0.25, 0.45))
        t_users = bpy.context.active_object
        t_users.name = f"TL_UserLabel_{idx+1}"
        t_users.data.body = format_users(item["copies"])
        t_users.data.size = 0.09
        t_users.data.align_x = 'CENTER'
        t_users.rotation_euler = (math.radians(90), 0, 0)
        t_users.data.materials.append(mat_humanoid)
        t_users.parent = st_root

        # Staggered Spring Pop
        pop_f = 10 + idx * 14
        st_root.scale = (0.001, 0.001, 0.001)
        st_root.keyframe_insert(data_path="scale", frame=max(1, pop_f - 10))
        st_root.scale = (1.0, 1.0, 1.0)
        st_root.keyframe_insert(data_path="scale", frame=pop_f)

    # 5. Camera Setup (Value-to-Value Tour -> Whole Overview Finale)
    bpy.context.preferences.edit.keyframe_new_interpolation_type = 'BEZIER'
    cam = bpy.data.objects.get("Camera")
    if not cam:
        bpy.ops.object.camera_add(location=(0, -8.0, 2.0), rotation=(math.radians(85), 0, 0))
        cam = bpy.context.active_object
        cam.name = "Camera"
    else:
        cam.animation_data_clear()

    bpy.context.scene.camera = cam

    # State 1: Panning Value-to-Value Tour (Visits Row 1 LTR, then Row 2 LTR)
    current_frame = 1
    for idx, (sx, sy, sz) in enumerate(station_locations):
        f_target = 10 + idx * 14
        cam.location = (sx, sy - 4.5, sz + 0.8)
        cam.rotation_euler = (math.radians(82), 0, 0)
        cam.keyframe_insert(data_path="location", frame=f_target)
        cam.keyframe_insert(data_path="rotation_euler", frame=f_target)

    # State 2: Pull-back to Whole-Value Overview (Grand Finale Hero Shot)
    finale_frame = 10 + len(station_locations) * 14 + 18
    cam.location = (0, -11.5, 3.8)
    cam.rotation_euler = (math.radians(76), 0, 0)
    cam.keyframe_insert(data_path="location", frame=finale_frame)
    cam.keyframe_insert(data_path="rotation_euler", frame=finale_frame)

    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = finale_frame + 30

    print(f"[OK] Timeline Engine Built: {len(items)} stations, Sorted by '{cfg['sort_by']}', Direction '{cfg['panning_direction']}', Layout '{cfg['layout_mode']}'.")

if __name__ == "__main__":
    build_scene()
