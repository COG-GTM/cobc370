# Call graph and register conventions: PLCYBAT -> PLCYIO

Written by Devin from the source alone (no surviving documentation; the author retired).

## Call graph

```
PLCYBAT (COBOL-74 policy renewal batch, src/PLCYBAT.cbl)
  CALL 'PLCYIO' USING WS-FUNC POL-REC WS-STAT     lines 27, 29, 32, 46
    PLCYIO (assembler, src/PLCYIO.asm)
      FUNC 'O' -> OPEN  (POLDCB,(INPUT))           line 18
      FUNC 'R' -> GET   POLDCB  (QSAM locate mode)  line 21
                  ASHRLEN 9,5  (shop macro, maclib/ASHRLEN.mac)  line 24
                  MVCL  8,6    copy record to caller            line 27
      FUNC 'C' -> CLOSE (POLDCB)                    line 32
      end of file -> EOF1, status '10'              lines 30-31, DCB EODAD line 39
```

POLDCB (line 39) reads DD `POLMAST`. Block size and record format come from the dataset, not the program.

## Register conventions (standard OS linkage)

| Register | On entry | Inside PLCYIO |
|---|---|---|
| R1 | address of the parameter list (3 addresses) | after `GET`: address of the record in the I/O buffer |
| R13 | caller's save area | PLCYIO's own `SAVE` (line 38), chained at line 7 |
| R14 / R15 | return address / entry point | restored at line 35; R15 set to 0 (line 36) |
| R2, R3, R4 | | FUNC, REC, STAT addresses (`LM 2,4,0(1)`, line 9) |
| R5 | | address of POLDCB (line 23) |
| R6 / R7 | | MVCL source: record address / length (lines 22, 25) |
| R8 / R9 | | MVCL target: caller's POL-REC / length (lines 26, 24) |
| R12 | | base register (lines 5-6) |

Status codes returned in STAT: `00` ok, `10` end of file, `90` unknown function.
