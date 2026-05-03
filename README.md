# R35S Soy Sauce Elite Tweaks 💎🎮
**Elite Engineering Project for Clone Handheld Handhelds**

This project documents the journey of restoring and optimizing a **Soy Sauce V03 (Panel 1)** handheld using **dArkOSRE**. It features advanced kernel-level patching, diagnostic automation, and architectural governance.

## 🚀 Quick Navigation
- **[RECOVERY GUIDE](docs/RECOVERY-GUIDE.md)**: "Break Glass" instructions for SD card failure.
- **[HARDWARE BIBLE](docs/REFERENCE.md)**: Deep technical specs (HSync, GPIOs, Power).
- **[ARCHITECTURAL DECISIONS (ADR)](docs/ARCHITECTURAL-DECISIONS.md)**: The "Why" behind every technical choice.
- **[SENTINEL LOG](docs/process/sentinel-log.md)**: Session-by-session history.

## 🛠️ Key Achievements
1. **Perfect Display Restoration**: Fixed scrambled green stripes by identifying the `0xda` HSync requirement.
2. **Smart Boot Logic**: Eliminated the "White Screen" anomaly via regulator-driven power sequencing (ADR 003).
3. **Automated Diagnostics**: Integrated `Sentinel X-Ray` to capture low-level system logs automatically (ADR 005).
4. **WiFi Breakthrough**: Confirmed **RTL8188FU** support via identity hacking (ADR 004).
5. **Data Integrity**: Established a 11GB Golden Safepoint for rapid restoration.

## 👨‍🔬 Technical Context
- **Motherboard**: Y3506_V03
- **LCD**: Elida KD35T133 (Panel 1)
- **OS**: dArkOSRE (Debian Trixie / Kernel 4.4.189)

---
*Maintained under the Sentinel Sovereign Protocol.*
