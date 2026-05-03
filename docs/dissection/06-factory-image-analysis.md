# Relatório de Análise: Backup de Fábrica (128GB Truncado)

Este documento registra as descobertas feitas ao analisar a imagem original de 128GB (`r35s_backup_completo.img`) que veio no console e funciona 100%.

## ⚠️ Diagnóstico da Imagem
- **Tamanho Real:** 4.5 GB (Truncada). 
- **Impacto:** A imagem contém apenas a partição BOOT e o início da ROOTFS. A partição de ROMs e o restante do sistema estão ausentes devido a uma cópia incompleta no passado.
- **Aproveitamento:** A partição BOOT está 100% íntegra, o que nos permitiu extrair o DNA original do hardware.

## 🧬 Descobertas de Hardware (Ground Truth)

### 1. Painel de LCD (O "Coração" do Problema)
- **Modelo:** `elida,kd35t133`
- **Driver:** `simple-panel-dsi`
- **Timings Originais:**
  - `hsync-len = 120 (0x78)`
  - `hfront-porch = 120 (0x78)`
  - `hback-porch = 120 (0x78)`
- **Conclusão:** Qualquer DTB que use valores genéricos de `simple-panel` (como 218 ou 240) resultará em tela preta ou cintilante.

### 2. Controle de LED (O "Inimigo" Silencioso)
- **Mapeamento:** 
  - `led-red-gpios`: Banco `0x59`, Pino `5` (GPIO0_A5)
  - `led-blue1-gpios`: Banco `0x59`, Pino `0` (GPIO0_A0)
- **Comportamento:** O driver de vídeo original (panel-simple) é quem liga esses LEDs durante a inicialização da tela.

### 3. Boot Chain
- **Arquivo:** `rk3326-r35s-linux.dtb`
- **Kernel:** Linux versão 4.4.189 (Build 2025).
- **Parâmetros:** `quiet splash` ativos por padrão.

## 🛠 Arquivos Preservados no Projeto
Os seguintes arquivos foram extraídos e salvos em `docs/dissection/factory/` e `dtb/factory/`:
- `factory_boot.ini`: Configuração de boot original.
- `rk3326-r35s-linux.dtb`: Binário original de fábrica.
- `rk3326-r35s-linux.dts`: Código-fonte descompilado do hardware original.

## 🚀 Guia para o Desenvolvimento Futuro
1.  **Sempre use os timings do Elida:** Não tente "otimizar" a resolução ou o refresh rate sem usar o `hsync-len = 120` como base.
2.  **Patching via DTS:** Em vez de scripts bash, a forma "Elite" de desligar o LED é remover os nós `led-*-gpios` do DTS e recompilar, como fizemos na Operação Frankenstein.
3.  **Monitoramento de SD:** O fato de a imagem original ter sido corrompida reforça a necessidade do **Sentinel: SD Canary** para monitorar a integridade do chip falso.

---
*Relatório gerado pelo Gemini Architecture Engine em 2026-05-02.*
