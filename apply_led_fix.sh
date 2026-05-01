#!/bin/bash
# Integra o fix do LED frontal ao sistema existente do ArkOS
# Modifica fix_power_led e batt_life_warning.py no sistema montado
# Execute: sudo bash apply_led_fix.sh

set -e

MNT="$(cd "$(dirname "$0")" && pwd)/mnt/rootfs"

[ -d "$MNT/usr/local/bin" ] || { echo "ERRO: imagem não montada. Execute: sudo bash mount.sh"; exit 1; }

echo "[1/2] Atualizando fix_power_led..."
cat > "$MNT/usr/local/bin/fix_power_led" << 'EOF'
#!/bin/bash
# GPIO 77 (GPIO2_B5) — LED padrão ODROID-GO2/RG351
sudo chmod 777 /sys/class/gpio/export
echo 77 > /sys/class/gpio/export
sudo chmod 777 /sys/class/gpio/gpio77/direction
sudo echo out > /sys/class/gpio/gpio77/direction
sudo chmod 777 /sys/class/gpio/gpio77/value
echo 1 > /sys/class/gpio/gpio77/value

# GPIO 0 (GPIO0_A0) e GPIO 5 (GPIO0_A5) — LEDs frontais do R35S (Clone R36S Soy Sauce)
# O driver simple-panel-dsi os seta HIGH ao inicializar o display e nunca os limpa
for gpio in 0 5; do
    echo $gpio > /sys/class/gpio/export 2>/dev/null || true
    sleep 0.05
    echo out > /sys/class/gpio/gpio${gpio}/direction
    echo 0   > /sys/class/gpio/gpio${gpio}/value
done
EOF
chmod 755 "$MNT/usr/local/bin/fix_power_led"

echo "[2/2] Atualizando batt_life_warning.py..."
cat > "$MNT/usr/local/bin/batt_life_warning.py" << 'EOF'
#!/usr/bin/env python3

import os
import time

batt_life = "/sys/class/power_supply/battery/capacity"

# GPIO 77 = LED padrão ODROID-GO2/RG351
# GPIO 0  = LED frontal azul do R35S (GPIO0_A0, acionado pelo panel driver)
# GPIO 5  = LED frontal vermelho do R35S (GPIO0_A5, acionado pelo panel driver)
LED_GPIOS = [77, 0, 5]


def led_set(value: str):
    for gpio in LED_GPIOS:
        path = f"/sys/class/gpio/gpio{gpio}/value"
        if os.path.exists(path):
            try:
                open(path, "w").write(value)
            except OSError:
                pass


def led_get() -> str:
    path = f"/sys/class/gpio/gpio{LED_GPIOS[0]}/value"
    try:
        return open(path).read().strip()
    except OSError:
        return "1"


while True:
    try:
        level = int(open(batt_life).read())
    except OSError:
        time.sleep(30)
        continue

    if level <= 10:
        led_set("0" if led_get() == "1" else "1")
        time.sleep(1)
    elif level <= 20:
        led_set("0" if led_get() == "1" else "1")
        time.sleep(10)
    else:
        if led_get() == "0":
            led_set("1")
        time.sleep(30)
EOF
chmod 755 "$MNT/usr/local/bin/batt_life_warning.py"

echo ""
echo "=== Fix integrado com sucesso ==="
echo "  fix_power_led     → desliga GPIOs 0 e 5 no boot"
echo "  batt_life_warning → pisca GPIOs 0, 5 e 77 quando bateria baixa"
echo ""
echo "Próximo passo: sudo bash mount.sh umount"
