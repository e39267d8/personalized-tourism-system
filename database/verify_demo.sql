SET client_encoding = 'UTF8';

-- Quick checks after importing schema.sql and seed_demo.sql.

SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'scenic_spots', COUNT(*) FROM scenic_spots
UNION ALL SELECT 'facilities', COUNT(*) FROM facilities
UNION ALL SELECT 'graph_nodes', COUNT(*) FROM graph_nodes
UNION ALL SELECT 'graph_edges', COUNT(*) FROM graph_edges
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL SELECT 'travel_diaries', COUNT(*) FROM travel_diaries
UNION ALL SELECT 'route_plans', COUNT(*) FROM route_plans
ORDER BY table_name;

SELECT id, name, rating, rating_count, city, tags
FROM scenic_spots
ORDER BY rating DESC, id
LIMIT 5;

SELECT
    rp.id,
    rp.title,
    start_node.name AS start_name,
    end_node.name AS end_name,
    rp.travel_mode,
    rp.total_distance,
    rp.total_duration
FROM route_plans rp
LEFT JOIN graph_nodes start_node ON start_node.id = rp.start_node_id
LEFT JOIN graph_nodes end_node ON end_node.id = rp.end_node_id
ORDER BY rp.id;
