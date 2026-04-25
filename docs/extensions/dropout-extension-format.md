# Dropout Extension Format

This document defines a standard extension format for storing dropout annotations for CVBS files.

The format is an extension to the core [CVBS File Format Specification](../index.md) and is intentionally separate from the core metadata schema.

---

## Purpose and Scope

A dropout annotation marks one or more contiguous CVBS samples within a frame where source signal quality is lost or significantly degraded.

This extension format is for producer-generated dropout metadata only. It does not alter CVBS sample payload bytes, video timing definitions, or any core metadata semantics.

---

## File Naming

The dropout extension file is a separate SQLite sidecar file:

- **Dropout extension metadata:** `<basename>.dropouts.meta`

`<basename>` must match the basename of the associated CVBS data/metadata files.

---

## Association with Core Metadata

A dropout extension file applies to one logical CVBS capture identified by basename.

If the core metadata file (`<basename>.meta`) exists, the extension's `cvbs_file_id` values must reference a valid `cvbs_file.cvbs_file_id` row in that file.

Producers must ensure the sidecar is mapped to the correct capture by validating all of the following before writing annotations:

1. The sidecar basename exactly matches the associated CVBS basename.
2. Every row's `cvbs_file_id` exists in `<basename>.meta`.
3. All dropout rows in the sidecar refer only to that associated capture.

If no core metadata file exists, producers must set `cvbs_file_id = 1` and treat it as the implicit default capture identifier.

---

## SQLite Schema

```sql
PRAGMA user_version = 5;

CREATE TABLE dropout_run (
    cvbs_file_id    INTEGER NOT NULL,
    frame_id        INTEGER NOT NULL
        CHECK (frame_id >= 0),
    sample_start    INTEGER NOT NULL
        CHECK (sample_start >= 0),
    sample_count    INTEGER NOT NULL
        CHECK (sample_count > 0),
    severity        INTEGER NOT NULL
        CHECK (severity >= 0 AND severity <= 100),
    PRIMARY KEY (cvbs_file_id, frame_id, sample_start)
);

CREATE INDEX idx_dropout_run_frame
    ON dropout_run (cvbs_file_id, frame_id);
```

---

## Table Definition

### `dropout_run` Table

The `dropout_run` table records sample-range dropout annotations within frames.

Each row defines one contiguous dropout run in a frame.

#### `cvbs_file_id`

- **Type:** INTEGER
- **Nullable:** No
- **Description:** Identifier of the associated capture. Must match `cvbs_file.cvbs_file_id` in `<basename>.meta` when that file exists.

#### `frame_id`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0 to `number_of_sequential_frames - 1` when known
- **Description:** Zero-based sequential frame index within capture order.

#### `sample_start`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0 to `samples_per_frame - 1` when known
- **Description:** Zero-based sample index within the frame where the dropout run begins.

#### `sample_count`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** `>= 1`
- **Description:** Number of consecutive samples affected by the dropout run.

#### `severity`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0 to 100
- **Description:** Producer confidence/severity percentage for the annotated dropout run.

---

## Frame and Sample Validity Rules

1. `frame_id` is frame-relative and uses 0-based indexing.
2. `sample_start` is frame-relative and uses 0-based indexing.
3. `sample_count` is the run length in samples and must be greater than 0.
4. A given `(cvbs_file_id, frame_id, sample_start)` tuple must appear at most once.
5. Producers should split non-contiguous dropout regions into separate rows.
6. Producers should avoid emitting overlapping runs for the same frame.
7. When frame sample bounds are known, producers should ensure `sample_start + sample_count` does not exceed frame sample length.

---

## Consumer Requirements

1. Consumers must treat this extension as optional.
2. If the file is missing or unreadable, consumers must continue processing the CVBS content without dropout overlays.
3. Consumers must ignore unknown columns added by future extension revisions.
4. Consumers should ignore rows whose `frame_id` falls outside known capture bounds when those bounds are known.
5. Consumers should ignore rows where `sample_start` or `sample_count` is out of bounds when frame sample bounds are known.

---

## Versioning and Forward Compatibility

- Schema versioning uses `PRAGMA user_version`.
- This document defines version `5`.
- Version `5` changes `severity` to an integer percentage in the range 0 to 100.
- Version `4` defines sample-range dropout runs (`dropout_run`) using `frame_id`, `sample_start`, and `sample_count`.
- Future versions may add columns and additional tables.
- Future versions must not redefine the meaning of existing columns in an incompatible way.
