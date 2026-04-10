# CVBS File Format Specification

---

## 1. Introduction

This document defines the **CVBS File Format** for use with the `ld-decode`, `vhs-decode` and related projects. **CVBS** (Colour, Video, Blank, and Sync) describes the full class of analogue video signal — both composite (luma and chroma combined into a single signal) and component YC representations carry the same Colour, Video, Blank, and Sync elements and are therefore both CVBS signals.

The format is organised around three independent **preset systems**, each of which captures a distinct dimension of the signal:

- **Video Standard Presets** (Section 4): define the timing and structural parameters of the video signal — line counts, field rates, horizontal sample structure, colour field sequence, and the normative sample level tables for standards-compliant signals. Current presets: `PAL`, `NTSC`, `PAL_M`.
- **Sample Encoding Presets** (Section 6): define the bit depth, word format, and amplitude mapping used when the sample data was recorded. Current presets: `CVBS_10BIT` (the standard encoding derived from EBU 3280 / SMPTE ST.0244), `RAW_S16_28MSPS`, `RAW_S16_40MSPS`.
- **Signal State Presets** (Section 7): define the processing state of the signal at the time of storage — whether a standard 4×fsc sample rate was used, whether time-base correction (TBC) was applied, and whether the decoder was phase-locked to the colour burst. Current presets: `STANDARD_TBC_LOCKED`, `STANDARD_TBC_UNLOCKED`, `STANDARD_RAW`, `NONSTANDARD_TBC_LOCKED`, `NONSTANDARD_TBC_UNLOCKED`, `NONSTANDARD_RAW`.

Every CVBS file is described by one preset from each system. Together they fully specify how to locate field boundaries, interpret sample amplitudes, and determine the reliability of phase and level measurements.

The format accommodates **non-standard cases** (e.g., LaserDisc PAL pilot bursts) through metadata flags rather than structural changes.

---

## 2. File Naming Convention

Each file type uses a distinct extension:

- **Composite CVBS:** `<basename>.composite`
- **Dual-File YC CVBS (Luma):** `<basename>.y`
- **Dual-File YC CVBS (Chroma):** `<basename>.c`

---

## 3. Video Data Format

### 3.1. Sample Encoding

The physical encoding and amplitude mapping of samples are defined by the **Sample Encoding Preset** declared for the file (see Section 6). The main properties governed by the sample encoding preset are:

- **Word format:** the integer width, signedness, and byte order of each stored sample word.
- **Amplitude mapping:** the relationship between the stored integer value and the analogue signal amplitude — specifically, where sync tip, blanking, black, white, and peak levels fall within the integer range.
- **Headroom:** whether negative or positive values beyond the nominal 0–1023 range are meaningful.

The two standard encoding presets (`CVBS_10BIT` for both EBU 3280 and SMPTE ST.0244 sources, defined in Section 6.1) represent the normative production output of `ld-decode`, `vhs-decode`, and similar tools. The raw capture presets (`RAW_S16_28MSPS`, `RAW_S16_40MSPS`, defined in Sections 6.2 and 6.3) represent unscaled ADC output from hardware capturers such as the DomesdayDuplicator.

Both representations are CVBS (Colour, Video, Blank, and Sync) signals; they differ only in how colour information is carried:

- **Composite CVBS:** Single file containing luma and chroma combined into one signal.
- **Dual-File YC CVBS:** Separate files for luma (Y) and chroma (C), keeping the colour components separated.

The specific sample range — sync tip, blanking, black, white, and peak levels together with any reserved protected values — is defined by the declared Sample Encoding Preset (see Section 6). When the Signal State Preset (see Section 7) has `tbc_applied = TRUE`, the sample data **must comply** with the amplitude mapping defined by the Sample Encoding Preset. **Exceptions** (e.g., LaserDisc PAL pilot bursts, signalled by `has_ld_nonstandard_bursts = TRUE` in the metadata) are allowed but **must be noted in the metadata**. When `tbc_applied = FALSE`, the preset's sample range is informational only; raw or non-TBC'd data is not required to conform to it.

### 3.2. File Layout

Video data is stored field-by-field with no additional framing or headers:

```
[Field 1 Video Data: N bytes]
[Field 2 Video Data: N bytes]
...
```

---

## 4. Video Standard Presets

### 4.1. Preset System

A **Video Standard Preset** is a named configuration that fully defines all timing and structural parameters for a video standard. Video Standard Presets encapsulate everything that is intrinsic to a given standard: sampling rate, line counts, field structure, sample level tables, colour field sequence length, and references to the external standards on which the preset is based. These presets do **not** define the physical sample word format or the processing state of the signal — those are covered by the Sample Encoding Preset (Section 6) and Signal State Preset (Section 7) respectively.

**Naming convention:** Preset names follow the pattern `PRIMARY` or `PRIMARY_SUBSET`, where `PRIMARY` identifies the base standard and `SUBSET` (when present) identifies a regional or technical variant. The underscore `_` separates the primary designator from the subset. Preset names use only uppercase ASCII letters, digits, and underscores; each name defined in this specification is unique.

Examples:
- `PAL` — the primary PAL standard
- `NTSC` — the primary NTSC standard
- `PAL_M` — a PAL-family variant using NTSC 525-line/60 Hz timing with PAL colour subcarrier modulation

The `preset` field in the `cvbs_file` metadata table (see Section 5.2) identifies which Video Standard Preset applies to a given CVBS file. Consumers must implement a preset in full to correctly process files that use it; an unrecognised preset name must not be silently interpreted — the consumer must refuse to process the file or report an error.

Video Standard Presets defined in this specification: `PAL`, `NTSC`, `PAL_M`. Additional presets may be defined in future revisions or companion documents; the naming convention ensures that each new preset has a unique, unambiguous identifier.

### 4.2. Preset Definitions

Full preset definitions are maintained in a separate document: [video-standard-presets.md](video-standard-presets.md).

#### 4.2.1. Preset: `PAL` — [see video-standard-presets.md](video-standard-presets.md#preset-pal)

*(See [video-standard-presets.md](video-standard-presets.md#preset-pal) for the full PAL definition.)*

#### 4.2.2. Preset: `NTSC` — [see video-standard-presets.md](video-standard-presets.md#preset-ntsc)

*(See [video-standard-presets.md](video-standard-presets.md#preset-ntsc) for the full NTSC definition.)*

#### 4.2.3. Preset: `PAL_M` — [see video-standard-presets.md](video-standard-presets.md#preset-pal_m)

*(See [video-standard-presets.md](video-standard-presets.md#preset-pal_m) for the full PAL-M definition.)*

### 4.3. Non-Standard Extensions

- **LaserDisc PAL Pilot Bursts:** Allowed to exceed standard blanking levels.
- **DC Offset:** Not required. The signed 16-bit storage format provides sufficient negative headroom below 0 to accommodate chroma excursions without clipping.

### 4.4. Field Ordering and Phase Verification

Fields are stored sequentially in the file with no embedded markers identifying where in the colour field sequence the file begins (see Section 3.2). **No assumption must be made that the first field in a file is field 1 (or field I) of the colour sequence.** Capture sources (e.g., LaserDisc RF captures) may begin recording at any point in the colour field cycle, and the sequence may contain discontinuities caused by disc jumps, skipped fields, or dropouts.

Consumers of CVBS files must verify field ordering independently by examining the colour burst phase of each field and checking that consecutive fields exhibit the expected phase progression for the declared preset.

**PAL — 8-field sequence (EBU tech3280 §1.1.1):**

> *(Informational — EBU tech3280 §1.1.1 and Fig. 1):* At 0° Sc/H (the normative PAL sampling phase), the +U axis of the subcarrier is at zero phase relative to the horizontal timing reference point (0H) on line 1 of field 1 (EBU 1-indexed; field line 0 of field 1 in this specification's 0-indexed convention). The colour burst phase rotates through a known pattern over the 8-field cycle. Any break in the expected Sc/H phase progression between consecutive stored fields indicates a discontinuity in the colour field sequence.

**NTSC — 4-field colour frame sequence (SMPTE ST.0244 §4.1.2):**

> *(Informational — SMPTE ST.0244 §3.2, §4.1.2):* At 0° SC/H (the normative NTSC sampling phase), sample 0 of line 10, field I, colour frame A is an I-axis (+123°) sample (SMPTE 1-indexed frame line 10 = field line 9 of field I in this specification's 0-indexed convention). Each of the 4 fields in the colour frame cycle has a unique SC/H relationship; comparing the measured burst phase at sample 0 against the expected value identifies the field's position in the 4-field sequence. A phase discontinuity between consecutive fields indicates a colour frame sequence break.

A conformant CVBS file may be accompanied by a metadata file (see Section 5) that records the colour field sequence identity of the first stored field, enabling consumers to verify phase continuity from a known starting point rather than having to infer it. Where no metadata file is present, the consumer must obtain this information from user-supplied processing parameters.

> *(Informational — ld-decode/vhs-decode field ordering convention):* The current implementations of the `ld-decode` and `vhs-decode` decoders identify each decoded field with an `isFirstField` boolean that is determined from the VSYNC sync-pulse timing structure. The two systems resolve differently:
>
> | System | `isFirstField = true` | EBU/SMPTE field | Spatial position | Line count |
> |--------|----------------------|-----------------|------------------|------------|
> | NTSC   | 1H gap before VSYNC  | SMPTE Field I   | Odd / upper      | 263        |
> | PAL    | 0.5H gap before VSYNC | EBU Field 2    | Even / lower     | 312        |
>
> For **NTSC**, `isFirstField = true` corresponds to SMPTE Field I (the odd/upper field, 263 lines). For **PAL**, `isFirstField = true` corresponds to EBU Field 2 (the even/lower field, 312 lines) — because it is EBU Field 2 that leads into its VSYNC interval with a half-line (0.5H) period, not Field 1. This means that in `ld-decode` output, a PAL TBC file conventionally starts with the even analogue field, while an NTSC TBC file starts with the odd analogue field. The C++ metadata library exposes a separate `isFirstFieldFirst` flag that records whether the first sequential field in the file carries `isFirstField = true`; this will normally be `true` for well-formed ld-decode output. Consumers processing ld-decode or vhs-decode CVBS files must account for this asymmetry when reconstructing interlaced frames or verifying the 8-field (PAL) or 4-field (NTSC) colour sequence.

---

## 5. Metadata Schema

The metadata file is **optional**. A CVBS file is self-contained as raw sample data and can be processed without a metadata file provided the consumer obtains the necessary parameters (such as video standard, field count, and colour sequence position) by other means — for example, from user-supplied command-line arguments or application settings.

When present, metadata is stored in a **separate `.meta` file** alongside the video data files.

- **Metadata:** `<basename>.meta`

The metadata file is a **SQLite database** containing the tables defined below.

### 5.1. SQLite Metadata Schema

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
    sample_rate_numerator       INTEGER
        CHECK ((sample_rate_numerator IS NULL) = (sample_rate_denominator IS NULL)),
    sample_rate_denominator     INTEGER,
    decoder                     TEXT    NOT NULL,
    decoder_name                TEXT,
    git_branch                  TEXT,
    git_commit                  TEXT,
    number_of_sequential_fields INTEGER NOT NULL,
    sc_h_phase_degrees          REAL,
    black_level                 INTEGER
        CHECK (black_level IS NULL OR black_level BETWEEN 0 AND 1023),
    first_field_sequence_number INTEGER
        CHECK (first_field_sequence_number IS NULL OR
               (preset = 'PAL'   AND first_field_sequence_number BETWEEN 1 AND 8) OR
               (preset = 'NTSC'  AND first_field_sequence_number BETWEEN 1 AND 4) OR
               (preset = 'PAL_M' AND first_field_sequence_number BETWEEN 1 AND 8)),
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

### 5.2. `cvbs_file` Table

The `cvbs_file` table records file-level metadata. There is one row per CVBS file.

#### `cvbs_file_id`

- **Type:** INTEGER, PRIMARY KEY
- **Nullable:** No
- **Description:** Unique identifier for the CVBS file record within this metadata database.

#### `preset`

- **Type:** TEXT
- **Nullable:** No
- **Range:** Any Video Standard Preset name defined in Section 4.2; currently `'PAL'`, `'NTSC'`, `'PAL_M'`
- **Description:** Identifies the Video Standard Preset that applies to this CVBS file. The preset name uniquely determines all timing and structural parameters — sampling rate, line counts, field structure, sample level tables, and colour field sequence length — as specified in Section 4.2. Consumers must implement the named preset in full; an unrecognised preset name must not be silently interpreted.

#### `sample_encoding_preset`

- **Type:** TEXT
- **Nullable:** No
- **Range:** Any Sample Encoding Preset name defined in Section 6; currently `'CVBS_10BIT'`, `'RAW_S16_28MSPS'`, `'RAW_S16_40MSPS'`
- **Description:** Identifies the Sample Encoding Preset that defines the physical word format and amplitude mapping of the sample data. See Section 6 for full definitions.

#### `signal_state_preset`

- **Type:** TEXT
- **Nullable:** No
- **Range:** Any Signal State Preset name defined in Section 7; currently `'STANDARD_TBC_LOCKED'`, `'STANDARD_TBC_UNLOCKED'`, `'STANDARD_RAW'`, `'NONSTANDARD_TBC_LOCKED'`, `'NONSTANDARD_TBC_UNLOCKED'`, `'NONSTANDARD_RAW'`
- **Description:** Identifies the Signal State Preset that describes the processing state of the signal at the time of storage. The Signal State Preset encodes whether the sample rate is the standard 4×fsc for the declared Video Standard Preset, whether TBC was applied, and whether burst locking was applied. See Section 7 for full definitions.

#### `signal_type`

- **Type:** TEXT
- **Nullable:** No
- **Range:** `'composite'`, `'yc'`
- **Description:** Declares whether the accompanying CVBS data file is a composite signal (`'composite'`, paired with a `.composite` file) or one file of a dual-file YC pair (`'yc'`, paired with a `.y` or `.c` file). This allows consumers to determine the project type explicitly without relying on file presence detection.

#### `sample_rate_numerator` / `sample_rate_denominator`

- **Type:** INTEGER
- **Nullable:** Yes (both must be non-null together, or both null)
- **Description:** Exact rational sample rate in Hz, expressed as `sample_rate_numerator / sample_rate_denominator`. `NULL` / `NULL` (the default) indicates the standard 4×fsc rate for the declared `preset` applies; no explicit rate need be stored for standard-compliant files. A non-null pair records the exact rate for oversampled or otherwise non-standard captures — for example, 40,000,000 / 1 for a DomesdayDuplicator capture. When `signal_state_preset` is one of the `NONSTANDARD_*` variants, this field should be populated. A CHECK constraint enforces that the two columns are null together or non-null together.

#### `decoder`

- **Type:** TEXT
- **Nullable:** No
- **Range:** `'ld-decode'`, `'vhs-decode'`, `'cvbs-encode'`, `'cvbs-decode'`, `'other'`
- **Description:** The tool that produced the CVBS file. For tools not in the known list, set `decoder` to `'other'` and record the tool name in `decoder_name`. Used to identify the software source and inform interpretation of any tool-specific behaviours.

#### `decoder_name`

- **Type:** TEXT
- **Nullable:** Yes
- **Description:** Human-readable name of the producing tool when `decoder = 'other'` (e.g. `'domesday-duplicator'`, `'cx-decode'`). `NULL` when `decoder` is one of the known standard values.

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
- **Nullable:** No
- **Range:** ≥ 1
- **Description:** The total number of fields stored in the accompanying CVBS data file(s), counted sequentially from the first to the last. This count includes all fields regardless of colour sequence position.

#### `sc_h_phase_degrees`

- **Type:** REAL
- **Nullable:** Yes
- **Description:** The subcarrier-to-horizontal (Sc/H) phase at sample 0 of the first stored field, in degrees. `NULL` if the phase is unknown or if the Signal State Preset has `burst_locked = FALSE`. When known, this value allows consumers to phase-align multiple independent captures or to verify that the file begins at the canonical Sc/H reference phase defined by EBU 3280 or SMPTE ST.0244. This value is informational and does not alter the normative field or sample layout.

#### `black_level`

- **Type:** INTEGER
- **Nullable:** Yes
- **Range:** 0–1023 (10-bit sample value), or `NULL`
- **Description:** Override for non-standard black levels within the `CVBS_10BIT` encoding. `NULL` means use the standard black level defined by the declared Video Standard Preset (PAL: 282; NTSC/PAL-M: 252). A non-`NULL` value specifies the nominal picture black level as a 10-bit sample value. For example, NTSC-J uses a black level of 240 instead of the standard 252. This field is not meaningful for raw capture Sample Encoding Presets (`RAW_S16_28MSPS`, `RAW_S16_40MSPS`), where amplitude calibration must be performed by the consumer.

#### `first_field_sequence_number`

- **Type:** INTEGER
- **Nullable:** Yes
- **Range:** 1–8 for `'PAL'` and `'PAL_M'`; 1–4 for `'NTSC'`; or `NULL`
- **Description:** The position within the colour field cycle of the first field stored in the file. The valid range is determined by the colour field sequence length of the declared Video Standard Preset (see Section 4.2): 1–8 for `'PAL'` and `'PAL_M'`; 1–4 for `'NTSC'`. `NULL` if the colour sequence position of the first field is unknown. Consumers should use this value to verify colour burst phase continuity from a known starting point (see Section 4.4).

#### `has_ld_nonstandard_bursts`

- **Type:** BOOLEAN
- **Nullable:** Yes
- **Description:** Indicates the presence of LaserDisc-specific non-standard burst signals in the blanking interval. The meaning is determined by the declared `preset`: when `preset = 'PAL'` and `has_ld_nonstandard_bursts = TRUE`, the file contains PAL pilot bursts as defined by IEC 60856-1986; when `preset = 'NTSC'` and `has_ld_nonstandard_bursts = TRUE`, the file contains additional colour bursts as defined by IEC 60857-1986. When `TRUE`, consumers must not treat blanking-region samples that fall outside the standard protected range as errors. `NULL` means not applicable or not known.

#### `capture_notes`

- **Type:** TEXT
- **Nullable:** Yes
- **Description:** Free-form human-readable notes about the capture. May include source material description, known non-compliance (e.g., LaserDisc PAL pilot bursts), equipment details, or other contextual information. `NULL` if no notes are recorded.

### 5.3. `field_record` Table

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

### 5.4. `sample_flags` Table

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

## 6. Sample Encoding Presets

A **Sample Encoding Preset** defines the physical word format and amplitude mapping applied to every sample in the file. It specifies the integer width, signedness, byte order, and the relationship between stored values and analogue signal levels (sync tip, blanking, black, white, peak). The preset name is stored in the `sample_encoding_preset` field of the `cvbs_file` metadata table (see Section 5.2).

**Naming convention:** Sample Encoding Preset names use only uppercase ASCII letters, digits, and underscores. Names derived from a broadcast standard use the format `CVBS_<ENCODING>`; names for raw hardware captures use the format `RAW_<FORMAT>_<RATE>`.

Sample Encoding Presets defined in this specification: `CVBS_10BIT`, `RAW_S16_28MSPS`, `RAW_S16_40MSPS`.

Full preset definitions are maintained in a separate document: [sample-encoding-presets.md](sample-encoding-presets.md).

---

## 7. Signal State Presets

A **Signal State Preset** defines the processing state of the signal at the time of storage along three independent axes:

| Axis | Standard state | Non-standard state |
|---|---|---|
| Sample rate | Exactly 4×fsc for the declared Video Standard Preset | Non-standard (e.g., oversampled at 28.6 MHz or 40 MHz) |
| TBC applied | Yes — fixed samples per line, stable timing | No — line lengths vary, timing is raw |
| Burst locked | Yes — subcarrier phase is stable and known | No — subcarrier phase drifts or is unknown |

These axes are independent. In particular, a file can be TBC'd but not burst-locked (e.g., standard NTSC `.tbc` output from `ld-decode` or `vhs-decode`: timing is corrected but the subcarrier phase at each field is not anchored to a canonical 0° reference), and a file at a non-standard sample rate can still have TBC applied (oversampled TBC output).

The Signal State Preset is stored in the `signal_state_preset` field of the `cvbs_file` metadata table (see Section 5.2) and governs several aspects of format interpretation:

- **Normative field sizes** (Section 4.2) apply only when `tbc_applied = TRUE` and the sample rate is the standard 4×fsc. Without TBC there is no guarantee of a fixed sample count per line; consumers must use `byte_offset` / `byte_count` from `field_record` instead.
- **Signal level compliance** (Section 3.1) is only meaningful when `tbc_applied = TRUE` and the Sample Encoding Preset is `CVBS_10BIT`. A raw RF capture contains signal levels that bear no relation to the preset's reference sample values.
- **Dropout coordinates** (`sample_flags.startx` / `endx`) reference a sample index within a field line. This coordinate system is only stable when lines have a fixed, known length, i.e., when TBC has been applied.
- **Subcarrier phase analysis** (Section 4.4) requires knowing whether burst locking was applied so that consumers can determine whether phase continuity can be assumed between fields.

**Naming convention:** Signal State Preset names follow the pattern `<RATE>_<TBC>_<LOCK>`, where `<RATE>` is `STANDARD` (4×fsc) or `NONSTANDARD`, `<TBC>` is `TBC` or `RAW`, and `<LOCK>` is `LOCKED` or `UNLOCKED`. The `RAW` state implies unlocked (a raw signal with no TBC cannot be burst-locked in a stable sense), so `<RATE>_RAW` presets do not include a `_LOCKED` / `_UNLOCKED` suffix.

Signal State Presets defined in this specification: `STANDARD_TBC_LOCKED`, `STANDARD_TBC_UNLOCKED`, `STANDARD_RAW`, `NONSTANDARD_TBC_LOCKED`, `NONSTANDARD_TBC_UNLOCKED`, `NONSTANDARD_RAW`.

Full preset definitions are maintained in a separate document: [signal-state-presets.md](signal-state-presets.md).

---

## 8. Audio Data

Audio tracks are stored as separate **48 kHz Stereo PCM WAV** files. Up to 16 audio tracks are supported, each as a separate file.

**File naming:** `<basename>_audio_<track_number>.wav`

Track number is zero-padded to two digits: `00`, `01`, `02`, …, `16`.

---

## 9. Open Questions and Items Under Discussion

1. **Additional video standard presets:** Are additional Video Standard Presets required? Candidates include SECAM, PAL-N, and PAL-B/G variants. The naming convention (`PRIMARY_SUBSET`) accommodates these without structural changes.

2. **Compression:** A lossless compression option has been proposed for video and audio data:
   - **Video:** FLAC, gzip, or zstd applied to `.composite`, `.y`, `.c` files; compressed files use the `.gz` suffix (e.g., `<basename>.composite.gz`). Compression applied per-field to allow random access.
   - **Audio:** FLAC for `.wav` files; compressed files use the `.flac` suffix.
   - Should compression be mandatory, optional, or user-selectable? (Current preference: user-selectable.)
   - Should the format support chunked compression for streaming or partial access? (Current preference: yes.)
   - Should a `compression` field be added to the metadata schema to record the method used?
   - Are there preferred algorithms for specific use cases (archival vs. editing)?

3. **Reference tools and test vectors:** No reference tools exist yet. Test vector files for PAL, NTSC, and PAL-M with known metadata are desired to validate conformance.

4. **Additional sample encoding presets:** Are further raw capture presets needed (e.g., for 8-bit ADC output, or for specific hardware capturers with known gain/offset calibrations that would allow a defined amplitude mapping)?

5. **Additional signal state presets:** The current six presets cover the most practically important combinations. Are there additional combinations required? For example, a `STANDARD_RAW_LOCKED` state (standard rate, no TBC, but burst is locked) is theoretically possible; is it encountered in practice?

6. **`tbc_applied` / `burst_locked` as explicit boolean columns:** The current design encodes these properties inside the Signal State Preset name. An alternative is to retain them as explicit boolean columns in the metadata schema alongside the preset name, for ease of querying. Under discussion.

7. **Audio track count:** The maximum of 16 audio tracks is a provisional limit. Is this sufficient for all anticipated sources?
