# Signal State Preset Definitions

This document is part of the [CVBS File Format Specification](index.md). It contains the normative Signal State Preset definitions referenced in the [Signal State Presets](index.md#signal-state-presets) section of that specification.

**Naming convention:** Signal State Preset names follow the pattern `<RATE>_<TBC>_<LOCK>`, where `<RATE>` is `STANDARD` (4×fsc) or `NONSTANDARD`, `<TBC>` is `TBC` or `RAW`, and `<LOCK>` is `LOCKED` or `UNLOCKED`. The `RAW` state implies unlocked (a raw signal with no TBC cannot be burst-locked in a stable sense), so `<RATE>_RAW` presets do not include a `_LOCKED` / `_UNLOCKED` suffix.

A Signal State Preset captures three independent axes of the signal's processing state:

| Axis | Standard state | Non-standard state |
|---|---|---|
| Sample rate | Exactly 4×fsc for the declared Video Standard Preset | Non-standard (e.g., oversampled at 28.6 MHz or 40 MHz) |
| TBC applied | Yes — fixed samples per line, stable timing | No — line lengths vary, timing is raw |
| Burst locked | Yes — subcarrier phase is stable and known | No — subcarrier phase drifts or is unknown |

These axes are independent. In particular, a file can be TBC'd but not burst-locked (e.g., standard NTSC `.tbc` output from `ld-decode` or `vhs-decode`: timing is corrected but the subcarrier phase at each field is not anchored to a canonical 0° reference), and a file at a non-standard sample rate can still have TBC applied (oversampled TBC output).

The preset governs several aspects of format interpretation:

- **Normative field sizes** as defined by the declared Video Standard Preset in [video-standard-presets](video-standard-presets.md) apply only when `tbc_applied = TRUE` and the sample rate is the standard 4×fsc. Without TBC there is no guarantee of a fixed sample count per line, so consumers must not infer fixed per-field byte sizes from presets alone.
- **Signal level compliance** is only meaningful when `tbc_applied = TRUE` and the Sample Encoding Preset is `CVBS_U10_4FSC` or `CVBS_U16_4FSC`. A raw RF capture contains signal levels that bear no relation to the preset's reference sample values.
- **Sample-coordinate anomaly annotations** (for example dropout coordinates) are only stable when lines have a fixed, known length, i.e., when TBC has been applied. Such annotations are extension metadata, not part of the core schema.
- **Subcarrier phase analysis** requires knowing whether burst locking was applied so that consumers can determine whether phase continuity can be assumed between fields.

---

## Preset: `STANDARD_TBC_LOCKED`

| Property | Value |
|---|---|
| Sample rate | Standard 4×fsc for the declared Video Standard Preset |
| TBC applied | Yes |
| Burst locked | Yes |

**Typical source:** `cvbs-encode` synthetic output; broadcast-grade capture; `ld-decode` / `vhs-decode` PAL `.tbc` output when Sc/H locked.

**Normative field sizes:** Apply as defined by the declared Video Standard Preset in [video-standard-presets](video-standard-presets.md).

**Signal level compliance:** Required when Sample Encoding Preset is `CVBS_U10_4FSC` or `CVBS_U16_4FSC`.

**Extension anomaly annotations:** Valid and meaningful if an extension format provides them.

---

## Preset: `STANDARD_TBC_UNLOCKED`

| Property | Value |
|---|---|
| Sample rate | Standard 4×fsc for the declared Video Standard Preset |
| TBC applied | Yes |
| Burst locked | No |

**Typical source:** `ld-decode` / `vhs-decode` NTSC `.tbc` output — timing corrected but subcarrier phase not anchored to a canonical reference.

**Normative field sizes:** Apply as defined by the declared Video Standard Preset in [video-standard-presets](video-standard-presets.md).

**Signal level compliance:** Required when Sample Encoding Preset is `CVBS_U10_4FSC` or `CVBS_U16_4FSC`.

**Extension anomaly annotations:** Valid and meaningful if an extension format provides them.

---

## Preset: `STANDARD_RAW`

| Property | Value |
|---|---|
| Sample rate | Standard 4×fsc for the declared Video Standard Preset |
| TBC applied | No |
| Burst locked | No |

**Typical source:** A signal sampled at the standard rate but without time-base correction applied — e.g., a synchronous ADC capture at the standard 4×fsc rate before any TBC processing.

**Normative field sizes:** Do not apply.

**Signal level compliance:** Not required.

**Extension anomaly annotations:** Per-line/sample coordinates are generally not stable and should not be emitted.

---

## Preset: `NONSTANDARD_TBC_LOCKED`

| Property | Value |
|---|---|
| Sample rate | Non-standard (e.g., 28.6 MHz, 40 MHz) |
| TBC applied | Yes |
| Burst locked | Yes |

**Typical source:** Oversampled TBC output; a burst-locked TBC applied after raw oversampled capture.

**Normative field sizes:** Do not apply at field sample counts defined for standard 4×fsc presets in [video-standard-presets](video-standard-presets.md).

**Signal level compliance:** Not applicable for standard-mapped CVBS amplitude values at non-standard sample rates; consumers must use calibration data to map sample values to analogue levels.

**Extension anomaly annotations:** Valid (sample coordinates are stable because TBC was applied), but coordinates reference samples at the non-standard sample rate.

---

## Preset: `NONSTANDARD_TBC_UNLOCKED`

| Property | Value |
|---|---|
| Sample rate | Non-standard (e.g., 28.6 MHz, 40 MHz) |
| TBC applied | Yes |
| Burst locked | No |

**Typical source:** Oversampled TBC output where subcarrier phase is not stabilised.

**Normative field sizes:** Do not apply.

**Signal level compliance:** Not applicable.

**Extension anomaly annotations:** Valid for stable sample coordinate references.

---

## Preset: `NONSTANDARD_RAW`

| Property | Value |
|---|---|
| Sample rate | Non-standard (e.g., 28.6 MHz, 40 MHz) |
| TBC applied | No |
| Burst locked | No |

**Typical source:** DomesdayDuplicator raw RF capture; raw ADC output at any non-standard rate.

**Normative field sizes:** Do not apply.

**Signal level compliance:** Not applicable.

**Extension anomaly annotations:** Per-line/sample coordinates are generally not stable and should not be emitted.
