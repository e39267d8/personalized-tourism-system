SET client_encoding = 'UTF8';

-- Stitch imported OSM road islands into the global route graph without deleting
-- the older demo edges. Run after internal_navigation_schema.sql, OSM imports,
-- seed_demo.sql and route_tiantan_global_node.sql.

BEGIN;

SELECT setval('graph_edges_id_seq', (SELECT COALESCE(MAX(id), 1) FROM graph_edges));

-- Different imported scenic/campus areas can contain duplicated OSM junctions
-- at the same coordinate. These tiny stitch edges make those duplicates behave
-- as one road intersection for Dijkstra/TSP.
WITH pairs AS (
    SELECT
        a.id AS from_node,
        b.id AS to_node,
        GREATEST(ST_Distance(a.location, b.location), 0.5) AS distance_meters,
        a.location AS from_location,
        b.location AS to_location
    FROM graph_nodes a
    JOIN graph_nodes b
        ON a.id < b.id
       AND a.source = 'osm'
       AND b.source = 'osm'
       AND a.node_type = 'junction'
       AND b.node_type = 'junction'
       AND ST_DWithin(a.location, b.location, 2.0)
),
directed AS (
    SELECT from_node, to_node, distance_meters, from_location, to_location FROM pairs
    UNION ALL
    SELECT to_node, from_node, distance_meters, to_location, from_location FROM pairs
)
INSERT INTO graph_edges
    (from_node, to_node, distance, travel_mode, travel_time, base_weight,
     congestion_level, geometry, source, source_ref, source_tags)
SELECT
    from_node,
    to_node,
    distance_meters,
    'walk',
    GREATEST(1, CEIL(distance_meters / 1.2)::int),
    GREATEST(0.01, distance_meters / 100.0),
    2,
    ST_MakeLine(from_location::geometry, to_location::geometry)::geography,
    'osm_stitch',
    'osm-stitch:' || from_node || ':' || to_node,
    jsonb_build_object('purpose', 'merge_duplicate_osm_junctions', 'max_distance_meters', 2.0)
FROM directed
ON CONFLICT (from_node, to_node, travel_mode) DO NOTHING;

-- Attach the global route-planning scenic nodes to nearby OSM road junctions.
-- Long-range city travel still keeps the existing demo/global edges as fallback,
-- but nearby road geometry can now be used when a stitched OSM path exists.
WITH scenic AS (
    SELECT id, name, location
    FROM graph_nodes
    WHERE id BETWEEN 1 AND 9
      AND node_type = 'scenic'
      AND location IS NOT NULL
),
candidates AS (
    SELECT
        s.id AS scenic_id,
        n.id AS junction_id,
        ST_Distance(s.location, n.location) AS distance_meters,
        s.location AS scenic_location,
        n.location AS junction_location,
        ROW_NUMBER() OVER (
            PARTITION BY s.id
            ORDER BY ST_Distance(s.location, n.location), n.id
        ) AS rn
    FROM scenic s
    JOIN graph_nodes n
        ON n.source = 'osm'
       AND n.node_type = 'junction'
       AND ST_DWithin(s.location, n.location, 600.0)
),
selected AS (
    SELECT *
    FROM candidates
    WHERE rn <= 3
),
directed AS (
    SELECT scenic_id AS from_node, junction_id AS to_node, distance_meters, scenic_location AS from_location, junction_location AS to_location
    FROM selected
    UNION ALL
    SELECT junction_id AS from_node, scenic_id AS to_node, distance_meters, junction_location AS from_location, scenic_location AS to_location
    FROM selected
)
INSERT INTO graph_edges
    (from_node, to_node, distance, travel_mode, travel_time, base_weight,
     congestion_level, geometry, source, source_ref, source_tags)
SELECT
    from_node,
    to_node,
    distance_meters,
    'walk',
    GREATEST(1, CEIL(distance_meters / 1.2)::int),
    GREATEST(0.05, distance_meters / 100.0),
    2,
    ST_MakeLine(from_location::geometry, to_location::geometry)::geography,
    'global_connector',
    'global-connector:' || from_node || ':' || to_node,
    jsonb_build_object('purpose', 'attach_global_scenic_node_to_osm', 'max_distance_meters', 600.0)
FROM directed
ON CONFLICT (from_node, to_node, travel_mode) DO UPDATE SET
    distance = EXCLUDED.distance,
    travel_time = EXCLUDED.travel_time,
    base_weight = EXCLUDED.base_weight,
    congestion_level = EXCLUDED.congestion_level,
    geometry = EXCLUDED.geometry,
    source = EXCLUDED.source,
    source_ref = EXCLUDED.source_ref,
    source_tags = EXCLUDED.source_tags;

SELECT setval('graph_edges_id_seq', (SELECT COALESCE(MAX(id), 1) FROM graph_edges));

COMMIT;
