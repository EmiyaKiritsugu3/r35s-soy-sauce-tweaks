# Engenharia Reversa: Hardware, Fixes e Binários

## 1. Gestão de Performance (`perfmax` / `perfnorm`)

O ArkOS possui um sistema agressivo de gestão de energia e performance para extrair o máximo do SoC RK3326.

### Estratégia de Overclock/Boost:
Ao iniciar um jogo (`perfmax`), o sistema não apenas muda o governador da CPU, mas ataca três frentes:
1. **CPU**: Altera `/sys/devices/system/cpu/cpufreq/policy0/scaling_governor` para `performance`.
2. **GPU (Mali-G31)**: Altera `/sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor` para `simple_performance`.
3. **DMC (Dynamic Memory Controller)**: Força a latência da RAM ao mínimo alterando o governador em `/sys/devices/platform/dmc/devfreq/dmc/governor`.

### Splash Screens Customizados:
Descobrimos uma funcionalidade de "Loading Screen" baseada em arquivos ocultos:
- Se existir `~/.config/.GameLoadingIModeASCII`, ele exibe arte ASCII no `/dev/tty1`.
- Se existir `~/.config/.GameLoadingIModePIC`, ele usa o `ffplay` para exibir uma imagem por 2 segundos antes do jogo carregar.

---

## 2. Monitoramento de Botões (`ogage`)

O binário `/usr/local/bin/ogage` (e suas variantes) é uma aplicação compilada em C que utiliza a biblioteca `libevdev`.

### Funcionamento Interno:
- **Captura de Eventos**: O programa abre os descritores de arquivo em `/dev/input/event*` e monitora em tempo real.
- **Integração com Systemd**: O serviço `oga_events.service` garante que este binário esteja sempre rodando em background.
- **Ações**: Ao detectar combinações específicas (como o botão de Power ou combinações de Hotkeys), o binário emite sinais para o sistema, como o comando `killall` para fechar emuladores travados ou comandos de brilho.

---

## 3. Ajustes de Som (`.asoundrc`)

Um detalhe curioso encontrado no `perfmax`: o script **remove** o arquivo `/home/ark/.asoundrc` antes de iniciar um jogo e o `perfnorm` o **restaura** de um backup (`.asoundrcbak`).
- **Motivo provável**: Evitar que filtros de software do ALSA causem latência ou bugs de áudio durante a emulação pesada, mantendo o áudio o mais "direto" possível para o hardware.

---

## 4. Conclusão da Dissecação
Este mapa "byte a byte" revela que o ArkOS para R35S é uma colcha de retalhos altamente otimizada, onde quase todo binário importante possui um script wrapper que prepara o hardware (CPU, GPU, RAM, Áudio e LED) antes da execução.
