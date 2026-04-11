# cvbs-file-format-specification

This repository contains the agreed common file format specification for representing decoded analogue video (CVBS — Colour, Video, Blank, and Sync) as used by [ld-decode](https://github.com/happycube/ld-decode), [vhs-decode](https://github.com/oyvindln/vhs-decode), and related tools in the decode family.

> **Documentation:** The full specification is published at **[simoninns.github.io/cvbs-file-format-specification](https://simoninns.github.io/cvbs-file-format-specification)**.

## Purpose

The CVBS file format replaces the previous `.tbc` (Time Base Corrected) format with an industry-standards-compliant specification based on:

- **SMPTE ST.0244** — for NTSC and PAL-M composite digital video
- **EBU Tech 3280** — for PAL composite digital video

The format stores 10-bit video samples as signed 16-bit little-endian integers, field-by-field, with no proprietary framing or headers. This makes it straightforward to process with standard broadcast tooling and ensures long-term interoperability.

## Key Features

- **Standards-compliant:** Signal levels, sampling rates, and field structures follow ST.0244 and EBU 3280 exactly
- **Headroom support:** The signed 16-bit storage provides negative and positive headroom beyond the nominal 10-bit range, accommodating signals such as LaserDisc PAL pilot bursts
- **Three file types:** Composite CVBS (`.composite`), luma (`.y`), and chroma (`.c`) for dual-file YC representations
- **Separate metadata:** An accompanying `.meta` SQLite file carries field-level metadata, dropout records, and colour field sequence information without contaminating the raw sample data

## Versioning

The latest [release](../../releases/latest) of this repository represents the current stable version of the specification. Any changes on the default branch between releases should be considered draft and subject to change.

## Specification

The full specification is in [docs/cvbs-file-format-specification.md](docs/cvbs-file-format-specification.md). It is divided into two parts:

- **Part 1 (Agreed):** File naming, sample encoding, field sizes, compliance tables, and field ordering — stable for implementation
- **Part 2 (Under Discussion):** Audio track storage and the metadata schema — subject to change
