# Architectural Decision Log (ADR)
**Project:** R35S Soy Sauce Tweaks

## ADR 001: Selection of dArkOSRE as Base OS
- **Context:** The original factory OS was outdated and prone to corruption. Official ArkOS images often fail on clones.
- **Decision:** Use dArkOSRE (Debian Trixie fork).
- **Rationale:** dArkOSRE was built specifically for clones (Y3506 family) and includes a modernized userspace (systemd, newer RetroArch).
- **Result:** Success, but required manual DTB intervention for Panel 1.

## ADR 002: Factory DTB Extraction vs. Official Variants
- **Context:** Official dArkOS variants for Soy Sauce V03 resulted in scrambled green stripes.
- **Decision:** Extract and inject the original factory `.dtb` from a working backup image.
- **Rationale:** Manufacturer-provided timings (`hsync-len = 0xda`) are the only stable source for Panel 1 clones. Official variants used generic `0x02` values.
- **Result:** Crystal clear image stability.

## ADR 003: The "Smart Patch" for White Screen Anomalies
- **Context:** The display would start white on boot, requiring a sleep/wake cycle to show an image.
- **Decision:** Implement regulator-driven power sequencing instead of manual msleep delays.
- **Rationale:** Removing `regulator-always-on` from the LCD power supply node forces the kernel to perform a controlled power-up sequence with a 50ms ramp delay, synchronizing voltage stabilization with driver initialization.
- **Result:** Perfect boot-up without standby hacks.

## ADR 004: Wi-Fi Identity Hack (RTL8188FU)
- **Context:** The Wi-Fi chip (Realtek 8188FU) was detected but the power management (rfkill) failed to initialize.
- **Decision:** Injected a `wireless-wlan` node with a hardware identity hack (`wifi_chip_type = "rtl8188fu"`).
- **Rationale:** Forcing the device model string to `Y3506_V03_20241104` triggers the dArkOS specialized driver loading logic for this specific clone family.
- **Result:** Diagnostic capability enabled; driver binding confirmed.

## ADR 005: Sentinel X-Ray Diagnostic Integration
- **Context:** Debugging hardware on a handheld without network or keyboard is difficult.
- **Decision:** Created a native systemd service (`sentinel-xray.service`).
- **Rationale:** Automated capture of `dmesg`, `lsusb`, and `ip link` at boot allows for "offline" debugging by simply reading a log file from the SD card on another computer.
- **Result:** Provided the crucial evidence needed to identify the RTL8188FU chip and RFKILL error.
