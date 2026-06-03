"""Fetch Amap POIs and generate SQL for this project.

Examples:
  py scripts/import_amap_pois.py --key YOUR_AMAP_KEY --city 北京 --keywords 景点 --output database/imports/amap_pois.sql

  py scripts/import_amap_pois.py --key YOUR_AMAP_KEY --preset national-demo --keywords 景点,博物馆,公园 --pages 2 --output database/imports/amap_pois.sql

The output path is the only official Amap import SQL. Regenerating it will
overwrite database/imports/amap_pois.sql, so review the file before import:
  psql -U postgres -d tourism_system -f database/imports/amap_pois.sql
"""

from __future__ import annotations

import argparse
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path

IMPORT_HEADER_SQL = """SET client_encoding = 'UTF8';
BEGIN;

-- 保证高德 POI 导入时所有标准分类都存在。
INSERT INTO categories (id, name, description, icon, parent_id, sort_order)
VALUES
    (1, '旅游景点', '高德 POI 导入时使用的通用景点分类', 'map-pin', NULL, 1),
    (2, '历史古迹', '历史文化遗产与古建筑', 'landmark', NULL, 2),
    (3, '博物馆', '展览、文博与公共文化空间', 'museum', NULL, 3),
    (4, '城市公园', '休闲散步和自然景观', 'trees', NULL, 4),
    (5, '商业街区', '购物、美食与夜游区域', 'shopping-bag', NULL, 5),
    (6, '观景摄影', '适合拍照与城市观景的地点', 'camera', NULL, 6),
    (7, '城市地标', '城市广场、地标建筑与公共空间', 'building-2', NULL, 7)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order;
"""


AMAP_PLACE_TEXT_URL = "https://restapi.amap.com/v3/place/text"

PRESET_CITIES = {
    "national-demo": [
        "\u5317\u4eac",
        "\u4e0a\u6d77",
        "\u5e7f\u5dde",
        "\u6df1\u5733",
        "\u676d\u5dde",
        "\u5357\u4eac",
        "\u82cf\u5dde",
        "\u6210\u90fd",
        "\u91cd\u5e86",
        "\u897f\u5b89",
        "\u6b66\u6c49",
        "\u957f\u6c99",
        "\u53a6\u95e8",
        "\u798f\u5dde",
        "\u9752\u5c9b",
        "\u6d4e\u5357",
        "\u5929\u6d25",
        "\u90d1\u5dde",
        "\u6d1b\u9633",
        "\u5f00\u5c01",
        "\u5927\u540c",
        "\u592a\u539f",
        "\u6c88\u9633",
        "\u5927\u8fde",
        "\u957f\u6625",
        "\u54c8\u5c14\u6ee8",
        "\u547c\u548c\u6d69\u7279",
        "\u94f6\u5ddd",
        "\u5170\u5dde",
        "\u897f\u5b81",
        "\u4e4c\u9c81\u6728\u9f50",
        "\u62c9\u8428",
        "\u6606\u660e",
        "\u5927\u7406",
        "\u4e3d\u6c5f",
        "\u8d35\u9633",
        "\u6842\u6797",
        "\u5357\u5b81",
        "\u4e09\u4e9a",
        "\u6d77\u53e3",
        "\u5408\u80a5",
        "\u5357\u660c",
        "\u77f3\u5bb6\u5e84",
    ],
}


def sql_literal(value: object) -> str:
    text = "" if value is None else str(value)
    return "'" + text.replace("'", "''") + "'"


def request_json(url: str, params: dict[str, object]) -> dict:
    query = urllib.parse.urlencode(params)
    with urllib.request.urlopen(f"{url}?{query}", timeout=20) as response:
        return json.loads(response.read().decode("utf-8"))


def split_arg(value: str) -> list[str]:
    return [item.strip() for item in value.replace("\uff0c", ",").split(",") if item.strip()]


def resolve_cities(city: str, cities: str, cities_file: str, preset: str) -> list[str]:
    resolved: list[str] = []

    if preset:
        if preset not in PRESET_CITIES:
            names = ", ".join(sorted(PRESET_CITIES))
            raise RuntimeError(f"Unknown preset '{preset}'. Available presets: {names}")
        resolved.extend(PRESET_CITIES[preset])

    if cities:
        resolved.extend(split_arg(cities))

    if cities_file:
        path = Path(cities_file)
        file_cities = [
            line.strip()
            for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.strip().startswith("#")
        ]
        resolved.extend(file_cities)

    if city:
        resolved.append(city)

    if not resolved:
        resolved.append("\u5317\u4eac")

    unique: list[str] = []
    seen: set[str] = set()
    for item in resolved:
        if item not in seen:
            unique.append(item)
            seen.add(item)
    return unique


def fetch_pois(
    key: str,
    city: str,
    keywords: str,
    types: str,
    pages: int,
    offset: int,
    delay: float,
    extensions: str,
) -> list[dict]:
    pois: list[dict] = []
    for page in range(1, pages + 1):
        payload = request_json(
            AMAP_PLACE_TEXT_URL,
            {
                "key": key,
                "city": city,
                "citylimit": "true",
                "keywords": keywords,
                "types": types,
                "offset": offset,
                "page": page,
                "extensions": extensions,
                "output": "JSON",
            },
        )
        if payload.get("status") != "1":
            info = payload.get("info") or "Amap request failed"
            infocode = payload.get("infocode") or ""
            suffix = f" ({infocode})" if infocode else ""
            raise RuntimeError(f"{info}{suffix}")
        page_pois = payload.get("pois") or []
        if not page_pois:
            break
        pois.extend(page_pois)
        time.sleep(delay)
    return pois


def first_photo_url(poi: dict) -> str:
    photos = poi.get("photos") or []
    if photos and isinstance(photos[0], dict):
        return photos[0].get("url") or ""
    return ""


def resolve_category_id(poi: dict, fallback_category_id: int) -> int:
    typecode = str(poi.get("typecode") or "")
    text = " ".join(
        str(poi.get(key) or "")
        for key in ("name", "type", "address", "cityname", "pname")
    )
    rules = [
        (3, ("博物馆", "纪念馆", "展览", "美术馆", "科技馆", "文化馆")),
        (7, ("广场", "地标", "城楼", "电视塔", "体育场", "中心")),
        (5, ("商业", "购物", "步行街", "美食", "小吃", "夜市", "酒吧", "餐厅", "工体", "三里屯", "王府井", "前门")),
        (4, ("公园", "森林", "湿地", "湖", "山", "自然", "园林", "植物园", "动物园", "颐和园", "圆明园", "北海")),
        (2, ("历史", "古迹", "古建", "遗址", "故宫", "长城", "寺", "庙", "宫", "塔", "陵", "文化遗产", "天坛", "雍和宫")),
        (6, ("摄影", "观景", "打卡", "日落", "夜景", "俯瞰")),
    ]
    for category_id, keywords in rules:
        if any(keyword in text for keyword in keywords):
            return category_id

    if typecode.startswith("1101"):
        return 4
    if typecode.startswith("1102"):
        return 2
    return fallback_category_id


def poi_to_sql(poi: dict, category_id: int) -> str | None:
    location = poi.get("location") or ""
    if "," not in location:
        return None
    longitude, latitude = location.split(",", 1)

    name = poi.get("name") or ""
    address = poi.get("address") or ""
    city = poi.get("cityname") or ""
    province = poi.get("pname") or ""
    type_name = (poi.get("type") or "\u666f\u70b9").split(";")[-1]
    resolved_category_id = resolve_category_id(poi, category_id)
    photo = first_photo_url(poi)

    description = f"{name}\uff0c\u4f4d\u4e8e{province}{city}{address}\u3002\u6570\u636e\u6765\u6e90\uff1a\u9ad8\u5fb7\u5730\u56fe\u5f00\u653e\u5e73\u53f0 POI\u3002"

    point_expr = f"ST_SetSRID(ST_MakePoint({longitude}, {latitude}), 4326)::geography"
    identity_where = f"""
lower(trim(name)) = lower(trim({sql_literal(name)}))
      AND COALESCE(city, '') = {sql_literal(city)}
      AND ST_DWithin(location, {point_expr}, 100)
""".strip()

    update_category = f"""
UPDATE scenic_spots
SET category_id = {resolved_category_id}
WHERE {identity_where}
  AND (category_id IS NULL OR category_id = 1);
""".strip()

    update_photo = ""
    if photo:
        update_photo = f"""
UPDATE scenic_spots
SET images = ARRAY[{sql_literal(photo)}],
    thumbnail_url = {sql_literal(photo)}
WHERE {identity_where}
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );
""".strip()

    insert_sql = f"""
INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    {sql_literal(name)},
    {sql_literal(description)},
    {point_expr},
    {resolved_category_id},
    4.20,
    0,
    {sql_literal(address)},
    {sql_literal(city)},
    '\u4ee5\u666f\u533a\u516c\u544a\u4e3a\u51c6',
    0,
    90,
    2,
    ARRAY[{sql_literal(photo)}],
    {sql_literal(photo)},
    ARRAY[{sql_literal(type_name)}, {sql_literal(city)}, {sql_literal(province)}],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE {identity_where}
);
""".strip()

    return "\n\n".join(item for item in [update_category, update_photo, insert_sql] if item)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", required=True, help="Amap Web Service API key")
    parser.add_argument("--city", default="", help="Single city name, for example Beijing")
    parser.add_argument("--cities", default="", help="Comma-separated cities")
    parser.add_argument("--cities-file", default="", help="UTF-8 text file, one city per line")
    parser.add_argument("--preset", default="", help="City preset. Available: national-demo")
    parser.add_argument("--keywords", default="\u666f\u70b9", help="One or more comma-separated keywords")
    parser.add_argument("--types", default="110000|110100|110200", help="Amap POI type codes")
    parser.add_argument("--extensions", choices=["base", "all"], default="all")
    parser.add_argument("--pages", type=int, default=3)
    parser.add_argument("--offset", type=int, default=20)
    parser.add_argument("--delay", type=float, default=0.2, help="Seconds between Amap requests")
    parser.add_argument("--category-id", type=int, default=1, help="Fallback category id when no POI rule matches")
    parser.add_argument("--output", default="database/imports/amap_pois.sql")
    args = parser.parse_args()

    cities = resolve_cities(args.city, args.cities, args.cities_file, args.preset)
    keywords = split_arg(args.keywords)

    all_pois: list[dict] = []
    seen: set[tuple[str, str, str]] = set()
    for city in cities:
        for keyword in keywords:
            print(f"Fetching city={city} keyword={keyword} extensions={args.extensions} ...")
            pois = fetch_pois(
                args.key,
                city,
                keyword,
                args.types,
                args.pages,
                args.offset,
                args.delay,
                args.extensions,
            )
            for poi in pois:
                dedupe_key = (
                    str(poi.get("name") or ""),
                    str(poi.get("address") or ""),
                    str(poi.get("cityname") or city),
                )
                if dedupe_key in seen:
                    continue
                seen.add(dedupe_key)
                all_pois.append(poi)

    statements = [poi_to_sql(poi, args.category_id) for poi in all_pois]
    statements = [item for item in statements if item]
    photo_count = sum(1 for poi in all_pois if first_photo_url(poi))

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        IMPORT_HEADER_SQL
        + "\n"
        + "\n\n".join(statements)
        + "\n\nCOMMIT;\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(statements)} POIs from {len(cities)} cities to {output}")
    print(f"POIs with photos: {photo_count}")


if __name__ == "__main__":
    main()
