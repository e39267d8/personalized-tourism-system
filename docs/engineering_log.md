# Engineering Log

This file records important project engineering changes after branch handoff.
Keep entries short and factual. Do not create a new "changes after branch X"
document for every pull or merge.

Use this log for:

- Meaningful feature changes.
- Database schema, import, or seed changes.
- Collaboration rules that affect how teammates run or verify the project.
- Important bug fixes with user-visible impact.

Use ADR files under `docs/adr/` for major architecture decisions.

## 2026-06-09 / feature-yhm-graph / indoor navigation workflow

Type: indoor navigation, database workflow, documentation.

Changes:

- Added formal indoor navigation tables and seed files:
  `database/indoor_navigation_schema.sql` and
  `database/seed_indoor_navigation.sql`.
- Added the Beida Red Building / 北大红楼 first-phase indoor graph data using
  `local_indoor_graph`.
- Updated quick-start and database docs to clarify that `git pull` does not
  change local PostgreSQL data.
- Clarified that existing databases must apply the indoor migration and seed in
  the same `tourism_system` database.

Verification:

- `database/indoor_navigation_schema.sql` is idempotent through
  `CREATE TABLE IF NOT EXISTS`.
- `database/seed_indoor_navigation.sql` uses stable `source_ref` upserts.
- Expected indoor seed result: one Beida Red Building indoor building, two
  floors, ten features, and eighteen directed edges.

Notes:

- Do not create a second database for indoor navigation.
- Do not add branch-specific change documents for ordinary future work. Append
  concise entries here, and create an ADR only for major architecture choices.
