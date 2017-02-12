;===============================================================================
;  _____ __  __       _  ___   ___ ____
; | ____|  \/  |     / |( _ ) / _ \___ \
; |  _| | |\/| |_____| |/ _ \| | | |__) |
; | |___| |  | |_____| | (_) | |_| / __/
; |_____|_|  |_|     |_|\___/ \___/_____|
;
; An RCA CDP1802 Emulator
;-------------------------------------------------------------------------------
; Copyright (C)2014-2016 HandCoded Software Ltd.
; All rights reserved.
;
; This work is made available under the terms of the Creative Commons
; Attribution-NonCommercial-ShareAlike 4.0 International license. Open the
; following URL to see the details.
;
; http://creativecommons.org/licenses/by-nc-sa/4.0/
;-------------------------------------------------------------------------------
;
; Notes:
;
;===============================================================================
; Revision History:
;
; 2014-12-16 AJ Initial version
;-------------------------------------------------------------------------------

        .include "hardware.inc"
        .include "em-retro.inc"
        .include "em-1802.inc"

;===============================================================================
; Data Area
;-------------------------------------------------------------------------------

        .section .nbss,bss,near
REGS:
        .space  16 * 2

;===============================================================================
;-------------------------------------------------------------------------------

        .section .1802,code
        
        .global EM_1802
        .extern CYCLE
        .extern PutStr
EM_1802:
        call    PutStr
        .asciz  "EM-1802 [16.09]\r\n"

        mov     #REGS,w0
        mov     w0,R_REGS
        repeat  #15                     ; Clear all the registers
        clr     [w0++]
        clr     R_P
        clr     R_X
        clr     R_D
        clr     R_SR
        clr     R_IE

        mov     #MEMORY_MAP,M_BASE      ; Initialise memory map
        clr     M_FLAG                  ; .. and read-only flags

        mov     #0x0fff,M_MASK

        mov     #edspage(RAM1),w1       ; RAM  0x0000-0x0fff
        mov     #edsoffset(RAM1),w2
        mov     w1,[M_BASE+ 0]
        mov     w2,[M_BASE+ 2]
        mov     #edspage(RAM1),w1       ; RAM  0x1000-0x1fff
        mov     #edsoffset(RAM1),w2
        mov     w1,[M_BASE+ 4]
        mov     w2,[M_BASE+ 6]
        mov     #edspage(RAM1),w1       ; RAM  0x2000-0x2fff
        mov     #edsoffset(RAM1),w2
        mov     w1,[M_BASE+ 8]
        mov     w2,[M_BASE+10]
        mov     #edspage(RAM1),w1       ; RAM  0x3000-0x3fff
        mov     #edsoffset(RAM1),w2
        mov     w1,[M_BASE+12]
        mov     w2,[M_BASE+14]
        mov     #edspage(RAM1),w1       ; RAM  0x4000-0x4fff
        mov     #edsoffset(RAM1),w2
        mov     w1,[M_BASE+16]
        mov     w2,[M_BASE+18]

        mov     #edspage(RAM1),w1       ; RAM  0x5000-0x5fff
        mov     #edsoffset(RAM1),w2
        mov     w1,[M_BASE+20]
        mov     w2,[M_BASE+22]
        mov     #edspage(RAM2),w1       ; RAM  0x6000-0x6fff
        mov     #edsoffset(RAM2),w2
        mov     w1,[M_BASE+24]
        mov     w2,[M_BASE+26]
        mov     #edspage(RAM3),w1       ; RAM  0x7000-0x7fff
        mov     #edsoffset(RAM3),w2
        mov     w1,[M_BASE+28]
        mov     w2,[M_BASE+30]
        mov     #edspage(RAM4),w1       ; RAM  0x8000-0x8fff
        mov     #edsoffset(RAM4),w2
        mov     w1,[M_BASE+32]
        mov     w2,[M_BASE+34]
        mov     #edspage(RAM5),w1       ; RAM  0x9000-0x9fff
        mov     #edsoffset(RAM5),w2
        mov     w1,[M_BASE+36]
        mov     w2,[M_BASE+38]
        mov     #edspage(RAM6),w1       ; RAM  0xa000-0xafff
        mov     #edsoffset(RAM6),w2
        mov     w1,[M_BASE+40]
        mov     w2,[M_BASE+42]
        mov     #edspage(RAM7),w1       ; RAM  0xb000-0xbfff
        mov     #edsoffset(RAM7),w2
        mov     w1,[M_BASE+44]
        mov     w2,[M_BASE+46]
        mov     #edspage(RAM8),w1       ; RAM  0xc000-0xcfff
        mov     #edsoffset(RAM8),w2
        mov     w1,[M_BASE+48]
        mov     w2,[M_BASE+50]
        mov     #edspage(RAM9),w1       ; RAM  0xd000-0xdfff
        mov     #edsoffset(RAM9),w2
        mov     w1,[M_BASE+52]
        mov     w2,[M_BASE+54]
        mov     #edspage(RAMA),w1       ; RAM  0xe000-0xefff
        mov     #edsoffset(RAMA),w2
        mov     w1,[M_BASE+56]
        mov     w2,[M_BASE+58]
        mov     #edspage(RAMB),w1       ; RAM  0xf000-0xffff
        mov     #edsoffset(RAMB),w2
        mov     w1,[M_BASE+60]
        mov     w2,[M_BASE+62]

        clr     CYCLE
Run:
        rcall   Step
        add     CYCLE
1:      cp0     CYCLE
        bra     gt,1b
        bra     Run

Step:
; Interrupt handling

        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w0
        bra     w0

;-------------------------------------------------------------------------------

        bra     DO_IDL                  ; 00 - IDL
        bra     DO_LDN_R1               ; 01 - LDN R1
        bra     DO_LDN_R2               ; 02 - LDN R2
        bra     DO_LDN_R3               ; 03 - LDN R3
        bra     DO_LDN_R4               ; 04 - LDN R4
        bra     DO_LDN_R5               ; 05 - LDN R5
        bra     DO_LDN_R6               ; 06 - LDN R6
        bra     DO_LDN_R7               ; 07 - LDN R7
        bra     DO_LDN_R8               ; 08 - LDN R8
        bra     DO_LDN_R9               ; 09 - LDN R9
        bra     DO_LDN_RA               ; 0a - LDN RA
        bra     DO_LDN_RB               ; 0b - LDN RB
        bra     DO_LDN_RC               ; 0c - LDN RC
        bra     DO_LDN_RD               ; 0d - LDN RD
        bra     DO_LDN_RE               ; 0e - LDN RE
        bra     DO_LDN_RF               ; 0f - LDN RF

        bra     DO_INC_R0               ; 10 - INC R0
        bra     DO_INC_R1               ; 11 - INC R1
        bra     DO_INC_R2               ; 12 - INC R2
        bra     DO_INC_R3               ; 13 - INC R3
        bra     DO_INC_R4               ; 14 - INC R4
        bra     DO_INC_R5               ; 15 - INC R5
        bra     DO_INC_R6               ; 16 - INC R6
        bra     DO_INC_R7               ; 17 - INC R7
        bra     DO_INC_R8               ; 18 - INC R8
        bra     DO_INC_R9               ; 19 - INC R9
        bra     DO_INC_RA               ; 1a - INC RA
        bra     DO_INC_RB               ; 1b - INC RB
        bra     DO_INC_RC               ; 1c - INC RC
        bra     DO_INC_RD               ; 1d - INC RD
        bra     DO_INC_RE               ; 1e - INC RE
        bra     DO_INC_RF               ; 1f - INC RF

        bra     DO_DEC_R0               ; 20 - DEC R0
        bra     DO_DEC_R1               ; 21 - DEC R1
        bra     DO_DEC_R2               ; 22 - DEC R2
        bra     DO_DEC_R3               ; 23 - DEC R3
        bra     DO_DEC_R4               ; 24 - DEC R4
        bra     DO_DEC_R5               ; 25 - DEC R5
        bra     DO_DEC_R6               ; 26 - DEC R6
        bra     DO_DEC_R7               ; 27 - DEC R7
        bra     DO_DEC_R8               ; 28 - DEC R8
        bra     DO_DEC_R9               ; 29 - DEC R9
        bra     DO_DEC_RA               ; 2a - DEC RA
        bra     DO_DEC_RB               ; 2b - DEC RB
        bra     DO_DEC_RC               ; 2c - DEC RC
        bra     DO_DEC_RD               ; 2d - DEC RD
        bra     DO_DEC_RE               ; 2e - DEC RE
        bra     DO_DEC_RF               ; 2f - DEC RF

        bra     DO_BR                   ; 30 - BR
        bra     DO_BQ                   ; 31 - BQ
        bra     DO_BZ                   ; 32 - BZ
        bra     DO_BDF                  ; 33 - BDF
        bra     DO_B1                   ; 34 - B1
        bra     DO_B2                   ; 35 - B2
        bra     DO_B3                   ; 36 - B3
        bra     DO_B4                   ; 37 - B4
        bra     DO_NBR                  ; 38 - NBR
        bra     DO_BNQ                  ; 39 - BNQ
        bra     DO_BNZ                  ; 3a - BNZ
        bra     DO_BNF                  ; 3b - BNF
        bra     DO_BN1                  ; 3c - BN1
        bra     DO_BN2                  ; 3d - BN2
        bra     DO_BN3                  ; 3e - BN3
        bra     DO_BN4                  ; 3f - BN4

        bra     DO_LDA_R0               ; 40 - LDA R0
        bra     DO_LDA_R1               ; 41 - LDA R1
        bra     DO_LDA_R2               ; 42 - LDA R2
        bra     DO_LDA_R3               ; 43 - LDA R3
        bra     DO_LDA_R4               ; 44 - LDA R4
        bra     DO_LDA_R5               ; 45 - LDA R5
        bra     DO_LDA_R6               ; 46 - LDA R6
        bra     DO_LDA_R7               ; 47 - LDA R7
        bra     DO_LDA_R8               ; 48 - LDA R8
        bra     DO_LDA_R9               ; 49 - LDA R9
        bra     DO_LDA_RA               ; 4a - LDA RA
        bra     DO_LDA_RB               ; 4b - LDA RB
        bra     DO_LDA_RC               ; 4c - LDA RC
        bra     DO_LDA_RD               ; 4d - LDA RD
        bra     DO_LDA_RE               ; 4e - LDA RE
        bra     DO_LDA_RF               ; 4f - LDA RF

        bra     DO_STR_R0               ; 50 - STR R0
        bra     DO_STR_R1               ; 51 - STR R1
        bra     DO_STR_R2               ; 52 - STR R2
        bra     DO_STR_R3               ; 53 - STR R3
        bra     DO_STR_R4               ; 54 - STR R4
        bra     DO_STR_R5               ; 55 - STR R5
        bra     DO_STR_R6               ; 56 - STR R6
        bra     DO_STR_R7               ; 57 - STR R7
        bra     DO_STR_R8               ; 58 - STR R8
        bra     DO_STR_R9               ; 59 - STR R9
        bra     DO_STR_RA               ; 5a - STR RA
        bra     DO_STR_RB               ; 5b - STR RB
        bra     DO_STR_RC               ; 5c - STR RC
        bra     DO_STR_RD               ; 5d - STR RD
        bra     DO_STR_RE               ; 5e - STR RE
        bra     DO_STR_RF               ; 5f - STR RF

        bra     DO_IRX                  ; 60 - IRX
        bra     DO_OUT1                 ; 61 - OUT 1
        bra     DO_OUT2                 ; 62 - OUT 2
        bra     DO_OUT3                 ; 63 - OUT 3
        bra     DO_OUT4                 ; 64 - OUT 4
        bra     DO_OUT5                 ; 65 - OUT 5
        bra     DO_OUT6                 ; 66 - OUT 6
        bra     DO_OUT7                 ; 67 - OUT 7
        bra     DO_ERR                  ; 68 -
        bra     DO_INP1                 ; 69 - INP 1
        bra     DO_INP2                 ; 6a - INP 2
        bra     DO_INP3                 ; 6b - INP 3
        bra     DO_INP4                 ; 6c - INP 4
        bra     DO_INP5                 ; 6d - INP 5
        bra     DO_INP6                 ; 6e - INP 6
        bra     DO_INP7                 ; 6f - INP 7

        bra     DO_RET                  ; 70 - RET
        bra     DO_DIS                  ; 71 - DIS
        bra     DO_LDXA                 ; 72 - LDXA
        bra     DO_STXD                 ; 73 - STXD
        bra     DO_ADC                  ; 74 - ADC
        bra     DO_SDB                  ; 75 - SDB
        bra     DO_SHRC                 ; 76 - SHRC
        bra     DO_SMB                  ; 77 - SMB
        bra     DO_SAV                  ; 78 - SAV
        bra     DO_MARK                 ; 79 - MARK
        bra     DO_REQ                  ; 7a - REQ
        bra     DO_SEQ                  ; 7b - SEQ
        bra     DO_ADCI                 ; 7c - ADCI
        bra     DO_SDBI                 ; 7d - SDBI
        bra     DO_SHLC                 ; 7e - SHLC
        bra     DO_SMBI                 ; 7f - SMBI

        bra     DO_GLO_R0               ; 80 - GLO R0
        bra     DO_GLO_R1               ; 81 - GLO R1
        bra     DO_GLO_R2               ; 82 - GLO R2
        bra     DO_GLO_R3               ; 83 - GLO R3
        bra     DO_GLO_R4               ; 84 - GLO R4
        bra     DO_GLO_R5               ; 85 - GLO R5
        bra     DO_GLO_R6               ; 86 - GLO R6
        bra     DO_GLO_R7               ; 87 - GLO R7
        bra     DO_GLO_R8               ; 88 - GLO R8
        bra     DO_GLO_R9               ; 89 - GLO R9
        bra     DO_GLO_RA               ; 8a - GLO RA
        bra     DO_GLO_RB               ; 8b - GLO RB
        bra     DO_GLO_RC               ; 8c - GLO RC
        bra     DO_GLO_RD               ; 8d - GLO RD
        bra     DO_GLO_RE               ; 8e - GLO RE
        bra     DO_GLO_RF               ; 8d - GLO RF

        bra     DO_GHI_R0               ; 90 - GHI R0
        bra     DO_GHI_R1               ; 91 - GHI R1
        bra     DO_GHI_R2               ; 92 - GHI R2
        bra     DO_GHI_R3               ; 93 - GHI R3
        bra     DO_GHI_R4               ; 94 - GHI R4
        bra     DO_GHI_R5               ; 95 - GHI R5
        bra     DO_GHI_R6               ; 96 - GHI R6
        bra     DO_GHI_R7               ; 97 - GHI R7
        bra     DO_GHI_R8               ; 98 - GHI R8
        bra     DO_GHI_R9               ; 99 - GHI R9
        bra     DO_GHI_RA               ; 9a - GHI RA
        bra     DO_GHI_RB               ; 9b - GHI RB
        bra     DO_GHI_RC               ; 9c - GHI RC
        bra     DO_GHI_RD               ; 9d - GHI RD
        bra     DO_GHI_RE               ; 9e - GHI RE
        bra     DO_GHI_RF               ; 9f - GHI RF

        bra     DO_PLO_R0               ; a0 - PLO R0
        bra     DO_PLO_R1               ; a1 - PLO R1
        bra     DO_PLO_R2               ; a2 - PLO R2
        bra     DO_PLO_R3               ; a3 - PLO R3
        bra     DO_PLO_R4               ; a4 - PLO R4
        bra     DO_PLO_R5               ; a5 - PLO R5
        bra     DO_PLO_R6               ; a6 - PLO R6
        bra     DO_PLO_R7               ; a7 - PLO R7
        bra     DO_PLO_R8               ; a8 - PLO R8
        bra     DO_PLO_R9               ; a9 - PLO R9
        bra     DO_PLO_RA               ; aa - PLO RA
        bra     DO_PLO_RB               ; ab - PLO RB
        bra     DO_PLO_RC               ; ac - PLO RC
        bra     DO_PLO_RD               ; ad - PLO RD
        bra     DO_PLO_RE               ; ae - PLO RE
        bra     DO_PLO_RF               ; af - PLO RF

        bra     DO_PHI_R0               ; b0 - PHI R0
        bra     DO_PHI_R1               ; b1 - PHI R1
        bra     DO_PHI_R2               ; b2 - PHI R2
        bra     DO_PHI_R3               ; b3 - PHI R3
        bra     DO_PHI_R4               ; b4 - PHI R4
        bra     DO_PHI_R5               ; b5 - PHI R5
        bra     DO_PHI_R6               ; b6 - PHI R6
        bra     DO_PHI_R7               ; b7 - PHI R7
        bra     DO_PHI_R8               ; b8 - PHI R8
        bra     DO_PHI_R9               ; b9 - PHI R9
        bra     DO_PHI_RA               ; ba - PHI RA
        bra     DO_PHI_RB               ; bb - PHI RB
        bra     DO_PHI_RC               ; bc - PHI RC
        bra     DO_PHI_RD               ; bd - PHI RD
        bra     DO_PHI_RE               ; be - PHI RE
        bra     DO_PHI_RF               ; bf - PHI RF

        bra     DO_LBR                  ; c0 - LBR
        bra     DO_LBQ                  ; c1 - LBQ
        bra     DO_LBZ                  ; c2 - LBZ
        bra     DO_LBDF                 ; c3 - LBDF
        bra     DO_NOP                  ; c4 - NOP
        bra     DO_LSNQ                 ; c5 - LSNQ
        bra     DO_LSNZ                 ; c6 - LSNZ
        bra     DO_LSNF                 ; c7 - LSNF
        bra     DO_NLBR                 ; c8 - NLBR
        bra     DO_LBNQ                 ; c9 - LBNQ
        bra     DO_LBNZ                 ; ca - LBNZ
        bra     DO_LBNF                 ; cb - LBNF
        bra     DO_LSIE                 ; cc - LSIE
        bra     DO_LSQ                  ; cd - LSQ
        bra     DO_LSZ                  ; ce - LSZ
        bra     DO_LSDF                 ; cf - LSDF

        bra     DO_SEP_R0               ; d0 - SEP R0
        bra     DO_SEP_R1               ; d1 - SEP R1
        bra     DO_SEP_R2               ; d2 - SEP R2
        bra     DO_SEP_R3               ; d3 - SEP R3
        bra     DO_SEP_R4               ; d4 - SEP R4
        bra     DO_SEP_R5               ; d5 - SEP R5
        bra     DO_SEP_R6               ; d6 - SEP R6
        bra     DO_SEP_R7               ; d7 - SEP R7
        bra     DO_SEP_R8               ; d8 - SEP R8
        bra     DO_SEP_R9               ; d9 - SEP R9
        bra     DO_SEP_RA               ; da - SEP RA
        bra     DO_SEP_RB               ; db - SEP RB
        bra     DO_SEP_RC               ; dc - SEP RC
        bra     DO_SEP_RD               ; dd - SEP RD
        bra     DO_SEP_RE               ; de - SEP RE
        bra     DO_SEP_RF               ; df - SEP RF

        bra     DO_SEX_R0               ; e0 - SEX R0
        bra     DO_SEX_R1               ; e1 - SEX R1
        bra     DO_SEX_R2               ; e2 - SEX R2
        bra     DO_SEX_R3               ; e3 - SEX R3
        bra     DO_SEX_R4               ; e4 - SEX R4
        bra     DO_SEX_R5               ; e5 - SEX R5
        bra     DO_SEX_R6               ; e6 - SEX R6
        bra     DO_SEX_R7               ; e7 - SEX R7
        bra     DO_SEX_R8               ; e8 - SEX R8
        bra     DO_SEX_R9               ; e9 - SEX R9
        bra     DO_SEX_RA               ; ea - SEX RA
        bra     DO_SEX_RB               ; eb - SEX RB
        bra     DO_SEX_RC               ; ec - SEX RC
        bra     DO_SEX_RD               ; ed - SEX RD
        bra     DO_SEX_RE               ; ee - SEX RE
        bra     DO_SEX_RF               ; ef - SEX RF

        bra     DO_LDX                  ; f0 - LDX
        bra     DO_OR                   ; f1 - OR
        bra     DO_AND                  ; f2 - AND
        bra     DO_XOR                  ; f3 - XOR
        bra     DO_ADD                  ; f4 - ADD
        bra     DO_SD                   ; f5 - SD
        bra     DO_SHR                  ; f6 - SHR
        bra     DO_SM                   ; f7 - SM
        bra     DO_LDI                  ; f8 - LDI
        bra     DO_ORI                  ; f9 - ORI
        bra     DO_ANI                  ; fa - ANI
        bra     DO_XRI                  ; fb - XRI
        bra     DO_ADI                  ; fc - ADI
        bra     DO_SDI                  ; fd - SDI
        bra     DO_SHL                  ; fe - SHL
        bra     DO_SMI                  ; ff - SMI

;-------------------------------------------------------------------------------

DO_ADC:
        OP_ADC

;-------------------------------------------------------------------------------

DO_ADCI:
        OP_ADCI

;-------------------------------------------------------------------------------

DO_ADD:
        OP_ADD

;-------------------------------------------------------------------------------

DO_ADI:
        OP_ADI

;-------------------------------------------------------------------------------

DO_AND:
        OP_AND

;-------------------------------------------------------------------------------

DO_ANI:
        OP_ANI

;-------------------------------------------------------------------------------

DO_B1:
        OP_B    EF1_PORT,EF1_PIN

DO_B2:
        OP_B    EF2_PORT,EF2_PIN

DO_B3:
        OP_B    EF3_PORT,EF3_PIN

DO_B4:
        OP_B    EF4_PORT,EF4_PIN

;-------------------------------------------------------------------------------

DO_BDF:
        OP_BDF

;-------------------------------------------------------------------------------

DO_BN1:
        OP_BN   EF1_PORT,EF1_PIN

DO_BN2:
        OP_BN   EF2_PORT,EF2_PIN

DO_BN3:
        OP_BN   EF3_PORT,EF3_PIN

DO_BN4:
        OP_BN   EF4_PORT,EF4_PIN

;-------------------------------------------------------------------------------

DO_BNF:
        OP_BNF

;-------------------------------------------------------------------------------

DO_BNQ:
        OP_BNQ

;-------------------------------------------------------------------------------

DO_BNZ:
        OP_BNZ

;-------------------------------------------------------------------------------

DO_BQ:
        OP_BQ

;-------------------------------------------------------------------------------

DO_BR:
        OP_BR

;-------------------------------------------------------------------------------

DO_BZ:
        OP_BZ

;-------------------------------------------------------------------------------

DO_DEC_R0:
        OP_DEC  0

DO_DEC_R1:
        OP_DEC  1

DO_DEC_R2:
        OP_DEC  2

DO_DEC_R3:
        OP_DEC  3

DO_DEC_R4:
        OP_DEC  4

DO_DEC_R5:
        OP_DEC  5

DO_DEC_R6:
        OP_DEC  6

DO_DEC_R7:
        OP_DEC  7

DO_DEC_R8:
        OP_DEC  8

DO_DEC_R9:
        OP_DEC  9

DO_DEC_RA:
        OP_DEC  10

DO_DEC_RB:
        OP_DEC  11

DO_DEC_RC:
        OP_DEC  12

DO_DEC_RD:
        OP_DEC  13

DO_DEC_RE:
        OP_DEC  14

DO_DEC_RF:
        OP_DEC  15

;-------------------------------------------------------------------------------

DO_DIS:
        OP_DIS

;-------------------------------------------------------------------------------

DO_GHI_R0:
        OP_GHI  0

DO_GHI_R1:
        OP_GHI  1

DO_GHI_R2:
        OP_GHI  2

DO_GHI_R3:
        OP_GHI  3

DO_GHI_R4:
        OP_GHI  4

DO_GHI_R5:
        OP_GHI  5

DO_GHI_R6:
        OP_GHI  6

DO_GHI_R7:
        OP_GHI  7

DO_GHI_R8:
        OP_GHI  8

DO_GHI_R9:
        OP_GHI  9

DO_GHI_RA:
        OP_GHI  10

DO_GHI_RB:
        OP_GHI  11

DO_GHI_RC:
        OP_GHI  12

DO_GHI_RD:
        OP_GHI  13

DO_GHI_RE:
        OP_GHI  14

DO_GHI_RF:
        OP_GHI  15

;-------------------------------------------------------------------------------

DO_GLO_R0:
        OP_GLO  0

DO_GLO_R1:
        OP_GLO  1

DO_GLO_R2:
        OP_GLO  2

DO_GLO_R3:
        OP_GLO  3

DO_GLO_R4:
        OP_GLO  4

DO_GLO_R5:
        OP_GLO  5

DO_GLO_R6:
        OP_GLO  6

DO_GLO_R7:
        OP_GLO  7

DO_GLO_R8:
        OP_GLO  8

DO_GLO_R9:
        OP_GLO  9

DO_GLO_RA:
        OP_GLO  10

DO_GLO_RB:
        OP_GLO  11

DO_GLO_RC:
        OP_GLO  12

DO_GLO_RD:
        OP_GLO  13

DO_GLO_RE:
        OP_GLO  14

DO_GLO_RF:
        OP_GLO  15

;-------------------------------------------------------------------------------

DO_IDL:
        OP_IDL

;-------------------------------------------------------------------------------

DO_INC_R0:
        OP_INC  0

DO_INC_R1:
        OP_INC  1

DO_INC_R2:
        OP_INC  2

DO_INC_R3:
        OP_INC  3

DO_INC_R4:
        OP_INC  4

DO_INC_R5:
        OP_INC  5

DO_INC_R6:
        OP_INC  6

DO_INC_R7:
        OP_INC  7

DO_INC_R8:
        OP_INC  8

DO_INC_R9:
        OP_INC  9

DO_INC_RA:
        OP_INC  10

DO_INC_RB:
        OP_INC  11

DO_INC_RC:
        OP_INC  12

DO_INC_RD:
        OP_INC  13

DO_INC_RE:
        OP_INC  14

DO_INC_RF:
        OP_INC  15

;-------------------------------------------------------------------------------

DO_INP1:
        OP_INP  1

DO_INP2:
        OP_INP  2

DO_INP3:
        OP_INP  3

DO_INP4:
        OP_INP  4

DO_INP5:
        OP_INP  5

DO_INP6:
        OP_INP  6

DO_INP7:
        OP_INP  7

;-------------------------------------------------------------------------------

DO_IRX:
        OP_IRX

;-------------------------------------------------------------------------------

DO_LBDF:
        OP_LBDF

;-------------------------------------------------------------------------------

DO_LBNF:
        OP_LBNF

;-------------------------------------------------------------------------------

DO_LBNQ:
        OP_LBNQ

;-------------------------------------------------------------------------------

DO_LBNZ:
        OP_LBNZ

;-------------------------------------------------------------------------------

DO_LBQ:
        OP_LBQ

;-------------------------------------------------------------------------------

DO_LBR:
        OP_LBR

;-------------------------------------------------------------------------------

DO_LBZ:
        OP_LBZ

;-------------------------------------------------------------------------------

DO_LDA_R0:
        OP_LDA  0

DO_LDA_R1:
        OP_LDA  1

DO_LDA_R2:
        OP_LDA  2

DO_LDA_R3:
        OP_LDA  3

DO_LDA_R4:
        OP_LDA  4

DO_LDA_R5:
        OP_LDA  5

DO_LDA_R6:
        OP_LDA  6

DO_LDA_R7:
        OP_LDA  7

DO_LDA_R8:
        OP_LDA  8

DO_LDA_R9:
        OP_LDA  9

DO_LDA_RA:
        OP_LDA  10

DO_LDA_RB:
        OP_LDA  11

DO_LDA_RC:
        OP_LDA  12

DO_LDA_RD:
        OP_LDA  13

DO_LDA_RE:
        OP_LDA  14

DO_LDA_RF:
        OP_LDA  15

;-------------------------------------------------------------------------------

DO_LDI:
        OP_LDI

;-------------------------------------------------------------------------------

DO_LDN_R1:
        OP_LDN  1

DO_LDN_R2:
        OP_LDN  2

DO_LDN_R3:
        OP_LDN  3

DO_LDN_R4:
        OP_LDN  4

DO_LDN_R5:
        OP_LDN  5

DO_LDN_R6:
        OP_LDN  6

DO_LDN_R7:
        OP_LDN  7

DO_LDN_R8:
        OP_LDN  8

DO_LDN_R9:
        OP_LDN  9

DO_LDN_RA:
        OP_LDN  10

DO_LDN_RB:
        OP_LDN  11

DO_LDN_RC:
        OP_LDN  12

DO_LDN_RD:
        OP_LDN  13

DO_LDN_RE:
        OP_LDN  14

DO_LDN_RF:
        OP_LDN  15

;-------------------------------------------------------------------------------

DO_LDX:
        OP_LDX

;-------------------------------------------------------------------------------

DO_LDXA:
        OP_LDXA

;-------------------------------------------------------------------------------

DO_LSDF:
        OP_LSDF

;-------------------------------------------------------------------------------

DO_LSIE:
        OP_LSIE

;-------------------------------------------------------------------------------

DO_LSNF:
        OP_LSNF

;-------------------------------------------------------------------------------

DO_LSNQ:
        OP_LSNQ

;-------------------------------------------------------------------------------

DO_LSNZ:
        OP_LSNZ

;-------------------------------------------------------------------------------

DO_LSQ:
        OP_LSQ

;-------------------------------------------------------------------------------

DO_LSZ:
        OP_LSZ

;-------------------------------------------------------------------------------

DO_MARK:
        OP_MARK

;-------------------------------------------------------------------------------

DO_NBR:
        OP_NBR

;-------------------------------------------------------------------------------

DO_NLBR:
        OP_NLBR

;-------------------------------------------------------------------------------

DO_NOP:
        OP_NOP

;-------------------------------------------------------------------------------

DO_OR:
        OP_OR

;-------------------------------------------------------------------------------

DO_ORI:
        OP_ORI

;-------------------------------------------------------------------------------

DO_OUT1:
        OP_OUT  1

DO_OUT2:
        OP_OUT  2

DO_OUT3:
        OP_OUT  3

DO_OUT4:
        OP_OUT  4

DO_OUT5:
        OP_OUT  5

DO_OUT6:
        OP_OUT  6

DO_OUT7:
        OP_OUT  7

;-------------------------------------------------------------------------------

DO_PHI_R0:
        OP_PHI  0

DO_PHI_R1:
        OP_PHI  1

DO_PHI_R2:
        OP_PHI  2

DO_PHI_R3:
        OP_PHI  3

DO_PHI_R4:
        OP_PHI  4

DO_PHI_R5:
        OP_PHI  5

DO_PHI_R6:
        OP_PHI  6

DO_PHI_R7:
        OP_PHI  7

DO_PHI_R8:
        OP_PHI  8

DO_PHI_R9:
        OP_PHI  9

DO_PHI_RA:
        OP_PHI  10

DO_PHI_RB:
        OP_PHI  11

DO_PHI_RC:
        OP_PHI  12

DO_PHI_RD:
        OP_PHI  13

DO_PHI_RE:
        OP_PHI  14

DO_PHI_RF:
        OP_PHI  15

;-------------------------------------------------------------------------------

DO_PLO_R0:
        OP_PLO  0

DO_PLO_R1:
        OP_PLO  1

DO_PLO_R2:
        OP_PLO  2

DO_PLO_R3:
        OP_PLO  3

DO_PLO_R4:
        OP_PLO  4

DO_PLO_R5:
        OP_PLO  5

DO_PLO_R6:
        OP_PLO  6

DO_PLO_R7:
        OP_PLO  7

DO_PLO_R8:
        OP_PLO  8

DO_PLO_R9:
        OP_PLO  9

DO_PLO_RA:
        OP_PLO  10

DO_PLO_RB:
        OP_PLO  11

DO_PLO_RC:
        OP_PLO  12

DO_PLO_RD:
        OP_PLO  13

DO_PLO_RE:
        OP_PLO  14

DO_PLO_RF:
        OP_PLO  15

;-------------------------------------------------------------------------------

DO_RET:
        OP_RET

;-------------------------------------------------------------------------------

DO_REQ:
        OP_REQ

;-------------------------------------------------------------------------------

DO_SAV:
        OP_SAV

;-------------------------------------------------------------------------------

DO_SD:
        OP_SD

;-------------------------------------------------------------------------------

DO_SDB:
        OP_SM

;-------------------------------------------------------------------------------

DO_SDBI:
        OP_SM

;-------------------------------------------------------------------------------

DO_SDI:
        OP_SDI

;-------------------------------------------------------------------------------

DO_SEP_R0:
        OP_SEP  0

DO_SEP_R1:
        OP_SEP  1

DO_SEP_R2:
        OP_SEP  2

DO_SEP_R3:
        OP_SEP  3

DO_SEP_R4:
        OP_SEP  4

DO_SEP_R5:
        OP_SEP  5

DO_SEP_R6:
        OP_SEP  6

DO_SEP_R7:
        OP_SEP  7

DO_SEP_R8:
        OP_SEP  8

DO_SEP_R9:
        OP_SEP  9

DO_SEP_RA:
        OP_SEP  10

DO_SEP_RB:
        OP_SEP  11

DO_SEP_RC:
        OP_SEP  12

DO_SEP_RD:
        OP_SEP  13

DO_SEP_RE:
        OP_SEP  14

DO_SEP_RF:
        OP_SEP  15

;-------------------------------------------------------------------------------

DO_SEQ:
        OP_SEQ

;-------------------------------------------------------------------------------

DO_SEX_R0:
        OP_SEX  0

DO_SEX_R1:
        OP_SEX  1

DO_SEX_R2:
        OP_SEX  2

DO_SEX_R3:
        OP_SEX  3

DO_SEX_R4:
        OP_SEX  4

DO_SEX_R5:
        OP_SEX  5

DO_SEX_R6:
        OP_SEX  6

DO_SEX_R7:
        OP_SEX  7

DO_SEX_R8:
        OP_SEX  8

DO_SEX_R9:
        OP_SEX  9

DO_SEX_RA:
        OP_SEX  10

DO_SEX_RB:
        OP_SEX  11

DO_SEX_RC:
        OP_SEX  12

DO_SEX_RD:
        OP_SEX  13

DO_SEX_RE:
        OP_SEX  14

DO_SEX_RF:
        OP_SEX  15

;-------------------------------------------------------------------------------

DO_SHL:
        OP_SHL

;-------------------------------------------------------------------------------

DO_SHLC:
        OP_SHLC

;-------------------------------------------------------------------------------

DO_SHR:
        OP_SHR

;-------------------------------------------------------------------------------

DO_SHRC:
        OP_SHLC

;-------------------------------------------------------------------------------

DO_SM:
        OP_SM

;-------------------------------------------------------------------------------

DO_SMB:
        OP_SMB

;-------------------------------------------------------------------------------

DO_SMBI:
        OP_SMBI

;-------------------------------------------------------------------------------

DO_SMI:
        OP_SMI

;-------------------------------------------------------------------------------

DO_STR_R0:
        OP_STR  0

DO_STR_R1:
        OP_STR  1

DO_STR_R2:
        OP_STR  2

DO_STR_R3:
        OP_STR  3

DO_STR_R4:
        OP_STR  4

DO_STR_R5:
        OP_STR  5

DO_STR_R6:
        OP_STR  6

DO_STR_R7:
        OP_STR  7

DO_STR_R8:
        OP_STR  8

DO_STR_R9:
        OP_STR  9

DO_STR_RA:
        OP_STR  10

DO_STR_RB:
        OP_STR  11

DO_STR_RC:
        OP_STR  12

DO_STR_RD:
        OP_STR  13

DO_STR_RE:
        OP_STR  14

DO_STR_RF:
        OP_STR  15

;-------------------------------------------------------------------------------

DO_STXD:
        OP_STXD

;-------------------------------------------------------------------------------

DO_XOR:
        OP_XOR

;-------------------------------------------------------------------------------

DO_XRI:
        OP_XRI

;-------------------------------------------------------------------------------

DO_ERR:
        OP_ERR

        .end
