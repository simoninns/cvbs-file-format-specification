# CVBS File Format Specification

---

## Introduction

This document defines the **CVBS File Format** for use with the `ld-decode`, `vhs-decode` and related projects. **CVBS** (Colour, Video, Blank, and Sync) describes the full class of analogue video signal — both composite (luma and chroma combined into a single signal) and component YC representations carry the same Colour, Video, Blank, and Sync elements and are therefore both CVBS signals.

The format is organised around three independent **preset systems**, each of which captures a distinct dimension of the signal:

- [**Video Standard Presets**](#video-standard-presets): define the timing and structural parameters of the video signal — line counts, field rates, horizontal sample structure, colour field sequence, and the normative sample level tables for standards-compliant signals.
- [**Sample Encoding Presets**](#sample-encoding-presets): define the bit depth, word format, and amplitude mapping used when the sample data was recorded.
- [**Signal State Presets**](#signal-state-presets): define the processing state of the signal at the time of storage — whether a standard 4×fsc sample rate was used, whether time-base correction (TBC) was applied, and whether the decoder was phase-locked to the colour burst.

Every CVBS file is described by one preset from each system. Together they fully specify how to locate field boundaries, interpret sample amplitudes, and determine the reliability of phase and level measurements.

The format accommodates **non-standard cases** (e.g., LaserDisc PAL pilot bursts and variations such as NTSC-J) through metadata flags rather than structural changes.

---

## File Naming Convention

Each file type uses a distinct extension:

- **Composite CVBS:** `<basename>.composite`
- **Dual-File YC CVBS (Luma):** `<basename>.y`
- **Dual-File YC CVBS (Chroma):** `<basename>.c`

---

## Video Data Format

### Sample Encoding

The physical encoding and amplitude mapping of samples are defined by the [**Sample Encoding Preset**](#sample-encoding-presets) declared for the file. The main properties governed by the sample encoding preset are:

- **Word format:** the integer width, signedness, and byte order of each stored sample word.
- **Amplitude mapping:** the relationship between the stored integer value and the analogue signal amplitude — specifically, where sync tip, blanking, black, white, and peak levels fall within the integer range.
- **Headroom:** whether negative or positive values beyond the nominal 0–1023 range are meaningful.

The standard encoding preset (`CVBS_10BIT`) represents the normative production output of `ld-decode`, `vhs-decode`, and similar tools. The raw capture presets represent unscaled ADC output from hardware capturers such as the DomesdayDuplicator. See [sample-encoding-presets](sample-encoding-presets.md) for the full definitions.

This specification supports two CVBS (Colour, Video, Blank, and Sync) storage representations, which differ only in how colour information is carried:

- **Composite CVBS:** Single file containing luma and chroma combined into one signal.
- **Dual-File YC CVBS:** Separate files for luma (Y) and chroma (C), keeping the colour components separated.

The specific sample range — sync tip, blanking, black, white, and peak levels together with any reserved protected values — is defined by the declared [Sample Encoding Preset](#sample-encoding-presets).

### File Layout

Video data is stored field-by-field with no additional framing or headers:

```
[Field 1 Video Data: N bytes]
[Field 2 Video Data: N bytes]
...
```

---

## Video Standard Presets

### Preset System

A **Video Standard Preset** is a named configuration that fully defines all timing and structural parameters for a video standard: sampling rate, line counts, field structure, sample level tables, colour field sequence length, and references to the external standards on which the preset is based. These presets do **not** define the physical sample word format or the processing state of the signal — those are covered by the [Sample Encoding Preset](#sample-encoding-presets) and [Signal State Preset](#signal-state-presets) respectively.

The `preset` field in the `cvbs_file` metadata table (see the [`cvbs_file` table](#cvbs_file-table)) identifies which Video Standard Preset applies to a given CVBS file. Consumers must implement a preset in full; an unrecognised preset name must not be silently interpreted — the consumer must refuse to process the file or report an error.

### Preset Definitions

Full definitions — including naming convention, sampling rates, sample level tables, horizontal and vertical structure, and normative field sizes — are in [video-standard-presets](video-standard-presets.md).

### Non-Standard Extensions

Certain source materials (e.g., LaserDisc) carry signals in the blanking interval that fall outside the standard protected sample range. See [video-standard-presets](video-standard-presets.md#non-standard-extensions) for details.

### Field Ordering and Phase Verification

Fields are stored sequentially in the file with no embedded markers identifying where in the colour field sequence the file begins (see [File Layout](#file-layout)). **No assumption must be made that the first field in a file is field 1 (or field I) of the colour sequence.** Capture sources (e.g., LaserDisc RF captures) may begin recording at any point in the colour field cycle, and the sequence may contain discontinuities caused by source media capture issues such as disc jumps, skipped fields, or dropouts.

Consumers must verify field ordering independently by examining the colour burst phase of each field and checking that consecutive fields exhibit the expected phase progression for the declared preset.

Preset-specific phase progression rules and the `ld-decode`/`vhs-decode` field ordering convention are in [video-standard-presets](video-standard-presets.md#field-ordering-and-phase-verification).

---

## Metadata Schema

The metadata file is **optional**. A CVBS file is self-contained as raw sample data and can be processed without a metadata file provided the consumer obtains the necessary parameters (such as video standard, field count, and colour sequence position) by other means — for example, from user-supplied command-line arguments or application settings.

When present, metadata is stored in a **separate `.meta` file** alongside the video data files.

- **Metadata:** `<basename>.meta`

The metadata file is a **SQLite database** containing the tables defined below.

### SQLite Metadata Schema

```sql
PRAGMA user_version = 4;

CREATE TABLE cvbs_file (
    cvbs_file_id                INTEGER PRIMARY KEY,
    preset                      TEXT    NOT NULL
        CHECK (preset IN ('NTSC', 'PAL', 'PAL_M')),
    sample_encoding_preset      TEXT    NOT NULL
        CHECK (sample_encoding_preset IN ('CVBS_10BIT', 'RAW_S16_28MSPS', 'RAW_S16_40MSPS')),
    signal_state_preset         TEXT    NOT NULL
        CHECK (signal_state_preset IN (
            'STANDARD_TBC_LOCKED',
            'STANDARD_TBC_UNLOCKED',
            'STANDARD_RAW',
            'NONSTANDARD_TBC_LOCKED',
            'NONSTANDARD_TBC_UNLOCKED',
            'NONSTANDARD_RAW'
        )),
    signal_type                 TEXT    NOT NULL
        CHECK (signal_type IN ('composite', 'yc')),
    decoder                     TEXT    NOT NULL,
    git_branch                  TEXT,
    git_commit                  TEXT,
    number_of_sequential_fields INTEGER
        CHECK (number_of_sequential_fields IS NULL OR number_of_sequential_fields >= 1),
    black_level                 INTEGER,
    has_ld_nonstandard_bursts   BOOLEAN,
    capture_notes               TEXT
);

CREATE TABLE field_record (
    cvbs_file_id    INTEGER NOT NULL,
    field_id        INTEGER NOT NULL,
    sync_conf       INTEGER NOT NULL,
    byte_offset     INTEGER,
    byte_count      INTEGER,
    PRIMARY KEY (cvbs_file_id, field_id),
    FOREIGN KEY (cvbs_file_id)
        REFERENCES cvbs_file(cvbs_file_id)
        ON DELETE CASCADE
);

CREATE TABLE sample_flags (
    cvbs_file_id    INTEGER NOT NULL,
    field_id        INTEGER NOT NULL,
    field_line      INTEGER NOT NULL,
    type            TEXT    NOT NULL
        CHECK (type IN ('dropout')),
    startx          INTEGER NOT NULL,
    endx            INTEGER NOT NULL,
    PRIMARY KEY (cvbs_file_id, field_id, field_line, startx, endx),
    FOREIGN KEY (cvbs_file_id, field_id)
        REFERENCES field_record(cvbs_file_id, field_id)
        ON DELETE CASCADE
);
```

### `cvbs_file` Table

The `cvbs_file` table records file-level metadata. There is one row per CVBS file.

#### `cvbs_file_id`

- **Type:** INTEGER, PRIMARY KEY
- **Nullable:** No
- **Description:** Unique identifier for the CVBS file record within this metadata database.

#### `preset`

- **Type:** TEXT
- **Nullable:** No
- **Range:** Any Video Standard Preset name defined in [video-standard-presets](video-standard-presets.md)
- **Description:** Identifies the Video Standard Preset that applies to this CVBS file. The preset name uniquely determines all timing and structural parameters — sampling rate, line counts, field structure, sample level tables, and colour field sequence length. Consumers must implement the named preset in full; an unrecognised preset name must not be silently interpreted.

#### `sample_encoding_preset`

- **Type:** TEXT
- **Nullable:** No
- **Range:** Any Sample Encoding Preset name defined in [sample-encoding-presets](sample-encoding-presets.md)
- **Description:** Identifies the Sample Encoding Preset that defines the physical word format and amplitude mapping of the sample data.

#### `signal_state_preset`

- **Type:** TEXT
- **Nullable:** No
- **Range:** Any Signal State Preset name defined in [signal-state-presets](signal-state-presets.md)
- **Description:** Identifies the Signal State Preset that describes the processing state of the signal at the time of storage — whether the sample rate is standard 4×fsc, whether TBC was applied, and whether burst locking was applied.

#### `signal_type`

- **Type:** TEXT
- **Nullable:** No
- **Range:** `'composite'`, `'yc'`
- **Description:** Declares whether the accompanying CVBS data file is a composite signal (`'composite'`, paired with a `.composite` file) or one file of a dual-file YC pair (`'yc'`, paired with a `.y` or `.c` file). This allows consumers to determine the project type explicitly without relying on file presence detection.

#### `decoder`

- **Type:** TEXT
- **Nullable:** No
- **Range:** `'ld-decode'`, `'vhs-decode'`, `'cvbs-encode'`, `'cvbs-decode'`, `'other'`
- **Description:** The tool that produced the CVBS file. Used to identify the software source and inform interpretation of any tool-specific behaviours.

#### `git_branch`

- **Type:** TEXT
- **Nullable:** Yes
- **Description:** The Git branch name of the decoder tool at the time of capture. `NULL` if not recorded.

#### `git_commit`

- **Type:** TEXT
- **Nullable:** Yes
- **Description:** The Git commit hash of the decoder tool at the time of capture. `NULL` if not recorded. Enables exact reproduction of the decoding conditions.

#### `number_of_sequential_fields`

- **Type:** INTEGER
- **Nullable:** Yes
- **Range:** ≥ 1, or `NULL`
- **Description:** The total number of fields stored in the accompanying CVBS data file(s), counted sequentially from the first to the last. This count includes all fields regardless of colour sequence position. `NULL` if the field count is not known at the time of writing — for example, when the file is produced by a raw sampling device that does not segment or count fields during capture. Consumers encountering a `NULL` value must determine the field count by parsing the file directly.

#### `black_level`

- **Type:** INTEGER
- **Nullable:** Yes
- **Range:** `NULL`, or an INTEGER value interpreted according to the declared presets
- **Description:** Optional override for non-standard black levels. `NULL` means no explicit override is provided and consumers should use the default black level behavior defined by the declared Video Standard Preset and Sample Encoding Preset (see [video-standard-presets](video-standard-presets.md) and [sample-encoding-presets](sample-encoding-presets.md)). A non-`NULL` value provides an explicit black-level override in the integer domain of the declared Sample Encoding Preset. For Sample Encoding Presets where black-level calibration is not defined or not meaningful (for example raw capture presets), this field should be `NULL`.

#### `has_ld_nonstandard_bursts`

- **Type:** BOOLEAN
- **Nullable:** Yes
- **Description:** Indicates the presence of LaserDisc-specific non-standard burst signals in the blanking interval. The meaning is preset-specific; see [video-standard-presets](video-standard-presets.md#non-standard-extensions) for details. `NULL` means not applicable or not known.

#### `capture_notes`

- **Type:** TEXT
- **Nullable:** Yes
- **Description:** Free-form human-readable notes about the capture. May include source material description, known non-compliance (e.g., LaserDisc PAL pilot bursts), equipment details, or other contextual information. `NULL` if no notes are recorded.

### `field_record` Table

The `field_record` table records per-field metadata. There is one row per field stored in the CVBS data file.

#### `cvbs_file_id`

- **Type:** INTEGER, FOREIGN KEY → `cvbs_file.cvbs_file_id`
- **Nullable:** No
- **Description:** References the parent `cvbs_file` record.

#### `field_id`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0 to `number_of_sequential_fields − 1`
- **Description:** Zero-based sequential index of this field within the CVBS data file. Field 0 is the first stored field.

#### `sync_conf`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0–100
- **Description:** Sync confidence for this field, expressed as a percentage (0 = no usable sync detected; 100 = perfect sync). Values below a decoder-defined threshold indicate unreliable sync and should be treated with caution by consumers.

#### `byte_offset`

- **Type:** INTEGER
- **Nullable:** Yes
- **Description:** Absolute byte offset of the start of this field's sample data within the CVBS data file. `NULL` when the Signal State Preset has `tbc_applied = TRUE` at the standard 4×fsc sample rate, as field boundaries can be derived from the normative size table and `field_id`. Should be populated when `tbc_applied = FALSE` or the sample rate is non-standard and the field boundaries are known. When both `byte_offset` and `byte_count` are `NULL` for a non-TBC'd file, the consumer must treat the file as an unsegmented stream.

#### `byte_count`

- **Type:** INTEGER
- **Nullable:** Yes
- **Description:** Byte length of this field's sample data in the CVBS data file. `NULL` under the same conditions as `byte_offset`. Must be non-null if and only if `byte_offset` is non-null.

### `sample_flags` Table

The `sample_flags` table records sample-level anomaly flags within individual fields. Each row identifies a contiguous horizontal run of flagged samples on a specific line of a specific field.

**Note:** `sample_flags` entries are only valid when the Signal State Preset has `tbc_applied = TRUE`. Without time-base correction, line lengths vary between fields and the field-line-relative sample index (`startx` / `endx`) is ambiguous as a physical position in the signal. When `tbc_applied = FALSE`, this table should be left empty.

#### `cvbs_file_id`

- **Type:** INTEGER, FOREIGN KEY → `cvbs_file.cvbs_file_id`
- **Nullable:** No
- **Description:** References the parent `cvbs_file` record.

#### `field_id`

- **Type:** INTEGER, FOREIGN KEY → `field_record.field_id`
- **Nullable:** No
- **Description:** References the field within which the flagged samples appear.

#### `field_line`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0 to (lines per field − 1)
- **Description:** Zero-based line index within the field on which the flagged samples occur.

#### `type`

- **Type:** TEXT
- **Nullable:** No
- **Range:** `'dropout'`
- **Description:** The class of anomaly affecting the flagged samples. Currently only `'dropout'` is defined, indicating a region where the source signal was lost or corrupted (e.g., due to tape damage or disc defect).

#### `startx`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** 0 to (samples per line − 1)
- **Description:** Zero-based sample index of the first flagged sample in the run. Sample 0 is the first sample of the CVBS field line.

#### `endx`

- **Type:** INTEGER
- **Nullable:** No
- **Range:** `startx` to (samples per line − 1)
- **Description:** Zero-based sample index of the last flagged sample in the run (inclusive). The flagged run covers samples `startx` through `endx` inclusive.

---

## Sample Encoding Presets

A **Sample Encoding Preset** defines the physical word format and amplitude mapping applied to every sample in the file: the integer width, signedness, byte order, and the relationship between stored values and analogue signal levels (sync tip, blanking, black, white, peak). The preset name is stored in the `sample_encoding_preset` field of the `cvbs_file` metadata table (see the [`cvbs_file` table](#cvbs_file-table)).

Full definitions: [sample-encoding-presets](sample-encoding-presets.md)

---

## Signal State Presets

A **Signal State Preset** defines the processing state of the signal at the time of storage along three independent axes: sample rate (standard 4×fsc vs. non-standard), TBC applied (yes vs. no), and burst locked (yes vs. no). The combination governs whether normative field sizes apply, whether signal level compliance is required, whether dropout coordinates are meaningful, and whether phase continuity can be assumed. The preset name is stored in the `signal_state_preset` field of the `cvbs_file` metadata table (see the [`cvbs_file` table](#cvbs_file-table)).

Full definitions: [signal-state-presets](signal-state-presets.md)

---

## Audio Data

Audio tracks are stored as separate **48 kHz Stereo PCM WAV** files (no other formats, sample rates or encoding are permitted). Up to 16 audio tracks are supported, each as a separate file.

Each file must be a standard **RIFF WAV** file with the following properties:

- **Container:** RIFF/WAVE with a standard RIFF header (`RIFF` chunk, `WAVE` format identifier, `fmt ` sub-chunk, `data` sub-chunk)
- **Format tag:** PCM (`0x0001`)
- **Channels:** 2 (stereo)
- **Sample rate:** 48000 Hz
- **Bit depth:** 16-bit signed integer, little-endian

No compression, no extended `fmt ` chunks, and no non-standard RIFF variants are permitted.

**File naming:** `<basename>_audio_<track_number>.wav`

Track number is zero-padded to two digits: `00`, `01`, `02`, …, `16`.

---

