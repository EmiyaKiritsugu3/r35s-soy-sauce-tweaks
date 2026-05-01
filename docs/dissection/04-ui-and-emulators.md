# Engenharia Reversa: EmulationStation e RetroArch

## 1. EmulationStation (`es_systems.cfg`)

O EmulationStation atua como o frontend que organiza os ROMs e executa os emuladores.

### Estrutura de Comando de Lançamento:
Um padrão se repete para quase todos os sistemas:
```bash
sudo perfmax %GOVERNOR% %ROM%; nice -n -19 /usr/local/bin/retroarch -L /home/ark/.config/retroarch/cores/%CORE%_libretro.so %ROM%; sudo perfnorm
```
1. **`sudo perfmax`**: Antes de abrir qualquer jogo, o sistema força o clock da CPU ao máximo (`performance governor`).
2. **`nice -n -19`**: Define a prioridade do processo do emulador como altíssima (-19), garantindo que ele tenha preferência total sobre outros processos em background.
3. **`/usr/local/bin/retroarch`**: Chama o wrapper do RetroArch (analisado abaixo).
4. **`sudo perfnorm`**: Ao fechar o jogo, restaura o clock da CPU para o modo econômico (`ondemand`).

---

## 2. RetroArch Wrapper (`/usr/local/bin/retroarch`)

O script `/usr/local/bin/retroarch` não é o binário real, mas um gestor inteligente.

### Funcionalidades Identificadas:
- **Netplay via Botão X**: Ao segurar o botão **X** (BTN_NORTH) enquanto lança um jogo, o script abre um menu `dialog` perguntando se o usuário quer ser Host ou Client de uma partida online.
- **Configurações Dinâmicas**: O script monta o nome da sessão de Netplay usando o final do endereço MAC do Wi-Fi: `$(cat /sys/class/net/wlan0/address | awk -F':' '{ print $4$5$6}')`.
- **Limpeza de Console**: Após o jogo fechar, ele executa `reset` e restaura a fonte do console (`Lat7-Terminus20x10.psf.gz`) para manter o sistema limpo.

---

## 3. Configurações de Driver (`retroarch.cfg`)

Extraímos os drivers vitais que garantem a performance no RK3326:
- **`video_driver = "gl"`**: Utiliza a GPU Mali-G31 via OpenGL ES.
- **`audio_driver = "alsathread" `**: Usa ALSA com threading para evitar stuttering (engasgos) no áudio.
- **`input_joypad_driver = "udev"`**: Driver moderno do Linux para detecção de controles, essencial para as hotkeys.
