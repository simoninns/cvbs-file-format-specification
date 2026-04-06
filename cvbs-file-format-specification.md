# CVBS File Format Specification

## Part 1: Agreed Specification

The sections below are agreed and considered stable for implementation.

---

## 1. Introduction

This document defines the **CVBS File Format** for use with the `cvbs-encode` project. **CVBS** (Colour, Video, Blank, and Sync) describes the full class of analogue video signal — both composite (luma and chroma combined into a single signal) and component YC representations carry the same Colour, Video, Blank, and Sync elements and are therefore both CVBS signals. The format targets **10-bit ST.0244** and **EBU 3280** compliance and accommodates **non-standard cases** (e.g., LaserDisc PAL pilot bursts).

---

## 2. File Naming Convention

Each file type uses a distinct extension:

- **Composite CVBS:** `<basename>.composite`
- **Dual-File YC CVBS (Luma):** `<basename>.y`
- **Dual-File YC CVBS (Chroma):** `<basename>.c`

---

## 3. Video Data Format

### 3.1. Sample Encoding

- **10-bit samples** are stored as **signed 16-bit little-endian integers**. The unsigned 10-bit value (0–1023) maps directly into the signed 16-bit range such that 10-bit value 0 equals signed 16-bit value 0 and 10-bit value 1023 equals signed 16-bit value 1023. This provides:
  - **Negative headroom:** signed 16-bit values below 0 (down to −32768)
  - **Positive headroom:** signed 16-bit values above 1023 (up to 32767)
- This encoding is known as the **cvbs-decode** encoding. It is the standard, standards-compliant output format for all CVBS files produced by `cvbs-encode`.
- All EBU 3280 and ST.0244 rules governing the position of sync, blanking, and white levels apply as defined — the 10-bit values are simply interpreted within the signed 16-bit space without any offset or scaling.
- Both representations below are CVBS (Colour, Video, Blank, and Sync) signals; they differ only in how colour information is carried:
  - **Composite CVBS:** Single file containing luma and chroma combined into one signal.
  - **Dual-File YC CVBS:** Separate files for luma (Y) and chroma (C), keeping the colour components separated.

#### Sample Range — PAL (EBU 3280):

| Level           | 10-bit Decimal | 10-bit Hex        | Notes                              |
| --------------- | -------------- | ----------------- | ---------------------------------- |
| Protected min   | 0–3            | 000h–003h         | Must never appear; reserved        |
| Sync tip        | 4              | 004h (01.0h)      | Minimum legal sample value         |
| Blanking        | 256            | 100h (40.0h)      | Zero-signal reference              |
| Black           | 282            | 11Ah              | Nominal picture black              |
| White (100%)    | 844            | 34Ch (D3.0h)      | 100% white                         |
| Peak (w/ chroma)| 1019           | 3FBh              | Maximum legal sample value         |
| Protected max   | 1020–1023      | 3FCh–3FFh         | Must never appear; reserved        |

#### Sample Range — NTSC and PAL-M (SMPTE ST.244):

PAL-M uses the same signal levels as NTSC (ST.244 levels with PAL colour subcarrier modulation).

| Level           | 10-bit Decimal | 10-bit Hex        | Notes                              |
| --------------- | -------------- | ----------------- | ---------------------------------- |
| Protected min   | 0–3            | 000h–003h         | Must never appear; reserved        |
| Sync tip        | 16             | 010h              | Minimum legal sample value         |
| Blanking        | 240            | 0F0h              | Zero-signal reference              |
| Black           | 252            | 0FCh              | Nominal picture black (7.5 IRE)    |
| White (100%)    | 800            | 320h              | 100% white                         |
| Peak (w/ chroma)| 988            | 3DCh              | Maximum legal sample value         |
| Protected max   | 1020–1023      | 3FCh–3FFh         | Must never appear; reserved        |

**Note:** The 10-bit data **must comply** with EBU 3280 (PAL) or ST.0244 (NTSC, PAL-M) as appropriate, including the exclusion of values at the top and bottom of the 10-bit range. **Exceptions** (e.g., LaserDisc PAL pilot bursts) are allowed but **must be noted in the metadata**.

### 3.2. File Layout

Video data is stored field-by-field with no additional framing or headers:

```
[Field 1 Video Data: N bytes]
[Field 2 Video Data: N bytes]
...
```

---

## 4. Compliance

### 4.1. ST.0244 (NTSC) and EBU 3280 (PAL) Compliance

#### Sampling Rate

| Standard | Formula | Frequency |
|----------|---------|-----------|
| PAL (EBU 3280) | 4 × 625 × 25 × (1135/4 + 1/625) | **17,734,475 Hz** (exact) |
| NTSC (ST.0244) | 4 × 525 × (30000/1001) × (455/2) | **14,318,181.8… Hz** |
| PAL-M | 4 × 525 × (30000/1001) × (909/4) | **14,302,448.1… Hz** |

#### Bit Depth

10-bit values stored as signed 16-bit little-endian integers. 10-bit value 0 maps to signed 16-bit value 0, with negative and positive headroom below 0 and above 1023 respectively.

#### Horizontal Line Structure

| Standard | Total samples/line | Digital active samples | Digital blanking samples |
|----------|--------------------|------------------------|--------------------------|
| PAL      | 1135 (nominal; see note) | 948 | 187 |
| NTSC     | 910 (exact) | 768 | 142 |
| PAL-M    | 909 (exact) | 768 | 141 |

**PAL — non-integer samples per line:** The precise PAL sample rate yields exactly 1135 + 4/625 samples per line on average. The normative consequence is that **exactly 2 lines per field carry 1136 samples** and all remaining lines carry 1135. This is exact, not an approximation. Per frame: 4 lines carry 1136 samples and the remaining 621 carry 1135 (total 709,379 samples per frame). The specific lines that carry 1136 samples are phase-dependent — they fall immediately before the first active picture sample of the field — and shift through the 8-field PAL colour sequence.

> *(Informational — EBU tech3280 §1.2):* For PAL the digital active line consists of samples 0–947; the digital horizontal blanking interval is samples 948–1134 (and sample 1135 on lines that carry 1136 samples). The half-amplitude point of the leading sync edge on line 1, field 1 falls mid-way between samples; on succeeding lines the sampling structure advances by 0.361 ns per line (4 samples per frame).

> *(Informational — SMPTE ST.0244 §4.1.1):* For NTSC, sampling is orthogonal; all lines carry exactly 910 samples. The half-amplitude point of the leading (falling) horizontal sync edge falls between samples 784 and 785. The digital active line is samples 0–767; the digital horizontal blanking interval is samples 768–909.

#### Vertical Structure — Lines and Fields

| Standard | Lines/frame | Fields/frame | Lines/odd field | Lines/even field | Colour field sequence |
|----------|-------------|--------------|-----------------|------------------|-----------------------|
| PAL      | 625         | 2            | 313             | 312              | 8-field               |
| NTSC     | 525         | 2            | 263             | 262              | 4-field               |
| PAL-M    | 525         | 2            | 263             | 262              | 8-field               |

> *(Informational — EBU tech3280 §1.1.1):* PAL uses 2:1 interlace over 625 lines at 25 frames/s. The PAL subcarrier-to-horizontal (Sc/H) phase relationship cycles over 8 fields before repeating; fields are labelled 1–8. Odd fields (1, 3, 5, 7) contain 313 lines (lines 1–313 within each frame); even fields (2, 4, 6, 8) contain 312 lines (lines 314–625).

> *(Informational — SMPTE ST.0244 §4.1, §4.1.2):* NTSC uses 2:1 interlace over 525 lines at 30000/1001 frames/s. The SC/H phase relationship cycles over 4 fields (colour frames A and B, fields I–IV). Fields I and III are odd fields (263 lines each); fields II and IV are even fields (262 lines each). Sample 0 of line 10, field I, colour frame A is an I-axis (+123°) sample.

#### Digital Vertical Blanking Interval

> *(Informational — EBU tech3280 §1.3.2):* For PAL, the digital vertical blanking interval extends:
> - Odd fields (1, 3, 5, 7): line 623 sample 382 to line 5 sample 947 (inclusive, wrapping across the frame boundary).
> - Even fields (2, 4, 6, 8): line 310 sample 948 to line 317 sample 947 (inclusive).

> *(Informational — SMPTE ST.0244 §5.4.1):* For NTSC, the digital vertical blanking interval extends:
> - Fields I and III: line 525 sample 768 to line 9 sample 767 (inclusive, wrapping across the frame boundary).
> - Fields II and IV: line 263 sample 313 to line 272 sample 767 (inclusive).

#### Exact Field Sizes

The following field sizes are normative for this file format. All readers and writers must use these exact values.

| Standard | Field type            | Lines | Total samples | Total bytes |
|----------|-----------------------|-------|---------------|-------------|
| PAL      | Odd (1, 3, 5, 7)      | 313   | **355,257**   | **710,514** |
| PAL      | Even (2, 4, 6, 8)     | 312   | **354,122**   | **708,244** |
| NTSC     | Odd (I, III)          | 263   | **239,330**   | **478,660** |
| NTSC     | Even (II, IV)         | 262   | **238,420**   | **476,840** |
| PAL-M    | Odd                   | 263   | **239,067**   | **478,134** |
| PAL-M    | Even                  | 262   | **238,158**   | **476,316** |

Derivations:
- **PAL odd:** 311 × 1135 + 2 × 1136 = 352,985 + 2,272 = **355,257 samples**
- **PAL even:** 310 × 1135 + 2 × 1136 = 351,850 + 2,272 = **354,122 samples**
- **NTSC odd:** 263 × 910 = **239,330 samples**
- **NTSC even:** 262 × 910 = **238,420 samples**
- **PAL-M odd:** 263 × 909 = **239,067 samples**
- **PAL-M even:** 262 × 909 = **238,158 samples**

Bytes = samples × 2 (each sample is one 16-bit little-endian word).

### 4.2. Non-Standard Extensions

- **LaserDisc PAL Pilot Bursts:** Allowed to exceed standard blanking levels. **Metadata must flag such exceptions.**
- **DC Offset:** Not required. The signed 16-bit storage format provides sufficient negative headroom below 0 to accommodate chroma excursions without clipping.

### 4.3. Field Ordering and Phase Verification

Fields are stored sequentially in the file with no embedded markers identifying where in the colour field sequence the file begins (see Section 3.2). **No assumption must be made that the first field in a file is field 1 (or field I) of the colour sequence.** Capture sources (e.g., LaserDisc RF captures) may begin recording at any point in the colour field cycle, and the sequence may contain discontinuities caused by disc jumps, skipped fields, or dropouts.

Consumers of CVBS files must verify field ordering independently by examining the colour burst phase of each field and checking that consecutive fields exhibit the expected phase progression for the declared standard.

**PAL — 8-field sequence (EBU tech3280 §1.1.1):**

> *(Informational — EBU tech3280 §1.1.1 and Fig. 1):* At 0° Sc/H (the normative PAL sampling phase), the +U axis of the subcarrier is at zero phase relative to the horizontal timing reference point (0H) on line 1 of field 1. The colour burst phase rotates through a known pattern over the 8-field cycle. Any break in the expected Sc/H phase progression between consecutive stored fields indicates a discontinuity in the colour field sequence.

**NTSC — 4-field colour frame sequence (SMPTE ST.0244 §4.1.2):**

> *(Informational — SMPTE ST.0244 §3.2, §4.1.2):* At 0° SC/H (the normative NTSC sampling phase), sample 0 of line 10, field I, colour frame A is an I-axis (+123°) sample. Each of the 4 fields in the colour frame cycle has a unique SC/H relationship; comparing the measured burst phase at sample 0 against the expected value identifies the field's position in the 4-field sequence. A phase discontinuity between consecutive fields indicates a colour frame sequence break.

A conformant CVBS file should be accompanied by metadata (see Section 6) that records the colour field sequence identity of the first stored field, enabling consumers to verify phase continuity from a known starting point rather than having to infer it.

---

## Part 2: Under Discussion

The following sections are proposals only and have not yet been agreed. Content is subject to change based on further discussion.

---

## 5. Audio Data (UNDER DISCUSSION)

- **Audio tracks** are stored as separate **48KHz Stereo PCM WAV** files.
- Up to 16 audio tracks are supported, each as a separate file.
- **File naming:** `<basename>_audio_<track_number>.wav`

Track number is 00-16 (so, 00, 01, 02, etc.)

---

## 6. Metadata Schema (UNDER DISCUSSION)

Metadata is stored in a **separate `.meta` file** to ensure compliance with EBU and ST specifications for transmission.

- **Metadata:** `<basename>.meta`

### 6.1. SQLite Metadata Schema

```
------------------------------------------------------------------
-- Schema Versioning
------------------------------------------------------------------
PRAGMA user_version = 1;

------------------------------------------------------------------
-- 1. CVBS File Metadata
------------------------------------------------------------------
CREATE TABLE cvbs_file (
    cvbs_file_id INTEGER PRIMARY KEY,
    system TEXT NOT NULL
        CHECK (system IN ('NTSC', 'PAL', 'PAL_M')),
    decoder TEXT NOT NULL
        CHECK (decoder IN ('ld-decode', 'vhs-decode', 'cvbs-encode', 'cvbs-decode')),
    git_branch TEXT,
    git_commit TEXT,
    number_of_sequential_fields INTEGER NOT NULL,
    burst_locked BOOLEAN NOT NULL,
    first_field_sequence_number INTEGER
        CHECK (first_field_sequence_number IS NULL OR
               (system = 'PAL'   AND first_field_sequence_number BETWEEN 1 AND 8) OR
               (system = 'NTSC'  AND first_field_sequence_number BETWEEN 1 AND 4) OR
               (system = 'PAL_M' AND first_field_sequence_number BETWEEN 1 AND 8)),
        -- PAL-M: 1–8 (8-field Sc/H cycle; same colour sequence length as PAL)
    capture_notes TEXT
);

------------------------------------------------------------------
-- 2. Field Metadata
------------------------------------------------------------------
CREATE TABLE field_record (
    cvbs_file_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL, -- Zero-indexed
    sync_conf INTEGER NOT NULL, -- 0-100 percent
    PRIMARY KEY (cvbs_file_id, field_id),
    FOREIGN KEY (cvbs_file_id)
        REFERENCES cvbs_file(cvbs_file_id)
        ON DELETE CASCADE
);

------------------------------------------------------------------
-- 3. Sample Flags (e.g., dropouts)
------------------------------------------------------------------
CREATE TABLE sample_flags (
    cvbs_file_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL,
    field_line INTEGER NOT NULL, -- Zero-indexed
    type TEXT NOT NULL
        CHECK (type IN ('dropout')),
    startx INTEGER NOT NULL, -- 0 = start of CVBS field line
    endx INTEGER NOT NULL,
    PRIMARY KEY (cvbs_file_id, field_id, field_line, startx, endx),
    FOREIGN KEY (cvbs_file_id, field_id)
        REFERENCES field_record(cvbs_file_id, field_id)
        ON DELETE CASCADE
);
```

---

## 7. Compression (UNDER DISCUSSION)

### 7.1. Overview

This section outlines a proposal for **lossless compression** of video and audio data to reduce storage requirements while preserving all original information.

### 7.2. Proposed Compression Method

- **Video Data:**
  - Use **FLAC**, **gzip** or **zstd** for lossless compression of `.composite`, `.y`, `.c`, and `.flags` files.
  - Compressed files should use the `.gz` extension (e.g., `<basename>.composite.gz`).
  - Compression should be applied **per-field** to allow random access and partial decompression.
- **Audio Data:**
  - Use **FLAC** for lossless compression of `.wav` files.
  - Compressed files should use the `.flac` extension.

### 7.3. Metadata Updates

The metadata file should include a `compression` field to indicate the compression method used:

```yaml
compression:
  video: "gzip"  # or "zstd", "none"
  audio: "FLAC"  # or "none"
```

### 7.4. Open Questions

- Should compression be mandatory, optional, or user-selectable?
  (Current preference: user-selectable — uncompressed storage is useful during development.)
- Should the format support **chunked compression** for streaming or partial access?
  (Current preference: yes.)
- Are there preferred compression algorithms for specific use cases (e.g., archival vs. editing)?

---

## 8. Tools and Validation (UNDER DISCUSSION)

### 8.1. Reference Tools

None

### 8.2. Test Vectors

- Provide reference files for **PAL, NTSC, and PAL-M** with known metadata and compression examples.

---

## 9. Open Questions

1. Are additional **special cases** (e.g., SECAM, PAL-N) required?
2. Should the format enforce a specific compression algorithm, or remain flexible?

---
