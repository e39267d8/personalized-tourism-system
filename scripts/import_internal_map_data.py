#!/usr/bin/env python3
"""Generate real-map internal navigation SQL for scenic spots.

The script uses OpenStreetMap/Overpass for internal roads and buildings, and
AMap Web Service POI around-search for service facilities when an AMap key is
available. It writes SQL only; review and import it with psql.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


DEFAULT_AMAP_WEB_SERVICE_KEY = "fbdf40a14e05c09c0e6c56230dd2688f"
OVERPASS_URLS = [
    "https://overpass-api.de/api/interpreter",
    "https://dev.overpass-api.de/api/interpreter",
]
AMAP_AROUND_URL = "https://restapi.amap.com/v3/place/around"
CONNECTOR_MAX_DISTANCE_METERS = 60.0
COORDINATE_DEDUP_DECIMALS = 6

DEFAULT_SPOTS = [
    {"key": "gugong", "name": "故宫博物院", "aliases": ["故宫", "故宫博物院", "紫禁城"], "lng": 116.397026, "lat": 39.918058, "radius": 1700},
    {"key": "tiantan", "name": "天坛公园", "aliases": ["天坛", "天坛公园"], "lng": 116.4066, "lat": 39.8822, "radius": 1800},
    {"key": "yiheyuan", "name": "颐和园", "aliases": ["颐和园"], "lng": 116.2755, "lat": 39.9999, "radius": 2200},
    {"key": "beihai", "name": "北海公园", "aliases": ["北海公园", "北海"], "lng": 116.389535, "lat": 39.925455, "radius": 1600},
    {"key": "aosen", "name": "奥林匹克森林公园", "aliases": ["奥林匹克森林公园", "奥森"], "lng": 116.3899, "lat": 40.0164, "radius": 2400},
]

AMAP_QUERIES = [
    ("toilet", "公共厕所"),
    ("restaurant", "餐厅"),
    ("cafe", "咖啡"),
    ("shop", "商店"),
    ("supermarket", "超市"),
    ("parking", "停车场"),
    ("service", "游客服务中心"),
    ("ticket", "售票处"),
    ("atm", "ATM"),
    ("clinic", "医务室"),
]


def sql_literal(value: object) -> str:
    text = "" if value is None else str(value)
    return "'" + text.replace("'", "''") + "'"


def sql_json(value: object) -> str:
    return sql_literal(json.dumps(value, ensure_ascii=False, separators=(",", ":"))) + "::jsonb"


def compact_ref(prefix: str, raw: object, max_length: int = 110) -> str:
    text = str(raw or "")
    candidate = f"{prefix}{text}"
    if len(candidate) <= max_length:
        return candidate
    digest = hashlib.sha1(candidate.encode("utf-8")).hexdigest()[:24]
    return f"{prefix}sha1-{digest}"


def request_json(url: str, params: dict[str, object], timeout: int = 30) -> dict[str, Any]:
    query = urllib.parse.urlencode(params)
    with urllib.request.urlopen(f"{url}?{query}", timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def request_overpass(query: str, timeout: int = 45) -> dict[str, Any]:
    body = urllib.parse.urlencode({"data": query}).encode("utf-8")
    headers = {
        "User-Agent": "TourPilotInternalNavigationImporter/1.0",
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
    }
    last_error: Exception | None = None
    for url in OVERPASS_URLS:
        req = urllib.request.Request(url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as response:
                return json.loads(response.read().decode("utf-8"))
        except Exception as error:
            last_error = error
    if last_error:
        raise last_error
    raise RuntimeError("Overpass request failed")


def haversine_m(a: tuple[float, float], b: tuple[float, float]) -> float:
    lng1, lat1 = a
    lng2, lat2 = b
    radius = 6371000.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    value = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return radius * 2 * math.atan2(math.sqrt(value), math.sqrt(1 - value))


def out_of_china(lng: float, lat: float) -> bool:
    return lng < 72.004 or lng > 137.8347 or lat < 0.8293 or lat > 55.8271


def transform_lat(lng: float, lat: float) -> float:
    ret = -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat + 0.1 * lng * lat + 0.2 * math.sqrt(abs(lng))
    ret += (20.0 * math.sin(6.0 * lng * math.pi) + 20.0 * math.sin(2.0 * lng * math.pi)) * 2.0 / 3.0
    ret += (20.0 * math.sin(lat * math.pi) + 40.0 * math.sin(lat / 3.0 * math.pi)) * 2.0 / 3.0
    ret += (160.0 * math.sin(lat / 12.0 * math.pi) + 320 * math.sin(lat * math.pi / 30.0)) * 2.0 / 3.0
    return ret


def transform_lng(lng: float, lat: float) -> float:
    ret = 300.0 + lng + 2.0 * lat + 0.1 * lng * lng + 0.1 * lng * lat + 0.1 * math.sqrt(abs(lng))
    ret += (20.0 * math.sin(6.0 * lng * math.pi) + 20.0 * math.sin(2.0 * lng * math.pi)) * 2.0 / 3.0
    ret += (20.0 * math.sin(lng * math.pi) + 40.0 * math.sin(lng / 3.0 * math.pi)) * 2.0 / 3.0
    ret += (150.0 * math.sin(lng / 12.0 * math.pi) + 300.0 * math.sin(lng / 30.0 * math.pi)) * 2.0 / 3.0
    return ret


def wgs84_to_gcj02(lng: float, lat: float) -> tuple[float, float]:
    if out_of_china(lng, lat):
        return (lng, lat)
    a = 6378245.0
    ee = 0.00669342162296594323
    dlat = transform_lat(lng - 105.0, lat - 35.0)
    dlng = transform_lng(lng - 105.0, lat - 35.0)
    radlat = lat / 180.0 * math.pi
    magic = math.sin(radlat)
    magic = 1 - ee * magic * magic
    sqrt_magic = math.sqrt(magic)
    dlat = (dlat * 180.0) / ((a * (1 - ee)) / (magic * sqrt_magic) * math.pi)
    dlng = (dlng * 180.0) / (a / sqrt_magic * math.cos(radlat) * math.pi)
    return (lng + dlng, lat + dlat)


def gcj02_to_wgs84(lng: float, lat: float) -> tuple[float, float]:
    if out_of_china(lng, lat):
        return (lng, lat)
    gcj_lng, gcj_lat = wgs84_to_gcj02(lng, lat)
    return (lng * 2 - gcj_lng, lat * 2 - gcj_lat)


def bbox_for(lng: float, lat: float, radius_m: int) -> tuple[float, float, float, float]:
    dlat = radius_m / 111320.0
    dlng = radius_m / (111320.0 * max(0.2, math.cos(math.radians(lat))))
    return (lat - dlat, lng - dlng, lat + dlat, lng + dlng)


def coordinate_ref(spot_key: str, lng: float, lat: float) -> str:
    return f"{spot_key}:osm-junction-{round(lng, COORDINATE_DEDUP_DECIMALS):.{COORDINATE_DEDUP_DECIMALS}f}:{round(lat, COORDINATE_DEDUP_DECIMALS):.{COORDINATE_DEDUP_DECIMALS}f}"


def classify_osm_facility(tags: dict[str, Any]) -> str:
    amenity = tags.get("amenity", "")
    shop = tags.get("shop", "")
    tourism = tags.get("tourism", "")
    building = tags.get("building", "")
    if amenity == "toilets":
        return "toilet"
    if amenity in {"restaurant", "fast_food", "food_court"}:
        return "restaurant"
    if amenity == "cafe":
        return "cafe"
    if amenity == "parking":
        return "parking"
    if amenity in {"atm", "bank"}:
        return "atm"
    if amenity in {"clinic", "doctors", "hospital", "first_aid"}:
        return "clinic"
    if amenity == "drinking_water":
        return "drinking_water"
    if shop:
        return "shop" if shop != "supermarket" else "supermarket"
    if tourism in {"information", "museum", "attraction"}:
        return "service" if tourism == "information" else tourism
    if tags.get("entrance") or tags.get("barrier") == "gate":
        return "entrance"
    if building:
        return "building"
    return "service"


def node_name(prefix: str, source_id: object, tags: dict[str, Any], fallback_type: str) -> str:
    name = tags.get("name") or tags.get("name:zh") or tags.get("official_name")
    if name:
        return str(name)
    labels = {
        "building": "建筑",
        "entrance": "入口",
        "junction": "路口",
        "toilet": "卫生间",
        "restaurant": "餐饮",
        "cafe": "咖啡",
        "parking": "停车场",
        "service": "服务设施",
    }
    return f"{prefix}{labels.get(fallback_type, '设施')} {source_id}"


def centroid(points: list[tuple[float, float]]) -> tuple[float, float]:
    if not points:
        return (0.0, 0.0)
    return (sum(point[0] for point in points) / len(points), sum(point[1] for point in points) / len(points))


def overpass_query(spot: dict[str, Any]) -> str:
    south, west, north, east = bbox_for(float(spot["lng"]), float(spot["lat"]), int(spot["radius"]))
    bbox = f"{south:.7f},{west:.7f},{north:.7f},{east:.7f}"
    return f"""
[out:json][timeout:35];
(
  way["highway"~"^(footway|path|pedestrian|steps|service|living_street|cycleway)$"]({bbox});
  way["building"]({bbox});
  node["amenity"]({bbox});
  node["shop"]({bbox});
  node["tourism"]({bbox});
  node["entrance"]({bbox});
  node["barrier"="gate"]({bbox});
);
out body geom;
"""


def collect_overpass_spot(spot: dict[str, Any]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    payload = request_overpass(overpass_query(spot))
    nodes: dict[str, dict[str, Any]] = {}
    edges: list[dict[str, Any]] = []
    spot_key = spot["key"]

    def add_node(source_ref: str, name: str, node_type: str, lng: float, lat: float, tags: dict[str, Any], facility_type: str = "") -> None:
        if not lng or not lat:
            return
        nodes[source_ref] = {
            "spot_key": spot_key,
            "source": "osm",
            "source_ref": source_ref,
            "name": name,
            "node_type": node_type,
            "lng": lng,
            "lat": lat,
            "facility_type": facility_type,
            "address": "",
            "rating": "",
            "price_level": "",
            "opening_hours": str(tags.get("opening_hours") or ""),
            "phone": str(tags.get("phone") or tags.get("contact:phone") or ""),
            "source_tags": tags,
        }

    for element in payload.get("elements", []):
        tags = element.get("tags") or {}
        element_id = element.get("id")
        if element.get("type") == "way" and "highway" in tags and element.get("geometry"):
            refs: list[str] = []
            geometry = [(float(point["lon"]), float(point["lat"])) for point in element["geometry"] if "lon" in point and "lat" in point]
            for index, (lng, lat) in enumerate(geometry):
                ref = coordinate_ref(spot_key, lng, lat)
                add_node(ref, node_name("OSM ", f"{element_id}-{index}", tags, "junction"), "junction", lng, lat, tags)
                refs.append(ref)
            for index in range(len(refs) - 1):
                if refs[index] == refs[index + 1]:
                    continue
                distance = haversine_m(geometry[index], geometry[index + 1])
                line = [geometry[index], geometry[index + 1]]
                source_ref = f"{spot_key}:osm-way-{element_id}-edge-{index}"
                edges.append({
                    "spot_key": spot_key,
                    "source": "osm",
                    "source_ref": source_ref,
                    "from_ref": refs[index],
                    "to_ref": refs[index + 1],
                    "distance": max(1, round(distance, 2)),
                    "duration": max(1, round(distance / 1.2)),
                    "geometry": line,
                    "source_tags": tags,
                })
                edges.append({
                    "spot_key": spot_key,
                    "source": "osm",
                    "source_ref": source_ref + ":reverse",
                    "from_ref": refs[index + 1],
                    "to_ref": refs[index],
                    "distance": max(1, round(distance, 2)),
                    "duration": max(1, round(distance / 1.2)),
                    "geometry": list(reversed(line)),
                    "source_tags": tags,
                })
        elif element.get("type") == "way" and "building" in tags and element.get("geometry"):
            geometry = [(float(point["lon"]), float(point["lat"])) for point in element["geometry"] if "lon" in point and "lat" in point]
            lng, lat = centroid(geometry)
            ref = f"{spot_key}:osm-building-{element_id}"
            add_node(ref, node_name("OSM ", element_id, tags, "building"), "building", lng, lat, tags, "building")
        elif element.get("type") == "node" and "lat" in element and "lon" in element:
            facility_type = classify_osm_facility(tags)
            node_type = "entrance" if facility_type == "entrance" else "facility"
            ref = f"{spot_key}:osm-node-{element_id}"
            add_node(ref, node_name("OSM ", element_id, tags, facility_type), node_type, float(element["lon"]), float(element["lat"]), tags, facility_type)

    return list(nodes.values()), edges


def amap_key(explicit_key: str) -> str:
    return explicit_key or os.getenv("AMAP_WEB_SERVICE_KEY") or os.getenv("AMAP_KEY") or DEFAULT_AMAP_WEB_SERVICE_KEY


def collect_amap_spot(spot: dict[str, Any], key: str, pages: int, delay: float) -> list[dict[str, Any]]:
    if not key:
        return []
    nodes: list[dict[str, Any]] = []
    seen: set[str] = set()
    amap_lng, amap_lat = wgs84_to_gcj02(float(spot["lng"]), float(spot["lat"]))
    for facility_type, keyword in AMAP_QUERIES:
        for page in range(1, pages + 1):
            payload = request_json(AMAP_AROUND_URL, {
                "key": key,
                "location": f"{amap_lng},{amap_lat}",
                "radius": spot["radius"],
                "keywords": keyword,
                "offset": 20,
                "page": page,
                "extensions": "base",
                "output": "JSON",
            })
            if payload.get("status") != "1":
                raise RuntimeError(f"AMap {keyword} failed: {payload.get('info') or 'unknown error'}")
            pois = payload.get("pois") or []
            if not pois:
                break
            for poi in pois:
                location = poi.get("location") or ""
                if "," not in location:
                    continue
                lng_text, lat_text = location.split(",", 1)
                poi_id = poi.get("id") or f"{poi.get('name')}:{location}"
                ref = compact_ref(f"{spot['key']}:amap-", poi_id)
                if ref in seen:
                    continue
                seen.add(ref)
                gcj_lng = float(lng_text)
                gcj_lat = float(lat_text)
                wgs_lng, wgs_lat = gcj02_to_wgs84(gcj_lng, gcj_lat)
                tags = {
                    "amap_type": poi.get("type", ""),
                    "keyword": keyword,
                    "coordinate_system": "gcj02",
                    "amap_location_gcj02": [gcj_lng, gcj_lat],
                    "location_wgs84": [round(wgs_lng, 7), round(wgs_lat, 7)],
                    "coordinate_conversion": "gcj02_to_wgs84",
                }
                nodes.append({
                    "spot_key": spot["key"],
                    "source": "amap",
                    "source_ref": ref,
                    "name": poi.get("name") or keyword,
                    "node_type": "facility",
                    "lng": wgs_lng,
                    "lat": wgs_lat,
                    "facility_type": facility_type,
                    "address": poi.get("address") or "",
                    "rating": "",
                    "price_level": "",
                    "opening_hours": "",
                    "phone": poi.get("tel") or "",
                    "source_tags": tags,
                })
            time.sleep(delay)
    return nodes


def trim_spot_graph(nodes: list[dict[str, Any]], edges: list[dict[str, Any]], max_edges: int) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    if max_edges <= 0 or len(edges) <= max_edges:
        return nodes, edges
    trimmed_edges = edges[:max_edges]
    used_refs = {edge["from_ref"] for edge in trimmed_edges} | {edge["to_ref"] for edge in trimmed_edges}
    trimmed_nodes = [
        node for node in nodes
        if node.get("facility_type") or node["source_ref"] in used_refs
    ]
    return trimmed_nodes, trimmed_edges


def node_matches_scope(node: dict[str, Any], spot: dict[str, Any]) -> bool:
    bounds = spot.get("bounds") or {}
    if bounds:
        lng = float(node["lng"])
        lat = float(node["lat"])
        if lng < float(bounds["west"]) or lng > float(bounds["east"]):
            return False
        if lat < float(bounds["south"]) or lat > float(bounds["north"]):
            return False

    exclude_terms = [str(term) for term in spot.get("exclude_terms", [])]
    if exclude_terms:
        searchable = json.dumps({
            "name": node.get("name", ""),
            "address": node.get("address", ""),
            "source_tags": node.get("source_tags", {}),
        }, ensure_ascii=False)
        if any(term in searchable for term in exclude_terms):
            return False
    return True


def edge_matches_scope(edge: dict[str, Any], spot: dict[str, Any], used_refs: set[str]) -> bool:
    if edge["from_ref"] not in used_refs or edge["to_ref"] not in used_refs:
        return False

    exclude_terms = [str(term) for term in spot.get("exclude_terms", [])]
    if exclude_terms:
        searchable = json.dumps(edge.get("source_tags", {}), ensure_ascii=False)
        if any(term in searchable for term in exclude_terms):
            return False
    return True


def filter_spot_scope(spot: dict[str, Any], nodes: list[dict[str, Any]], edges: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    if not spot.get("bounds") and not spot.get("exclude_terms"):
        return nodes, edges

    scoped_nodes = [node for node in nodes if node_matches_scope(node, spot)]
    scoped_refs = {node["source_ref"] for node in scoped_nodes}
    scoped_edges = [edge for edge in edges if edge_matches_scope(edge, spot, scoped_refs)]
    return scoped_nodes, scoped_edges


def linestring_wkt(points: list[tuple[float, float]]) -> str:
    text = ", ".join(f"{lng:.7f} {lat:.7f}" for lng, lat in points)
    return f"SRID=4326;LINESTRING({text})"


def values_rows(rows: list[str], header: str, empty_select: str) -> str:
    if not rows:
        return empty_select
    return header + "\n" + ",\n".join(rows) + ";"


def render_sql(spots: list[dict[str, Any]],
               nodes: list[dict[str, Any]],
               edges: list[dict[str, Any]],
               connector_max_distance_meters: float) -> str:
    spot_rows = []
    for spot in spots:
        alias_conditions = " OR ".join(f"s.name ILIKE '%' || {sql_literal(alias)} || '%'" for alias in spot["aliases"])
        spot_rows.append(f"""
INSERT INTO tmp_internal_spots (spot_key, scenic_spot_id)
SELECT {sql_literal(spot['key'])}, s.id
FROM scenic_spots s
WHERE s.status = 1 AND ({alias_conditions})
ORDER BY ST_Distance(s.location, ST_SetSRID(ST_MakePoint({spot['lng']}, {spot['lat']}), 4326)::geography), s.id
LIMIT 1;
""".strip())

    node_rows = []
    for node in nodes:
        node_rows.append("(" + ",".join([
            sql_literal(node["spot_key"]),
            sql_literal(node["source"]),
            sql_literal(node["source_ref"]),
            sql_literal(node["name"]),
            sql_literal(node["node_type"]),
            str(float(node["lng"])),
            str(float(node["lat"])),
            sql_literal(node["facility_type"]),
            sql_literal(node["address"]),
            "NULL" if node["rating"] == "" else str(node["rating"]),
            "NULL" if node["price_level"] == "" else str(node["price_level"]),
            sql_literal(node["opening_hours"]),
            sql_literal(node["phone"]),
            sql_json(node["source_tags"]),
        ]) + ")")

    edge_rows = []
    for edge in edges:
        edge_rows.append("(" + ",".join([
            sql_literal(edge["spot_key"]),
            sql_literal(edge["source"]),
            sql_literal(edge["source_ref"]),
            sql_literal(edge["from_ref"]),
            sql_literal(edge["to_ref"]),
            str(edge["distance"]),
            str(edge["duration"]),
            sql_literal(linestring_wkt(edge["geometry"])),
            sql_json(edge["source_tags"]),
        ]) + ")")

    node_values = values_rows(
        node_rows,
        "INSERT INTO tmp_internal_nodes (spot_key, source, source_ref, name, node_type, lng, lat, facility_type, address, rating, price_level, opening_hours, phone, source_tags) VALUES",
        "SELECT 1 WHERE FALSE;",
    )
    edge_values = values_rows(
        edge_rows,
        "INSERT INTO tmp_internal_edges (spot_key, source, source_ref, from_ref, to_ref, distance, travel_time, geometry_wkt, source_tags) VALUES",
        "SELECT 1 WHERE FALSE;",
    )

    return f"""SET client_encoding = 'UTF8';
BEGIN;

ALTER TABLE facilities
    ADD COLUMN IF NOT EXISTS scenic_spot_id INTEGER REFERENCES scenic_spots(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS source VARCHAR(50),
    ADD COLUMN IF NOT EXISTS source_ref VARCHAR(120),
    ADD COLUMN IF NOT EXISTS source_tags JSONB;

ALTER TABLE graph_nodes
    ADD COLUMN IF NOT EXISTS source VARCHAR(50),
    ADD COLUMN IF NOT EXISTS source_ref VARCHAR(120),
    ADD COLUMN IF NOT EXISTS source_tags JSONB;

ALTER TABLE graph_edges
    ADD COLUMN IF NOT EXISTS geometry GEOGRAPHY(LINESTRING, 4326),
    ADD COLUMN IF NOT EXISTS source VARCHAR(50),
    ADD COLUMN IF NOT EXISTS source_ref VARCHAR(160),
    ADD COLUMN IF NOT EXISTS source_tags JSONB;

CREATE UNIQUE INDEX IF NOT EXISTS ux_facilities_source_ref ON facilities(source, source_ref);
CREATE UNIQUE INDEX IF NOT EXISTS ux_graph_nodes_source_ref ON graph_nodes(source, source_ref);
CREATE INDEX IF NOT EXISTS idx_facilities_scenic_spot ON facilities(scenic_spot_id);
CREATE INDEX IF NOT EXISTS idx_graph_edges_geometry ON graph_edges USING GIST (geometry);

CREATE TEMP TABLE tmp_internal_spots (
    spot_key TEXT PRIMARY KEY,
    scenic_spot_id INTEGER NOT NULL
) ON COMMIT DROP;

{"".join(spot_rows)}

DELETE FROM graph_edges ge
USING graph_nodes linked_node, tmp_internal_spots s
WHERE (ge.from_node = linked_node.id OR ge.to_node = linked_node.id)
  AND linked_node.scenic_spot_id = s.scenic_spot_id
  AND linked_node.source_ref LIKE s.spot_key || ':%';

DELETE FROM graph_nodes node
USING tmp_internal_spots s
WHERE node.scenic_spot_id = s.scenic_spot_id
  AND node.source_ref LIKE s.spot_key || ':%';

DELETE FROM facilities facility
USING tmp_internal_spots s
WHERE facility.scenic_spot_id = s.scenic_spot_id
  AND facility.source_ref LIKE s.spot_key || ':%';

CREATE TEMP TABLE tmp_internal_nodes (
    spot_key TEXT NOT NULL,
    source TEXT NOT NULL,
    source_ref TEXT NOT NULL,
    name TEXT NOT NULL,
    node_type TEXT NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    facility_type TEXT,
    address TEXT,
    rating NUMERIC,
    price_level INTEGER,
    opening_hours TEXT,
    phone TEXT,
    source_tags JSONB
) ON COMMIT DROP;

{node_values}

CREATE TEMP TABLE tmp_internal_edges (
    spot_key TEXT NOT NULL,
    source TEXT NOT NULL,
    source_ref TEXT NOT NULL,
    from_ref TEXT NOT NULL,
    to_ref TEXT NOT NULL,
    distance NUMERIC NOT NULL,
    travel_time INTEGER NOT NULL,
    geometry_wkt TEXT NOT NULL,
    source_tags JSONB
) ON COMMIT DROP;

{edge_values}

INSERT INTO facilities
    (name, type, location, address, rating, price_level, opening_hours, phone,
     scenic_spot_id, source, source_ref, source_tags)
SELECT
    LEFT(deduped.name, 100),
    LEFT(NULLIF(deduped.facility_type, ''), 50),
    ST_SetSRID(ST_MakePoint(deduped.lng, deduped.lat), 4326)::geography,
    LEFT(deduped.address, 200),
    COALESCE(deduped.rating, 0),
    deduped.price_level,
    LEFT(deduped.opening_hours, 100),
    LEFT(deduped.phone, 20),
    s.scenic_spot_id,
    LEFT(deduped.source, 50),
    LEFT(deduped.source_ref, 120),
    deduped.source_tags
FROM (
    SELECT DISTINCT ON (source, source_ref) *
    FROM tmp_internal_nodes
    WHERE COALESCE(facility_type, '') <> ''
    ORDER BY source, source_ref
) deduped
JOIN tmp_internal_spots s ON s.spot_key = deduped.spot_key
ON CONFLICT (source, source_ref) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    location = EXCLUDED.location,
    address = EXCLUDED.address,
    scenic_spot_id = EXCLUDED.scenic_spot_id,
    source_tags = EXCLUDED.source_tags;

INSERT INTO graph_nodes
    (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
SELECT
    LEFT(deduped.name, 100),
    ST_SetSRID(ST_MakePoint(deduped.lng, deduped.lat), 4326)::geography,
    LEFT(deduped.node_type, 20),
    s.scenic_spot_id,
    f.id,
    2,
    LEFT(deduped.source, 50),
    LEFT(deduped.source_ref, 120),
    deduped.source_tags
FROM (
    SELECT DISTINCT ON (source, source_ref) *
    FROM tmp_internal_nodes
    ORDER BY source, source_ref
) deduped
JOIN tmp_internal_spots s ON s.spot_key = deduped.spot_key
LEFT JOIN facilities f ON f.source = deduped.source AND f.source_ref = deduped.source_ref
ON CONFLICT (source, source_ref) DO UPDATE SET
    name = EXCLUDED.name,
    location = EXCLUDED.location,
    node_type = EXCLUDED.node_type,
    scenic_spot_id = EXCLUDED.scenic_spot_id,
    facility_id = EXCLUDED.facility_id,
    source_tags = EXCLUDED.source_tags;

DELETE FROM graph_edges ge
USING graph_nodes from_node, graph_nodes to_node, tmp_internal_spots s
WHERE ge.from_node = from_node.id
  AND ge.to_node = to_node.id
  AND ge.source = 'generated'
  AND ge.source_tags->>'kind' = 'facility-road-connector'
  AND (from_node.scenic_spot_id = s.scenic_spot_id OR to_node.scenic_spot_id = s.scenic_spot_id);

INSERT INTO graph_edges
    (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level,
     geometry, source, source_ref, source_tags)
WITH anchors AS (
    SELECT node.id, node.location, node.scenic_spot_id
    FROM graph_nodes node
    JOIN tmp_internal_nodes imported ON imported.source_ref = node.source_ref
    WHERE node.node_type <> 'junction'
      AND node.location IS NOT NULL
),
nearest_roads AS (
    SELECT
        anchor.id AS anchor_id,
        road.id AS road_id,
        ST_Distance(anchor.location, road.location) AS distance
    FROM anchors anchor
    CROSS JOIN LATERAL (
        SELECT candidate.id, candidate.location
        FROM graph_nodes candidate
        WHERE candidate.node_type = 'junction'
          AND candidate.location IS NOT NULL
          AND candidate.scenic_spot_id = anchor.scenic_spot_id
        ORDER BY candidate.location <-> anchor.location
        LIMIT 1
    ) road
    WHERE ST_Distance(anchor.location, road.location) <= {connector_max_distance_meters:.2f}
)
SELECT
    anchor_id,
    road_id,
    GREATEST(distance, 1),
    'walk',
    GREATEST(CEIL(distance / 1.2)::int, 1),
    GREATEST(distance / 100.0, 1),
    2,
    ST_MakeLine(anchor.location::geometry, road.location::geometry)::geography,
    'generated',
    LEFT('connector:' || anchor_id::text || ':' || road_id::text, 160),
    jsonb_build_object('kind', 'facility-road-connector', 'maxDistanceMeters', {connector_max_distance_meters:.2f})
FROM nearest_roads
JOIN graph_nodes anchor ON anchor.id = nearest_roads.anchor_id
JOIN graph_nodes road ON road.id = nearest_roads.road_id
UNION ALL
SELECT
    road_id,
    anchor_id,
    GREATEST(distance, 1),
    'walk',
    GREATEST(CEIL(distance / 1.2)::int, 1),
    GREATEST(distance / 100.0, 1),
    2,
    ST_MakeLine(road.location::geometry, anchor.location::geometry)::geography,
    'generated',
    LEFT('connector:' || road_id::text || ':' || anchor_id::text, 160),
    jsonb_build_object('kind', 'facility-road-connector', 'maxDistanceMeters', {connector_max_distance_meters:.2f})
FROM nearest_roads
JOIN graph_nodes anchor ON anchor.id = nearest_roads.anchor_id
JOIN graph_nodes road ON road.id = nearest_roads.road_id
ON CONFLICT (from_node, to_node, travel_mode) DO UPDATE SET
    distance = EXCLUDED.distance,
    travel_time = EXCLUDED.travel_time,
    base_weight = EXCLUDED.base_weight,
    geometry = EXCLUDED.geometry,
    source = EXCLUDED.source,
    source_ref = EXCLUDED.source_ref,
    source_tags = EXCLUDED.source_tags;

INSERT INTO graph_edges
    (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level,
     geometry, source, source_ref, source_tags)
SELECT DISTINCT ON (from_node.id, to_node.id)
    from_node.id,
    to_node.id,
    e.distance,
    'walk',
    e.travel_time,
    GREATEST(e.distance / 100.0, 1),
    2,
    ST_GeogFromText(e.geometry_wkt),
    LEFT(e.source, 50),
    LEFT(e.source_ref, 160),
    e.source_tags
FROM tmp_internal_edges e
JOIN graph_nodes from_node ON from_node.source_ref = e.from_ref
JOIN graph_nodes to_node ON to_node.source_ref = e.to_ref
ORDER BY from_node.id, to_node.id, e.distance
ON CONFLICT (from_node, to_node, travel_mode) DO UPDATE SET
    distance = EXCLUDED.distance,
    travel_time = EXCLUDED.travel_time,
    base_weight = EXCLUDED.base_weight,
    geometry = EXCLUDED.geometry,
    source = EXCLUDED.source,
    source_ref = EXCLUDED.source_ref,
    source_tags = EXCLUDED.source_tags;

COMMIT;
"""


def load_spots(path: str) -> list[dict[str, Any]]:
    if not path:
        return DEFAULT_SPOTS
    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(payload, list):
        raise RuntimeError("spots file must be a JSON array")
    return payload


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spots-file", default="", help="JSON array with key/name/aliases/lng/lat/radius")
    parser.add_argument("--output", default="database/imports/internal_navigation.sql")
    parser.add_argument("--amap-key", default="", help="Defaults to AMAP_WEB_SERVICE_KEY, AMAP_KEY, then built-in free key")
    parser.add_argument("--no-amap", action="store_true")
    parser.add_argument("--amap-pages", type=int, default=1)
    parser.add_argument("--max-edges-per-spot", type=int, default=2000)
    parser.add_argument("--connector-max-distance", type=float, default=CONNECTOR_MAX_DISTANCE_METERS, help="Maximum meters from facility/building to nearest OSM road before connector is skipped")
    parser.add_argument("--delay", type=float, default=0.25)
    args = parser.parse_args()

    spots = load_spots(args.spots_file)
    key = "" if args.no_amap else amap_key(args.amap_key)
    all_nodes: list[dict[str, Any]] = []
    all_edges: list[dict[str, Any]] = []
    loaded_spots: list[dict[str, Any]] = []

    for spot in spots:
        try:
            print(f"Fetching OSM internal map for {spot['name']} ...")
            nodes, edges = collect_overpass_spot(spot)
            nodes, edges = filter_spot_scope(spot, nodes, edges)
            nodes, edges = trim_spot_graph(nodes, edges, args.max_edges_per_spot)
            all_nodes.extend(nodes)
            all_edges.extend(edges)
            loaded_spots.append(spot)
            print(f"  OSM nodes={len(nodes)} edges={len(edges)}")

            if key:
                print(f"Fetching AMap facilities around {spot['name']} ...")
                amap_nodes = collect_amap_spot(spot, key, args.amap_pages, args.delay)
                amap_nodes, _ = filter_spot_scope(spot, amap_nodes, [])
                all_nodes.extend(amap_nodes)
                print(f"  AMap facilities={len(amap_nodes)}")
        except Exception as error:
            print(f"WARNING: skipped {spot['name']}: {error}")
        time.sleep(args.delay)

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_sql(loaded_spots, all_nodes, all_edges, args.connector_max_distance), encoding="utf-8")

    facilities = [node for node in all_nodes if node.get("facility_type")]
    facility_types = sorted({node["facility_type"] for node in facilities})
    buildings = [node for node in all_nodes if node.get("facility_type") == "building"]
    print(f"Wrote {output}")
    print(f"Totals: nodes={len(all_nodes)} edges={len(all_edges)} facilities={len(facilities)} facility_types={len(facility_types)} buildings={len(buildings)}")
    print(f"Connector max distance: {args.connector_max_distance:.1f} m")
    if len(buildings) < 20:
        print("WARNING: building count is below 20; choose a larger/scenic-rich area or add spots.")
    if len(facilities) < 50:
        print("WARNING: facility count is below 50; increase AMap pages or add spots.")
    if len(all_edges) < 200:
        print("WARNING: edge count is below 200; choose a larger area or more spots.")


if __name__ == "__main__":
    main()
