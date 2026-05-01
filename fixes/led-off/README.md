# Fix: Front LED always on

## Symptom

On the R35S (Clone R36S Soy Sauce), the front LED stays **permanently lit** — even
after the device finishes booting and EmulationStation is running.

## Root cause

The DTB panel node (`rk3326-r35s-linux.dtb`) declares two LED GPIOs inside the
`simple-panel-dsi` display node:

```dts
panel@0 {
    led-blue1-gpios = <&gpio0 0 GPIO_ACTIVE_HIGH>;  /* GPIO0_A0 */
    led-red-gpios   = <&gpio0 5 GPIO_ACTIVE_HIGH>;  /* GPIO0_A5 */
    ...
};
```

The panel driver asserts these pins **HIGH** when it initialises the display, and
never clears them.  The `gpio_leds` node is `status = "disabled"`, so
`/sys/class/leds/` is empty — there is no runtime LED API to use.

## Fix

A systemd one-shot service (`led-off.service`) runs after `multi-user.target`,
drives GPIO0_A0 and GPIO0_A5 **LOW** via the sysfs GPIO interface, and stays
resident so the pins are not reclaimed.

```
Power on → display init (LEDs turn ON) → boot → multi-user.target → led-off (LEDs turn OFF)
```

The LED is still lit during boot, which is useful as a power/activity indicator.

## Files

| File | Purpose |
|------|---------|
| `led-off.sh` | Shell script that exports and drives LOW GPIO 0 and GPIO 5 |
| `led-off.service` | systemd unit that runs `led-off.sh` after `multi-user.target` |
| `install.sh` | Installer — works on a live device or directly into a `.img` file |

## Installation

### Option A — On the running device (SSH or serial)

```bash
git clone https://github.com/EmiyaKiritsugu3/r35s-soy-sauce-tweaks.git
cd r35s-soy-sauce-tweaks/fixes/led-off
sudo bash install.sh
```

### Option B — Inject into a ROOT partition image (from PC, no sudo on device)

Requires `debugfs` (`e2fsprogs` package):

```bash
bash install.sh --image /path/to/root_partition.img
```

Then flash the updated image to sdb2 and boot normally.

## GPIO reference (RK3326)

| sysfs number | DTB name | Colour | Bank formula |
|---|---|---|---|
| 0 | GPIO0_A0 | Blue | 0×32 + 0 |
| 5 | GPIO0_A5 | Red  | 0×32 + 5 |

Formula: `sysfs_num = bank * 32 + (group_letter - 'A') * 8 + pin`
