SET client_encoding = 'UTF8';

-- Internal scenic-area navigation support.
-- This migration is additive and can be run more than once.

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

CREATE INDEX IF NOT EXISTS idx_facilities_scenic_spot ON facilities(scenic_spot_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_facilities_source_ref ON facilities(source, source_ref);
CREATE UNIQUE INDEX IF NOT EXISTS ux_graph_nodes_source_ref ON graph_nodes(source, source_ref);
CREATE INDEX IF NOT EXISTS idx_facilities_source_ref ON facilities(source, source_ref);
CREATE INDEX IF NOT EXISTS idx_graph_nodes_source_ref ON graph_nodes(source, source_ref);
CREATE INDEX IF NOT EXISTS idx_graph_edges_source_ref ON graph_edges(source, source_ref);
CREATE INDEX IF NOT EXISTS idx_graph_edges_geometry ON graph_edges USING GIST (geometry);

COMMIT;
