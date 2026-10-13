#!/usr/bin/env bash
# Golden-output harness for PLCYIO on an MVS 3.8j guest (TK5 under Hercules).
# One job: assemble PLCYIO (shop macro ASHRLEN inlined), compile PLCYBAT with cobc370, link both,
# then run the batch twice on the same 24 policies: POLMAST unblocked (BLKSIZE=80, how production
# has always allocated it) and blocked (BLKSIZE=800). Output: harness/work/{deck.jcl,job.out,results.txt}
# ASHRLEN_MACRO=<file> assembles with a different copy of the shop macro (used to prove a proposed fix).
# Runner: $COBC370_RUNNER (default tk5-run) takes <deck.jcl> <outfile>, as for the cobc370 test suite.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
work=${HARNESS_WORK:-$here/harness/work}; mkdir -p "$work"
runner=${COBC370_RUNNER:-tk5-run}
"$here/../../src/cobc370" "$here/src/PLCYBAT.cbl" -o "$work/PLCYBAT.asm"
data=$(cat "$here/data/POLMAST.dat")
{
cat <<'EOF2'
//ASHPLCY  JOB (ACCT),'PLCYIO HARNESS',CLASS=A,MSGCLASS=Z,
//             MSGLEVEL=(1,1)
//MKU     EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=Z
//SYSIN    DD DUMMY
//SYSUT2   DD DSN=&&POLU,DISP=(NEW,PASS),UNIT=SYSDA,SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=80)
//SYSUT1   DD *
EOF2
echo "$data"
cat <<'EOF2'
/*
//MKB     EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=Z
//SYSIN    DD DUMMY
//SYSUT2   DD DSN=&&POLB,DISP=(NEW,PASS),UNIT=SYSDA,SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=800)
//SYSUT1   DD *
EOF2
echo "$data"
cat <<'EOF2'
/*
//S1      EXEC ASMFC,PARM.ASM='OBJ,NODECK'
//ASM.SYSGO DD DSN=&&SUBOBJ,DISP=(NEW,PASS),UNIT=SYSDA,
//             SPACE=(80,(200,50))
//ASM.SYSIN DD *
EOF2
cat "${ASHRLEN_MACRO:-$here/maclib/ASHRLEN.mac}" "$here/src/PLCYIO.asm"
cat <<'EOF2'
/*
//S2      EXEC ASMFCLG
//ASM.SYSIN DD *
EOF2
cat "$work/PLCYBAT.asm"
cat <<'EOF2'
/*
//LKED.SYSIN DD DSN=&&SUBOBJ,DISP=(OLD,DELETE)
//GO.POLMAST DD DSN=&&POLU,DISP=(OLD,PASS)
//GO.SYSOUT  DD SYSOUT=Z
//GOB     EXEC PGM=*.S2.LKED.SYSLMOD
//POLMAST  DD DSN=&&POLB,DISP=(OLD,PASS)
//SYSOUT   DD SYSOUT=Z
EOF2
} > "$work/deck.jcl"
"$runner" "$work/deck.jcl" "$work/job.out"
out=${RESULTS:-$work/results.txt}
tr -d '\r\f' < "$work/job.out" | grep -a -E "^RESULT|^IEF142I" | cut -c1-72 | sed 's/ *$//' > "$out" || true
cat "$out"
