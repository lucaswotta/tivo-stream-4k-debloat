# 06 — Medições

Aparelho: TiVo Stream 4K, Android 12 build `SC.1272`, 2 GB de RAM, Amlogic S905Y2. Tudo medido em 2026-10-22, em uma unidade, por `scripts/bench.sh` (3 rodadas, mediana) salvo onde indicado. O bruto fica em `runs/` (ignorado pelo git, pode conter dados do aparelho); cada entrada do [diário](diario.md) traz o comando e a data.

## Como ler os números

- Medidas feitas com a TV em estados diferentes (recém-reiniciada ou ligada há horas) **não são comparáveis**. As linhas abaixo dizem o estado de cada uma.
- A abertura a frio de um mesmo app varia muito entre medições idênticas: o launcher abriu entre 408 e 634 ms sem nenhuma mudança. Diferenças de 100 ms ou menos não significam nada.
- `MemAvailable` oscila uns 15 MB entre rodadas iguais.

## Memória e processos

| Estado | `MemAvailable` | Processos | PSS do launcher | YouTube | Netflix | Prime |
|---|---|---|---|---|---|---|
| Linha de base: de fábrica menos 7 apps que o dono já removera; ligada há horas, sem reboot | 976 MB | 314 | 104 MB | 507 ms | 529 ms | 785 ms |
| `sageservice` e `daemon` suspensos, sem reboot | 990 MB | 315 | 108 MB | 439 ms | 521 ms | 646 ms |
| 10 pacotes suspensos, `force-stop` em `coreservice` e `sageservice`, sem reboot dentro do benchmark | 1058 MB | 310 | 68 MB | 521 ms | 504 ms | 689 ms |
| Mesmo, comparação limpa, 3 reboots, **sem** as suspensões | 905 MB | 332 | 60 MB | 668 ms | 694 ms | 1519 ms |
| Mesmo, comparação limpa, 3 reboots, **com** as suspensões | 920 MB | 330 | 64 MB | 673 ms | 775 ms | 1479 ms |
| Launcher do cleanyourtv, `post-boot.sh` | 1060 MB | 317 | 21 MB | 526 ms | 511 ms | 655 ms |
| + launcher original e Katniss parados | 1151 MB | 316 | 22 MB | 545 ms | 653 ms | 655 ms |
| Ciclo completo com `bootclean`, 6 min depois do boot | 1014 MB | n/d | n/d | n/d | n/d | n/d |
| Mesmo, benchmark depois | 1139 MB | 312 | 22 MB | 508 ms | 491 ms | 961 ms |

Leitura:

- Só suspender os 10 primeiros pacotes **não deu ganho mensurável** (905 contra 920 MB, na comparação limpa depois de reboot).
- A memória sobe de verdade quando o launcher original (60 a 100 MB) e o `coreservice`, `sageservice`, `katniss` e `tvrecommendations` ficam parados: de ~920 MB para 1014 a 1151 MB, ordem de 100 a 200 MB.
- O PSS do launcher cai de 60 a 108 MB para 21 a 22 MB.
- A abertura a frio dos apps de streaming não melhorou de forma consistente; o 961 ms do Prime na última linha é primeira abertura depois do boot.

## Atividade em segundo plano

| Medição | Antes | Depois |
|---|---|---|
| `ClearDataForGotaFun: getSystemUpdateStatus()` (consulta de atualização do `coreservice`) | 180 em 180 s | 0 em 90 s |
| Linhas de log por minuto do `com.nes.coreservice` | 61 | 0 |
| CPU em repouso | ~10% dos 4 núcleos | idem; sobra o serviço de áudio do fabricante (~26% de um núcleo, com o áudio em standby) e o `com.uei.uas.tivo` (~9%, QuickSet do controle, mantido porque liga a TV) |

## Interface

`dumpsys gfxinfo com.gathin.tvhome`, 24 toques de D-pad por passada com 0,35 s entre eles.

| Condição | Quadros por passada | Quadros travados | p90 do quadro |
|---|---|---|---|
| Interface em 1080p | ~650 | 3 a 4 (0,46 a 0,61%) | 16 a 27 ms |
| Interface em 720p (`wm size 1280x720`, não aplicada) | ~650 | 0 | 11 ms |
| `reduced_motion` | ~125 | 0 a 5 | 15 a 23 ms |
| `reduced_motion` + `animations: false` + `focus_overshoot: false` + `module_cards: false` + `ambient_glow: false` | ~21 | 1 a 3 | 10 a 27 ms |

Os quadros travados parecem fixos (~3 por passada, nos movimentos verticais) e nenhuma opção de tema os remove. O estado final usa `reduced_motion`, `animations: false` e `focus_overshoot: false` e dois patches no foco (sem destaque, zoom instantâneo); **os quadros travados deste estado final não foram medidos**.

## Hardware (lido do aparelho)

4 núcleos ARM de 100 MHz a 1,8 GHz, governor `interactive`, Mali-G31 com OpenGL ES 3.2, userspace só `armeabi-v7a`, interface em 1920x1080 a 320 dpi. Decodificadores de hardware: H.264, H.265 e VP9; AV1 não aparece. O governor e a frequência pertencem ao usuário `system`: não dá para mudá-los pelo ADB, e o bootloader é travado.

## O que o `scripts/bench.sh` mede

| Métrica | Como |
|---|---|
| Memória disponível | `MemAvailable` de `/proc/meminfo` |
| Processos | linhas de `ps -A` |
| Pacotes habilitados | `pm list packages -e` (suspender não desabilita, então não muda) |
| PSS do launcher | `dumpsys meminfo <launcher>` |
| Abertura a frio | `am force-stop` e `am start -W` (`TotalTime`) |
| Boot (`--boot`) | `adb reboot` até `sys.boot_completed=1` |

```bash
scripts/bench.sh antes                       # 3 rodadas, sem boot
scripts/bench.sh depois --boot               # reinicia a TV 3 vezes
HOME_CMD='am start -n com.gathin.tvhome/.MainActivity' HOME_PKG=com.gathin.tvhome scripts/bench.sh depois
```

Com o launcher próprio, a tecla Home injetada por ADB ainda abre o original (só a tecla real passa pelo serviço), por isso `HOME_CMD` e `HOME_PKG`. O `force-stop` do launcher desliga o serviço de teclas dele: rode `scripts/push-theme.sh` depois.
