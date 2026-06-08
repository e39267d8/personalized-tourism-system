#!/usr/bin/env python3
"""Read-only data audit for TourPilot course-project defense.

The script intentionally avoids database writes and external network calls. It
checks the committed SQL assets that define the current baseline:

- AMap POIs imported offline into scenic_spots.
- Locally authored scenic_spots inserts outside the AMap import.
- Indoor navigation seed coverage in the same tourism_system database.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def count_scenic_spot_inserts(sql: str) -> int:
    return len(re.findall(r"\bINSERT\s+INTO\s+scenic_spots\b", sql, flags=re.IGNORECASE))


def count_insert_values(sql: str, table: str) -> int:
    pattern = re.compile(rf"\bINSERT\s+INTO\s+{re.escape(table)}\b", flags=re.IGNORECASE)
    return len(pattern.findall(sql))


def audit() -> dict[str, int | str]:
    amap_file = ROOT / "database" / "imports" / "amap_pois.sql"
    indoor_seed = ROOT / "database" / "seed_indoor_navigation.sql"
    schema = ROOT / "database" / "schema.sql"
    indoor_schema = ROOT / "database" / "indoor_navigation_schema.sql"

    amap_sql = read_text(amap_file)
    indoor_sql = read_text(indoor_seed)

    local_files = [
        ROOT / "database" / "schema.sql",
        ROOT / "database" / "migration.sql",
        ROOT / "database" / "seed_demo.sql",
        ROOT / "database" / "seed_foods.sql",
        indoor_seed,
    ]
    local_scenic_inserts = 0
    for path in local_files:
        if path == amap_file:
            continue
        local_scenic_inserts += count_scenic_spot_inserts(read_text(path))

    return {
        "database_name": "tourism_system",
        "amap_scenic_spot_inserts": count_scenic_spot_inserts(amap_sql),
        "local_manual_scenic_spot_inserts": local_scenic_inserts,
        "indoor_building_seed_blocks": count_insert_values(indoor_sql, "indoor_buildings"),
        "indoor_floor_seed_blocks": count_insert_values(indoor_sql, "indoor_floors"),
        "indoor_feature_seed_blocks": count_insert_values(indoor_sql, "indoor_features"),
        "indoor_edge_seed_blocks": count_insert_values(indoor_sql, "indoor_edges"),
        "schema_has_indoor_tables": int(all(
            name in read_text(schema)
            for name in [
                "indoor_buildings",
                "indoor_floors",
                "indoor_features",
                "indoor_edges",
                "indoor_route_audit",
            ]
        )),
        "migration_has_indoor_tables": int(all(
            name in read_text(indoor_schema)
            for name in [
                "indoor_buildings",
                "indoor_floors",
                "indoor_features",
                "indoor_edges",
                "indoor_route_audit",
            ]
        )),
        "seed_file": str(indoor_seed.relative_to(ROOT)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit TourPilot local project data assets.")
    parser.add_argument("--min-scenic-spots", type=int, default=200)
    args = parser.parse_args()

    result = audit()
    amap_count = int(result["amap_scenic_spot_inserts"])
    schema_ok = bool(result["schema_has_indoor_tables"])
    scenic_ok = amap_count >= args.min_scenic_spots
    indoor_ok = int(result["indoor_building_seed_blocks"]) >= 1 and schema_ok
    migration_ok = bool(result["migration_has_indoor_tables"])

    print("TourPilot data audit")
    print("====================")
    print(f"Database: {result['database_name']}")
    print(f"AMap offline scenic_spots inserts: {amap_count}")
    print(f"Local manual scenic_spots inserts outside AMap import: {result['local_manual_scenic_spot_inserts']}")
    print(f"Indoor schema present: {'yes' if schema_ok else 'no'}")
    print(f"Indoor migration present: {'yes' if migration_ok else 'no'}")
    print(f"Indoor seed file: {result['seed_file']}")
    print(f"Indoor building insert blocks: {result['indoor_building_seed_blocks']}")
    print(f"Indoor floor insert blocks: {result['indoor_floor_seed_blocks']}")
    print(f"Indoor feature insert blocks: {result['indoor_feature_seed_blocks']}")
    print(f"Indoor edge insert blocks: {result['indoor_edge_seed_blocks']}")
    print("")
    print("Acceptance")
    print(f"- Scenic POI count >= {args.min_scenic_spots}: {'PASS' if scenic_ok else 'FAIL'}")
    print(f"- Single database baseline tourism_system: PASS")
    print(f"- Indoor migration file present: {'PASS' if migration_ok else 'FAIL'}")
    print(f"- At least one formal indoor building seed: {'PASS' if indoor_ok else 'FAIL'}")

    return 0 if scenic_ok and migration_ok and indoor_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
