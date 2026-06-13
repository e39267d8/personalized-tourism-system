SET client_encoding = 'UTF8';

-- Add Tiantan Park to the global route-planning demo graph.
-- This migration is idempotent and is safe to run on existing tourism_system databases.

BEGIN;

WITH tiantan_spot AS (
    SELECT id
    FROM scenic_spots
    WHERE name ILIKE '%天坛%'
    ORDER BY
        CASE WHEN name ILIKE '%天坛公园%' THEN 0 ELSE 1 END,
        id
    LIMIT 1
)
INSERT INTO graph_nodes
    (id, name, location, node_type, scenic_spot_id, facility_id, congestion_level)
SELECT
    9,
    '天坛公园节点',
    ST_SetSRID(ST_MakePoint(116.406601, 39.882156), 4326)::geography,
    'scenic',
    id,
    NULL,
    3
FROM tiantan_spot
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    location = EXCLUDED.location,
    node_type = EXCLUDED.node_type,
    scenic_spot_id = EXCLUDED.scenic_spot_id,
    facility_id = EXCLUDED.facility_id,
    congestion_level = EXCLUDED.congestion_level;

INSERT INTO graph_edges
    (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry)
VALUES
    (6, 9, 2300, 'walk', 1900, 23.00, 3, 'SRID=4326;LINESTRING(116.397957 39.899318, 116.398400 39.895900, 116.400900 39.891400, 116.404200 39.886800, 116.406601 39.882156)'),
    (9, 6, 2300, 'walk', 1900, 23.00, 3, 'SRID=4326;LINESTRING(116.406601 39.882156, 116.404200 39.886800, 116.400900 39.891400, 116.398400 39.895900, 116.397957 39.899318)'),
    (5, 9, 2800, 'walk', 2300, 28.00, 3, 'SRID=4326;LINESTRING(116.401015 39.905103, 116.402200 39.899600, 116.403700 39.893400, 116.405100 39.887900, 116.406601 39.882156)'),
    (9, 5, 2800, 'walk', 2300, 28.00, 3, 'SRID=4326;LINESTRING(116.406601 39.882156, 116.405100 39.887900, 116.403700 39.893400, 116.402200 39.899600, 116.401015 39.905103)'),
    (2, 9, 3200, 'walk', 2600, 32.00, 3, 'SRID=4326;LINESTRING(116.397477 39.908692, 116.399100 39.901600, 116.402300 39.894200, 116.404900 39.887700, 116.406601 39.882156)'),
    (9, 2, 3200, 'walk', 2600, 32.00, 3, 'SRID=4326;LINESTRING(116.406601 39.882156, 116.404900 39.887700, 116.402300 39.894200, 116.399100 39.901600, 116.397477 39.908692)')
ON CONFLICT (from_node, to_node, travel_mode) DO UPDATE SET
    distance = EXCLUDED.distance,
    travel_time = EXCLUDED.travel_time,
    base_weight = EXCLUDED.base_weight,
    congestion_level = EXCLUDED.congestion_level,
    geometry = EXCLUDED.geometry;

SELECT setval('graph_nodes_id_seq', (SELECT MAX(id) FROM graph_nodes));
SELECT setval('graph_edges_id_seq', (SELECT COALESCE(MAX(id), 1) FROM graph_edges));

COMMIT;
