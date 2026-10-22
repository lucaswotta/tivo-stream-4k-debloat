# 06 — Benchmark

Número sem método não prova nada. Regras:

- Mesma TV, mesmo cabo, mesma rede, TV ligada há pelo menos 3 minutos depois do boot.
- 3 rodadas por fase; a tabela do README usa a mediana.
- Nenhum app aberto além da Home no momento da medição.

## O que o `scripts/bench.sh` mede

| Métrica | Como | Por que |
|---|---|---|
| RAM disponível | `MemAvailable` de `/proc/meminfo` | Quanto sobra para os apps que você usa |
| Processos | `ps -A` contando linhas | Proxy de "quanta coisa roda à toa" |
| Pacotes habilitados | `pm list packages -e` | Mostra o tamanho do debloat |
| PSS do launcher | `dumpsys meminfo <home>` | O launcher é o que mais pesa na tela inicial |
| Abertura a frio | `am force-stop` + `am start -W` (TotalTime) | O que o usuário sente |
| Boot (opcional, `--boot`) | `adb reboot` até `sys.boot_completed=1` | Tempo até a TV responder |

O cleanyourtv também tem `tools/bench.py`, que mede latência de tecla e jank do launcher. Usar na fase 4.

## Uso

```bash
scripts/bench.sh antes            # 3 rodadas, sem boot
scripts/bench.sh antes --boot     # inclui o tempo de boot (reinicia a TV 3x)
scripts/bench.sh depois
```

Resultados em `runs/<data>-bench-<fase>/` (CSV + log bruto).
