# Signal State Preset Definitions

This document is part of the [CVBS File Format Specification](cvbs-file-format-specification.md). It contains the normative Signal State Preset definitions referenced in Section 7 of that specification.

**Naming convention:** Signal State Preset names follow the pattern `<RATE>_<TBC>_<LOCK>`, where `<RATE>` is `STANDARD` (4×fsc) or `NONSTANDARD`, `<TBC>` is `TBC` or `RAW`, and `<LOCK>` is `LOCKED` or `UNLOCKED`. The `RAW` state implies unlocked (a raw signal with no TBC cannot be burst-locked in a stable sense), so `<RATE>_RAW` presets do not include a `_LOCKED` / `_UNLOCKED` suffix.

---

## Preset: `STANDARD_TBC_LOCKED`

| Property | Value |
|---|---|
| Sample rate | Standard 4×fsc for the declared Video Standard Preset |
| TBC applied | Yes |
| Burst locked | Yes |

**Typical source:** `cvbs-encode` synthetic output; broadcast-grade capture; `ld-decode` / `vhs-decode` PAL `.tbc` output when Sc/H locked.

**Normative field sizes:** Apply as defined in Section 4.2.

**Signal level compliance:** Required (Section 3.1) when Sample Encoding Preset is `CVBS_10BIT`.

**`sample_flags`:** Valid and meaningful.

**`sc_h_phase_degrees`:** Should be populated if the Sc/H phase is known.

---

## Preset: `STANDARD_TBC_UNLOCKED`

| Property | Value |
|---|---|
| Sample rate | Standard 4×fsc for the declared Video Standard Preset |
| TBC applied | Yes |
| Burst locked | No |

**Typical source:** `ld-decode` / `vhs-decode` NTSC `.tbc` output — timing corrected but subcarrier phase not anchored to a canonical reference.

**Normative field sizes:** Apply as defined in Section 4.2.

**Signal level compliance:** Required (Section 3.1) when Sample Encoding Preset is `CVBS_10BIT`.

**`sample_flags`:** Valid and meaningful.

**`sc_h_phase_degrees`:** `NULL` (phase is not stably known field-to-field).

---

## Preset: `STANDARD_RAW`

| Property | Value |
|---|---|
| Sample rate | Standard 4×fsc for the declared Video Standard Preset |
| TBC applied | No |
| Burst locked | No |

**Typical source:** A signal sampled at the standard rate but without time-base correction applied — e.g., a synchronous ADC capture at the standard 4×fsc rate before any TBC processing.

**Normative field sizes:** Do not apply; use `byte_offset` / `byte_count` from `field_record`.

**Signal level compliance:** Not required.

**`sample_flags`:** Should be left empty.

---

## Preset: `NONSTANDARD_TBC_LOCKED`

| Property | Value |
|---|---|
| Sample rate | Non-standard (e.g., 28.6 MHz, 40 MHz) |
| TBC applied | Yes |
| Burst locked | Yes |

**Typical source:** Oversampled TBC output; a burst-locked TBC applied after raw oversampled capture.

**Normative field sizes:** Do not apply at field sample counts defined in Section 4.2 (those assume the standard 4×fsc rate). Field sizes must be derived from `byte_offset` / `byte_count` in `field_record`, or computed from the non-standard sample rate.

**Signal level compliance:** Not applicable for `CVBS_10BIT` amplitude values; consumers must use calibration data to map sample values to analogue levels.

**`sample_flags`:** Valid (sample coordinates are stable because TBC was applied), but `startx` / `endx` values reference samples at the non-standard sample rate.

**`sample_rate_numerator` / `sample_rate_denominator`:** Should be populated.

**`sc_h_phase_degrees`:** Should be populated if the Sc/H phase is known.

---

## Preset: `NONSTANDARD_TBC_UNLOCKED`

| Property | Value |
|---|---|
| Sample rate | Non-standard (e.g., 28.6 MHz, 40 MHz) |
| TBC applied | Yes |
| Burst locked | No |

**Typical source:** Oversampled TBC output where subcarrier phase is not stabilised.

**Normative field sizes:** Do not apply; use `byte_offset` / `byte_count` from `field_record`.

**Signal level compliance:** Not applicable.

**`sample_flags`:** Valid for stable sample coordinate references.

**`sample_rate_numerator` / `sample_rate_denominator`:** Should be populated.

**`sc_h_phase_degrees`:** `NULL`.

---

## Preset: `NONSTANDARD_RAW`

| Property | Value |
|---|---|
| Sample rate | Non-standard (e.g., 28.6 MHz, 40 MHz) |
| TBC applied | No |
| Burst locked | No |

**Typical source:** DomesdayDuplicator raw RF capture; raw ADC output at any non-standard rate.

**Normative field sizes:** Do not apply; use `byte_offset` / `byte_count` from `field_record` if known. When field boundaries are not known, the consumer must treat the file as an unsegmented stream.

**Signal level compliance:** Not applicable.

**`sample_flags`:** Should be left empty.

**`sample_rate_numerator` / `sample_rate_denominator`:** Should be populated.
