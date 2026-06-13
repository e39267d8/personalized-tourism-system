# -*- coding: utf-8 -*-
"""
生成颐和园内部步行演示图 seed（database/seeds/seed_yiheyuan_demo_map.sql）。

背景：真实 OSM 内部路网碎成数千个连通块（故宫 3181 块、北大 415 块，缝隙中位
数 32 米），无法支撑"按路网距离给附近设施排序"的验收。本脚本手工搭一张
*连通* 的步行网 + 真实分类设施，供场所查询/内部导航验收演示。算法（Dijkstra
路网距离、类别过滤、关键词查找）是真实的，仅这一个演示景点的地图为人工构造。

幂等：seed 用 source_ref 前缀 'yiheyuan-demo:%' 标记本脚本数据，重跑前先删除
同前缀旧数据，不影响其它景点。
"""

import math

SPOT_NAME = "颐和园"
SRC = "yiheyuan-demo"
CENTER_LAT, CENTER_LNG = 39.9985, 116.2755

# 经纬度每度的米数（颐和园纬度约 40°）
M_PER_LAT = 111_000.0
M_PER_LNG = 111_000.0 * math.cos(math.radians(CENTER_LAT))

def coord(dx_m, dy_m):
    """以中心点为原点，按米偏移换算经纬度（dx 东向，dy 北向）。"""
    return CENTER_LNG + dx_m / M_PER_LNG, CENTER_LAT + dy_m / M_PER_LAT

def dist_m(a, b):
    (lng1, lat1), (lng2, lat2) = a, b
    return math.hypot((lng1 - lng2) * M_PER_LNG, (lat1 - lat2) * M_PER_LAT)

# --- 路网节点（步行路径/景点/入口），坐标用相对中心的米偏移布置成连通网 ---
# key: (中文名, node_type, 东向米, 北向米)
WAYPOINTS = {
    "e_dong":   ("东宫门",      "entrance", 620,  120),
    "w1":       ("东宫门广场",  "scenic",   480,  110),
    "w2":       ("仁寿殿",      "scenic",   360,  140),
    "w3":       ("玉澜堂",      "scenic",   250,   60),
    "w4":       ("乐寿堂",      "scenic",   170,  150),
    "w5":       ("长廊东口",    "scenic",    60,  120),
    "w6":       ("排云殿前",    "scenic",  -120,  150),
    "w7":       ("石舫",        "scenic",  -340,  120),
    "w8":       ("佛香阁下",    "scenic",  -120,  290),
    "w9":       ("苏州街",      "scenic",  -120,  430),
    "w10":      ("北宫门内",    "scenic",   -40,  520),
    "e_bei":    ("北宫门",      "entrance",  20,  600),
    "w11":      ("昆明湖东堤",  "scenic",   430, -120),
    "w12":      ("知春亭",      "scenic",   300, -200),
    "w13":      ("十七孔桥北",  "scenic",   180, -360),
    "w14":      ("南湖岛",      "scenic",    60, -470),
    "w15":      ("铜牛",        "scenic",   330, -300),
    "w16":      ("西堤玉带桥",  "scenic",  -360, -260),
    "w17":      ("新建宫门内",  "scenic",  -430, -120),
    "e_xin":    ("新建宫门",    "entrance", -540, -150),
}

# --- 步行路径边（无向，脚本自动补双向）；构成环湖主路 + 长廊 + 万寿山支线 ---
PATH_EDGES = [
    ("e_dong", "w1"), ("w1", "w2"), ("w2", "w3"), ("w3", "w4"), ("w4", "w5"),
    ("w5", "w6"), ("w6", "w7"),                       # 长廊（沿北岸东西向）
    ("w6", "w8"), ("w8", "w9"), ("w9", "w10"), ("w10", "e_bei"),  # 万寿山 → 北宫门
    ("w1", "w11"), ("w11", "w12"), ("w12", "w13"), ("w13", "w14"),  # 东堤 → 十七孔桥 → 南湖岛
    ("w11", "w15"), ("w15", "w13"),                   # 铜牛连东堤与桥
    ("w7", "w16"), ("w16", "w17"), ("w17", "e_xin"),  # 西堤 → 新建宫门
    ("w14", "w16"),                                   # 南湖岛 ↔ 西堤，闭合环湖
]

# --- 电瓶车线（景区固定线路，travel_mode='shuttle'，验收 4c）---
# 沿主轴的固定观光线：东宫门 → 长廊东口 → 石舫 → 佛香阁下 → 北宫门，
# 速度比步行快（5 vs 1.2 m/s），拥挤度低（专线）。停靠点复用已有路网节点。
# 演示：东宫门到北宫门，纯步行很慢；步行+电瓶车混合，算法自动选电瓶车更快。
SHUTTLE_EDGES = [
    ("e_dong", "w5"),   # 东宫门 → 长廊东口
    ("w5", "w7"),       # 长廊东口 → 石舫
    ("w7", "w8"),       # 石舫 → 佛香阁下
    ("w8", "w10"),      # 佛香阁下 → 北宫门内
    ("w10", "e_bei"),   # 北宫门内 → 北宫门
]

# --- 设施：(名称, 类型, 最近路网节点 key, 评分, 价位) ---
# 类型用系统已识别的英文枚举：toilet/restaurant/shop/service/atm
FACILITIES = [
    ("东宫门公共卫生间",   "toilet",     "w1",  4.3, 0),
    ("仁寿殿游客服务点",   "service",    "w2",  4.5, 0),
    ("听鹂馆饭庄",         "restaurant", "w4",  4.6, 3),
    ("长廊东口卫生间",     "toilet",     "w5",  4.2, 0),
    ("排云殿文创商店",     "shop",       "w6",  4.4, 2),
    ("石舫咖啡厅",         "restaurant", "w7",  4.3, 2),
    ("佛香阁观景平台",     "service",    "w8",  4.8, 0),
    ("苏州街小吃店",       "restaurant", "w9",  4.1, 1),
    ("北宫门综合超市",     "shop",       "w10", 4.2, 1),
    ("北宫门公共卫生间",   "toilet",     "w10", 4.0, 0),
    ("知春亭茶室",         "restaurant", "w12", 4.5, 2),
    ("十七孔桥服务驿站",   "service",    "w13", 4.3, 0),
    ("南湖岛公共卫生间",   "toilet",     "w14", 3.9, 0),
    ("西堤自助售卖机",     "atm",        "w16", 4.0, 1),
    ("新建宫门卫生间",     "toilet",     "w17", 4.1, 0),
    ("东堤便利店",         "shop",       "w11", 4.2, 1),
]

# 设施摆在最近路网节点旁约 18 米处（错开方向，避免重叠）
FAC_OFFSET_M = 18.0


def node_coord(key):
    _, _, dx, dy = WAYPOINTS[key]
    return coord(dx, dy)


def sql_escape(s):
    return s.replace("'", "''")


def main():
    lines = []
    w = lines.append
    w("-- =====================================================")
    w("-- 颐和园内部步行演示图（人工构造的连通路网 + 分类设施）")
    w("-- 由 scripts/gen_yiheyuan_demo_map.py 生成，请勿手工编辑。")
    w("-- 用途：场所查询/内部导航验收演示。真实 OSM 路网碎片化无法用，")
    w("--       本图保证连通，算法（Dijkstra 路网距离/类别过滤/关键词）真实。")
    w("-- 幂等：按 source_ref 前缀 'yiheyuan-demo:%' 清理后重建。")
    w("-- =====================================================")
    w("SET client_encoding = 'UTF8';")
    w("BEGIN;")
    w("")
    w("DO $$")
    w("DECLARE")
    w("    v_spot INTEGER;")
    w("BEGIN")
    w(f"    SELECT id INTO v_spot FROM scenic_spots WHERE name = '{SPOT_NAME}' AND city = '北京市' LIMIT 1;")
    w("    IF v_spot IS NULL THEN")
    w("        RAISE EXCEPTION '未找到景点 颐和园，请先执行 imports/amap_pois_supplement.sql';")
    w("    END IF;")
    w("")
    w("    -- 1. 清理本脚本旧数据（边→节点→设施，按 source_ref 前缀）")
    w(f"    DELETE FROM graph_edges WHERE source_ref LIKE '{SRC}:%';")
    w(f"    DELETE FROM graph_nodes WHERE source_ref LIKE '{SRC}:%';")
    w(f"    DELETE FROM facilities  WHERE source_ref LIKE '{SRC}:%';")
    w("")
    w("    -- 2. 设施（facilities）")
    for i, (name, ftype, _near, rating, price) in enumerate(FACILITIES):
        lng, lat = node_coord(_near)
        # 在节点旁错开摆放
        ang = (i * 2.399963)  # 黄金角，均匀错开
        flng = lng + (FAC_OFFSET_M * math.cos(ang)) / M_PER_LNG
        flat = lat + (FAC_OFFSET_M * math.sin(ang)) / M_PER_LAT
        ref = f"{SRC}:fac:{i}"
        price_sql = "NULL" if price == 0 else str(price)
        w("    INSERT INTO facilities (name, type, location, address, rating, price_level, "
          "opening_hours, scenic_spot_id, source, source_ref)")
        w(f"    VALUES ('{sql_escape(name)}', '{ftype}', "
          f"ST_SetSRID(ST_MakePoint({flng:.6f}, {flat:.6f}), 4326)::geography, "
          f"'颐和园内', {rating}, {price_sql}, '08:00-17:00', v_spot, 'demo', '{ref}');")
    w("")
    w("    -- 3. 路网节点（graph_nodes）：路径/景点/入口")
    for key, (name, ntype, dx, dy) in WAYPOINTS.items():
        lng, lat = coord(dx, dy)
        ref = f"{SRC}:node:{key}"
        w("    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)")
        w(f"    VALUES ('{sql_escape(name)}', ST_SetSRID(ST_MakePoint({lng:.6f}, {lat:.6f}), 4326)::geography, "
          f"'{ntype}', v_spot, 'demo', '{ref}');")
    w("")
    w("    -- 4. 设施对应的路网节点（node_type='facility'，绑定 facility_id）")
    for i, (name, ftype, _near, rating, price) in enumerate(FACILITIES):
        fac_ref = f"{SRC}:fac:{i}"
        node_ref = f"{SRC}:facnode:{i}"
        w("    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)")
        w(f"    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', '{node_ref}'")
        w(f"    FROM facilities f WHERE f.source_ref = '{fac_ref}';")
    w("")
    # 路径边用 source='osm'：系统以 'osm' 标记"可导航真实道路"（route_uses_real_road
    # 据此放行内部路线规划，前端 SVG 据此画实线）。接入边用 'generated' 画虚线。
    w("    -- 5. 步行路径边（双向，source='osm' 标记为可导航真实道路）")
    for a, b in PATH_EDGES:
        ca, cb = node_coord(a), node_coord(b)
        d = dist_m(ca, cb)
        t = int(d / 1.2)
        for (x, y) in ((a, b), (b, a)):
            xref, yref = f"{SRC}:node:{x}", f"{SRC}:node:{y}"
            w("    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, "
              "base_weight, congestion_level, source, source_ref)")
            w(f"    SELECT na.id, nb.id, {d:.1f}, 'walk', {t}, {d/100.0:.2f}, 2, 'osm', '{SRC}:edge'")
            w(f"    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='{xref}' AND nb.source_ref='{yref}';")
    w("")
    w("    -- 5b. 电瓶车线（双向，travel_mode='shuttle'，速度快、拥挤度低，验收 4c）")
    for a, b in SHUTTLE_EDGES:
        ca, cb = node_coord(a), node_coord(b)
        d = dist_m(ca, cb)
        t = int(d / 5.0)  # 电瓶车 5 m/s
        for (x, y) in ((a, b), (b, a)):
            xref, yref = f"{SRC}:node:{x}", f"{SRC}:node:{y}"
            w("    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, "
              "base_weight, congestion_level, source, source_ref)")
            w(f"    SELECT na.id, nb.id, {d:.1f}, 'shuttle', {t}, {d/100.0:.2f}, 1, 'osm', '{SRC}:shuttle'")
            w(f"    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='{xref}' AND nb.source_ref='{yref}';")
    w("")
    w("    -- 6. 设施接入边（双向，source='generated' 表示接入连接边）")
    for i, (name, ftype, near, rating, price) in enumerate(FACILITIES):
        node_ref = f"{SRC}:facnode:{i}"
        near_ref = f"{SRC}:node:{near}"
        # 接入距离 = 设施节点到最近路网节点（约 FAC_OFFSET_M）
        d = FAC_OFFSET_M
        t = int(d / 1.2)
        for (x, y) in ((node_ref, near_ref), (near_ref, node_ref)):
            w("    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, "
              "base_weight, congestion_level, source, source_ref)")
            w(f"    SELECT na.id, nb.id, {d:.1f}, 'walk', {t}, {d/100.0:.2f}, 2, 'generated', '{SRC}:connector'")
            w(f"    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='{x}' AND nb.source_ref='{y}';")
    w("")
    w("    RAISE NOTICE '颐和园演示图已重建: % 路网节点, % 设施', "
      f"{len(WAYPOINTS)}, {len(FACILITIES)};")
    w("END $$;")
    w("")
    w("COMMIT;")

    out = "\n".join(lines) + "\n"
    path = "database/seeds/seed_yiheyuan_demo_map.sql"
    with open(path, "w", encoding="utf-8") as f:
        f.write(out)
    print(f"已生成 {path}")
    print(f"  路网节点: {len(WAYPOINTS)}  路径边(双向): {len(PATH_EDGES)*2}  "
          f"设施: {len(FACILITIES)}  接入边(双向): {len(FACILITIES)*2}")


if __name__ == "__main__":
    main()
