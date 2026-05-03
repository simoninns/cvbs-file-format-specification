# Video Standard Preset Definitions

This document is part of the [CVBS File Format Specification](index.md). It contains the normative Video Standard Preset definitions referenced in Section 4.2 of that specification.

> **Note — Line Numbering Convention:** This specification uses **0-based field line numbering**: field line 0 is the first line of a field, and the last line of a field is numbered N−1 (where N is the total number of lines in that field). This follows software/coding convention and differs from the 1-based line numbering used in EBU and SMPTE broadcast standards, where lines are numbered starting from 1. Informational blocks that quote line numbers from EBU or SMPTE documents preserve the original 1-indexed numbering from those standards; each such block notes this explicitly. Additionally, EBU and SMPTE number lines sequentially across the entire interlaced frame; where such frame line numbers appear in informational blocks they are labelled as frame line numbers to distinguish them from the field-relative line numbers used throughout the rest of this specification.

**Naming convention:** Preset names follow the pattern `PRIMARY` or `PRIMARY_SUBSET`, where `PRIMARY` identifies the base standard and `SUBSET` (when present) identifies a regional or technical variant. The underscore `_` separates the primary designator from the subset. Preset names use only uppercase ASCII letters, digits, and underscores; each name defined in this specification is unique. Additional presets may be defined in future revisions or companion documents.

Examples:
- `PAL` — the primary PAL standard
- `NTSC` — the primary NTSC standard
- `PAL_M` — a PAL-family variant using NTSC 525-line/60 Hz timing with PAL colour subcarrier modulation

---

## Preset: `PAL`

**External standards:** EBU tech3280 (EBU 3280).

**Sampling rate:**

| Formula | Frequency |
|---------|-----------|
| 4 × 625 × 25 × (1135/4 + 1/625) | **17,734,475 Hz** (exact) |

**Sample level table (EBU 3280) — applicable when Sample Encoding Preset is `CVBS_U10_4FSC` or `CVBS_U16_4FSC`:**

| Level            | 10-bit Decimal | 10-bit Hex   | Notes                       |
| ---------------- | -------------- | ------------ | --------------------------- |
| Protected min    | 0–3            | 000h–003h    | Must never appear; reserved |
| Sync tip         | 4              | 004h (01.0h) | Minimum legal sample value  |
| Blanking         | 256            | 100h (40.0h) | Zero-signal reference       |
| Black            | 282            | 11Ah         | Nominal picture black       |
| White (100%)     | 844            | 34Ch (D3.0h) | 100% white                  |
| Peak (w/ chroma) | 1019           | 3FBh         | Maximum legal sample value  |
| Protected max    | 1020–1023      | 3FCh–3FFh    | Must never appear; reserved |

**Horizontal line structure:**

| Total samples/line       | Digital active samples | Digital blanking samples |
| ------------------------ | ---------------------- | ------------------------ |
| 1135 (nominal; see note) | 948                    | 187                      |


**PAL — non-integer samples per line:** The precise PAL sample rate yields exactly 1135 + 4/625 samples per line on average. The normative consequence is that **exactly 2 lines per field carry 1136 samples** and all remaining lines carry 1135. This is exact, not an approximation. Per frame: 4 lines carry 1136 samples and the remaining 621 carry 1135 (total 709,379 samples per frame).

The positions of the 1136-sample lines are **fixed and identical in every frame**. Because 625 × (4/625) = 4 exactly, the fractional phase resets to zero at the end of every frame with no remainder, so the pattern does not drift and does not vary with the 8-field PAL colour sequence.

This file format defines the fractional sample phase to be **zero at the start of field line 0 of the odd field** (the first line of the odd field). The 1136-sample lines are then those where placing one extra sample is required to keep the cumulative sample count an integer, i.e. the condition `⌊4(n+1)/625⌋ > ⌊4n/625⌋` holds, where *n* is the **0-based frame line index** (0 = field line 0 of the odd field; 624 = field line 311 of the even field, the last line of the even field). This yields the following normative line positions:

| Field            | Lines carrying 1136 samples (0-indexed within field)    |
| ---------------- | ------------------------------------------------------- |
| Odd (313 lines)  | **156** and **312** (312 is the last line of the field) |
| Even (312 lines) | **155** and **311** (311 is the last line of the field) |

> *(Informational — EBU tech3280 §1.2):* For PAL the digital active line consists of samples 0–947; the digital horizontal blanking interval is samples 948–1134 (and sample 1135 on lines that carry 1136 samples). The half-amplitude point of the leading sync edge on line 1, field 1 falls mid-way between samples; on succeeding lines the sampling structure advances by 0.361 ns per line (4 samples per frame). *(Line numbers in this block use EBU tech3280's 1-indexed convention; EBU "line 1, field 1" corresponds to field line 0 of the first field in this specification.)*

**Vertical structure:**

| Lines/frame | Fields/frame | Lines/odd field | Lines/even field | Colour field sequence |
| ----------- | ------------ | --------------- | ---------------- | --------------------- |
| 625         | 2            | 313             | 312              | 8-field               |

> *(Informational — EBU tech3280 §1.1.1):* PAL uses 2:1 interlace over 625 lines at 25 frames/s. The PAL subcarrier-to-horizontal (Sc/H) phase relationship cycles over 8 fields before repeating; fields are labelled 1–8. Odd fields (1, 3, 5, 7) contain 313 lines (lines 1–313 within each frame); even fields (2, 4, 6, 8) contain 312 lines (lines 314–625). *(Line numbers in this block are EBU 1-indexed frame line numbers, counting sequentially across the full 625-line frame.)*

**Digital vertical blanking interval:**

> *(Informational — EBU tech3280 §1.3.2):* For PAL, the digital vertical blanking interval extends (line numbers use EBU tech3280's 1-indexed frame line convention, counting sequentially across the full 625-line frame):
> - Odd fields (1, 3, 5, 7): line 623 sample 382 to line 5 sample 947 (inclusive, wrapping across the frame boundary).
> - Even fields (2, 4, 6, 8): line 310 sample 948 to line 317 sample 947 (inclusive).

**Exact field sizes** (normative when the Signal State Preset has `tbc_applied = TRUE` at the standard 4×fsc sample rate; when either condition does not hold, these tables are not normative):

| Field type        | Lines | Total samples | Total bytes |
| ----------------- | ----- | ------------- | ----------- |
| Odd (1, 3, 5, 7)  | 313   | **355,257**   | **710,514** |
| Even (2, 4, 6, 8) | 312   | **354,122**   | **708,244** |

Derivations:
- **PAL odd:** 311 × 1135 + 2 × 1136 = 352,985 + 2,272 = **355,257 samples**
- **PAL even:** 310 × 1135 + 2 × 1136 = 351,850 + 2,272 = **354,122 samples**

Bytes = samples × 2 (each sample is one 16-bit little-endian word).

**Colour field sequence:**

The PAL colour sequence cycles over **8 fields**, numbered 1–8. Odd fields (1, 3, 5, 7) are 313-line fields; even fields (2, 4, 6, 8) are 312-line fields.

> *(Informational — EBU tech3280 §1.1.1 and Fig. 1):* At 0° Sc/H (the normative PAL sampling phase), the +U axis of the subcarrier is at zero phase relative to the horizontal timing reference point (0H) on field line 0 of field 1. The colour burst phase rotates through a known pattern over the 8-field cycle. Any break in the expected Sc/H phase progression between consecutive stored fields indicates a discontinuity in the colour field sequence.

> *(Informational — ld-decode/vhs-decode convention):* `isFirstField = true` corresponds to EBU Field 2 (the even/lower field, 312 lines) — Field 2 leads into its VSYNC interval with a half-line (0.5H) gap, not Field 1. PAL TBC output from `ld-decode` therefore conventionally starts with the even analogue field.

---

## Preset: `NTSC`

**External standards:** SMPTE ST.0244.

**Sampling rate:**

| Formula | Frequency |
|---------|-----------|
| 4 × 525 × (30000/1001) × (455/2) | **14,318,181.8… Hz** |

**Sample level table (SMPTE ST.0244) — applicable when Sample Encoding Preset is `CVBS_U10_4FSC` or `CVBS_U16_4FSC`:**

| Level            | 10-bit Decimal | 10-bit Hex | Notes                           |
| ---------------- | -------------- | ---------- | ------------------------------- |
| Protected min    | 0–3            | 000h–003h  | Must never appear; reserved     |
| Sync tip         | 16             | 010h       | Minimum legal sample value      |
| Blanking         | 240            | 0F0h       | Zero-signal reference           |
| Black            | 252            | 0FCh       | Nominal picture black (7.5 IRE) |
| White (100%)     | 800            | 320h       | 100% white                      |
| Peak (w/ chroma) | 988            | 3DCh       | Maximum legal sample value      |
| Protected max    | 1020–1023      | 3FCh–3FFh  | Must never appear; reserved     |

**Horizontal line structure:**

| Total samples/line | Digital active samples | Digital blanking samples |
| ------------------ | ---------------------- | ------------------------ |
| 910 (exact)        | 768                    | 142                      |

> *(Informational — SMPTE ST.0244 §4.1.1):* For NTSC, sampling is orthogonal; all lines carry exactly 910 samples. The half-amplitude point of the leading (falling) horizontal sync edge falls between samples 784 and 785. The digital active line is samples 0–767; the digital horizontal blanking interval is samples 768–909.

**Vertical structure:**

| Lines/frame | Fields/frame | Lines/odd field | Lines/even field | Colour field sequence |
| ----------- | ------------ | --------------- | ---------------- | --------------------- |
| 525         | 2            | 263             | 262              | 4-field               |

> *(Informational — SMPTE ST.0244 §4.1, §4.1.2):* NTSC uses 2:1 interlace over 525 lines at 30000/1001 frames/s. The SC/H phase relationship cycles over 4 fields (colour frames A and B, fields I–IV). Fields I and III are odd fields (263 lines each); fields II and IV are even fields (262 lines each). Sample 0 of line 10, field I, colour frame A is an I-axis (+123°) sample. *(Line numbers in this block use SMPTE ST.0244's 1-indexed frame line convention, counting sequentially across the full 525-line frame; SMPTE "line 10" corresponds to field line 9 of field I in this specification's 0-indexed convention.)*

**Digital vertical blanking interval:**

> *(Informational — SMPTE ST.0244 §5.4.1):* For NTSC, the digital vertical blanking interval extends (line numbers use SMPTE ST.0244's 1-indexed frame line convention, counting sequentially across the full 525-line frame):
> - Fields I and III: line 525 sample 768 to line 9 sample 767 (inclusive, wrapping across the frame boundary).
> - Fields II and IV: line 263 sample 313 to line 272 sample 767 (inclusive).

**Exact field sizes** (normative when the Signal State Preset has `tbc_applied = TRUE` at the standard 4×fsc sample rate; when either condition does not hold, these tables are not normative):

| Field type    | Lines | Total samples | Total bytes |
| ------------- | ----- | ------------- | ----------- |
| Odd (I, III)  | 263   | **239,330**   | **478,660** |
| Even (II, IV) | 262   | **238,420**   | **476,840** |

Derivations:
- **NTSC odd:** 263 × 910 = **239,330 samples**
- **NTSC even:** 262 × 910 = **238,420 samples**

Bytes = samples × 2 (each sample is one 16-bit little-endian word).

**Colour field sequence:**

The NTSC colour sequence cycles over **4 fields** (Field I, Field II, Field III, Field IV), forming colour frames A (fields I–II) and B (fields III–IV). Fields I and III are odd fields (263 lines); fields II and IV are even fields (262 lines).

> *(Informational — SMPTE ST.0244 §3.2, §4.1.2):* At 0° SC/H (the normative NTSC sampling phase), sample 0 of line 10, field I, colour frame A is an I-axis (+123°) sample (SMPTE 1-indexed frame line 10 = field line 9 of field I in this specification's 0-indexed convention). Each of the 4 fields has a unique SC/H relationship; comparing the measured burst phase at sample 0 against the expected value for that field identifies its position in the 4-field sequence. A phase discontinuity between consecutive fields indicates a colour frame sequence break.

> *(Informational — ld-decode/vhs-decode convention):* `isFirstField = true` corresponds to SMPTE Field I (the odd/upper field, 263 lines) — Field I leads into VSYNC with a full 1H gap. NTSC TBC output from `ld-decode` therefore conventionally starts with the odd analogue field.

---

## Preset: `PAL_M`

**External standards:** SMPTE ST.0244 (signal levels and timing structure); PAL colour subcarrier modulation (IEC/ABNT standards for Brazil).

PAL-M uses 525-line/60 Hz timing (identical frame and line structure to NTSC) with PAL colour subcarrier modulation. Signal levels follow ST.0244. The colour field sequence is 8 fields (longer than NTSC's 4-field sequence) due to the PAL colour encoding.

**Sampling rate:**

| Formula | Frequency |
|---------|-----------|
| 4 × 525 × (30000/1001) × (909/4) | **14,302,448.1… Hz** |

**Sample level table (SMPTE ST.0244 levels) — applicable when Sample Encoding Preset is `CVBS_U10_4FSC` or `CVBS_U16_4FSC`:**

| Level            | 10-bit Decimal | 10-bit Hex | Notes                           |
| ---------------- | -------------- | ---------- | ------------------------------- |
| Protected min    | 0–3            | 000h–003h  | Must never appear; reserved     |
| Sync tip         | 16             | 010h       | Minimum legal sample value      |
| Blanking         | 240            | 0F0h       | Zero-signal reference           |
| Black            | 252            | 0FCh       | Nominal picture black (7.5 IRE) |
| White (100%)     | 800            | 320h       | 100% white                      |
| Peak (w/ chroma) | 988            | 3DCh       | Maximum legal sample value      |
| Protected max    | 1020–1023      | 3FCh–3FFh  | Must never appear; reserved     |

**Horizontal line structure:**

| Total samples/line | Digital active samples | Digital blanking samples |
| ------------------ | ---------------------- | ------------------------ |
| 909 (exact)        | 768                    | 141                      |

**Vertical structure:**

| Lines/frame | Fields/frame | Lines/odd field | Lines/even field | Colour field sequence |
| ----------- | ------------ | --------------- | ---------------- | --------------------- |
| 525         | 2            | 263             | 262              | 8-field               |

**Exact field sizes** (normative when the Signal State Preset has `tbc_applied = TRUE` at the standard 4×fsc sample rate; when either condition does not hold, these tables are not normative):

| Field type | Lines | Total samples | Total bytes |
| ---------- | ----- | ------------- | ----------- |
| Odd        | 263   | **239,067**   | **478,134** |
| Even       | 262   | **238,158**   | **476,316** |

Derivations:
- **PAL-M odd:** 263 × 909 = **239,067 samples**
- **PAL-M even:** 262 × 909 = **238,158 samples**

Bytes = samples × 2 (each sample is one 16-bit little-endian word).

**Colour field sequence:**

Despite using 525-line/60 Hz timing, PAL-M uses a **8-field** colour sequence (not 4-field) due to the PAL colour subcarrier modulation. Phase verification follows the PAL SC/H approach applied to the 525-line/60 Hz timing structure.

---

## Frame Ordering and Phase Verification

Video Standard Presets are frame-described. Frames are stored sequentially in file order, and each frame is composed of two interlaced fields (odd/even) per the selected preset. Position within the colour field sequence is not encoded in-band; consumers determine sequence position by measuring burst phase and checking that successive frames preserve the expected preset-specific odd/even pairing and phase progression.

- **PAL:** verify against the 8-field progression described in the PAL preset section above.
- **NTSC:** verify against the 4-field progression described in the NTSC preset section above.
- **PAL_M:** verify against the 8-field progression described in the PAL_M preset section above.

`ld-decode` and `vhs-decode` field-ordering conventions are documented in the informational notes in each preset section.

**Frame boundary and length integrity (normative):**

When a Signal State Preset requires locked timing at the standard 4x fsc sample rate (for example `tbc_applied = TRUE` and burst/colour lock sufficient to preserve sequence continuity), producers shall preserve frame boundaries and exact frame sample counts throughout the stream. For affected presets, each frame shall contain exactly one odd field and one even field in the correct preset-specific progression, with no skipped fields, duplicated fields, or re-pairing that would shift frame boundary alignment.

For these presets, the exact frame sample counts are:
- **PAL:** 709,379 samples/frame (355,257 odd + 354,122 even)
- **NTSC:** 477,750 samples/frame (239,330 odd + 238,420 even)
- **PAL_M:** 477,225 samples/frame (239,067 odd + 238,158 even)

If a producer cannot guarantee this lock (for example because source skips, repeated source fields, dropouts in timing recovery, or other instability prevent reliable frame-to-frame sequence continuity), that producer shall not claim the corresponding locked preset constraints as normative for that content.

---

## Non-Standard Value Signaling

- **Declared non-standard values:** When `has_nonstandard_values = TRUE` in core metadata, consumers must allow non-standard sample values without treating them as automatic compliance errors.
- **Source-specific interpretation:** The metadata flag indicates presence only. The exact type, location, and semantics of non-standard content (for example PAL pilot bursts, NTSC additional bursts, or other anomalies) are source-specific and may be documented in `capture_notes` or a producer extension format.
- **Encoding interaction:** Depending on the declared Sample Encoding Preset and processing path, non-standard values may be preserved directly, quantized, or clipped before storage.
- **DC Offset:** Not required. The signed 16-bit storage format provides sufficient negative headroom below 0 to accommodate chroma excursions without clipping.


