# 09 — Repositórios de referência

[English](../09-references.md)

Leitura feita em 2026-10-22 sobre clones rasos (`main`) de `Gathin23/cleanyourtv` (commit `30626a8`) e `simbasjungles/free-my-tv`. O nome `free-my-tv` aparece em vários forks; o original citado por eles é `simbasjungles/free-my-tv`.

## cleanyourtv

Debloat por ADB e um launcher nativo (`com.gathin.tvhome`, Java, `minSdk` 26, sem `INTERNET`). MIT.

| Peça | Função |
|---|---|
| `PROMPT.md` | roteiro para um agente: conectar, backup, debloat, launcher, fechar o ADB; as regras de segurança ficam aqui |
| `tools/disable.sh` / `restore.sh` | lê a lista (um pacote por linha, `#` comenta), valida e roda `pm disable-user --user 0` em lote via `tools/tv.py --batch` |
| `tools/recovery.py` | grava em `~/.cleanyourtv/` o estado anterior à primeira mudança; o `restore.sh` desfaz a partir dele |
| `tools/check.py`, `privacy.py`, `adb-closed.py` | validação de listas, auditoria de privacidade, confirmação de que a porta 5555 fechou |
| `examples/<marca-modelo>/debloat.txt` | uma lista por aparelho testado, com `README.md` e `config.json` opcionais |

Guardas do `disable.sh`, que recusam a lista ou pulam o pacote:

1. Nome de pacote bem formado (a linha vai para um shell da TV).
2. Pacotes core do Android (`android`, `systemui`, `shell`, `phone`, `settings`, `tv.settings`, permissioncontroller, packageinstaller, ext.services, modulemetadata, `overlay.modules*`, `providers.*`), sem exceção.
3. `setupwraith` pulado se for dono do Wi-Fi salvo (`FORCE_SETUPWRAITH=1` libera).
4. Dono da Home pulado se nenhum outro app puder responder HOME (`FORCE_HOME=1`).
5. Pacote que pede `TV_INPUT_HARDWARE` pulado, porque é camada de HDMI/AV (`TVINPUT_ALLOW=1`).
6. Aviso se `ro.adb.secure=0`.

Regras do repositório (`AGENTS.md`): nenhum `pm uninstall` em lista ou script, sem root, sem APK pré-compilado, atualizador de firmware de preferência mantido, nenhum pacote de fábrica ou teste iniciado, sem IP, MAC ou serial em commit. Uma lista nova exige modelo, Android e build na primeira linha, só pacotes usados por alguns dias, uma linha em `examples/README.md` e uma no `README.md`, e `python3 -m unittest discover -s tests` passando.

Onde diverge deste projeto:

- O cleanyourtv proíbe `pm uninstall`. No TiVo, `pm disable-user` é recusado e `uninstall -k --user 0` é o único método que remove os pacotes não-core. Por isso o PR levou a lista como o Nokia 8000 levou: sem `disable.sh`, com um `README.md` que descreve `suspend` + `appops`, e com os apps já removidos como comentários.
- `examples/nokia-streaming-box-8000` é o parente mais próximo (SEI/NES, Amlogic, 2 GB), mas com Android 14 e recusando tudo nos pacotes core. Mantém `coreservice`, `daemon`, `tvglobalkeyhandler`, `blerc` e `remoteota.*` pelo LED, OTA, teclas de atalho e pareamento do controle. `examples/dialog-viu-sei103dl` (Android 9) aceita `disable-user` e documenta as teclas globais da NES por código numérico (Apps 5116, Prime Video 5119, Catch-up 5122).
- No Nokia, o launcher original tem HOME `priority 2` e `set-home-activity` responde `Success` sem efeito, o mesmo quadro do TiVo. A saída documentada lá, `STOCK_LAUNCHER=none` com `HOME_KEY_SERVICE=1`, não foi verificada aqui; este projeto usa o launcher sem HOME e o `homekey` ([05](05-launcher.md)).

## free-my-tv

App Android (Java, sem Gradle: `build.sh` chama aapt2, javac, d8, zipalign e apksigner; APK de ~2 MB) que é tela inicial e protetor de tela, com versões web para LG webOS e Samsung Tizen. MIT.

- Não é uma lista de debloat: o app liga e desliga um modo. `HomeMode` guarda o estado original e, ao entrar no modo Free My TV, roda `pm disable-user --user 0` numa lista curta (`DEBLOAT`), com uma lista `PROTECTED` (imagem, som, entradas, CEC, pareamento) e conferência de dependências antes. Voltar a Original reabilita tudo e restaura `set-home-activity`.
- Fala com o ADB da própria TV em `127.0.0.1:5555` com uma chave própria (`Adb.java`), por isso a TV pede uma segunda autorização. O `bootclean` usa o mesmo método.
- Um `Watchdog` em processo separado volta ao launcher original depois de 3 falhas em 5 minutos; uma verificação no boot reaplica a escolha depois de uma atualização do sistema.
- Mesma guarda do Wi-Fi: se a rede salva pertence ao `setupwraith`, a troca para e pede para esquecer e reconectar a rede.
- O app exige TMDB, clima, cripto e `INTERNET`, o contrário de um launcher enxuto, por isso só o cliente ADB foi aproveitado.

## Comparação

| | cleanyourtv | free-my-tv | este repositório |
|---|---|---|---|
| Aparelhos | mais de 230 pastas em `examples/` | Google TV e Android TV, LG webOS, Samsung Tizen | 1 (TiVo Stream 4K, `SC.1272`) |
| Debloat | `pm disable-user` em lote, com guardas | lista curta por marca, reversível por botão | `pm suspend` e `appops`, 14 pacotes (16 com a camada pessoal), reversível por script |
| Launcher | próprio: temas, módulos, biblioteca de apps | próprio: recomendações, clima, cripto, precisa de internet | o do cleanyourtv com 1 patch (5 com a camada pessoal) |
| Home em firmware que fixa o launcher | registrado como não resolvido (Nokia 8000) | não verificado | resolvido neste firmware |
| Botões do controle | `app_keys` por keycode e scancode | só TCL | mais o keycode 5124 do Live e o desvio do botão do Assistente |
| Limpeza de processos no boot | não | não | `bootclean` |
| Testes e CI | sim | sim | só os scripts de conferência (`status.sh`, `bench.sh`) |

O que este repositório acrescenta: a lista de 53 pacotes e o gatilho de boot do `coreservice` ([03](03-coreservice.md)); a troca da Home sem declarar HOME, que sobreviveu a vários reboots; o desvio do botão do Assistente, que nunca chega a um serviço de acessibilidade ([08](08-controle.md)); e a limpeza depois do boot sem computador ([10](10-bootclean.md)).

O que não tem: largura (um aparelho contra mais de 230), temas, módulos, biblioteca de apps, versões para LG e Samsung, testes automatizados, CI e processo de revisão. A validação é de uma unidade, por um dia, e depende de uma versão de firmware.

## Lacunas

- `tools/tv.py`, `launcher/build-and-install.sh` e os testes do cleanyourtv não foram lidos linha a linha.
- As listas `DEBLOAT` e `PROTECTED` do free-my-tv para Android 12 não foram extraídas.
- O launcher do cleanyourtv sem o patch da categoria HOME não foi testado no TiVo: a remoção pelo `coreservice` foi observada com um app próprio que declarava HOME.
- Nada foi testado no Nokia 8000 nem no Dialog ViU.
