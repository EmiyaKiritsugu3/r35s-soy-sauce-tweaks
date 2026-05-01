# Engenharia Reversa: Root Filesystem e Serviços Systemd

## 1. Mapeamento de Serviços Críticos

O sistema operacional (baseado em Ubuntu 18.04/20.04 modificado) utiliza o `systemd` para gerenciar o hardware e a interface.

### Orquestração de Boot (`351mp.service`)
Este serviço é do tipo `oneshot` e roda scripts essenciais assim que o sistema atinge o `multi-user.target`:
- **`fix_power_led`**: Controla o LED frontal. Originalmente para o RG351MP (GPIO 77), mas agora modificado por nós para suportar o R35S (GPIO 0 e 5).
- **`checkbrightonboot`**: Verifica se o brilho está muito baixo (menor que 2) e força para 45.
- **`fixvolume.sh`**: Força o caminho de áudio para `SPK_HP` (Speaker/Headphones) usando `amixer`.

### O Fix do Áudio (`audio-resume.service`)
O chip de áudio **RK817-1A** possui um erro de design/driver que impede sua inicialização correta em alguns boots.
- **Estratégia:** O script `audio-fix.sh` executa `rtcwake -m mem -s 1`. Isso coloca o sistema em suspensão profunda por 1 segundo e acorda. O ciclo de energia parcial reseta o chip de áudio, permitindo que os comandos `amixer` funcionem em seguida.

---

## 2. Interface e Controle (`emulationstation.service`)

O EmulationStation não inicia diretamente o binário. Ele usa um script wrapper: `/usr/bin/emulationstation/emulationstation.sh`.

### Detecção Dinâmica de Hardware:
O script verifica `/dev/input/by-path/` para identificar o console:
- `anbernic`: Se encontrar o joystick USB.
- `oga`: Se encontrar o joypad nativo e o config de input bater com o ID do OGA.
- `ogs`: Se encontrar o joypad do Odroid Go Super.
- `chi`: Fallback para o GameShell/ClockworkPi.

### O Menu "BaRT" (Boot and Recovery Tools):
Descobrimos que se o usuário segurar o botão **BTN_SOUTH** (Botão A ou B dependendo do layout) durante o boot, o script esconde o splash screen e abre um menu de recuperação em modo texto (`dialog`) no `/dev/tty1`.

---

## 3. Scripts de Performance e Hotkeys

### `oga_events`
Serviço que monitora eventos de baixo nível do kernel (`evdev`). É responsável por traduzir combinações de botões em comandos do sistema (Volume +/-, Brilho, Kill Process).

### Governador de CPU:
O serviço `ondemand.service` (padrão Linux) é frequentemente sobrescrito por scripts como `perfmax` (roda no lançamento de emuladores pesados) e `perfnorm` (roda ao voltar para o menu).
