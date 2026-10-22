# 09 — Repositórios de referência

Leitura feita em 2026-10-22 sobre clones rasos (`main`): `Gathin23/cleanyourtv` (commit `30626a8`) e `simbasjungles/free-my-tv`. O nome `free-my-tv` aparece em vários forks; o original citado pelos forks é `simbasjungles/free-my-tv`.

## cleanyourtv

Debloat por ADB mais um launcher nativo (`com.gathin.tvhome`, Java, `minSdk` 26, sem `INTERNET`). MIT.

| Peça | Função |
|---|---|
| `PROMPT.md` | Roteiro colado num agente: conectar, backup, debloat, launcher, fechar o ADB. Regras de segurança ficam aqui. |
| `tools/disable.sh` / `restore.sh` | Lê a lista (um pacote por linha, `#` comenta), valida e roda `pm disable-user --user 0` em lote via `tools/tv.py --batch`. |
| `tools/recovery.py` | Grava em `~/.cleanyourtv/` o estado antes da primeira mudança; o `restore.sh` desfaz a partir dele. |
| `tools/check.py`, `privacy.py`, `adb-closed.py` | Validação de listas, auditoria de privacidade, confirma porta 5555 fechada. |
| `examples/<marca-modelo>/debloat.txt` | Uma lista por aparelho testado; `README.md` e `config.json` opcionais. |

Guardas do `disable.sh` (recusam a lista inteira ou pulam o pacote, sem override, salvo variável indicada):

1. Nome de pacote bem formado (a linha é colada num shell da TV).
2. Pacotes core do Android (`CORE_RE`: `android`, `systemui`, `shell`, `phone`, `settings`, `tv.settings`, permissioncontroller, packageinstaller, ext.services, modulemetadata, `overlay.modules*`, `providers.*`). Sem override.
3. `setupwraith` pulado se for dono do Wi-Fi salvo (`dumpsys wifi | grep cname=`); `FORCE_SETUPWRAITH=1`.
4. Dono do HOME pulado se nenhum outro app puder responder HOME; `FORCE_HOME=1`.
5. Pacote que pede `TV_INPUT_HARDWARE` pulado (camada de HDMI/AV); `TVINPUT_ALLOW=1`.
6. Avisa se `ro.adb.secure=0`.

Regras duras do repositório (`AGENTS.md`): nenhum `pm uninstall` em lista ou script, sem root, sem APK pré-compilado, updater de firmware preferencialmente mantido, nenhum pacote de fábrica/teste é iniciado, sem IP/MAC/serial em commit. Lista nova exige modelo, Android e build na primeira linha, só pacotes usados por alguns dias, uma linha na tabela de `examples/README.md` e uma no `README.md`, e `python3 -m unittest discover -s tests`.

### O que diverge deste projeto

- `cleanyourtv` proíbe `pm uninstall`. No TiVo, `pm disable-user` é recusado e `uninstall -k --user 0` é o único método que remove os não-core. Uma PR nossa precisa trazer a lista como o Nokia 8000 trouxe: sem `disable.sh`, com `README.md` na pasta descrevendo `suspend` + `appops`, e sem `uninstall` na lista (os já removidos ficam como comentário).
- `examples/nokia-streaming-box-8000` é o primo mais próximo (SEI/NES, Amlogic, 2 GB), mas Android 14 e com `core` recusando tudo. Mantém `coreservice`, `daemon`, `tvglobalkeyhandler`, `blerc`, `remoteota.*` pelo LED, OTA, teclas de atalho e pareamento do controle. `examples/dialog-viu-sei103dl` (Android 9) consegue `disable-user` e documenta as teclas NES globais por código numérico (Apps 5116, Prime 5119, Catch-up 5122) que chegam ao `HomeKeyService` do launcher.
- No Nokia o launcher original tem HOME `priority 2`, `set-home-activity` responde `Success` sem efeito. Nosso aparelho tem o mesmo quadro (ver [diário](diario.md)); a saída documentada é `STOCK_LAUNCHER=none` mais `HOME_KEY_SERVICE=1`, não verificada aqui.

## free-my-tv

App Android (Java, sem Gradle; `build.sh` chama aapt2, javac, d8, zipalign, apksigner; APK ~2 MB) que é tela inicial e protetor de tela, com versões web para LG webOS e Samsung Tizen. MIT.

- Não é lista de debloat: o app liga e desliga um "modo". `HomeMode` guarda o estado original e, ao entrar em modo Free My TV, roda `pm disable-user --user 0` numa lista curta (`DEBLOAT`), com `PROTECTED` (imagem, som, entradas, CEC, pareamento) e uma conferência de dependências antes. Voltar a "Original" reabilita tudo (`pm enable`) e restaura `set-home-activity`.
- O app fala com o ADB da própria TV em `127.0.0.1:5555` com chave própria (`Adb.java`); por isso a TV pede uma segunda autorização.
- `Watchdog` em processo separado volta ao launcher original após 3 falhas em 5 minutos; verificação no boot reaplica a escolha após atualização do sistema.
- Mesma guarda do Wi-Fi: se a rede salva pertence ao `setupwraith`, a troca para antes de alterar e pede para esquecer e reconectar a rede.
- Em TCL libera `AUTO_START` por `appops` para o job de troca rodar.
- Sequência de HOME: `cmd package set-home-activity`, `cmd role remove-role-holder ... android.app.role.HOME` como saída de reversão, `query-activities` para saber quem responde.

### O que aproveitar

- O padrão "estado original gravado + reverter com um comando" é o que `scripts/rollback.sh` já faz com `install-existing`.
- Para o problema do HOME `priority 2`, vale ler `HomeMode.java` (`homeHolder`, `set-home-activity`, `cmd role get-role-holders`) antes de testar launcher novo. Não foi testado neste aparelho.
- Não vale copiar: o app exige TMDB/clima/cripto e `INTERNET`, contra o princípio de launcher enxuto deste projeto.

## Lacunas

- Não li o `tools/tv.py` nem o `launcher/build-and-install.sh` do `cleanyourtv` linha a linha, nem os testes.
- A lista `DEBLOAT`/`PROTECTED` do `free-my-tv` para Android 12 não foi extraída.
- Nada aqui foi executado no TiVo.
