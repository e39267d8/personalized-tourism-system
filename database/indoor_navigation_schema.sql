SET client_encoding = 'UTF8';

-- Indoor navigation support.
-- Additive migration for existing tourism_system databases.

BEGIN;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS indoor_buildings (
    id SERIAL PRIMARY KEY,
    scenic_spot_id INTEGER NOT NULL REFERENCES scenic_spots(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    provider VARCHAR(40) NOT NULL DEFAULT 'local_indoor_graph'
        CHECK (provider IN ('amap_indoor', 'local_indoor_graph')),
    source VARCHAR(50) NOT NULL,
    source_ref VARCHAR(160) NOT NULL,
    amap_cpid VARCHAR(120),
    has_indoor_map BOOLEAN DEFAULT FALSE,
    description TEXT,
    default_floor_code VARCHAR(30),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(source, source_ref)
);

CREATE TABLE IF NOT EXISTS indoor_floors (
    id SERIAL PRIMARY KEY,
    building_id INTEGER NOT NULL REFERENCES indoor_buildings(id) ON DELETE CASCADE,
    floor_code VARCHAR(30) NOT NULL,
    floor_name VARCHAR(80) NOT NULL,
    floor_index INTEGER NOT NULL DEFAULT 0,
    provider VARCHAR(40) NOT NULL DEFAULT 'local_indoor_graph'
        CHECK (provider IN ('amap_indoor', 'local_indoor_graph')),
    source VARCHAR(50) NOT NULL,
    source_ref VARCHAR(160) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(building_id, floor_code),
    UNIQUE(source, source_ref)
);

CREATE TABLE IF NOT EXISTS indoor_features (
    id SERIAL PRIMARY KEY,
    building_id INTEGER NOT NULL REFERENCES indoor_buildings(id) ON DELETE CASCADE,
    floor_id INTEGER NOT NULL REFERENCES indoor_floors(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    type VARCHAR(40) NOT NULL,
    x DECIMAL(10,2) DEFAULT 0,
    y DECIMAL(10,2) DEFAULT 0,
    provider VARCHAR(40) NOT NULL DEFAULT 'local_indoor_graph'
        CHECK (provider IN ('amap_indoor', 'local_indoor_graph')),
    source VARCHAR(50) NOT NULL,
    source_ref VARCHAR(160) NOT NULL,
    amap_poi_id VARCHAR(120),
    is_public BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(source, source_ref)
);

CREATE TABLE IF NOT EXISTS indoor_edges (
    id SERIAL PRIMARY KEY,
    building_id INTEGER NOT NULL REFERENCES indoor_buildings(id) ON DELETE CASCADE,
    from_feature_id INTEGER NOT NULL REFERENCES indoor_features(id) ON DELETE CASCADE,
    to_feature_id INTEGER NOT NULL REFERENCES indoor_features(id) ON DELETE CASCADE,
    distance DECIMAL(10,2) NOT NULL,
    travel_time INTEGER NOT NULL,
    edge_type VARCHAR(40) NOT NULL DEFAULT 'corridor',
    provider VARCHAR(40) NOT NULL DEFAULT 'local_indoor_graph'
        CHECK (provider IN ('amap_indoor', 'local_indoor_graph')),
    source VARCHAR(50) NOT NULL,
    source_ref VARCHAR(180) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(source, source_ref),
    UNIQUE(from_feature_id, to_feature_id, edge_type)
);

CREATE TABLE IF NOT EXISTS indoor_route_audit (
    id BIGSERIAL PRIMARY KEY,
    building_id INTEGER REFERENCES indoor_buildings(id) ON DELETE SET NULL,
    provider VARCHAR(40) NOT NULL,
    algorithm VARCHAR(80) NOT NULL,
    start_feature_id INTEGER,
    end_feature_id INTEGER,
    strategy VARCHAR(40),
    success BOOLEAN DEFAULT FALSE,
    fallback_used BOOLEAN DEFAULT FALSE,
    duration_ms INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_indoor_buildings_spot ON indoor_buildings(scenic_spot_id);
CREATE INDEX IF NOT EXISTS idx_indoor_buildings_provider ON indoor_buildings(provider);
CREATE INDEX IF NOT EXISTS idx_indoor_floors_building ON indoor_floors(building_id);
CREATE INDEX IF NOT EXISTS idx_indoor_features_building ON indoor_features(building_id);
CREATE INDEX IF NOT EXISTS idx_indoor_features_floor ON indoor_features(floor_id);
CREATE INDEX IF NOT EXISTS idx_indoor_features_type ON indoor_features(type);
CREATE INDEX IF NOT EXISTS idx_indoor_edges_building ON indoor_edges(building_id);
CREATE INDEX IF NOT EXISTS idx_indoor_edges_from ON indoor_edges(from_feature_id);
CREATE INDEX IF NOT EXISTS idx_indoor_edges_to ON indoor_edges(to_feature_id);
CREATE INDEX IF NOT EXISTS idx_indoor_route_audit_building ON indoor_route_audit(building_id);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_indoor_buildings_updated_at') THEN
        CREATE TRIGGER update_indoor_buildings_updated_at
            BEFORE UPDATE ON indoor_buildings
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_indoor_floors_updated_at') THEN
        CREATE TRIGGER update_indoor_floors_updated_at
            BEFORE UPDATE ON indoor_floors
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_indoor_features_updated_at') THEN
        CREATE TRIGGER update_indoor_features_updated_at
            BEFORE UPDATE ON indoor_features
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_indoor_edges_updated_at') THEN
        CREATE TRIGGER update_indoor_edges_updated_at
            BEFORE UPDATE ON indoor_edges
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_indoor_route_audit_updated_at') THEN
        CREATE TRIGGER update_indoor_route_audit_updated_at
            BEFORE UPDATE ON indoor_route_audit
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

COMMIT;
