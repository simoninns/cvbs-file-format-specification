# AC3 Extension Format

This document defines a standard extension format for storing AC3 (also known as Dolby Digital) t-value data associated with CVBS files.

The format is an extension to the core [CVBS File Format Specification](../index.md) and is intentionally separate from the core metadata schema.

---

## Purpose and Scope

AC3 t-value data represents the raw channel t-values extracted from an AC3-encoded signal embedded within or accompanying a CVBS capture. T-values are unsigned byte values in the range 0–255, typically representing modulation intervals (conventionally T3 to T11, values 3 to 11).

The number of t-values per frame is variable and not predictable from the video standard or sample rate alone. This extension therefore uses two files: a binary data file containing the t-value byte stream and a SQLite sidecar providing the per-frame index into that stream.

This extension format is for producer-generated AC3 t-value data only. It does not alter CVBS sample payload bytes, video timing definitions, or any core metadata semantics.

---

## File Naming

The AC3 extension consists of two sidecar files:

- **AC3 t-value data:** `<basename>.ac3`
- **AC3 frame index metadata:** `<basename>.ac3.meta`

`<basename>` must match the basename of the associated CVBS data/metadata files.

---

## Association with Core Metadata

An AC3 extension file pair applies to one logical CVBS capture identified by basename.

If the core metadata file (`<basename>.meta`) exists, the extension's `cvbs_file_id` values must reference a valid `cvbs_file.cvbs_file_id` row in that file.

Producers must ensure the sidecar is mapped to the correct capture by validating all of the following before writing data:

1. The sidecar basename exactly matches the associated CVBS basename.
2. Every row's `cvbs_file_id` exists in `<basename>.meta`.
3. All frame index rows in the sidecar refer only to that associated capture.

If no core metadata file exists, producers must set `cvbs_file_id = 1` and treat it as the implicit default capture identifier.

---

## Binary Data File

The `<basename>.ac3` file is a flat binary stream of unsigned 8-bit t-values.

- Each byte represents one t-value in the range 0–255.
- T-values from successive frames are concatenated in ascending `frame_id` order with no padding or alignment between frames.
- There is no file header.
- The total number of bytes in the file must equal the sum of all `t_value_count` values across all rows in `<basename>.ac3.meta` for the associated capture.

---

## SQLite Schema

```sql
PRAGMA user_version = 1;

CREATE TABLE ac3_frame (
    cvbs_file_id    INTEGER NOT NULL,
    frame_id        INTEGER NOT NULL
        CHECK (frame_id >= 0),
    t_value_offset  INTEGER NOT NULL
        CHECK (t_value_offset >= 0),
    t_value_count   INTEGER NOT NULL
        CHECK (t_value_count >= 0),
    PRIMARY KEY (cvbs_file_id, frame_id)
);

CREATE INDEX idx_ac3_frame_frame
    ON ac3_frame (cvbs_file_id, frame_id);
```

---

## Table Definition

### `ac3_frame` Table

The `ac3_frame` table provides the per-frame index into the `<basename>.ac3` binary data file.

Each row defines the location and length of one frame's t-value data within the binary stream.

#### `cvbs_file_id`

- **Type:** INTEGER
- **Nullable:** No
- **Description:** Identifier of the associated capture. Must match `cvbs_file.cvbs_file_id` in `<basename>.meta` when that file exists.

#### `frame_id`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0 to `number_of_sequential_frames - 1` when known
- **Description:** Zero-based sequential frame index within capture order.

#### `t_value_offset`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** `>= 0`
- **Description:** Byte offset from the start of `<basename>.ac3` at which this frame's t-values begin. The first frame must have `t_value_offset = 0`. Each subsequent frame's offset must equal the previous frame's `t_value_offset + t_value_count`.

#### `t_value_count`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** `>= 0`
- **Description:** Number of t-value bytes belonging to this frame. A value of zero indicates no AC3 t-values were recovered for this frame.

---

## Frame Validity Rules

1. `frame_id` is frame-relative and uses 0-based indexing.
2. `t_value_offset` is a byte offset from the start of the binary data file.
3. The first row (lowest `frame_id`) must have `t_value_offset = 0`.
4. `t_value_offset` for each row must equal the sum of `t_value_count` values for all rows with a lower `frame_id`, within the same `cvbs_file_id`.
5. A given `(cvbs_file_id, frame_id)` tuple must appear at most once.
6. The total size of `<basename>.ac3` must equal `t_value_offset + t_value_count` for the row with the highest `frame_id`, within the same `cvbs_file_id`.

---

## Consumer Requirements

1. Consumers must treat this extension as optional.
2. If either file is missing or unreadable, consumers must continue processing the CVBS content without AC3 data.
3. If `<basename>.ac3.meta` is present but `<basename>.ac3` is absent, consumers must treat the extension as absent.
4. Consumers must ignore unknown columns added by future extension revisions.
5. Consumers should ignore rows whose `frame_id` falls outside known capture bounds when those bounds are known.
6. Consumers must not interpret the 0–255 byte value range as implying any constraint on valid t-values; all byte values are permitted.

---

## Versioning and Forward Compatibility

- Schema versioning uses `PRAGMA user_version`.
- This document defines version `1`.
- Future versions may add columns and additional tables.
- Future versions must not redefine the meaning of existing columns in an incompatible way.
