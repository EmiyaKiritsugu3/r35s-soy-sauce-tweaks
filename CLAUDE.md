# R35S Soy Sauce Tweaks — Contexto do Projeto

## O que é este projeto
Engenharia reversa e otimização do handheld **R35S (Clone Soy Sauce V03)**.
O projeto utiliza o **Sentinel Sovereign Protocol** para garantir integridade arquitetural e documentação de elite.

- **Motherboard:** Y3506_V03
- **LCD:** Elida KD35T133 (Panel 1) com controlador HX8394F.
- **WiFi:** Realtek 8188FU (Internal USB).
- **OS Atual:** **dArkOSRE** (Debian Trixie / Kernel 4.4.189).
- **SD Card:** 87,9 GB (Fake capacity 128GB).

---

## ⚡ ESTADO ATUAL (2026-05-03) - MASTERED
O sistema está 100% funcional, estabilizado e documentado.

### Conquistas desta sessão [PID-SENTINEL]:
1. **Restauração dArkOSRE:** Instalado e bootando com imagem cristalina.
2. **Factory DTB Injection:** Resolvemos as faixas verdes usando o DTB original de fábrica extraído do backup.
3. **Smart Patch (Boot Fix):** Corrigimos o bug da "Tela Branca" via gestão de energia do `LDO_REG8` (50ms ramp delay) em vez de delays manuais.
4. **WiFi Breakthrough:** Chip identificado como RTL8188FU. Aplicado "Identity Hack" no DTB (`model="Y3506_V03_20241104"`) para forçar o carregamento dos drivers.
5. **Sentinel X-Ray:** Diagnóstico nativo integrado ao OS, salvando logs em `/boot/SENTINEL_DIAGNOSTIC.log`.

---

## 📂 Documentação de Referência (MANDATÓRIO LER)
Qualquer nova AI deve consultar estes arquivos antes de agir:

- **[RECOVERY-GUIDE.md](docs/RECOVERY-GUIDE.md):** Manual de restauração rápida e gestão do cartão falso.
- **[HARDWARE-MAP.md](docs/HARDWARE-MAP.md):** Mapa de registros (Base Addr), IRQs e GPIOs.
- **[ARCHITECTURAL-DECISIONS.md](docs/ARCHITECTURAL-DECISIONS.md):** O "Porquê" de cada patch aplicado.
- **[REFERENCE.md](docs/REFERENCE.md):** A Bíblia do hardware Soy Sauce V03.
- **[sentinel-log.md](docs/process/sentinel-log.md):** Histórico detalhado de todas as manobras.

---

## 🛠️ Procedimentos de Elite

### Flashing & Safepoints
Para restaurar o baseline funcional:
```bash
bash flash_darkos.sh
```
Imagem Safepoint disponível em: `images/dArkOSRE_R35S_V03_Safepoint_20260503.img` (11GB).

### Injeção de DTB (mtools)
Sempre use `mtools` para evitar problemas de cache do Linux:
```bash
sudo mcopy -o -i /dev/sdb1 my_patched.dtb ::/rk3326-r36s-linux.dtb
```

---

## 👨‍🔬 Technical Ground Truth
- **HSync Length:** Deve ser **0xda** (218). Valores oficiais do dArkOS (0x02) causam faixas verdes.
- **U-Boot DTB:** Deve ser `rg351v-uboot.dtb` compatível com a família Soy Sauce.
- **WiFi Power:** Controlado pelo `LDO_REG9` e `GPIO1_C1`.

---
*Mantido sob o Protocolo Sentinel Sovereign pela Gemini Architecture Engine.*
