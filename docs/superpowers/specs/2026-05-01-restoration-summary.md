# Relatório Final: Instalação dArkOS4Clone (R36S Sauce Panel 1)

**Data:** 01 de Maio de 2026  
**Status:** Sucesso (Boot OK)  
**Hardware:** R36S (Identificado como Panel 1)  
**Armazenamento:** SD Card 128GB (Falsificado/Capacidade Real Incerta)

---

## 1. Processo de Preparação

### Flash da Imagem
- **Imagem utilizada:** `dArkOS4Clone` (Build baseada em ArkOS para clones).
- **Procedimento:** Escrita via `dd` no dispositivo `/dev/sdb`.
- **Resultado:** Partições criadas:
  - `BOOT` (FAT32, ~112MB)
  - `ROOTFS` (BTRFS, ~8GB)
  - `EASYROMS` (FAT32, Restante do disco)

### Injeção de Hardware (Cirurgia DTB)
Para garantir a compatibilidade com a tela do **R36S Panel 1**, os seguintes arquivos foram extraídos da pasta `/consoles/sauce panel1/` e movidos para a raiz da partição `BOOT`:
- `rk3326-r36s-sauce-panel1-linux.dtb` (DTB específico do hardware)
- `boot.ini` (Configuração de boot apontando para o DTB acima)
- `Image` (Kernel Linux extraído de `/consoles/kernel/common/`)

---

## 2. Proteção Anti-Corrupção (SD Falsificado)

Devido ao cartão SD ser identificado como falso (reporta 128GB mas possui menos capacidade real), foram aplicadas travas manuais para impedir a auto-expansão do sistema, que corromperia o cartão:

1.  **Sinalizador `doneit`:** Criado um arquivo vazio na raiz do boot. Isso faz o sistema acreditar que a expansão de partições já foi concluída com sucesso.
2.  **Desativação do Script de Expansão:** O script `/boot/expandtoexfat.sh` foi renomeado para `expandtoexfat.sh.bak`. Isso impede fisicamente a execução do redimensionamento.

---

## 3. Estado Atual dos Emuladores e ROMs

### Por que a lista está vazia?
- **Filtro do ArkOS:** O sistema esconde emuladores que não possuem arquivos nas respectivas pastas.
- **Instalação Limpa:** Como o cartão foi formatado, os jogos originais foram removidos.
- **Estrutura de Pastas:** A árvore de pastas em `EASYROMS` (ex: `gba/`, `snes/`, `psx/`) já está presente, porém vazia.

---

## 4. Próximos Passos: Restauração de Backup

O backup das ROMs originais está localizado em:
`../../../../run/media/emiyakiritsugu/726EC5436EC50139/R35S_Backup/roms_partition.img`

### Estratégia de Restauração Sugerida:
1.  **Montar a imagem de backup** em modo leitura.
2.  **Selecionar sistemas prioritários** (GBA, SNES, PS1) para não exceder a capacidade real do cartão (recomendado manter abaixo de 20GB totais).
3.  **Copiar seletivamente** os arquivos para a partição `EASYROMS` do novo SD.

---

## 5. Verificação de Arquivos (Checklist de Finalização)

| Arquivo | Localização | Status |
|---------|-------------|--------|
| `rk3326-r36s-sauce-panel1-linux.dtb` | /BOOT/ | Presente ✓ |
| `boot.ini` (Panel 1 config) | /BOOT/ | Presente ✓ |
| `Image` (Kernel) | /BOOT/ | Presente ✓ |
| `doneit` (Anti-expansion) | /BOOT/ | Presente ✓ |
| `expandtoexfat.sh.bak` | /BOOT/ | Presente ✓ |
| `mnt/new_roms/gba` (exemplo) | /EASYROMS/ | Presente (Vazio) ✓ |

---
**Fim do Relatório.** O console está funcional e seguro contra corrupção automática.
