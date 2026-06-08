# Indoor Navigation And Real Data Rules

## Data Baseline

- Scenic spot data is imported from AMap Open Platform POI results into `database/imports/amap_pois.sql`.
- The import is offline and reproducible: after SQL import, runtime pages mainly read local PostgreSQL tables.
- The single runtime database is `tourism_system`.
- The AMap import currently contains 3476 `INSERT INTO scenic_spots` statements.
- Local manually authored scenic spots are not mixed into a second scenic table. If manual scenic spots are added later, they must use clear `source` and `source_ref` fields.

This is close to a crawler-style "collect once, store locally" data workflow, but the source is the official AMap API, which is more structured and easier to explain in a course-project defense.

## Indoor Navigation Strategy

Indoor navigation is a formal project capability with controlled first-phase coverage. It is not a fake demo.

Provider boundary:

- `amap_indoor`: preferred provider for buildings that expose official AMap indoor map capability, such as `indoor_map`, `cpid`, floor data, and browser-side indoor map/routePath support.
- `local_indoor_graph`: local provider for stable course-project behavior, algorithm explanation, and fallback when official indoor data is missing or unavailable.

First phase:

- Use one real scenic spot building as a formal local indoor graph seed.
- Preserve the schema, API, provider fields, audit fields, and algorithm path so that more buildings can be added without redesign.
- Keep AMap indoor capability fields in `indoor_buildings` so official provider integration can be expanded later without another migration.

## Database Rules

Hard rule: only use `tourism_system`.

Indoor navigation tables are domain tables inside the same database:

- `indoor_buildings`
- `indoor_floors`
- `indoor_features`
- `indoor_edges`
- `indoor_route_audit`

Every new indoor table row must carry:

- `source`
- `source_ref`
- `provider`
- `created_at`
- `updated_at`

Do not add:

- a second database
- a second scenic spot table
- a second user table
- a parallel route table for the same responsibility

## API Contract

All frontend calls go through `frontend/src/services/tourismApi.js`.

### List Indoor Buildings

`GET /api/v1/scenic-spots/:id/indoor-buildings`

Returns buildings under the scenic spot:

- `provider`
- `hasIndoorMap`
- `amapCpid`
- `floorCount`
- `featureCount`

### List Indoor Features

`GET /api/v1/indoor-buildings/:id/features?floor=F1&type=toilet`

Returns facilities, rooms, halls, stairs, elevators, entrances, and other navigable features. `floor` and `type` are optional filters.

### Plan Indoor Route

`POST /api/v1/indoor-buildings/:id/routes/plan`

Request:

```json
{
  "startFeatureId": 101,
  "endFeatureId": 208,
  "strategy": "time"
}
```

Response:

```json
{
  "provider": "local_indoor_graph",
  "configuredProvider": "local_indoor_graph",
  "algorithm": "indoor-dijkstra",
  "distanceMeters": 180,
  "durationSeconds": 240,
  "steps": [],
  "path": [],
  "fallbackUsed": false
}
```

## Algorithm Rule

- Core indoor route planning is implemented in the backend.
- The frontend may select building, floor, start, end, and strategy, but must not implement core route planning.
- `local_indoor_graph` uses Dijkstra over `indoor_edges`.
- `strategy=time` uses `travel_time` as edge weight.
- `strategy=distance` uses `distance` as edge weight.
- Floor switches are represented as edges of type `elevator` or `stairs`, with realistic time costs.

## Data Audit

Run:

```powershell
python scripts\audit_project_data.py
```

The audit checks:

- AMap offline `scenic_spots` insert count.
- Locally authored scenic spot inserts outside the AMap import.
- Indoor schema presence.
- Indoor seed coverage.

Defense wording:

- The 3476 scenic spots were collected from AMap API once, generated into SQL, and imported locally.
- Runtime pages do not rely on calling AMap POI search for every page view.
- Indoor navigation is implemented with formal provider fallback and a local graph algorithm.
- First-phase indoor coverage is intentionally small, but the engineering interface is expandable.

## Development Order

1. Run data audit before changing data.
2. Add or update schema in the existing database only.
3. Add seed/import SQL with stable `source_ref` upserts.
4. Add backend API in the matching route module.
5. Add frontend calls through `tourismApi.js`.
6. Add UI that handles both available and empty states.
7. Update this document when provider behavior or schema changes.

## Acceptance Checklist

- Scenic POI count is greater than 200.
- All project data is in `tourism_system`.
- At least one real scenic spot has an indoor building record.
- A building with indoor data returns features.
- A building with indoor graph edges returns a route.
- A building without indoor data returns an empty state or explicit error, not a crash.
- Route response includes provider, configured provider, algorithm, distance, duration, steps, path, and fallback status.
