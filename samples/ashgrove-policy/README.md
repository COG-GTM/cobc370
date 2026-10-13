# Ashgrove Mutual policy batch: undocumented HLASM routine (synthetic sample)

A COBOL-74 policy renewal batch (`src/PLCYBAT.cbl`, compiled by cobc370) calls an undocumented assembler read routine (`src/PLCYIO.asm`) that uses a shop macro (`maclib/ASHRLEN.mac`). The carrier, routine, data and defect are synthetic, written for this sample; they show the method, not a production system.

| File | What it is |
|---|---|
| `docs/CALLGRAPH.md` | call graph and register conventions |
| `docs/SPEC.md` | specification with line citations, plain-language terms |
| `docs/FINDING-001.md` | the control-block offset defect and its proof |
| `docs/ESCALATION.md` | why the shared macro is not changed |
| `proposals/ASHRLEN.proposed.mac` | proposed macro, not applied |
| `evidence/dcbd-offsets.txt` | DCB field offsets, assembled from the guest's SYS1.MACLIB |
| `goldens/unblocked.txt` | golden batch output |

## Run (needs `make -C src` and a TK5 guest; setup in `docs/TK5-SETUP.md`)

```bash
samples/ashgrove-policy/tools/tk5-start                  # IPL TK5 under Hercules, about 40 s
bash samples/ashgrove-policy/harness/verify.sh           # about 8 s
bash samples/ashgrove-policy/harness/reset.sh
```

`verify.sh` uses `tools/tk5-run` as the runner unless `COBC370_RUNNER` names another one.

`verify.sh` runs one job twice (shipped macro, then the proposed macro) and prints a check table. Every job step ends COND CODE 0000; the shipped macro overwrites the caller's guard on 24 of 24 reads of the blocked file; the proposed macro clears it.
