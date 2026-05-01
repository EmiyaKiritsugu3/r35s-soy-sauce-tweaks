# Engenharia Reversa: Partição BOOT, Kernel e Initramfs

## 1. Configuração do Boot (`boot.ini`)

O arquivo `boot.ini` na partição BOOT (sdb1) é processado pelo U-Boot. Ele define os argumentos do kernel e a ordem de carregamento.

### Argumentos do Kernel (`bootargs`):
```bash
root=UUID='e139ce78-9841-40fe-8823-96a304a09859' rootwait rw fsck.repair=yes net.ifnames=0 fbcon=rotate:0 console=/dev/ttyFIQ0 quiet splash plymouth.ignore-serial-consoles consoleblank=0
```
- **`root=UUID=...`**: Diferente do hardcoded no binário do U-Boot, aqui ele usa UUID para identificar a partição ROOT.
- **`fbcon=rotate:0`**: Define a rotação do console de framebuffer.
- **`quiet splash`**: Esconde as mensagens de boot em favor de um splash screen (Plymouth).

### Endereços de Carga na RAM:
- **Kernel (`loadaddr`):** `0x02000000`
- **Initrd (`initrd_loadaddr`):** `0x01100000`
- **DTB (`dtb_loadaddr`):** `0x01f00000`

---

## 2. Análise do Kernel (`Image`)

O kernel é um binário ARM64 (AArch64).

- **Versão:** `Linux version 4.4.189 (dev@rk3326) (gcc version 7.3.1 20180425)`
- **Data de compilação:** `Wed Jan 22 20:19:30 CST 2025` (Binário muito recente!)
- **Drivers identificados via strings:**
  - `ext4`: Suporte nativo e robusto.
  - `simple-panel-dsi`: Driver que controla o LCD e (indiretamente) os LEDs que corrigimos.
  - `rk817`: Suporte ao PMIC e codec de áudio (alvo do `audio-fix.sh`).
  - **Ausência de `btrfs`**: Confirmado que o kernel original não suporta o sistema de arquivos do dArkOS sem modificações.

---

## 3. Dissecação do Initramfs (`uInitrd`)

O `uInitrd` é um arquivo comprimido em **LZ4** contendo um arquivo **cpio**.

### Estrutura Interna:
- **Base:** Debian/Ubuntu `initramfs-tools`.
- **Scripts:** Segue o padrão `/scripts/local` para montagem de dispositivos locais.
- **Fluxo de Inicialização:**
  1. Carrega módulos básicos.
  2. Identifica o dispositivo ROOT via UUID (especificado no `boot.ini`).
  3. Executa `fsck` se necessário.
  4. Monta o ROOT real em `/root`.
  5. Executa `switch_root` para passar o controle ao `systemd` da partição ROOT.

---

## 4. Arquivos DTB Adicionais
A partição BOOT contém vários DTBs para diferentes dispositivos, sugerindo que a mesma imagem é usada para múltiplos clones:
- `rk3326-r35s-linux.dtb` (O que estamos usando/corrigindo)
- `rk3326-rg351mp-linux.dtb`
- `rg351p-kernel.dtb`
