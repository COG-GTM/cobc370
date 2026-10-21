# FINDING-001: PLCYIO copies a whole block, not a record

**Severity**: storage overwrite in the caller. **Latent**: invisible while POLMAST stays unblocked.

## The defect
- maclib/ASHRLEN.mac line 5: `LH &REG,62(,&DCB)` with the comment `LRECL`.
- Offset 62 (X'3E') in the DCB is `DCBBLKSI` (block size). `DCBLRECL` (record length) is at X'52' (82). Source: IFOX00 listing of `DCBD` from `SYS1.MACLIB` on the guest, `evidence/dcbd-offsets.txt`.
- src/PLCYIO.asm lines 24-27 use that value as the length for `MVCL` into the caller's 80-byte record.

## Why nobody has seen it
POLMAST has always been allocated unblocked (`BLKSIZE=80`), so block size and record length are both 80 and the wrong field gives the right answer. The day the file is reblocked (a routine storage-efficiency change), every read copies 800 bytes into an 80-byte area and overwrites 720 bytes of whatever follows it in the caller.

## Proof (harness/verify.sh, on MVS 3.8j under Hercules)
Same 24 policies, same load module, two allocations of POLMAST:

| Run | Policy totals | Guard field after POL-REC |
|---|---|---|
| unblocked, BLKSIZE=80 | equal to golden | never touched |
| blocked, BLKSIZE=800, shipped macro | equal to golden | **overwritten on 24 of 24 reads** |
| blocked, BLKSIZE=800, proposed macro | equal to golden | never touched |

In this sample the overwrite lands in a guard and a spare area, so totals survive; in a program where other fields follow the record area, they would be corrupted silently.

## Proposed fix (not applied)
`proposals/ASHRLEN.proposed.mac`: load offset 82 (`DCBLRECL`). Not applied to `maclib/` because the macro is shared and has no owner; see `ESCALATION.md`.
