# Video Standard Preset Definitions

This document is part of the [CVBS File Format Specification](index.md). It contains the normative Video Standard Preset definitions referenced in Section 4.2 of that specification.

> **Note — Line Numbering Convention:** This specification uses **0-based frame line numbering**: frame line 0 is the first line of a frame, and the last line of a frame is numbered N−1 (where N is the total number of lines in that frame). This follows software/coding convention and differs from the 1-based line numbering used in EBU and SMPTE broadcast standards, where lines are numbered starting from 1. Informational blocks that quote line numbers from EBU or SMPTE documents preserve the original 1-indexed numbering from those standards; each such block notes this explicitly. Where the source standard numbers lines sequentially across the full frame, those values are referred to here as **frame line numbers**.

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
| 1135.0064 (exact average; see note) | 948 (nominal)         | 187.0064 (nominal)       |


**PAL — non-orthogonal 4fsc sampling structure:** At the exact PAL 4fsc sampling rate there are **1135.0064 sample periods per line** and therefore exactly **709,379 samples per frame**. For frame 1 of the PAL sequence at 0 degrees Sc/H, the half-amplitude point of the leading edge of the line sync pulse on frame line 1 falls midway between samples **957** and **958**. On succeeding lines the sampling structure advances by **0.361 ns per line**, i.e. **4 samples per frame**. Consequently the PAL 4fsc sampling lattice is **non-orthogonal** and repeats at **frame rate** rather than at line rate.

The analogue PAL composite waveform is sampled at **4fsc**, so sampling instants occur at **45 degrees, 135 degrees, 225 degrees, and 315 degrees** relative to the **+U axis**. No synthetic or "additional" samples are required in this native 4fsc representation; that concept is only needed when converting the sampled frame into an auxiliary orthogonal digital line representation.

The analogue horizontal timing reference is **0H**, defined as the midpoint of the leading edge of sync. Any mapping between analogue time and stored digital samples must track the **analogue line period from 0H to 0H** within this non-orthogonal frame-repeating structure, not an imposed line-orthogonal numbering scheme.

**PAL 4-frame sequence:**

| Frame in sequence | Description |
| ----------------- | ----------- |
| 1                 | Reference frame of the PAL sequence at 0 degrees Sc/H |
| 2                 | Second frame in the PAL sequence |
| 3                 | Third frame in the PAL sequence |
| 4                 | Fourth frame in the PAL sequence; the next frame repeats as frame 1 |

PAL is a **625-line, 25 frames/s** system. The Sc/H relationship repeats every **4 frames**. In this specification, PAL sequence position is described only by the repeating frame numbers **1-4**. Each stored PAL frame is the complete 625-line frame sample sequence within the non-orthogonal 4fsc sample lattice; the frame numbering identifies sequence position only and does **not** imply an orthogonal digital display or storage raster.

**Digital vertical blanking interval:**

> *(Informational — EBU tech3280 §1.3.2):* For PAL, the digital vertical blanking interval extends (line numbers use EBU tech3280's 1-indexed frame line convention, counting sequentially across the full 625-line frame):
> - frame line 623 sample 382 to frame line 5 sample 947 (inclusive, wrapping across the frame boundary).
> - frame line 310 sample 948 to frame line 317 sample 947 (inclusive).

**Exact frame size** (normative when the Signal State Preset has `tbc_applied = TRUE` at the standard 4×fsc sample rate; when either condition does not hold, this value is not normative):

| Frames/sample count | Samples | Bytes |
| ------------------- | ------- | ----- |
| PAL frame           | **709,379** | **1,418,758** |

Because the PAL 4fsc sampling structure is non-orthogonal, this specification defines the normative PAL sample count only at the **frame** level. The exact normative constraint is the **frame total** of **709,379 samples** repeating at frame rate.

Bytes = samples × 2 (each sample is one 16-bit little-endian word).

**Colour frame sequence:**

The PAL colour sequence cycles over **4 frames** and then repeats.

> *(Informational — EBU tech3280 §1.1.1 and Fig. 1):* At 0° Sc/H (the normative PAL sampling phase), the +U axis of the subcarrier is at zero phase relative to the horizontal timing reference point (0H) at the start of frame 1 in the PAL sequence. The colour burst phase rotates through the standard PAL progression across the 4-frame cycle. Any break in the expected Sc/H phase progression between consecutive stored frames indicates a discontinuity in the PAL sequence.

> *(Informational — ld-decode/vhs-decode convention):* PAL TBC output from `ld-decode` conventionally starts at the midpoint of frame 1 in the EBU PAL sequence rather than at its first line. Consumers that care about exact PAL sequence origin should account for that half-frame offset.

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

**NTSC 2-frame sequence:**

| Frame in sequence | Description |
| ----------------- | ----------- |
| A                 | First frame of the NTSC colour sequence |
| B                 | Second frame of the NTSC colour sequence; the next frame repeats as A |

NTSC is a **525-line, 30000/1001 frames/s** system. The SC/H relationship repeats every **2 frames**. In this specification, NTSC sequence position is described only by the alternating frame labels **A** and **B**.

> *(Informational — SMPTE ST.0244 §4.1, §4.1.2):* SMPTE ST.0244 describes the same repeating NTSC sequence using a lower-level phase progression. This specification instead normalises that description to a **2-frame** cycle because storage in this format is frame-based. At 0° SC/H, sample 0 of frame line 10 in colour frame A is an I-axis (+123°) sample. *(Line numbers in this block use SMPTE ST.0244's 1-indexed frame line convention, counting sequentially across the full 525-line frame.)*

**Digital vertical blanking interval:**

> *(Informational — SMPTE ST.0244 §5.4.1):* For NTSC, the digital vertical blanking interval extends (line numbers use SMPTE ST.0244's 1-indexed frame line convention, counting sequentially across the full 525-line frame):
> - line 525 sample 768 to line 9 sample 767 (inclusive, wrapping across the frame boundary).
> - line 263 sample 313 to line 272 sample 767 (inclusive).

**Exact frame size** (normative when the Signal State Preset has `tbc_applied = TRUE` at the standard 4×fsc sample rate; when either condition does not hold, this value is not normative):

| Frames/sample count | Samples | Bytes |
| ------------------- | ------- | ----- |
| NTSC frame          | **477,750** | **955,500** |

Derivation:
- **NTSC frame:** 525 × 910 = **477,750 samples**

Bytes = samples × 2 (each sample is one 16-bit little-endian word).

**Colour frame sequence:**

The NTSC colour sequence cycles over **2 frames**, conventionally labelled **A** and **B**, and then repeats.

> *(Informational — SMPTE ST.0244 §3.2, §4.1.2):* At 0° SC/H (the normative NTSC sampling phase), sample 0 of frame line 10 in colour frame A is an I-axis (+123°) sample. Comparing the measured burst phase at that reference point against the expected value for colour frame **A** or **B** identifies position within the 2-frame sequence. A phase discontinuity between consecutive stored frames indicates a colour frame sequence break.

> *(Informational — ld-decode/vhs-decode convention):* NTSC TBC output from `ld-decode` conventionally starts with colour frame **A**.

---

## Preset: `PAL_M`

**External standards:** SMPTE ST.0244 (signal levels and timing structure); PAL colour subcarrier modulation (IEC/ABNT standards for Brazil).

PAL-M uses 525-line/60 Hz timing (identical frame size and line structure to NTSC) with PAL colour subcarrier modulation. Signal levels follow ST.0244. The colour sequence repeats every **4 frames**, longer than NTSC's 2-frame colour sequence, due to the PAL colour encoding.

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

**PAL-M 4-frame sequence:**

| Frame in sequence | Description |
| ----------------- | ----------- |
| 1                 | Reference frame of the PAL-M sequence |
| 2                 | Second frame in the PAL-M sequence |
| 3                 | Third frame in the PAL-M sequence |
| 4                 | Fourth frame in the PAL-M sequence; the next frame repeats as frame 1 |

PAL-M is a **525-line, 30000/1001 frames/s** system. The SC/H relationship repeats every **4 frames**.

**Exact frame size** (normative when the Signal State Preset has `tbc_applied = TRUE` at the standard 4×fsc sample rate; when either condition does not hold, this value is not normative):

| Frames/sample count | Samples | Bytes |
| ------------------- | ------- | ----- |
| PAL-M frame         | **477,225** | **954,450** |

Derivation:
- **PAL-M frame:** 525 × 909 = **477,225 samples**

Bytes = samples × 2 (each sample is one 16-bit little-endian word).

**Colour frame sequence:**

Despite using 525-line/60 Hz timing, PAL-M uses a **4-frame** colour sequence rather than NTSC's 2-frame sequence, due to the PAL colour subcarrier modulation. Phase verification follows the PAL SC/H approach applied to the 525-line/60 Hz timing structure.

---

## Frame Ordering and Phase Verification

Video Standard Presets are frame-described. Frames are stored sequentially in file order. Position within the colour frame sequence is not encoded in-band; consumers determine sequence position by measuring burst phase and checking that successive frames preserve the expected preset-specific progression.

- **PAL:** verify against the 4-frame progression described in the PAL preset section above.
- **NTSC:** verify against the 2-frame progression described in the NTSC preset section above.
- **PAL_M:** verify against the 4-frame progression described in the PAL_M preset section above.

`ld-decode` and `vhs-decode` frame-sequence conventions are documented in the informational notes in each preset section.

**Frame boundary and length integrity (normative):**

When a Signal State Preset requires locked timing at the standard 4x fsc sample rate (for example `tbc_applied = TRUE` and burst/colour lock sufficient to preserve sequence continuity), producers shall preserve frame boundaries and exact frame sample counts throughout the stream. For affected presets, each stored frame shall preserve the correct preset-specific frame progression, with no skipped frames, duplicated frames, or boundary shifts that would alter sequence alignment.

For these presets, the exact frame sample counts are:
- **PAL:** 709,379 samples/frame
- **NTSC:** 477,750 samples/frame
- **PAL_M:** 477,225 samples/frame

If a producer cannot guarantee this lock (for example because source skips, repeated source frames, dropouts in timing recovery, or other instability prevent reliable frame-to-frame sequence continuity), that producer shall not claim the corresponding locked preset constraints as normative for that content.

---

## Non-Standard Value Signaling

- **Declared non-standard values:** When `has_nonstandard_values = TRUE` in core metadata, consumers must allow non-standard sample values without treating them as automatic compliance errors.
- **Source-specific interpretation:** The metadata flag indicates presence only. The exact type, location, and semantics of non-standard content (for example PAL pilot bursts, NTSC additional bursts, or other anomalies) are source-specific and may be documented in `capture_notes` or a producer extension format.
- **Encoding interaction:** Depending on the declared Sample Encoding Preset and processing path, non-standard values may be preserved directly, quantized, or clipped before storage.
- **DC Offset:** Not required. The signed 16-bit storage format provides sufficient negative headroom below 0 to accommodate chroma excursions without clipping.


