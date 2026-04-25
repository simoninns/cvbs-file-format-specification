# Dropout Extension Format

This document defines a standard extension format for storing dropout annotations for CVBS files.

The format is an extension to the core [CVBS File Format Specification](../index.md) and is intentionally separate from the core metadata schema.

---

## Purpose and Scope

A dropout annotation marks a frame where source signal quality is lost or significantly degraded.

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

If no core metadata file exists, producers must set `cvbs_file_id = 1` and treat it as the implicit default capture identifier.

---

## SQLite Schema

```sql
PRAGMA user_version = 3;

CREATE TABLE dropout_frame (
    cvbs_file_id    INTEGER NOT NULL,
    frame_id        INTEGER NOT NULL
        CHECK (frame_id >= 0),
    severity        TEXT    NOT NULL
        CHECK (severity IN ('suspected', 'confirmed')),
    source          TEXT,
    notes           TEXT,
    PRIMARY KEY (cvbs_file_id, frame_id)
);

CREATE INDEX idx_dropout_frame
    ON dropout_frame (cvbs_file_id, frame_id);
```

---

## Table Definition

### `dropout_frame` Table

The `dropout_frame` table records frame-level dropout annotations.

Each row defines one annotated frame.

#### `cvbs_file_id`

- **Type:** INTEGER
- **Nullable:** No
- **Description:** Identifier of the associated capture. Must match `cvbs_file.cvbs_file_id` in `<basename>.meta` when that file exists.

#### `frame_id`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0 to `number_of_sequential_frames - 1` when known
- **Description:** Zero-based sequential frame index within capture order.

#### `severity`

- **Type:** TEXT
- **Nullable:** No
- **Range:** `'suspected'`, `'confirmed'`
- **Description:** Producer confidence classification for the annotated dropout frame.

#### `source`

- **Type:** TEXT
- **Nullable:** Yes
- **Description:** Optional producer/source tag naming the algorithm, model, or workflow that generated the annotation.

#### `notes`

- **Type:** TEXT
- **Nullable:** Yes
- **Description:** Optional free-form note for debugging, review, or curation context.

---

## Frame Index and Validity Rules

1. `frame_id` is frame-relative and uses 0-based indexing.
2. A given `(cvbs_file_id, frame_id)` pair must appear at most once.
3. Producers should annotate a frame when any dropout condition for that frame meets the producer's selected detection/reporting threshold.

---

## Consumer Requirements

1. Consumers must treat this extension as optional.
2. If the file is missing or unreadable, consumers must continue processing the CVBS content without dropout overlays.
3. Consumers must ignore unknown columns added by future extension revisions.
4. Consumers should ignore rows whose `frame_id` falls outside known capture bounds when those bounds are known.

---

## Versioning and Forward Compatibility

- Schema versioning uses `PRAGMA user_version`.
- This document defines version `3`.
- Version `3` changes the extension from coordinate-level dropout runs to one row per frame (`dropout_frame`).
- Future versions may add columns and additional tables.
- Future versions must not redefine the meaning of existing columns in an incompatible way.
