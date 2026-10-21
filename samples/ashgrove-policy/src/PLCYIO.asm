*        PLCYIO   POLICY MASTER READ ROUTINE           ASHGROVE 1987
*        CALL 'PLCYIO' USING FUNC REC STAT
PLCYIO   CSECT
         STM   14,12,12(13)
         BALR  12,0
         USING *,12
         ST    13,SAVE+4
         LA    13,SAVE
         LM    2,4,0(1)
         CLI   0(2),C'O'
         BE    OPEN
         CLI   0(2),C'R'
         BE    READ
         CLI   0(2),C'C'
         BE    CLOSE
         MVC   0(2,4),=C'90'
         B     RETURN
OPEN     OPEN  (POLDCB,(INPUT))
         MVC   0(2,4),=C'00'
         B     RETURN
READ     GET   POLDCB
         LR    6,1
         LA    5,POLDCB
         ASHRLEN 9,5
         LR    7,9
         LR    8,3
         MVCL  8,6
         MVC   0(2,4),=C'00'
         B     RETURN
EOF1     MVC   0(2,4),=C'10'
         B     RETURN
CLOSE    CLOSE (POLDCB)
         MVC   0(2,4),=C'00'
RETURN   L     13,SAVE+4
         LM    14,12,12(13)
         SR    15,15
         BR    14
SAVE     DS    18F
POLDCB   DCB   DDNAME=POLMAST,DSORG=PS,MACRF=GL,EODAD=EOF1
         LTORG
         END
