;===============================================================================
;  _____ __  __      ____   ____    ____  __ ____
; | ____|  \/  |    / ___| / ___|  / /  \/  |  _ \
; |  _| | |\/| |____\___ \| |     / /| |\/| | |_) |
; | |___| |  | |_____|__) | |___ / / | |  | |  __/
; |_____|_|  |_|    |____/ \____/_/  |_|  |_|_|
;
; A National Semiconductor SC/MP Emulator
;-------------------------------------------------------------------------------
; Copyright (C)2014-2015 HandCoded Software Ltd.
; All rights reserved.
;
; This software is the confidential and proprietary information of HandCoded
; Software Ltd. ("Confidential Information").  You shall not disclose such
; Confidential Information and shall use it only in accordance with the terms
; of the license agreement you entered into with HandCoded Software.
;
; HANDCODED SOFTWARE MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE
; SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
; LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
; PARTICULAR PURPOSE, OR NON-INFRINGEMENT. HANDCODED SOFTWARE SHALL NOT BE
; LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING
; OR DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES.
;-------------------------------------------------------------------------------
;
; Notes:
;
;===============================================================================
; Revision History:
;
; 2014-10-11 AJ Initial version
;-------------------------------------------------------------------------------
; $Id: em-scmp.s 52 2015-10-09 22:46:45Z andrew $
;-------------------------------------------------------------------------------

        .include "hardware.inc"
        .include "em-retro.inc"
        .include "em-scmp.inc"

;===============================================================================
; Emulator
;-------------------------------------------------------------------------------

        .section .scmp,code
        
        .global EM_SCMP
        .extern CYCLE
        .extern INT_ENABLE
        .extern INT_FLAGS
        .extern PutStr
EM_SCMP:
        call    PutStr
        .asciz  "EM-SCMP [15.07]\r\n"

        clr     R_P0                    ; Initialise all registers
        clr     R_P1
        clr     R_P2
        clr     R_P3
        clr     R_AC
        clr     R_ER
        clr     R_SR

        mov     #MEMORY_MAP,M_BASE      ; Initialise memory map
        clr     M_FLAG                  ; .. and read-only flags

        mov     #0x0fff,M_MASK
        mov     #0xff80,M_DISP

        mov     #edspage(NIBL),w1       ; NIBL 0x0000-0x0fff R/O
        mov     #edsoffset(NIBL),w2
        mov     w1,[M_BASE+ 0]
        mov     w2,[M_BASE+ 2]
        bset    M_FLAG,#0

        mov     #edspage(RAM1),w1       ; RAM  0x1000-0x1fff
        mov     #edsoffset(RAM1),w2
        mov     w1,[M_BASE+ 4]
        mov     w2,[M_BASE+ 6]
        mov     #edspage(RAM2),w1       ; RAM  0x2000-0x2fff
        mov     #edsoffset(RAM2),w2
        mov     w1,[M_BASE+ 8]
        mov     w2,[M_BASE+10]
        mov     #edspage(RAM3),w1       ; RAM  0x3000-0x3fff
        mov     #edsoffset(RAM3),w2
        mov     w1,[M_BASE+12]
        mov     w2,[M_BASE+14]
        mov     #edspage(RAM4),w1       ; RAM  0x4000-0x4fff
        mov     #edsoffset(RAM4),w2
        mov     w1,[M_BASE+16]
        mov     w2,[M_BASE+18]
        mov     #edspage(RAM5),w1       ; RAM  0x5000-0x5fff
        mov     #edsoffset(RAM5),w2
        mov     w1,[M_BASE+20]
        mov     w2,[M_BASE+22]
        mov     #edspage(RAM6),w1       ; RAM  0x6000-0x6fff
        mov     #edsoffset(RAM6),w2
        mov     w1,[M_BASE+24]
        mov     w2,[M_BASE+26]
        mov     #edspage(RAM7),w1       ; RAM  0x7000-0x7fff
        mov     #edsoffset(RAM7),w2
        mov     w1,[M_BASE+28]
        mov     w2,[M_BASE+30]
        mov     #edspage(RAM8),w1       ; RAM  0x8000-0x8fff
        mov     #edsoffset(RAM8),w2
        mov     w1,[M_BASE+32]
        mov     w2,[M_BASE+34]
        mov     #edspage(RAM9),w1       ; RAM  0x9000-0x9fff
        mov     #edsoffset(RAM9),w2
        mov     w1,[M_BASE+36]
        mov     w2,[M_BASE+38]
        mov     #edspage(RAMA),w1       ; RAM  0xa000-0xafff
        mov     #edsoffset(RAMA),w2
        mov     w1,[M_BASE+40]
        mov     w2,[M_BASE+42]
        mov     #edspage(RAMB),w1       ; RAM  0xb000-0xbfff
        mov     #edsoffset(RAMB),w2
        mov     w1,[M_BASE+44]
        mov     w2,[M_BASE+46]

        mov     #edspage(FORTH),w1      ; FORTH 0xc000-0xcfff R/O
        mov     #edsoffset(FORTH),w2
        mov     w1,[M_BASE+48]
        mov     w2,[M_BASE+50]
        bset    M_FLAG,#12
        mov     #edspage(LISP),w1       ; LISP 0xd000-0xefff R/O
        mov     #edsoffset(LISP),w2
        mov     w1,[M_BASE+52]
        mov     w2,[M_BASE+54]
        bset    M_FLAG,#13
        mov     #edspage(LISP+4096),w1
        mov     #edsoffset(LISP+4096),w2
        mov     w1,[M_BASE+56]
        mov     w2,[M_BASE+58]
        bset    M_FLAG,#14
        mov     #edspage(SCARAB),w1     ; SCARAB 0xf000-0xffff R/O
        mov     #edsoffset(SCARAB),w2
        mov     w1,[M_BASE+60]
        mov     w2,[M_BASE+62]
        bset    M_FLAG,#15

        clr     CYCLE
Run:
        rcall   Step
        add     CYCLE
1:      cp0     CYCLE
        bra     gt,1b
        bra     Run

Step:
        bclr    R_SR,#F_SA             ; Copy sense pins to SR
        bclr    R_SR,#F_SB
        btsc    SA_PORT,#SA_PIN
        bset    R_SR,#F_SA
        btsc    SB_PORT,#SB_PIN
        bset    R_SR,#F_SB

        btsc    R_SR,#F_IE              ; Interrupts enabled?
        btss    R_SR,#F_SA              ; Sense A hi?
        bra     1f                      ; No, normal execution

        bclr    R_SR,#F_IE              ; Disable interrupts
        exch    R_P0,R_P3

1:
        BUMP    R_P0,w0,R_P0            ; Pre-increment the program counter

        .if     TRACE
        mov     #13,w0
        call    UartTx
        mov     #10,w0
        call    UartTx

        call    PutStr
        .asciz  " P0="
        mov     R_P0,w0
        call    PutHex4

        call    PutStr
        .asciz  " P1="
        mov     R_P1,w0
        call    PutHex4

        call    PutStr
        .asciz  " P2="
        mov     R_P2,w0
        call    PutHex4

        call    PutStr
        .asciz  " P3="
        mov     R_P3,w0
        call    PutHex4

        call    PutStr
        .asciz  " AC="
        mov     R_AC,w0
        call    PutHex2

        call    PutStr
        .asciz  " ER="
        mov     R_ER,w0
        call    PutHex2

        call    PutStr
        .asciz  " SR="
        mov     R_SR,w0
        call    PutHex2
        .endif

        RD_ADDR R_P0,ze,w0              ; Then read the next opcode

        .if     TRACE
        push    w0
        push    w0
        mov     #' ',w0
        call    UartTx
        pop     w0
        call    PutHex2
        pop     w0
        .endif

        bra     w0

;-------------------------------------------------------------------------------

        bra     DO_HALT                 ; 00 - HALT
        bra     DO_XAE                  ; 01 - XAE
        bra     DO_CCL                  ; 02 - CCL
        bra     DO_SCL                  ; 03 - SCL
        bra     DO_DINT                 ; 04 - DINT
        bra     DO_IEN                  ; 05 - IEN
        bra     DO_CSA                  ; 06 - CSA
        bra     DO_CAS                  ; 07 - CAS
        bra     DO_NOP                  ; 08 - NOP
        bra     DO_ERR                  ; 09
        bra     DO_ERR                  ; 0a
        bra     DO_ERR                  ; 0b
        bra     DO_ERR                  ; 0c
        bra     DO_ERR                  ; 0d
        bra     DO_ERR                  ; 0e
        bra     DO_ERR                  ; 0f

        bra     DO_ERR                  ; 10
        bra     DO_ERR                  ; 11
        bra     DO_ERR                  ; 12
        bra     DO_ERR                  ; 13
        bra     DO_ERR                  ; 14
        bra     DO_ERR                  ; 15
        bra     DO_ERR                  ; 16
        bra     DO_ERR                  ; 17
        bra     DO_ERR                  ; 18
        bra     DO_SIO                  ; 19 - SIO
        bra     DO_ERR                  ; 1a
        bra     DO_ERR                  ; 1b
        bra     DO_SR                   ; 1c - SR
        bra     DO_SRL                  ; 1d - SRL
        bra     DO_RR                   ; 1e - RR
        bra     DO_RRL                  ; 1f - RRL

        bra     DO_TXD                  ; 20 - TXD (*)
        bra     DO_RXD                  ; 21 - RXD (*)
        bra     DO_ERR                  ; 22
        bra     DO_ERR                  ; 23
        bra     DO_ERR                  ; 24
        bra     DO_ERR                  ; 25
        bra     DO_ERR                  ; 26
        bra     DO_ERR                  ; 27
        bra     DO_ERR                  ; 28
        bra     DO_ERR                  ; 29
        bra     DO_ERR                  ; 2a
        bra     DO_ERR                  ; 2b
        bra     DO_ERR                  ; 2c
        bra     DO_ERR                  ; 2d
        bra     DO_ERR                  ; 2e
        bra     DO_ERR                  ; 2f

        bra     DO_XPAL0                ; 30 - XPAL P0
        bra     DO_XPAL1                ; 31 - XPAL P1
        bra     DO_XPAL2                ; 32 - XPAL P2
        bra     DO_XPAL3                ; 33 - XPAL P3
        bra     DO_XPAH0                ; 34 - XPAH P0
        bra     DO_XPAH1                ; 35 - XPAH P1
        bra     DO_XPAH2                ; 36 - XPAH P2
        bra     DO_XPAH3                ; 37 - XPAH P3
        bra     DO_ERR                  ; 38
        bra     DO_ERR                  ; 39
        bra     DO_ERR                  ; 3a
        bra     DO_ERR                  ; 3b
        bra     DO_XPPC0                ; 3c - XPPC P0
        bra     DO_XPPC1                ; 3d - XPPC P1
        bra     DO_XPPC2                ; 3e - XPPC P2
        bra     DO_XPPC3                ; 3f - XPPC P3

        bra     DO_LDE                  ; 40 - LDE
        bra     DO_ERR                  ; 41
        bra     DO_ERR                  ; 42
        bra     DO_ERR                  ; 43
        bra     DO_ERR                  ; 44
        bra     DO_ERR                  ; 45
        bra     DO_ERR                  ; 46
        bra     DO_ERR                  ; 47
        bra     DO_ERR                  ; 48
        bra     DO_ERR                  ; 49
        bra     DO_ERR                  ; 4a
        bra     DO_ERR                  ; 4b
        bra     DO_ERR                  ; 4c
        bra     DO_ERR                  ; 4d
        bra     DO_ERR                  ; 4e
        bra     DO_ERR                  ; 4f

        bra     DO_ANE                  ; 50 - ANE
        bra     DO_ERR                  ; 51
        bra     DO_ERR                  ; 52
        bra     DO_ERR                  ; 53
        bra     DO_ERR                  ; 54
        bra     DO_ERR                  ; 55
        bra     DO_ERR                  ; 56
        bra     DO_ERR                  ; 57
        bra     DO_ORE                  ; 58 - ORE
        bra     DO_ERR                  ; 59
        bra     DO_ERR                  ; 5a
        bra     DO_ERR                  ; 5b
        bra     DO_ERR                  ; 5c
        bra     DO_ERR                  ; 5d
        bra     DO_ERR                  ; 5e
        bra     DO_ERR                  ; 5f

        bra     DO_XRE                  ; 60 - XRE
        bra     DO_ERR                  ; 61
        bra     DO_ERR                  ; 62
        bra     DO_ERR                  ; 63
        bra     DO_ERR                  ; 64
        bra     DO_ERR                  ; 65
        bra     DO_ERR                  ; 66
        bra     DO_ERR                  ; 67
        bra     DO_DAE                  ; 68 - DAE
        bra     DO_ERR                  ; 69
        bra     DO_ERR                  ; 6a
        bra     DO_ERR                  ; 6b
        bra     DO_ERR                  ; 6c
        bra     DO_ERR                  ; 6d
        bra     DO_ERR                  ; 6e
        bra     DO_ERR                  ; 6f

        bra     DO_ADE                  ; 70 - ADE
        bra     DO_ERR                  ; 71
        bra     DO_ERR                  ; 72
        bra     DO_ERR                  ; 73
        bra     DO_ERR                  ; 74
        bra     DO_ERR                  ; 75
        bra     DO_ERR                  ; 76
        bra     DO_ERR                  ; 77
        bra     DO_CAE                  ; 78 - CAE
        bra     DO_ERR                  ; 79
        bra     DO_ERR                  ; 7a
        bra     DO_ERR                  ; 7b
        bra     DO_ERR                  ; 7c
        bra     DO_ERR                  ; 7d
        bra     DO_ERR                  ; 7e
        bra     DO_ERR                  ; 7f

        bra     DO_ERR                  ; 80
        bra     DO_ERR                  ; 81
        bra     DO_ERR                  ; 82
        bra     DO_ERR                  ; 83
        bra     DO_ERR                  ; 84
        bra     DO_ERR                  ; 85
        bra     DO_ERR                  ; 86
        bra     DO_ERR                  ; 87
        bra     DO_ERR                  ; 88
        bra     DO_ERR                  ; 89
        bra     DO_ERR                  ; 8a
        bra     DO_ERR                  ; 8b
        bra     DO_ERR                  ; 8c
        bra     DO_ERR                  ; 8d
        bra     DO_ERR                  ; 8e
        bra     DO_DLY                  ; 8f - DLY d

        bra     DO_JMP0                 ; 90 - JMP d(P0)
        bra     DO_JMP1                 ; 91 - JMP d(P1)
        bra     DO_JMP2                 ; 92 - JMP d(P2)
        bra     DO_JMP3                 ; 93 - JMP d(P3)
        bra     DO_JP0                  ; 94 - JP d(P0)
        bra     DO_JP1                  ; 95 - JP d(P1)
        bra     DO_JP2                  ; 96 - JP d(P2)
        bra     DO_JP3                  ; 97 - JP d(P3)
        bra     DO_JZ0                  ; 98 - JZ d(P0)
        bra     DO_JZ1                  ; 99 - JZ d(P1)
        bra     DO_JZ2                  ; 9a - JZ d(P2)
        bra     DO_JZ3                  ; 9b - JZ d(P3)
        bra     DO_JNZ0                 ; 9c - JNZ d(P0)
        bra     DO_JNZ1                 ; 9d - JNZ d(P1)
        bra     DO_JNZ2                 ; 9e - JNZ d(P2)
        bra     DO_JNZ3                 ; 9f - JNZ d(P3)

        bra     DO_ERR                  ; a0
        bra     DO_ERR                  ; a1
        bra     DO_ERR                  ; a2
        bra     DO_ERR                  ; a3
        bra     DO_ERR                  ; a4
        bra     DO_ERR                  ; a5
        bra     DO_ERR                  ; a6
        bra     DO_ERR                  ; a7
        bra     DO_ILD_IDX0             ; a8
        bra     DO_ILD_IDX1             ; a9
        bra     DO_ILD_IDX2             ; aa
        bra     DO_ILD_IDX3             ; ab
        bra     DO_ERR                  ; ac
        bra     DO_ERR                  ; ad
        bra     DO_ERR                  ; ae
        bra     DO_ERR                  ; af

        bra     DO_ERR                  ; b0
        bra     DO_ERR                  ; b1
        bra     DO_ERR                  ; b2
        bra     DO_ERR                  ; b3
        bra     DO_ERR                  ; b4
        bra     DO_ERR                  ; b5
        bra     DO_ERR                  ; b6
        bra     DO_ERR                  ; b7
        bra     DO_DLD_IDX0             ; b8
        bra     DO_DLD_IDX1             ; b9
        bra     DO_DLD_IDX2             ; ba
        bra     DO_DLD_IDX3             ; bb
        bra     DO_ERR                  ; bc
        bra     DO_ERR                  ; bd
        bra     DO_ERR                  ; be
        bra     DO_ERR                  ; bf

        bra     DO_LD_IDX0              ; c0
        bra     DO_LD_IDX1              ; c1
        bra     DO_LD_IDX2              ; c2
        bra     DO_LD_IDX3              ; c3
        bra     DO_LDI                  ; c4
        bra     DO_LD_AIX1              ; c5
        bra     DO_LD_AIX2              ; c6
        bra     DO_LD_AIX3              ; c7
        bra     DO_ST_IDX0              ; c8
        bra     DO_ST_IDX1              ; c9
        bra     DO_ST_IDX2              ; ca
        bra     DO_ST_IDX3              ; cb
        bra     DO_ERR                  ; cc
        bra     DO_ST_AIX1              ; cd
        bra     DO_ST_AIX2              ; ce
        bra     DO_ST_AIX3              ; cf

        bra     DO_AND_IDX0             ; d0
        bra     DO_AND_IDX1             ; d1
        bra     DO_AND_IDX2             ; d2
        bra     DO_AND_IDX3             ; d3
        bra     DO_ANI                  ; d4
        bra     DO_AND_AIX1             ; d5
        bra     DO_AND_AIX2             ; d6
        bra     DO_AND_AIX3             ; d7
        bra     DO_OR_IDX0              ; d8
        bra     DO_OR_IDX1              ; d9
        bra     DO_OR_IDX2              ; da
        bra     DO_OR_IDX3              ; db
        bra     DO_ORI                  ; dc
        bra     DO_OR_AIX1              ; dd
        bra     DO_OR_AIX2              ; de
        bra     DO_OR_AIX3              ; df

        bra     DO_XOR_IDX0             ; e0
        bra     DO_XOR_IDX1             ; e1
        bra     DO_XOR_IDX2             ; e2
        bra     DO_XOR_IDX3             ; e3
        bra     DO_XRI                  ; e4
        bra     DO_XOR_AIX1             ; e5
        bra     DO_XOR_AIX2             ; e6
        bra     DO_XOR_AIX3             ; e7
        bra     DO_DAD_IDX0             ; e8
        bra     DO_DAD_IDX1             ; e9
        bra     DO_DAD_IDX2             ; ea
        bra     DO_DAD_IDX3             ; eb
        bra     DO_DAI                  ; ec
        bra     DO_DAD_AIX1             ; ed
        bra     DO_DAD_AIX2             ; ee
        bra     DO_DAD_AIX3             ; ef

        bra     DO_ADD_IDX0             ; f0
        bra     DO_ADD_IDX1             ; f1
        bra     DO_ADD_IDX2             ; f2
        bra     DO_ADD_IDX3             ; f3
        bra     DO_ADI                  ; f4
        bra     DO_ADD_AIX1             ; f5
        bra     DO_ADD_AIX2             ; f6
        bra     DO_ADD_AIX3             ; f7
        bra     DO_CAD_IDX0             ; f8
        bra     DO_CAD_IDX1             ; f9
        bra     DO_CAD_IDX2             ; fa
        bra     DO_CAD_IDX3             ; fb
        bra     DO_CAI                  ; fc
        bra     DO_CAD_AIX1             ; fd
        bra     DO_CAD_AIX2             ; fe
        bra     DO_CAD_AIX3             ; ff

;-------------------------------------------------------------------------------

DO_ADD_IDX0:
        AM_IDX  R_P0
        OP_ADD

DO_ADD_IDX1:
        AM_IDX  R_P1
        OP_ADD

DO_ADD_IDX2:
        AM_IDX  R_P2
        OP_ADD

DO_ADD_IDX3:
        AM_IDX  R_P3
        OP_ADD

DO_ADD_AIX1:
        AM_AIX  R_P1
        OP_ADD

DO_ADD_AIX2:
        AM_AIX  R_P2
        OP_ADD

DO_ADD_AIX3:
        AM_AIX  R_P3
        OP_ADD

;-------------------------------------------------------------------------------

DO_ADE:
        AM_INH
        OP_ADE

;-------------------------------------------------------------------------------

DO_ADI:
        AM_IMM
        OP_ADI

;-------------------------------------------------------------------------------

DO_AND_IDX0:
        AM_IDX  R_P0
        OP_AND

DO_AND_IDX1:
        AM_IDX  R_P1
        OP_AND

DO_AND_IDX2:
        AM_IDX  R_P2
        OP_AND

DO_AND_IDX3:
        AM_IDX  R_P3
        OP_AND

DO_AND_AIX1:
        AM_AIX  R_P1
        OP_AND

DO_AND_AIX2:
        AM_AIX  R_P2
        OP_AND

DO_AND_AIX3:
        AM_AIX  R_P3
        OP_AND

;-------------------------------------------------------------------------------

DO_ANE:
        AM_INH
        OP_ANE

;-------------------------------------------------------------------------------

DO_ANI:
        AM_IMM
        OP_ANI

;-------------------------------------------------------------------------------

DO_CAD_IDX0:
        AM_IDX  R_P0
        OP_CAD

DO_CAD_IDX1:
        AM_IDX  R_P1
        OP_CAD

DO_CAD_IDX2:
        AM_IDX  R_P2
        OP_CAD

DO_CAD_IDX3:
        AM_IDX  R_P3
        OP_CAD

DO_CAD_AIX1:
        AM_AIX  R_P1
        OP_CAD

DO_CAD_AIX2:
        AM_AIX  R_P2
        OP_CAD

DO_CAD_AIX3:
        AM_AIX  R_P3
        OP_CAD

;-------------------------------------------------------------------------------

DO_CAE:
        AM_INH
        OP_CAE

;-------------------------------------------------------------------------------

DO_CAI:
        AM_IMM
        OP_CAI

;-------------------------------------------------------------------------------

DO_CAS:
        AM_INH
        OP_CAS

;-------------------------------------------------------------------------------

DO_CCL:
        AM_INH
        OP_CCL

;-------------------------------------------------------------------------------

DO_CSA:
        AM_INH
        OP_CSA

;-------------------------------------------------------------------------------

DO_DAD_IDX0:
        AM_IDX  R_P0
        OP_DAD

DO_DAD_IDX1:
        AM_IDX  R_P1
        OP_DAD

DO_DAD_IDX2:
        AM_IDX  R_P2
        OP_DAD

DO_DAD_IDX3:
        AM_IDX  R_P3
        OP_DAD

DO_DAD_AIX1:
        AM_AIX  R_P1
        OP_DAD

DO_DAD_AIX2:
        AM_AIX  R_P2
        OP_DAD

DO_DAD_AIX3:
        AM_AIX  R_P3
        OP_DAD

;-------------------------------------------------------------------------------

DO_DAE:
        AM_INH
        OP_DAE

;-------------------------------------------------------------------------------

DO_DAI:
        AM_IMM
        OP_DAI

;-------------------------------------------------------------------------------

DO_DINT:
        AM_INH
        OP_DINT

;-------------------------------------------------------------------------------

DO_DLD_IDX0:
        AM_IDX  R_P0
        OP_DLD

DO_DLD_IDX1:
        AM_IDX  R_P1
        OP_DLD

DO_DLD_IDX2:
        AM_IDX  R_P2
        OP_DLD

DO_DLD_IDX3:
        AM_IDX  R_P3
        OP_DLD

;-------------------------------------------------------------------------------

DO_DLY:
        AM_IMM
        OP_DLY

;-------------------------------------------------------------------------------

DO_HALT:
        AM_INH
        OP_HALT

;-------------------------------------------------------------------------------

DO_IEN:
        AM_INH
        OP_IEN

;-------------------------------------------------------------------------------

DO_ILD_IDX0:
        AM_IDX  R_P0
        OP_ILD

DO_ILD_IDX1:
        AM_IDX  R_P1
        OP_ILD

DO_ILD_IDX2:
        AM_IDX  R_P2
        OP_ILD

DO_ILD_IDX3:
        AM_IDX  R_P3
        OP_ILD

;-------------------------------------------------------------------------------

DO_JMP0:
        AM_REL  R_P0
        OP_JMP

DO_JMP1:
        AM_REL  R_P1
        OP_JMP

DO_JMP2:
        AM_REL  R_P2
        OP_JMP

DO_JMP3:
        AM_REL  R_P3
        OP_JMP

;-------------------------------------------------------------------------------

DO_JNZ0:
        AM_REL  R_P0
        OP_JNZ

DO_JNZ1:
        AM_REL  R_P1
        OP_JNZ

DO_JNZ2:
        AM_REL  R_P2
        OP_JNZ

DO_JNZ3:
        AM_REL  R_P3
        OP_JNZ

;-------------------------------------------------------------------------------

DO_JP0:
        AM_REL  R_P0
        OP_JP 

DO_JP1:
        AM_REL  R_P1
        OP_JP 

DO_JP2:
        AM_REL  R_P2
        OP_JP 

DO_JP3:
        AM_REL  R_P3
        OP_JP 

;-------------------------------------------------------------------------------

DO_JZ0:
        AM_REL  R_P0
        OP_JZ 

DO_JZ1:
        AM_REL  R_P1
        OP_JZ 

DO_JZ2:
        AM_REL  R_P2
        OP_JZ 

DO_JZ3:
        AM_REL  R_P3
        OP_JZ 

;-------------------------------------------------------------------------------

DO_LD_IDX0:
        AM_IDX  R_P0
        OP_LD

DO_LD_IDX1:
        AM_IDX  R_P1
        OP_LD

DO_LD_IDX2:
        AM_IDX  R_P2
        OP_LD

DO_LD_IDX3:
        AM_IDX  R_P3
        OP_LD

DO_LD_AIX1:
        AM_AIX  R_P1
        OP_LD

DO_LD_AIX2:
        AM_AIX  R_P2
        OP_LD

DO_LD_AIX3:
        AM_AIX  R_P3
        OP_LD

;-------------------------------------------------------------------------------

DO_LDE:
        AM_INH
        OP_LDE

;-------------------------------------------------------------------------------

DO_LDI:
        AM_IMM
        OP_LDI

;-------------------------------------------------------------------------------

DO_NOP:
        AM_INH
        OP_NOP

;-------------------------------------------------------------------------------

DO_OR_IDX0:
        AM_IDX  R_P0
        OP_OR

DO_OR_IDX1:
        AM_IDX  R_P1
        OP_OR

DO_OR_IDX2:
        AM_IDX  R_P2
        OP_OR

DO_OR_IDX3:
        AM_IDX  R_P3
        OP_OR

DO_OR_AIX1:
        AM_AIX  R_P1
        OP_OR

DO_OR_AIX2:
        AM_AIX  R_P2
        OP_OR

DO_OR_AIX3:
        AM_AIX  R_P3
        OP_OR

;-------------------------------------------------------------------------------

DO_ORE:
        AM_INH
        OP_ORE

;-------------------------------------------------------------------------------

DO_ORI:
        AM_IMM
        OP_ORI

;-------------------------------------------------------------------------------

DO_RR:
        AM_INH
        OP_RR

;-------------------------------------------------------------------------------

DO_RRL:
        AM_INH
        OP_RRL

;-------------------------------------------------------------------------------

DO_SCL:
        AM_INH
        OP_SCL

;-------------------------------------------------------------------------------

DO_SIO:
        AM_INH
        OP_SIO

;-------------------------------------------------------------------------------

DO_SR:
        AM_INH
        OP_SR

;-------------------------------------------------------------------------------

DO_SRL:
        AM_INH
        OP_SRL

;-------------------------------------------------------------------------------

DO_ST_IDX0:
        AM_IDX  R_P0
        OP_ST

DO_ST_IDX1:
        AM_IDX  R_P1
        OP_ST

DO_ST_IDX2:
        AM_IDX  R_P2
        OP_ST

DO_ST_IDX3:
        AM_IDX  R_P3
        OP_ST

DO_ST_AIX1:
        AM_AIX  R_P1
        OP_ST

DO_ST_AIX2:
        AM_AIX  R_P2
        OP_ST

DO_ST_AIX3:
        AM_AIX  R_P3
        OP_ST

;-------------------------------------------------------------------------------

DO_XAE:
        AM_INH
        OP_XAE

;-------------------------------------------------------------------------------

DO_XOR_IDX0:
        AM_IDX  R_P0
        OP_XOR

DO_XOR_IDX1:
        AM_IDX  R_P1
        OP_XOR

DO_XOR_IDX2:
        AM_IDX  R_P2
        OP_XOR

DO_XOR_IDX3:
        AM_IDX  R_P3
        OP_XOR

DO_XOR_AIX1:
        AM_AIX  R_P1
        OP_XOR

DO_XOR_AIX2:
        AM_AIX  R_P2
        OP_XOR

DO_XOR_AIX3:
        AM_AIX  R_P3
        OP_XOR
;-------------------------------------------------------------------------------

DO_XPAH0:
        AM_INH
        OP_XPAH R_P0

DO_XPAH1:
        AM_INH
        OP_XPAH R_P1

DO_XPAH2:
        AM_INH
        OP_XPAH R_P2

DO_XPAH3:
        AM_INH
        OP_XPAH R_P3

;-------------------------------------------------------------------------------

DO_XPAL0:
        AM_INH
        OP_XPAL R_P0

DO_XPAL1:
        AM_INH
        OP_XPAL R_P1

DO_XPAL2:
        AM_INH
        OP_XPAL R_P2

DO_XPAL3:
        AM_INH
        OP_XPAL R_P3

;-------------------------------------------------------------------------------

DO_XPPC0:
        AM_INH
        OP_XPPC R_P0

DO_XPPC1:
        AM_INH
        OP_XPPC R_P1

DO_XPPC2:
        AM_INH
        OP_XPPC R_P2

DO_XPPC3:
        AM_INH
        OP_XPPC R_P3

;-------------------------------------------------------------------------------

DO_XRE:
        AM_INH
        OP_XRE

;-------------------------------------------------------------------------------

DO_XRI:
        AM_IMM
        OP_XRI

;-------------------------------------------------------------------------------

DO_ERR:
        AM_INH
        OP_ERR

;-------------------------------------------------------------------------------

DO_TXD:
        AM_INH
        OP_TXD

DO_RXD:
        AM_INH
        OP_RXD

;===============================================================================
; NIBL (Tiny-BASIC)
;-------------------------------------------------------------------------------
; A 4K ROM that is mapped to page 0

        .section .nibl_scmp,code,align(0x1000)
NIBL:
        .incbin "code/scmp/nibl/nibl.bin"

;===============================================================================
; FORTH
;-------------------------------------------------------------------------------
; A 4K ROM that is mapped to page C

        .section .forth_scmp,code,align(0x1000)
FORTH:
        .incbin "code/scmp/forth/forth.bin"

;===============================================================================
; LISP
;-------------------------------------------------------------------------------
; An 8K ROM that is mapped to pages D & E

        .section .lisp_scmp,code,align(0x1000)
LISP:
        .incbin "code/scmp/lisp/lisp.bin"

;===============================================================================
; SCARAB (Debugger)
;-------------------------------------------------------------------------------
; A 4K ROM that is mapped to page F

        .section .scarab_scmp,code,align(0x1000)
SCARAB:
        .incbin "code/scmp/scarab/scarab.bin"

        .end
