# -*- coding: utf-8 -*-
"""
生成北京大学校园内部连通路网 seed（database/seeds/seed_pku_curated_map.sql）。

背景：database/imports/internal_navigation_pku.sql 已导入 OSM 真实校园节点、建筑、
设施和道路边，但开放地图里的校园内部路网存在断裂片区，设施查询时经常只能在小连通
块里排序。这个脚本参考颐和园 seed 的做法，在正式 graph_nodes / graph_edges /
facilities 表内补一层人工校核的连通校园主路网。

注意：本 seed 不把人工校核边标成 OSM。道路边使用 source='campus_curated'，
设施接入短边使用 source='generated'，便于答辩时诚实说明数据来源。
"""

import json
import math

SPOT_NAME = "北京大学"
SRC = "pku-curated"
ROAD_SOURCE = "campus_curated"

M_PER_LAT = 111_000.0
M_PER_LNG = 111_000.0 * math.cos(math.radians(39.992))


def dist_m(a, b):
    lng1, lat1 = a
    lng2, lat2 = b
    return math.hypot((lng1 - lng2) * M_PER_LNG, (lat1 - lat2) * M_PER_LAT)


def offset_coord(lng, lat, meters, angle):
    return (
        lng + (meters * math.cos(angle)) / M_PER_LNG,
        lat + (meters * math.sin(angle)) / M_PER_LAT,
    )


def sql_escape(value):
    return str(value).replace("'", "''")


def json_sql(value):
    return "'" + sql_escape(json.dumps(value, ensure_ascii=False, separators=(",", ":"))) + "'::jsonb"


def point_wkt(lng, lat):
    return f"ST_SetSRID(ST_MakePoint({lng:.7f}, {lat:.7f}), 4326)::geography"


def line_wkt(a, b):
    return (
        "'SRID=4326;LINESTRING("
        f"{a[0]:.7f} {a[1]:.7f}, {b[0]:.7f} {b[1]:.7f}"
        ")'"
    )


# key: (名称, node_type, 经度, 纬度, 拥挤等级 1-4)
WAYPOINTS = {
    "west_gate": ("西门", "entrance", 116.2985927, 39.9932960, 2),
    "sackler": ("赛克勒考古与艺术博物馆", "building", 116.2997721, 39.9944351, 2),
    "jingchun": ("镜春园南路", "scenic", 116.3012961, 39.9946135, 2),
    "langrun": ("朗润园东路", "scenic", 116.3047211, 39.9947539, 2),
    "weiming_west": ("未名湖西岸", "scenic", 116.3005837, 39.9936661, 3),
    "admin": ("办公楼（贝公楼）", "building", 116.3004075, 39.9933434, 2),
    "chemistry": ("化学楼", "building", 116.2997763, 39.9923405, 2),
    "history": ("校史馆", "building", 116.3000564, 39.9920253, 2),
    "library": ("图书馆", "building", 116.3033211, 39.9915228, 3),
    "first_teaching": ("第一教学楼", "building", 116.3043376, 39.9915470, 3),
    "weiming_south": ("未名湖南路", "scenic", 116.3060249, 39.9918029, 3),
    "boya": ("博雅塔", "scenic", 116.3057830, 39.9926368, 2),
    "weiming_east": ("未名湖东路", "scenic", 116.3051885, 39.9942375, 2),
    "law": ("法学院（凯原楼）", "building", 116.3074497, 39.9932499, 3),
    "guanghua": ("光华管理学院", "building", 116.3071686, 39.9943315, 3),
    "government": ("政府管理学院（廖凯原楼）", "building", 116.3084343, 39.9944704, 2),
    "chengfu": ("成府园", "scenic", 116.3070746, 39.9933710, 2),
    "lakeview": ("北大博雅国际酒店", "building", 116.3072893, 39.9967281, 2),
    "north_gate": ("北门", "entrance", 116.3107343, 39.9906469, 2),
    "east_gate": ("东门", "entrance", 116.3121800, 39.9921700, 2),
    "science": ("理科教学楼", "building", 116.3071067, 39.9902876, 4),
    "second_teaching": ("第二教学楼", "building", 116.3073140, 39.9882798, 3),
    "fourth_teaching": ("第四教学楼", "building", 116.3080873, 39.9879980, 2),
    "gym": ("邱德拔体育馆", "building", 116.3089475, 39.9873434, 2),
    "hall": ("百周年纪念讲堂", "building", 116.3044872, 39.9885459, 3),
    "nongyuan": ("农园餐厅", "building", 116.3060962, 39.9875268, 4),
    "south_gate": ("南门", "entrance", 116.3059500, 39.9860800, 2),
    "hospital": ("校医院", "building", 116.3021076, 39.9893082, 2),
    "shao_yuan": ("勺园", "building", 116.2995321, 39.9904189, 2),
}


# 无向主路网，脚本会自动写入双向边。最后一个数字是该路段拥挤等级。
PATH_EDGES = [
    ("west_gate", "sackler", 2),
    ("sackler", "jingchun", 2),
    ("jingchun", "langrun", 2),
    ("jingchun", "weiming_west", 2),
    ("weiming_west", "admin", 3),
    ("admin", "history", 2),
    ("history", "chemistry", 2),
    ("chemistry", "library", 2),
    ("library", "first_teaching", 3),
    ("first_teaching", "weiming_south", 3),
    ("weiming_south", "boya", 2),
    ("boya", "weiming_east", 2),
    ("weiming_east", "langrun", 2),
    ("weiming_east", "guanghua", 3),
    ("guanghua", "government", 3),
    ("government", "chengfu", 2),
    ("chengfu", "east_gate", 2),
    ("government", "lakeview", 2),
    ("lakeview", "north_gate", 2),
    ("weiming_east", "law", 3),
    ("law", "chengfu", 3),
    ("library", "science", 4),
    ("science", "second_teaching", 4),
    ("second_teaching", "fourth_teaching", 2),
    ("fourth_teaching", "gym", 2),
    ("gym", "south_gate", 2),
    ("second_teaching", "hall", 3),
    ("hall", "nongyuan", 4),
    ("nongyuan", "south_gate", 3),
    ("hall", "hospital", 2),
    ("hospital", "shao_yuan", 2),
    ("shao_yuan", "west_gate", 2),
    ("admin", "shao_yuan", 2),
    ("admin", "library", 3),
    ("first_teaching", "boya", 3),
    ("science", "east_gate", 3),
]


# (名称, 类型, 最近路网节点, 评分, 价位)
FACILITIES = [
    ("西门公共卫生间", "toilet", "west_gate", 4.2, None),
    ("赛克勒馆服务台", "service", "sackler", 4.5, None),
    ("未名湖公共卫生间", "toilet", "weiming_west", 4.1, None),
    ("博雅塔游客服务点", "service", "boya", 4.6, None),
    ("图书馆咖啡吧", "cafe", "library", 4.4, 2),
    ("图书馆自助售卖点", "shop", "library", 4.1, 1),
    ("第一教学楼饮水服务点", "service", "first_teaching", 4.0, None),
    ("理科楼公共卫生间", "toilet", "science", 4.0, None),
    ("第二教学楼便利店", "shop", "second_teaching", 4.2, 1),
    ("百讲票务服务处", "shop", "hall", 4.3, 1),
    ("百讲公共卫生间", "toilet", "hall", 4.0, None),
    ("农园餐厅", "restaurant", "nongyuan", 4.5, 2),
    ("农园小卖部", "shop", "nongyuan", 4.2, 1),
    ("南门公共卫生间", "toilet", "south_gate", 4.0, None),
    ("校医院服务点", "service", "hospital", 4.2, None),
    ("勺园食堂", "restaurant", "shao_yuan", 4.3, 2),
    ("勺园公共卫生间", "toilet", "shao_yuan", 4.0, None),
    ("校史馆文创商店", "shop", "history", 4.4, 2),
    ("办公楼自助银行", "atm", "admin", 4.1, None),
    ("化学楼公共卫生间", "toilet", "chemistry", 4.0, None),
    ("光华咖啡厅", "cafe", "guanghua", 4.4, 2),
    ("法学院服务点", "service", "law", 4.2, None),
    ("东门便利店", "shop", "east_gate", 4.1, 1),
    ("北门公共卫生间", "toilet", "north_gate", 4.0, None),
    ("中关新园超市", "shop", "lakeview", 4.2, 1),
    ("成府园食堂", "restaurant", "chengfu", 4.1, 2),
    ("体育馆饮料售卖点", "shop", "gym", 4.0, 1),
]

FAC_OFFSET_M = 18.0


def waypoint_coord(key):
    _, _, lng, lat, _ = WAYPOINTS[key]
    return lng, lat


def edge_seconds(distance, congestion):
    speed_by_congestion = {1: 1.35, 2: 1.20, 3: 1.00, 4: 0.78}
    speed = speed_by_congestion.get(congestion, 1.20)
    return max(1, int(round(distance / speed)))


def main():
    lines = []
    w = lines.append
    w("-- =====================================================")
    w("-- 北京大学校园内部连通路网（人工校核主路网 + 分类设施）")
    w("-- 由 scripts/gen_pku_curated_map.py 生成，请勿手工编辑。")
    w("-- 用途：校园内部导航、附近设施查询、实际步行距离排序。")
    w("-- 来源：在 OSM 导入数据基础上补充 campus_curated 连通拓扑；")
    w("--       不把人工校核边标记为 OSM。设施接入短边为 generated。")
    w("-- 幂等：按 source_ref 前缀 'pku-curated:%' 清理后重建。")
    w("-- =====================================================")
    w("SET client_encoding = 'UTF8';")
    w("BEGIN;")
    w("")
    w("DO $$")
    w("DECLARE")
    w("    v_spot INTEGER;")
    w("BEGIN")
    w("    SELECT id INTO v_spot")
    w("    FROM scenic_spots")
    w("    WHERE status = 1")
    w("      AND city = '北京市'")
    w("      AND (name = '北京大学' OR name ILIKE '%北京大学%' OR name ILIKE '%北大%')")
    w("    ORDER BY ST_Distance(location, ST_SetSRID(ST_MakePoint(116.304, 39.992), 4326)::geography), id")
    w("    LIMIT 1;")
    w("    IF v_spot IS NULL THEN")
    w("        RAISE EXCEPTION '未找到北京大学，请先执行 database/seeds/seed_campus_spots.sql';")
    w("    END IF;")
    w("")
    w("    DELETE FROM graph_edges ge")
    w("    WHERE ge.source_ref LIKE 'pku-curated:%'")
    w("       OR EXISTS (")
    w("           SELECT 1 FROM graph_nodes n")
    w("           WHERE (n.id = ge.from_node OR n.id = ge.to_node)")
    w("             AND n.source_ref LIKE 'pku-curated:%'")
    w("       );")
    w("    DELETE FROM graph_nodes WHERE source_ref LIKE 'pku-curated:%';")
    w("    DELETE FROM facilities WHERE source_ref LIKE 'pku-curated:%';")
    w("")
    w("    -- 1. 分类设施")
    for i, (name, ftype, near, rating, price) in enumerate(FACILITIES):
        lng, lat = waypoint_coord(near)
        flng, flat = offset_coord(lng, lat, FAC_OFFSET_M, i * 2.399963)
        price_sql = "NULL" if price is None else str(price)
        tags = {"kind": "campus-curated-facility", "near": near}
        w("    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)")
        w(
            f"    VALUES ('{sql_escape(name)}', '{ftype}', {point_wkt(flng, flat)}, "
            f"'北京大学校园内', {rating}, {price_sql}, '08:00-22:00', v_spot, "
            f"'{ROAD_SOURCE}', '{SRC}:fac:{i}', {json_sql(tags)});"
        )
    w("")
    w("    -- 2. 校园主路网节点")
    for key, (name, ntype, lng, lat, congestion) in WAYPOINTS.items():
        tags = {"kind": "campus-curated-waypoint", "key": key}
        w("    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)")
        w(
            f"    VALUES ('{sql_escape(name)}', {point_wkt(lng, lat)}, '{ntype}', v_spot, "
            f"{congestion}, '{ROAD_SOURCE}', '{SRC}:node:{key}', {json_sql(tags)});"
        )
    w("")
    w("    -- 3. 设施对应路网节点")
    for i, (name, _ftype, near, _rating, _price) in enumerate(FACILITIES):
        tags = {"kind": "campus-curated-facility-node", "near": near}
        w("    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)")
        w(
            f"    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, "
            f"'{ROAD_SOURCE}', '{SRC}:facnode:{i}', {json_sql(tags)}"
        )
        w(f"    FROM facilities f WHERE f.source = '{ROAD_SOURCE}' AND f.source_ref = '{SRC}:fac:{i}';")
    w("")
    w("    -- 4. 校园主路网道路边（双向，source='campus_curated'）")
    for a, b, congestion in PATH_EDGES:
        ca, cb = waypoint_coord(a), waypoint_coord(b)
        d = dist_m(ca, cb)
        t = edge_seconds(d, congestion)
        for x, y, start, end, suffix in ((a, b, ca, cb, ""), (b, a, cb, ca, ":reverse")):
            tags = {"kind": "campus-curated-road", "congestionLevel": congestion}
            w("    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)")
            w(
                f"    SELECT na.id, nb.id, {d:.2f}, 'walk', {t}, {max(d / 100.0, 1):.2f}, {congestion}, "
                f"ST_GeogFromText({line_wkt(start, end)}), '{ROAD_SOURCE}', '{SRC}:edge:{x}:{y}{suffix}', {json_sql(tags)}"
            )
            w(f"    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = '{SRC}:node:{x}' AND nb.source_ref = '{SRC}:node:{y}';")
    w("")
    w("    -- 5. 设施接入边（双向短边，source='generated'）")
    for i, (_name, _ftype, near, _rating, _price) in enumerate(FACILITIES):
        fac_ref = f"{SRC}:facnode:{i}"
        near_ref = f"{SRC}:node:{near}"
        # 设施点是按固定半径从最近路网节点错开，接入距离取真实偏移。
        # SQL 中再用两个节点实际位置生成线段，避免手工同步坐标。
        tags = {"kind": "facility-road-connector", "curatedSource": SRC, "maxDistanceMeters": FAC_OFFSET_M}
        for from_ref, to_ref, suffix in ((fac_ref, near_ref, "to-road"), (near_ref, fac_ref, "to-facility")):
            w("    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)")
            w(
                "    SELECT na.id, nb.id, "
                "GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', "
                "GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), "
                "GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, "
                "ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, "
                f"'generated', '{SRC}:connector:{i}:{suffix}', {json_sql(tags)}"
            )
            w(f"    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = '{from_ref}' AND nb.source_ref = '{to_ref}';")
    w("")
    w(
        "    RAISE NOTICE '北京大学校核连通图已重建: % 主路网节点, % 主路网双向边, % 设施', "
        f"{len(WAYPOINTS)}, {len(PATH_EDGES) * 2}, {len(FACILITIES)};"
    )
    w("END $$;")
    w("")
    w("COMMIT;")

    output_path = "database/seeds/seed_pku_curated_map.sql"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"已生成 {output_path}")
    print(
        f"  主路网节点: {len(WAYPOINTS)}  主路网边(双向): {len(PATH_EDGES) * 2}  "
        f"设施: {len(FACILITIES)}  接入边(双向): {len(FACILITIES) * 2}"
    )


if __name__ == "__main__":
    main()
