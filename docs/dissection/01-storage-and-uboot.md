# Engenharia Reversa: Layout de Armazenamento e U-Boot

## 1. Tabela de Partições (MBR)

A imagem do sistema `images/r35s_arkos_os.img` apresenta um erro clássico de "partição fora do disco" no `parted`. Isso ocorre porque a tabela de partições define uma terceira partição que se estende muito além do tamanho físico do arquivo da imagem.

### Dados do Arquivo:
- **Tamanho Real:** 9.438.333.440 bytes (8,79 GiB / 18.434.245 setores)
- **Disk identifier:** 0xc9f931c9

### Partições Definidas:

| Partição | Início (Setor) | Fim (Setor) | Tamanho | Tipo | Status |
|---|---|---|---|---|---|
| **BOOT** | 32.768 | 262.143 | 112M | FAT32 | Válida (incluída no .img) |
| **ROOT** | 262.144 | 18.434.244 | 8,7G | Linux (ext4) | Válida (incluída no .img) |
| **EASYROMS** | 18.434.245 | 184.342.527 | 79,1G | exFAT | **Truncada** (apenas o setor inicial existe no .img) |

**Nota técnica:** O setor final da partição 3 (184.342.527) exigiria um arquivo de ~94,4 GB. Como a imagem tem apenas 8,8 GB, a partição de ROMs é apenas um "marcador" na tabela de partições.

---

## 2. Espaço Bruto (Unallocated / Pre-BOOT)

O espaço entre o MBR (Setor 0) e o início da partição BOOT (Setor 32.768) contém dados vitais de inicialização específicos do SoC RK3326.

- **Setor 0:** Master Boot Record (Tabela de Partições).
- **Setores 1-63:** Reservado/Vazio.
- **Setor 64:** Início do carregador de inicialização (IDBlock/U-Boot).

---

## 3. Extração do U-Boot

Extraímos a região de 16MB que precede a partição BOOT para análise:

```bash
dd if=images/r35s_arkos_os.img of=/tmp/uboot.bin bs=512 skip=64 count=32704
```

### Análise de Strings:
*(Aguardando execução do Task 1 - Step 3)*

### Análise Binwalk:
*(Aguardando execução do Task 1 - Step 3)*
