# 0001 Indoor Navigation Provider Model

Status: accepted

Date: 2026-06-09

## Context

The course project needs indoor navigation, but full large-scale indoor map
coverage is too costly for the current scope. At the same time, the feature
should not be a fake frontend-only demo. It needs formal data modeling, backend
route planning, provider boundaries, and a clear explanation for defense.

The project already has one PostgreSQL/PostGIS database, `tourism_system`, and
offline AMap scenic POI imports in `database/imports/amap_pois.sql`.

## Decision

Indoor navigation uses a provider model:

- `amap_indoor`: reserved for official AMap indoor map capability, such as
  `cpid`, floor data, and future indoor routePath integration.
- `local_indoor_graph`: implemented local provider using indoor graph tables and
  backend Dijkstra over `indoor_edges`.

All indoor navigation data stays in the existing `tourism_system` database.
The first phase may cover a small number of real buildings, but it must use the
same formal schema, API, source fields, provider fields, and verification rules
expected by a larger implementation.

## Consequences

- AMap data availability does not block course-project verification.
- The project can explain both official provider integration and local algorithm
  fallback.
- Future buildings can be added by inserting more indoor building, floor,
  feature, and edge rows without redesigning the API.
- Teammates must apply database migration and seed SQL after pulling code when
  their local PostgreSQL database is behind.
