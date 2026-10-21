# PLCYIO specification (derived by Devin, with line citations)

Plain-language terms used below:
- **HLASM / assembler**: the IBM mainframe's low-level language; one line is roughly one machine instruction.
- **DCB (data control block)**: a fixed-layout area of memory that describes an open file. Each field sits at a fixed byte offset, defined by IBM's `DCBD` macro in `SYS1.MACLIB`.
- **QSAM locate mode**: `GET` returns the address of the next record inside the system's buffer instead of copying it.
- **LRECL / BLKSIZE**: record length / block size. An unblocked file has one record per block (BLKSIZE = LRECL); a blocked file packs several records into a block.
- **JCL**: the job control language that runs a batch job and says which file each DD name points to.
- **EBCDIC**: the mainframe character encoding; the sources here are ASCII and are converted when submitted to the guest.

## Interface

`CALL 'PLCYIO' USING FUNC REC STAT` (src/PLCYBAT.cbl lines 27, 29, 32, 46)
- FUNC, 1 byte: `O` open, `R` read next, `C` close (src/PLCYIO.asm lines 10-15).
- REC, the caller's record area. PLCYBAT passes `POL-REC`, 80 bytes (src/PLCYBAT.cbl lines 15-21).
- STAT, 2 bytes: `00`, `10` end of file, `90` bad function (src/PLCYIO.asm lines 16, 19, 28, 30, 33).

## Behaviour

1. `O`: opens DD POLMAST for input (line 18).
2. `R`: `GET` in locate mode (line 21, `MACRF=GL` line 39). The record length is loaded by shop macro `ASHRLEN` (line 24), then `MVCL` copies that many bytes from the buffer to REC (lines 25-27).
3. End of file branches to `EOF1` via the DCB's EODAD (lines 30, 39) and returns `10`.
4. `C`: closes the file (line 32).

## Requirement the code must meet

The number of bytes copied must equal the logical record length: **DCBLRECL, halfword at offset X'52' (82)** in the DCB (`evidence/dcbd-offsets.txt`, assembled from TK5's `SYS1.MACLIB`).

## What the code actually does

`ASHRLEN` loads the halfword at offset **62 (X'3E')** (maclib/ASHRLEN.mac line 5), whose comment says `LRECL`. In the DCB, X'3E' is **DCBBLKSI, the block size** (`evidence/dcbd-offsets.txt`). See `FINDING-001.md`.
