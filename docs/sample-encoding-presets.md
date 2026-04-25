# Sample Encoding Preset Definitions

This document is part of the [CVBS File Format Specification](index.md). It contains the normative Sample Encoding Preset definitions referenced in the [Sample Encoding Presets](index.md#sample-encoding-presets) section of that specification.

**Naming convention:** Sample Encoding Preset names use only uppercase ASCII letters, digits, and underscores. Names derived from a broadcast standard use the format `CVBS_<ENCODING>`; names for raw hardware captures use the format `RAW_<FORMAT>_<RATE>`.

---

## Preset: `CVBS_10BIT`

**Applicable sources:** Standards-compliant output of `ld-decode`, `vhs-decode`, `cvbs-encode`, and similar tools targeting EBU 3280 or SMPTE ST.0244.

**Word format:** Each sample is stored as a **signed 16-bit little-endian integer**. The unsigned 10-bit value (0–1023) maps directly into the signed 16-bit range such that 10-bit value 0 equals signed 16-bit value 0 and 10-bit value 1023 equals signed 16-bit value 1023.

- **Negative headroom:** Signed 16-bit values below 0 (down to −32768) are available for chroma excursions below the sync tip or other sub-zero signal content.
- **Positive headroom:** Signed 16-bit values above 1023 (up to 32767) are available for signal excursions above the peak level.

This encoding is known as the **cvbs-encode** encoding.

**Amplitude mapping:** The sync tip, blanking, black, white, and peak 10-bit sample values are defined by the declared Video Standard Preset. The sample level tables in [video-standard-presets](video-standard-presets.md) are the normative reference values for this encoding.

**Protected values:** The bottom of the 10-bit range (values 0–3) and the top (values 1020–1023) are reserved (must never appear in conformant output). These exclusions are defined per Video Standard Preset.

---

## Preset: `RAW_S16_28MSPS`

**Applicable sources:** CX Cards and similar hardware capturers operating at approximately 28.6 MHz.

**Word format:** Each sample is stored as a **signed 16-bit little-endian integer**. Values span the full signed 16-bit range (−32768 to +32767) and represent the raw, unscaled ADC output of the capturing hardware.

**Sample rate:** The nominal sample rate for this preset is **28,636,360 Hz** (= 2 × 14,318,180 Hz, twice the NTSC colour subcarrier frequency). The exact rate may differ slightly between hardware units.

**Amplitude mapping:** No standardised mapping between stored values and analogue voltage levels is defined at the preset level. The relationship between the integer range and the analogue signal levels (sync, blanking, black, white) depends on the hardware gain and DC offset settings at the time of capture. Consumers must derive or externally supply this calibration information.

**Signal level compliance:** Signal level compliance is not meaningful for this preset. Signal levels bear no fixed relationship to the reference values defined by the Video Standard Preset.

---

## Preset: `RAW_S16_40MSPS`

**Applicable sources:** DomesdayDuplicator and similar hardware capturers configured for a 40 MHz capture rate.

**Word format:** Each sample is stored as a **signed 16-bit little-endian integer**. Values span the full signed 16-bit range (−32768 to +32767) and represent the raw, unscaled ADC output of the capturing hardware.

**Sample rate:** The nominal sample rate for this preset is **40,000,000 Hz** (40 MHz). 

**Amplitude mapping:** No standardised mapping between stored values and analogue voltage levels is defined at the preset level. Calibration information must be derived or externally supplied by the consumer.

**Signal level compliance:** Signal level compliance is not meaningful for this preset.

**TBC and burst locking:** Files using this preset will normally have the Signal State Preset `NONSTANDARD_RAW`.

---

## Preset: `SWTPG21_10BIT`

**Applicable sources:** Snell & Wilcox TPG21 test pattern generator and compatible equipment producing 10-bit CVBS output files.

**Word format:** Each sample is stored as an **unsigned 16-bit little-endian integer**. The 10-bit sample value (0–1023) is placed in the **most-significant bits** of the 16-bit word (bits 15–6), with the **six least-significant bits set to zero** (LSB-padded). The stored 16-bit value is therefore the 10-bit value multiplied by 64 (i.e. left-shifted by 6):

$$
\text{uint16} = \text{value}_{10\text{-bit}} \times 64
$$

To recover the original 10-bit sample value, right-shift the unsigned 16-bit word by 6:

$$
\text{value}_{10\text{-bit}} = \lfloor \text{uint16} / 64 \rfloor
$$

- **Unsigned container:** Values are unsigned; the 16-bit range is 0–65535. Negative headroom (e.g. for sub-sync-tip excursions) is not representable in this format.
- **Maximum encoded value:** The highest legal 10-bit value (1023) is stored as 65472 (= 1023 × 64).

**Amplitude mapping:** The sync tip, blanking, black, white, and peak 10-bit sample values are defined by the declared Video Standard Preset. The sample level tables in [video-standard-presets](video-standard-presets.md) are the normative reference values, interpreted in the 10-bit domain before applying the MSB-alignment scaling described above.

**Signal level compliance:** Signal level compliance applies to this preset. The protected exclusion ranges at the bottom (values 0–3) and top (values 1020–1023) of the 10-bit domain remain reserved, corresponding to stored uint16 values 0–192 and 65280–65472 respectively.
