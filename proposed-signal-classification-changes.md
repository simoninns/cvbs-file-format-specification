# Proposed Changes: Signal Classification and Non-Standard Capture Support

## Overview

The current specification assumes all CVBS files are fully compliant with EBU 3280 (PAL) or
ST.0244 (NTSC/PAL-M): sampled at exactly 4×fsc, with a correctly applied time-base correction
(TBC), and optionally phase-locked to the colour burst. In practice there are several legitimate
and commonly occurring signal types that do not satisfy all of these conditions. The format and
its metadata schema must be able to represent all of them unambiguously.

---

## 1. Signal Classification

### 1.1. The Three Axes of Variation

A CVBS file can vary along three independent axes:

| Axis | Compliant state | Non-compliant state |
|---|---|---|
| Sample rate | Exactly 4×fsc for the declared system | Non-standard (e.g. oversampled at 40 MHz) |
| TBC applied | Yes — fixed samples per line, stable timing | No — line lengths vary, timing is raw |
| Burst locked | Yes — subcarrier phase is stable and known | No — subcarrier phase drifts or is unknown |

These axes are not all dependent on each other. In particular:

- A file can be TBC'd but not burst-locked (e.g. standard NTSC `.tbc` output from ld-decode or
  vhs-decode: timing is corrected, but the subcarrier phase at each field is not anchored to a
  canonical 0° reference).
- A file can be burst-locked but not TBC'd (unusual, but possible: an ADC whose clock is locked
  to the capture system's subcarrier reference, sampling a raw, un-TBC'd signal).
- A file at a non-standard sample rate can still have TBC applied (oversampled TBC output).
- A file at a non-standard sample rate will generally not have TBC applied (raw oversampled
  capture from hardware such as the DomesdayDuplicator).

The four most practically important cases are:

| Case | `tbc_applied` | `burst_locked` | Typical source |
|---|---|---|---|
| Fully compliant | TRUE | TRUE | cvbs-encode synthetic output; broadcast-grade capture |
| TBC'd, not burst-locked | TRUE | FALSE | ld-decode / vhs-decode NTSC `.tbc` output |
| TBC'd, burst-locked | TRUE | TRUE | ld-decode / vhs-decode PAL `.tbc` output (if Sc/H locked) |
| Raw / non-TBC'd | FALSE | FALSE | DomesdayDuplicator raw RF capture; raw ADC output |

### 1.2. Why this Matters for the Specification

Different signal types require different handling by consumers:

- **Normative field sizes** (Section 4.1) are only valid when `tbc_applied = TRUE` and the sample
  rate is the standard 4×fsc. Without TBC there is no guarantee of a fixed sample count per line,
  so consumers need explicit byte-level field boundaries instead.
- **Signal level compliance** (Section 3.1) is only meaningful for TBC'd data. A raw RF capture
  contains FM-encoded or otherwise non-standard signal levels that bear no relation to the EBU /
  SMPTE 10-bit level tables.
- **Dropout coordinates** (`sample_flags.startx` / `endx`) reference a sample index within a
  field line. This coordinate system is only stable when lines have a fixed, known length — i.e.
  when TBC has been applied.
- **Subcarrier phase analysis** (Section 4.3) requires knowing whether burst locking was applied
  so that consumers can determine whether phase continuity can be assumed between fields.

---

## 2. Proposed Metadata Changes

### 2.1. New field: `tbc_applied BOOLEAN NOT NULL`

**Cause:** The existing `burst_locked` field records one dimension of signal quality but says
nothing about whether time-base correction has been applied. These are independent properties and
both are necessary to correctly classify the signal.

**Solution:** Add `tbc_applied` as a mandatory boolean to `cvbs_file`. This single flag
unlocks or constrains many other aspects of the spec:

- When `TRUE`: normative field sizes apply (provided also at standard sample rate); signal level
  compliance is expected; `sample_flags` coordinates are meaningful.
- When `FALSE`: normative field sizes do not apply; field boundaries must be given explicitly via
  `byte_offset` / `byte_count` in `field_record`; signal level compliance cannot be assumed;
  `sample_flags` should not be used.

The existing `burst_locked` field is retained unchanged. Together the two fields fully describe
the timing and phase properties of the signal.

### 2.2. New fields: `sample_rate_numerator INTEGER` / `sample_rate_denominator INTEGER` (nullable)

**Cause:** The sample rate is currently implicit — entirely inferred from `system`. This works
when all data is at the standard 4×fsc rate, but fails for oversampled captures. The
DomesdayDuplicator, for example, captures at approximately 40 MHz; cx-decode and other tools
may output at other rates. There is no way to record this in the current schema.

**Solution:** Add an optional exact rational sample rate to `cvbs_file`. Using a numerator /
denominator integer pair avoids the precision loss of a floating-point column, which matters for
rates such as NTSC's 14,318,181.8̄ Hz:

- `NULL` / `NULL`: standard 4×fsc for the declared `system` (backwards-compatible default;
  no change required for existing compliant files).
- Non-null pair: explicit sample rate in Hz, e.g. 40,000,000 / 1; or the exact NTSC rate as
  14,318,182 / 1 (or a more precise rational if known).

The two columns should be constrained as a pair: both must be non-null together or both null.

### 2.3. New fields: `byte_offset INTEGER` / `byte_count INTEGER` in `field_record` (nullable)

**Cause:** Section 4.1 defines exact, normative field sizes for all standards. These values are
only valid under TBC + standard 4×fsc conditions. For non-TBC'd data, line lengths vary — that
is precisely the problem TBC solves — so there is no fixed field size and a consumer cannot
locate field N in the file without an index. Similarly, at a non-standard sample rate the field
sizes change proportionally and cannot be looked up from a static table.

**Solution:** Add `byte_offset` and `byte_count` to `field_record`. This provides a general-
purpose field index:

- When `tbc_applied = TRUE` at the standard sample rate these columns may be omitted (`NULL`);
  a consumer can derive the field boundaries from the normative table and the `field_id`.
- When `tbc_applied = FALSE` **or** the sample rate is non-standard, these columns are mandatory.
  A consumer that finds them `NULL` in a non-standard file should treat the file as malformed.

This design is backwards-compatible: existing compliant files need not populate these columns.

### 2.4. New field: `sc_h_phase_degrees REAL` (nullable)

**Cause:** `burst_locked` is a boolean: it says *whether* the subcarrier phase is stable, but
not *what* the phase is. For files where burst locking was applied and the Sc/H phase at the
start of the file is known (for example, locked to 0° per the normative EBU or SMPTE reference),
this value is useful to consumers that need to phase-align multiple independent captures, or to
verify that a file begins at the canonical reference phase.

**Solution:** Add an optional `sc_h_phase_degrees REAL` to `cvbs_file`, recording the
subcarrier-to-horizontal phase at sample 0 of the first stored field, in degrees. `NULL` means
the phase is either unknown or not burst-locked. The value is informational and does not alter
the normative field or sample layout.

### 2.5. New field: `has_ld_nonstandard_bursts BOOLEAN` (nullable)

**Background:** Both LaserDisc PAL and LaserDisc NTSC define additional burst signals in the
blanking interval that are absent from standard broadcast CVBS and exceed the protected sample
ranges defined by EBU 3280 and ST.0244:

- **PAL LaserDisc — pilot burst** (IEC 60856-1986, *Laservision PAL*): a burst inserted at the
  start of each line in the vertical blanking interval (and on some active lines) at a fixed
  frequency used for disc-to-player synchronisation. Its amplitude can extend below the sync-tip
  protected range.
- **NTSC LaserDisc — additional colour bursts** (IEC 60857-1986, *Laservision NTSC*): extra
  colour burst insertions in the vertical blanking interval beyond what ST.0244 defines, used
  for similar synchronisation purposes.

These are distinct features defined by different IEC standards, but both manifest the same way
in a decoded CVBS file: samples in the blanking region that fall outside the standard protected
range and must not be treated as errors or dropouts.

**Cause:** This LaserDisc-specific non-compliance is currently handled entirely through the free-
text `capture_notes` field, which is unreliable for automated processing.

**Solution:** Add a dedicated `has_ld_nonstandard_bursts BOOLEAN` to `cvbs_file`. The field is
system-neutral: its meaning is determined by the `system` value already recorded in the same
row:

- When `system = 'PAL'` and `has_ld_nonstandard_bursts = TRUE`: the file contains PAL pilot
  bursts as defined by IEC 60856-1986.
- When `system = 'NTSC'` and `has_ld_nonstandard_bursts = TRUE`: the file contains NTSC
  additional colour bursts as defined by IEC 60857-1986.

When `TRUE`, consumers know that samples in the blanking region may exceed the standard
protected range and must not be treated as errors. The `capture_notes` field remains available
for additional free-text description. The flag is nullable (`NULL` = not applicable or not
known) so that it does not impose an obligation on non-LaserDisc sources.

---

## 3. Related Specification Issues

### 3.1. The `decoder` Enum is Too Narrow

**Cause:** The current `decoder` CHECK constraint accepts only `'ld-decode'`, `'vhs-decode'`,
`'cvbs-encode'`, `'cvbs-decode'`. A raw non-TBC'd capture from a DomesdayDuplicator, or output
from cx-decode or other community tools, has no valid value to record. This will become
increasingly problematic as the ecosystem grows.

**Options:**
1. Widen the enum to add `'domeday-duplicator'`, `'cx-decode'`, etc. as new values are needed —
   requires a schema migration each time a new tool is added.
2. Replace the enum with a free-text `decoder TEXT NOT NULL` column and add a separate
   `decoder_version TEXT` column — more flexible but loses database-enforced validation.
3. Keep the enum for "standard" tools and add an `'other'` value with a companion free-text
   `decoder_name TEXT` column for unlisted tools.

Option 3 is the most pragmatic: it preserves validation for known tools, accommodates new tools
without schema changes, and retains machine-readable identity for the common cases.

### 3.2. Signal Level Compliance Conditioned on TBC

**Cause:** Section 3.1 currently states that "10-bit data must comply with EBU 3280 (PAL) or
ST.0244 (NTSC, PAL-M)", with exceptions noted in metadata. For a raw capture at 40 MHz of a
LaserDisc FM signal, the sample values have no meaningful relationship to those level tables at
all. Treating compliance as a universal obligation misrepresents what the data is.

**Solution:** Add a qualifying clause to Section 3.1 conditioning the compliance requirement on
`tbc_applied = TRUE`. Non-TBC'd data is not required to conform to level tables; the tables are
informational for such files and describe the expected levels once TBC and decoding have been
applied.

### 3.3. `sample_flags` Coordinate System Requires TBC

**Cause:** Section 5.4 defines `startx` and `endx` as "zero-based sample index within the field
line". This coordinate is only meaningful when line lengths are fixed and identical across all
fields — a property guaranteed only by TBC. Without TBC the length of line N in field M may
differ from line N in field M+1, making a field-line-relative sample index ambiguous as a
physical position in the signal.

**Solution:** Add a note to Section 5.4 (and the `sample_flags` table description) stating that
`sample_flags` entries are only valid when `tbc_applied = TRUE`. When `tbc_applied = FALSE`,
the table should be left empty; per-sample flagging of raw non-TBC'd data is outside the scope
of this format version.

---

## 4. Proposed SQL Schema Changes

The additions below are additive and backwards-compatible with the existing schema (schema version
bumped from 2 to 3).

```sql
PRAGMA user_version = 3;

CREATE TABLE cvbs_file (
    cvbs_file_id                INTEGER PRIMARY KEY,
    system                      TEXT    NOT NULL
        CHECK (system IN ('NTSC', 'PAL', 'PAL_M')),
    signal_type                 TEXT    NOT NULL
        CHECK (signal_type IN ('composite', 'yc')),
    -- NEW: was the signal time-base corrected before storage?
    tbc_applied                 BOOLEAN NOT NULL,
    -- NEW: rational sample rate; NULL/NULL = standard 4xfsc for declared system
    sample_rate_numerator       INTEGER
        CHECK ((sample_rate_numerator IS NULL) = (sample_rate_denominator IS NULL)),
    sample_rate_denominator     INTEGER,
    decoder                     TEXT    NOT NULL,
    -- NEW: free-text name for tools not in the known-tool list
    decoder_name                TEXT,
    git_branch                  TEXT,
    git_commit                  TEXT,
    number_of_sequential_fields INTEGER NOT NULL,
    burst_locked                BOOLEAN NOT NULL,
    -- NEW: Sc/H phase at sample 0 of the first field, in degrees; NULL if unknown
    sc_h_phase_degrees          REAL,
    black_level                 INTEGER
        CHECK (black_level IS NULL OR black_level BETWEEN 0 AND 1023),
    first_field_sequence_number INTEGER
        CHECK (first_field_sequence_number IS NULL OR
               (system = 'PAL'   AND first_field_sequence_number BETWEEN 1 AND 8) OR
               (system = 'NTSC'  AND first_field_sequence_number BETWEEN 1 AND 4) OR
               (system = 'PAL_M' AND first_field_sequence_number BETWEEN 1 AND 8)),
    -- NEW: LaserDisc non-standard burst flag;
    --      PAL: pilot burst per IEC 60856-1986; NTSC: additional colour bursts per IEC 60857-1986
    --      TRUE = expect out-of-range samples in the blanking region
    has_ld_nonstandard_bursts   BOOLEAN,
    capture_notes               TEXT
);

CREATE TABLE field_record (
    cvbs_file_id    INTEGER NOT NULL,
    field_id        INTEGER NOT NULL,
    sync_conf       INTEGER NOT NULL,
    -- NEW: absolute byte offset and length in the data file;
    --      required when tbc_applied = FALSE or sample rate is non-standard
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

**Notes on the `decoder` column change:**

The CHECK constraint on `decoder` is removed. In its place, a convention is defined:

- `decoder` should be one of the known values `'ld-decode'`, `'vhs-decode'`, `'cvbs-encode'`,
  `'cvbs-decode'` where applicable.
- For any other tool, `decoder` should be set to `'other'` and `decoder_name` should contain the
  human-readable tool name (e.g. `'domesday-duplicator'`, `'cx-decode'`).
- `decoder_name` is ignored (should be `NULL`) when `decoder` is one of the known values.

This avoids requiring a schema migration every time a new tool is added to the ecosystem.

---

## 5. Summary of Proposed Additions

| Location | Addition | Type | Nullable | Purpose |
|---|---|---|---|---|
| `cvbs_file` | `tbc_applied` | BOOLEAN | No | Governs whether normative field sizes and level compliance apply |
| `cvbs_file` | `sample_rate_numerator` | INTEGER | Yes | Numerator of exact rational sample rate; NULL = standard 4×fsc |
| `cvbs_file` | `sample_rate_denominator` | INTEGER | Yes | Denominator of above; must be non-null iff numerator is non-null |
| `cvbs_file` | `sc_h_phase_degrees` | REAL | Yes | Subcarrier-to-horizontal phase at file start, in degrees |
| `cvbs_file` | `has_ld_nonstandard_bursts` | BOOLEAN | Yes | PAL: pilot burst (IEC 60856-1986); NTSC: additional colour bursts (IEC 60857-1986); `TRUE` = expect out-of-range blanking samples |
| `cvbs_file` | `decoder_name` | TEXT | Yes | Free-text tool name when `decoder = 'other'` |
| `field_record` | `byte_offset` | INTEGER | Yes | Absolute byte offset of field in data file |
| `field_record` | `byte_count` | INTEGER | Yes | Byte length of field in data file |

Specification text changes required:

| Section | Change |
|---|---|
| §3.1 | Condition level compliance on `tbc_applied = TRUE` |
| §4.1 | Condition normative field sizes on `tbc_applied = TRUE` and standard 4×fsc |
| §5.3 | Document new `field_record` columns; define NULL semantics |
| §5.4 | Note that `sample_flags` is undefined when `tbc_applied = FALSE` |
| §5.2 | Document all new `cvbs_file` columns; update schema version note |
