;===============================================================================
;  _____ __  __        __    ___   ___   ___
; | ____|  \/  |      / /_  ( _ ) / _ \ / _ \
; |  _| | |\/| |_____| '_ \ / _ \| | | | | | |
; | |___| |  | |_____| (_) | (_) | |_| | |_| |
; |_____|_|  |_|      \___/ \___/ \___/ \___/
;
; A Motorola 6800 Emulator
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
; 2014-12-13 AJ Initial version
;-------------------------------------------------------------------------------

        .include "hardware.inc"
        .include "em-retro.inc"
        .include "em-6800.inc"

;===============================================================================
;-------------------------------------------------------------------------------

        .section .6800,code
        
        .global EM_6800
        .extern CYCLE
        .extern UartTx
        .extern UartRx
        .extern UartTxCount
        .extern UartRxCount
        .extern PutStr
EM_6800:
        call    PutStr
        .asciz  "EM-6800 [16.07]\r\n"

        mov     #MEMORY_MAP,M_BASE      ; Initialise memory map
        mov     #0xc000,M_FLAG          ; .. and read-only flags
        mov     #0x0fff,M_MASK

        mov     #edspage(RAM1),w1       ; RAM  0x0000-0x0fff
        mov     #edsoffset(RAM1),w2
        mov     w1,[M_BASE+ 0]
        mov     w2,[M_BASE+ 2]
        mov     #edspage(RAM2),w1       ; RAM  0x1000-0x1fff
        mov     #edsoffset(RAM2),w2
        mov     w1,[M_BASE+ 4]
        mov     w2,[M_BASE+ 6]
        mov     #edspage(RAM3),w1       ; RAM  0x2000-0x2fff
        mov     #edsoffset(RAM3),w2
        mov     w1,[M_BASE+ 8]
        mov     w2,[M_BASE+10]
        mov     #edspage(RAM4),w1       ; RAM  0x3000-0x3fff
        mov     #edsoffset(RAM4),w2
        mov     w1,[M_BASE+12]
        mov     w2,[M_BASE+14]
        mov     #edspage(RAM5),w1       ; RAM  0x4000-0x4fff
        mov     #edsoffset(RAM5),w2
        mov     w1,[M_BASE+16]
        mov     w2,[M_BASE+18]
        mov     #edspage(RAM6),w1       ; RAM  0x5000-0x5fff
        mov     #edsoffset(RAM6),w2
        mov     w1,[M_BASE+20]
        mov     w2,[M_BASE+22]
        mov     #edspage(RAM7),w1       ; RAM  0x6000-0x6fff
        mov     #edsoffset(RAM7),w2
        mov     w1,[M_BASE+24]
        mov     w2,[M_BASE+26]
        mov     #edspage(RAM8),w1       ; RAM  0x7000-0x7fff
        mov     #edsoffset(RAM8),w2
        mov     w1,[M_BASE+28]
        mov     w2,[M_BASE+30]

        mov     #edspage(BLANK),w1      ; EMPTY 0x8000-08fff
        mov     #edsoffset(BLANK),w2
        mov     w1,[M_BASE+32]
        mov     w2,[M_BASE+34]
        mov     #edspage(BLANK),w1      ; EMPTY 0x9000-09fff
        mov     #edsoffset(BLANK),w2
        mov     w1,[M_BASE+36]
        mov     w2,[M_BASE+38]

        mov     #edspage(RAM9),w1       ; RAM  0xa000-0xafff
        mov     #edsoffset(RAM9),w2
        mov     w1,[M_BASE+40]
        mov     w2,[M_BASE+42]
        mov     #edspage(RAMA),w1       ; RAM  0xb000-0xbfff
        mov     #edsoffset(RAMA),w2
        mov     w1,[M_BASE+44]
        mov     w2,[M_BASE+46]
        mov     #edspage(RAMB),w1       ; RAM  0xc000-0xcfff
        mov     #edsoffset(RAMB),w2
        mov     w1,[M_BASE+48]
        mov     w2,[M_BASE+50]

        mov     #edspage(BLANK),w1      ; EMPTY 0xd000-0dfff
        mov     #edsoffset(BLANK),w2
        mov     w1,[M_BASE+52]
        mov     w2,[M_BASE+54]

        mov     #edspage(WEEVIL),w1     ; ROM  0xe000-0xffff
        mov     #edsoffset(WEEVIL),w2
        mov     w1,[M_BASE+56]
        mov     w2,[M_BASE+58]
        mov     #edspage(WEEVIL+4096),w1
        mov     #edsoffset(WEEVIL+4096),w2
        mov     w1,[M_BASE+60]
        mov     w2,[M_BASE+62]

Reset:
        mov     #0xfffe,w2              ; Fetch the RES vector
        RD_ADDR w2,ze,R_PC
        inc     w2,w2
        RD_ADDR w2,ze,w3
        swap    R_PC                    ; .. and load PC
        ior     R_PC,w3,R_PC

; Load reset vector

        clr     CYCLE
Run:
        rcall   Step                    ; Run one instruction
        add     CYCLE                   ; .. and work out cycle delay
1:      cp0     CYCLE                   ; Wait until it has elapsed
        bra     gt,1b                   ; Done
        bra     Run

;-------------------------------------------------------------------------------

Step:
        RD_ADDR R_PC,ze,w3              ; Fetch the next opcode
        inc     R_PC,R_PC               ; .. incrementing the PC
        bra     w3                      ; And execute it

        bra     DO_ERR                  ; 00 -
        bra     DO_NOP_INH              ; 01 - NOP
        bra     DO_ERR                  ; 02 -
        bra     DO_ERR                  ; 03 -
        bra     DO_ERR                  ; 04 -
        bra     DO_ERR                  ; 05 -
        bra     DO_TAP_INH              ; 06 - TAP
        bra     DO_TPA_INH              ; 07 - TPA
        bra     DO_INX_INH              ; 08 - INX
        bra     DO_DEX_INH              ; 09 - DEX
        bra     DO_CLV_INH              ; 0a - CLV
        bra     DO_SEV_INH              ; 0b - SEV
        bra     DO_CLC_INH              ; 0c - CLC
        bra     DO_SEC_INH              ; 0d - SEC
        bra     DO_CLI_INH              ; 0e - CLI
        bra     DO_SEI_INH              ; 0f - SEI

        bra     DO_SBA_INH              ; 10 - SBA
        bra     DO_CBA_INH              ; 11 - CBA
        bra     DO_ERR                  ; 12 -
        bra     DO_ERR                  ; 13 -
        bra     DO_ERR                  ; 14 -
        bra     DO_ERR                  ; 15 -
        bra     DO_TAB_INH              ; 16 - TAB
        bra     DO_TBA_INH              ; 17 - TBA
        bra     DO_ERR                  ; 18 -
        bra     DO_DAA_INH              ; 19 - DAA
        bra     DO_ERR                  ; 1a -
        bra     DO_ABA_INH              ; 1b - ABA
        bra     DO_ERR                  ; 1c -
        bra     DO_ERR                  ; 1d -
        bra     DO_ERR                  ; 1e -
        bra     DO_ERR                  ; 1f -

        bra     DO_BRA_REL              ; 20 - BRA rel
        bra     DO_ERR                  ; 21 -
        bra     DO_BHI_REL              ; 22 - BHI rel
        bra     DO_BLS_REL              ; 23 - BLS rel
        bra     DO_BCC_REL              ; 24 - BCC rel
        bra     DO_BCS_REL              ; 25 - BCS rel
        bra     DO_BNE_REL              ; 26 - BNE rel
        bra     DO_BEQ_REL              ; 27 - BEQ rel
        bra     DO_BVC_REL              ; 28 - BVC rel
        bra     DO_BVS_REL              ; 29 - BVS rel
        bra     DO_BPL_REL              ; 2a - BPL rel
        bra     DO_BMI_REL              ; 2b - BMI rel
        bra     DO_BGE_REL              ; 2c - BGE rel
        bra     DO_BLT_REL              ; 2d - BLT rel
        bra     DO_BGT_REL              ; 2e - BGT rel
        bra     DO_BLE_REL              ; 2f - BLE rel

        bra     DO_TSX_INH              ; 30 - TSX
        bra     DO_INS_INH              ; 31 - INS
        bra     DO_PUL_A_INH            ; 32 - PUL A
        bra     DO_PUL_B_INH            ; 33 - PUL B
        bra     DO_DES_INH              ; 34 - DES
        bra     DO_TXS_INH              ; 35 - TXS
        bra     DO_PSH_A_INH            ; 36 - PSH A
        bra     DO_PSH_B_INH            ; 37 - PSH B
        bra     DO_ERR                  ; 38 -
        bra     DO_RTS_INH              ; 39 - RTS
        bra     DO_ERR                  ; 3a -
        bra     DO_RTI_INH              ; 3b - RTI
        bra     DO_ERR                  ; 3c -
        bra     DO_ERR                  ; 3d -
        bra     DO_WAI_INH              ; 3e - WAI
        bra     DO_SWI_INH              ; 3f - SWI

        bra     DO_NEG_A_INH            ; 40 - NEG A
        bra     DO_ERR                  ; 41 -
        bra     DO_ERR                  ; 42 -
        bra     DO_COM_A_INH            ; 43 - COM A
        bra     DO_LSR_A_INH            ; 44 - LSR A
        bra     DO_ERR                  ; 45 -
        bra     DO_ROR_A_INH            ; 46 - ROR A
        bra     DO_ASR_A_INH            ; 47 - ASR A
        bra     DO_ASL_A_INH            ; 48 - ASL A
        bra     DO_ROL_A_INH            ; 49 - ROL A
        bra     DO_DEC_A_INH            ; 4a - DEC A
        bra     DO_ERR                  ; 4b -
        bra     DO_INC_A_INH            ; 4c - INC A
        bra     DO_TST_A_INH            ; 4d - TST A
        bra     DO_ERR                  ; 4e -
        bra     DO_CLR_A_INH            ; 4f - CLR A

        bra     DO_NEG_B_INH            ; 50 - NEG B
        bra     DO_ERR                  ; 51 -
        bra     DO_ERR                  ; 52 -
        bra     DO_COM_B_INH            ; 53 - COM B
        bra     DO_LSR_B_INH            ; 54 - LSR B
        bra     DO_ERR                  ; 55 -
        bra     DO_ROR_B_INH            ; 56 - ROR B
        bra     DO_ASR_B_INH            ; 57 - ASR B
        bra     DO_ASL_B_INH            ; 58 - ASL B
        bra     DO_ROL_B_INH            ; 59 - ROL B
        bra     DO_DEC_B_INH            ; 5a - DEC B
        bra     DO_ERR                  ; 5b -
        bra     DO_INC_B_INH            ; 5c - INC B
        bra     DO_TST_B_INH            ; 5d - TST B
        bra     DO_ERR                  ; 5e -
        bra     DO_CLR_B_INH            ; 5f - CLR B

        bra     DO_NEG_IDX              ; 60 - NEG idx,X
        bra     DO_ERR                  ; 61 -
        bra     DO_ERR                  ; 62 -
        bra     DO_COM_IDX              ; 63 - COM idx,X
        bra     DO_LSR_IDX              ; 64 - LSR idx,X
        bra     DO_ERR                  ; 65 -
        bra     DO_ROR_IDX              ; 66 - ROR idx,X
        bra     DO_ASR_IDX              ; 67 - ASR idx,X
        bra     DO_ASL_IDX              ; 68 - ASL idx,X
        bra     DO_ROL_IDX              ; 69 - ROL idx,X
        bra     DO_DEC_IDX              ; 6a - DEC idx,X
        bra     DO_ERR                  ; 6b -
        bra     DO_INC_IDX              ; 6c - INC idx,X
        bra     DO_TST_IDX              ; 6d - TST idx,X
        bra     DO_JMP_IDX              ; 6e - JMP idx,X
        bra     DO_CLR_IDX              ; 6f - CLR idx,X

        bra     DO_NEG_EXT              ; 70 - NEG ext
        bra     DO_ERR                  ; 71 -
        bra     DO_ERR                  ; 72 -
        bra     DO_COM_EXT              ; 73 - COM ext
        bra     DO_LSR_EXT              ; 74 - LSR ext
        bra     DO_ERR                  ; 75 -
        bra     DO_ROR_EXT              ; 76 - ROR ext
        bra     DO_ASR_EXT              ; 77 - ASR ext
        bra     DO_ASL_EXT              ; 78 - ASL ext
        bra     DO_ROL_EXT              ; 79 - ROL ext
        bra     DO_DEC_EXT              ; 7a - DEC ext
        bra     DO_ERR                  ; 7b -
        bra     DO_INC_EXT              ; 7c - INC ext
        bra     DO_TST_EXT              ; 7d - TST ext
        bra     DO_JMP_EXT              ; 7e - JMP ext
        bra     DO_CLR_EXT              ; 7f - CLR ext

        bra     DO_SUB_A_IMM            ; 80 - SUB A #imm
        bra     DO_CMP_A_IMM            ; 81 - CMP A #imm
        bra     DO_SBC_A_IMM            ; 82 - SBC A #imm
        bra     DO_ERR                  ; 83 -
        bra     DO_AND_A_IMM            ; 84 - AND A #imm
        bra     DO_BIT_A_IMM            ; 85 - BIT A #imm
        bra     DO_LDA_A_IMM            ; 86 - LDA A #imm
        bra     DO_ERR                  ; 87 -
        bra     DO_EOR_A_IMM            ; 88 - EOR A #imm
        bra     DO_ADC_A_IMM            ; 89 - ADC A #imm
        bra     DO_ORA_A_IMM            ; 8a - ORA A #imm
        bra     DO_ADD_A_IMM            ; 8b - ADD A #imm
        bra     DO_CPX_IMM              ; 8c - CPX #imm
        bra     DO_BSR_REL              ; 8d - BSR rel
        bra     DO_LDS_IMM              ; 8e - LDS #imm
        bra     DO_SYS_A_IMM            ; 8f - *SYS A #imm
 
        bra     DO_SUB_A_DPG            ; 90 - SUB A dir
        bra     DO_CMP_A_DPG            ; 91 - CMP A dir
        bra     DO_SBC_A_DPG            ; 92 - SBC A dir
        bra     DO_ERR                  ; 93 -
        bra     DO_AND_A_DPG            ; 94 - AND A dir
        bra     DO_BIT_A_DPG            ; 95 - BIT A dir
        bra     DO_LDA_A_DPG            ; 96 - LDA A dir
        bra     DO_STA_A_DPG            ; 97 - STA A dir
        bra     DO_EOR_A_DPG            ; 98 - EOR A dir
        bra     DO_ADC_A_DPG            ; 99 - ADC A dir
        bra     DO_ORA_A_DPG            ; 9a - ORA A dir
        bra     DO_ADD_A_DPG            ; 9b - ADD A dir
        bra     DO_CPX_DPG              ; 9c - CPX dir
        bra     DO_ERR                  ; 9d -
        bra     DO_LDS_DPG              ; 9e - LDS dir
        bra     DO_STS_DPG              ; 9f - STS dir

        bra     DO_SUB_A_IDX            ; a0 - SUB A idx,X
        bra     DO_CMP_A_IDX            ; a1 - CMP A idx,X
        bra     DO_SBC_A_IDX            ; a2 - SBC A idx,X
        bra     DO_ERR                  ; a3 -
        bra     DO_AND_A_IDX            ; a4 - AND A idx,X
        bra     DO_BIT_A_IDX            ; a5 - BIT A idx,X
        bra     DO_LDA_A_IDX            ; a6 - LDA A idx,X
        bra     DO_STA_A_IDX            ; a7 - STA A idx,X
        bra     DO_EOR_A_IDX            ; a8 - EOR A idx,X
        bra     DO_ADC_A_IDX            ; a9 - ADC A idx,X
        bra     DO_ORA_A_IDX            ; aa - ORA A idx,X
        bra     DO_ADD_A_IDX            ; ab - ADD A idx,X
        bra     DO_CPX_IDX              ; ac - CPX idx,X
        bra     DO_JSR_IDX              ; ad - JSR idx,X
        bra     DO_LDS_IDX              ; ae - LDS idx,X
        bra     DO_STS_IDX              ; af - STS idx,X

        bra     DO_SUB_A_EXT            ; b0 - SUB A ext
        bra     DO_CMP_A_EXT            ; b1 - CMP A ext
        bra     DO_SBC_A_EXT            ; b2 - SBC A ext
        bra     DO_ERR                  ; b3 -
        bra     DO_AND_A_EXT            ; b4 - AND A ext
        bra     DO_BIT_A_EXT            ; b5 - BIT A ext
        bra     DO_LDA_A_EXT            ; b6 - LDA A ext
        bra     DO_STA_A_EXT            ; b7 - STA A ext
        bra     DO_EOR_A_EXT            ; b8 - EOR A ext
        bra     DO_ADC_A_EXT            ; b9 - ADC A ext
        bra     DO_ORA_A_EXT            ; ba - ORA A ext
        bra     DO_ADD_A_EXT            ; bb - ADD A ext
        bra     DO_CPX_EXT              ; bc - CPX ext
        bra     DO_JSR_EXT              ; bd - JSR ext
        bra     DO_LDS_EXT              ; be - LDS ext
        bra     DO_STS_EXT              ; bf - STS ext

        bra     DO_SUB_B_IMM            ; c0 - SUB B #imm
        bra     DO_CMP_B_IMM            ; c1 - CMP B #imm
        bra     DO_SBC_B_IMM            ; c2 - SBC B #imm
        bra     DO_ERR                  ; c3 -
        bra     DO_AND_B_IMM            ; c4 - AND B #imm
        bra     DO_BIT_B_IMM            ; c5 - BIT B #imm
        bra     DO_LDA_B_IMM            ; c6 - LDA B #imm
        bra     DO_ERR                  ; c7 -
        bra     DO_EOR_B_IMM            ; c8 - EOR B #imm
        bra     DO_ADC_B_IMM            ; c9 - ADC B #imm
        bra     DO_ORA_B_IMM            ; ca - ORA B #imm
        bra     DO_ADD_B_IMM            ; cb - ADD B #imm
        bra     DO_ERR                  ; cc -
        bra     DO_ERR                  ; cd -
        bra     DO_LDX_IMM              ; ce - LDX #imm
        bra     DO_SYS_B_IMM            ; cf - *SYS B #imm

        bra     DO_SUB_B_DPG            ; d0 - SUB B dir
        bra     DO_CMP_B_DPG            ; d1 - CMP B dir
        bra     DO_SBC_B_DPG            ; d2 - SBC B dir
        bra     DO_ERR                  ; d3 -
        bra     DO_AND_B_DPG            ; d4 - AND B dir
        bra     DO_BIT_B_DPG            ; d5 - BIT B dir
        bra     DO_LDA_B_DPG            ; d6 - LDA B dir
        bra     DO_STA_B_DPG            ; d7 - STA B dir
        bra     DO_EOR_B_DPG            ; d8 - EOR B dir
        bra     DO_ADC_B_DPG            ; d9 - ADC B dir
        bra     DO_ORA_B_DPG            ; da - ORA B bir
        bra     DO_ADD_B_DPG            ; db - ADD B dir
        bra     DO_ERR                  ; dc -
        bra     DO_ERR                  ; dd -
        bra     DO_LDX_DPG              ; de - LDX dir
        bra     DO_STX_DPG              ; df - STX dir

        bra     DO_SUB_B_IDX            ; e0 - SUB B idx,X
        bra     DO_CMP_B_IDX            ; e1 - CMP B idx,X
        bra     DO_SBC_B_IDX            ; e2 - SBC B idx,X
        bra     DO_ERR                  ; e3 -
        bra     DO_AND_B_IDX            ; e4 - AND B idx,X
        bra     DO_BIT_B_IDX            ; e5 - BIT B idx,X
        bra     DO_LDA_B_IDX            ; e6 - LDA B idx,X
        bra     DO_STA_B_IDX            ; e7 - STA B idx,X
        bra     DO_EOR_B_IDX            ; e8 - EOR B idx,X
        bra     DO_ADC_B_IDX            ; e9 - ADC B idx,X
        bra     DO_ORA_B_IDX            ; ea - ORA B idx,X
        bra     DO_ADD_B_IDX            ; eb - ADD B idx,X
        bra     DO_ERR                  ; ec -
        bra     DO_ERR                  ; ed -
        bra     DO_LDX_IDX              ; ee - LDX idx,X
        bra     DO_STX_IDX              ; ef - STX idx,X

        bra     DO_SUB_B_EXT            ; f0 - SUB B ext
        bra     DO_CMP_B_EXT            ; f1 - CMP B ext
        bra     DO_SBC_B_EXT            ; f2 - SBC B ext
        bra     DO_ERR                  ; f3 -
        bra     DO_AND_B_EXT            ; f4 - AND B ext
        bra     DO_BIT_B_EXT            ; f5 - BIT B ext
        bra     DO_LDA_B_EXT            ; f6 - LDA B ext
        bra     DO_STA_B_EXT            ; f7 - STA B ext
        bra     DO_EOR_B_EXT            ; f8 - EOR B ext
        bra     DO_ADC_B_EXT            ; f9 - ADC B ext
        bra     DO_ORA_B_EXT            ; fa - ORA B ext
        bra     DO_ADD_B_EXT            ; fb - ADD B ext
        bra     DO_ERR                  ; fc -
        bra     DO_ERR                  ; fd -
        bra     DO_LDX_EXT              ; fe - LDX ext
        bra     DO_STX_EXT              ; ff - STX ext


;-------------------------------------------------------------------------------

DO_ABA_INH:
        AM_INH
        OP_ABA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_ADC_A_IMM:
        AM_IMM  1
        OP_ADC  R_A
        retlw   #2,w0

DO_ADC_A_DPG:
        AM_DPG
        OP_ADC  R_A
        retlw   #3,w0

DO_ADC_A_IDX:
        AM_IDX
        OP_ADC  R_A
        retlw   #5,w0

DO_ADC_A_EXT:
        AM_EXT
        OP_ADC  R_A
        retlw   #4,w0

DO_ADC_B_IMM:
        AM_IMM  1
        OP_ADC  R_B
        retlw   #2,w0

DO_ADC_B_DPG:
        AM_DPG
        OP_ADC  R_B
        retlw   #3,w0

DO_ADC_B_IDX:
        AM_IDX
        OP_ADC  R_B
        retlw   #5,w0

DO_ADC_B_EXT:
        AM_EXT
        OP_ADC  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ADD_A_IMM:
        AM_IMM  1
        OP_ADD  R_A
        retlw   #2,w0

DO_ADD_A_DPG:
        AM_DPG
        OP_ADD  R_A
        retlw   #3,w0

DO_ADD_A_IDX:
        AM_IDX
        OP_ADD  R_A
        retlw   #5,w0

DO_ADD_A_EXT:
        AM_EXT
        OP_ADD  R_A
        retlw   #4,w0

DO_ADD_B_IMM:
        AM_IMM  1
        OP_ADD  R_B
        retlw   #2,w0

DO_ADD_B_DPG:
        AM_DPG
        OP_ADD  R_B
        retlw   #3,w0

DO_ADD_B_IDX:
        AM_IDX
        OP_ADD  R_B
        retlw   #5,w0

DO_ADD_B_EXT:
        AM_EXT
        OP_ADD  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_AND_A_IMM:
        AM_IMM  1
        OP_AND  R_A
        retlw   #2,w0

DO_AND_A_DPG:
        AM_DPG
        OP_AND  R_A
        retlw   #3,w0

DO_AND_A_IDX:
        AM_IDX
        OP_AND  R_A
        retlw   #5,w0

DO_AND_A_EXT:
        AM_EXT
        OP_AND  R_A
        retlw   #4,w0

DO_AND_B_IMM:
        AM_IMM  1
        OP_AND  R_B
        retlw   #2,w0

DO_AND_B_DPG:
        AM_DPG
        OP_AND  R_B
        retlw   #3,w0

DO_AND_B_IDX:
        AM_IDX
        OP_AND  R_B
        retlw   #5,w0

DO_AND_B_EXT:
        AM_EXT
        OP_AND  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ASL_A_INH:
        AM_INH
        OP_ASL  R_A
        retlw   #2,w0

DO_ASL_B_INH:
        AM_INH
        OP_ASL  R_B
        retlw   #2,w0

DO_ASL_IDX:
        AM_IDX
        OP_ASLM
        retlw   #7,w0

DO_ASL_EXT:
        AM_EXT
        OP_ASLM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_ASR_A_INH:
        AM_INH
        OP_ASR  R_A
        retlw   #2,w0

DO_ASR_B_INH:
        AM_INH
        OP_ASR  R_B
        retlw   #2,w0

DO_ASR_IDX:
        AM_IDX
        OP_ASRM
        retlw   #7,w0

DO_ASR_EXT:
        AM_EXT
        OP_ASRM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_BCC_REL:
        AM_REL
        OP_BCC
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BCS_REL:
        AM_REL
        OP_BCS
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BEQ_REL:
        AM_REL
        OP_BEQ
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BGE_REL:
        AM_REL
        OP_BGE
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BGT_REL:
        AM_REL
        OP_BGT
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BHI_REL:
        AM_REL
        OP_BHI
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BIT_A_IMM:
        AM_IMM  1
        OP_BIT  R_A
        retlw   #2,w0

DO_BIT_A_DPG:
        AM_DPG
        OP_BIT  R_A
        retlw   #3,w0

DO_BIT_A_IDX:
        AM_IDX
        OP_BIT  R_A
        retlw   #5,w0

DO_BIT_A_EXT:
        AM_EXT
        OP_BIT  R_A
        retlw   #4,w0

DO_BIT_B_IMM:
        AM_IMM  1
        OP_BIT  R_B
        retlw   #2,w0

DO_BIT_B_DPG:
        AM_DPG
        OP_BIT  R_B
        retlw   #3,w0

DO_BIT_B_IDX:
        AM_IDX
        OP_BIT  R_B
        retlw   #5,w0

DO_BIT_B_EXT:
        AM_EXT
        OP_BIT  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BLE_REL:
        AM_REL
        OP_BLE
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BLS_REL:
        AM_REL
        OP_BLS
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BLT_REL:
        AM_REL
        OP_BLT
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BMI_REL:
        AM_REL
        OP_BMI
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BNE_REL:
        AM_REL
        OP_BNE
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BPL_REL:
        AM_REL
        OP_BPL
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BRA_REL:
        AM_REL
        OP_BRA
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BSR_REL:
        AM_REL
        OP_BSR
        retlw   #8,w0

;-------------------------------------------------------------------------------

DO_BVC_REL:
        AM_REL
        OP_BVC
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_BVS_REL:
        AM_REL
        OP_BVS
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_CBA_INH:
        AM_INH
        OP_CBA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_CLC_INH:
        AM_INH
        OP_CLC
        retlw   #2,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_CLI_INH:
        AM_INH
        OP_CLI
        retlw   #2,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_CLR_A_INH:
        AM_INH
        OP_CLR  R_A
        retlw   #2,w0

DO_CLR_B_INH:
        AM_INH
        OP_CLR  R_B
        retlw   #2,w0

DO_CLR_IDX:
        AM_IDX
        OP_CLRM
        retlw   #7,w0

DO_CLR_EXT:
        AM_EXT
        OP_CLRM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_CLV_INH:
        AM_INH
        OP_CLV
        retlw   #2,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_CMP_A_IMM:
        AM_IMM  1
        OP_CMP  R_A
        retlw   #3,w0

DO_CMP_A_DPG:
        AM_DPG
        OP_CMP  R_A
        retlw   #3,w0

DO_CMP_A_IDX:
        AM_IDX
        OP_CMP  R_A
        retlw   #5,w0

DO_CMP_A_EXT:
        AM_EXT
        OP_CMP  R_A
        retlw   #4,w0

DO_CMP_B_IMM:
        AM_IMM  1
        OP_CMP  R_B
        retlw   #2,w0

DO_CMP_B_DPG:
        AM_DPG
        OP_CMP  R_B
        retlw   #3,w0

DO_CMP_B_IDX:
        AM_IDX
        OP_CMP  R_B
        retlw   #5,w0

DO_CMP_B_EXT:
        AM_EXT
        OP_CMP  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_COM_A_INH:
        AM_INH
        OP_COM  R_A
        retlw   #2,w0

DO_COM_B_INH:
        AM_INH
        OP_COM  R_B
        retlw   #2,w0

DO_COM_IDX:
        AM_IDX
        OP_COMM
        retlw   #7,w0

DO_COM_EXT:
        AM_EXT
        OP_COMM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_CPX_IMM:
        AM_IMM  2
        OP_CPX
        retlw   #3,w0

DO_CPX_DPG:
        AM_DPG
        OP_CPX
        retlw   #4,w0

DO_CPX_IDX:
        AM_IDX
        OP_CPX
        retlw   #6,w0

DO_CPX_EXT:
        AM_EXT
        OP_CPX
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_DAA_INH:
        AM_INH
        OP_DAA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_DEC_A_INH:
        AM_INH
        OP_DEC  R_A
        retlw   #2,w0

DO_DEC_B_INH:
        AM_INH
        OP_DEC  R_B
        retlw   #2,w0

DO_DEC_IDX:
        AM_IDX
        OP_DECM
        retlw   #7,w0

DO_DEC_EXT:
        AM_EXT
        OP_DECM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_DES_INH:
        AM_REL
        OP_DES
        retlw   #4,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_DEX_INH:
        AM_INH
        OP_DEX
        retlw   #4,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_EOR_A_IMM:
        AM_IMM  1
        OP_EOR  R_A
        retlw   #2,w0

DO_EOR_A_DPG:
        AM_DPG
        OP_EOR  R_A
        retlw   #3,w0

DO_EOR_A_IDX:
        AM_IDX
        OP_EOR  R_A
        retlw   #5,w0

DO_EOR_A_EXT:
        AM_EXT
        OP_EOR  R_A
        retlw   #4,w0

DO_EOR_B_IMM:
        AM_IMM  1
        OP_EOR  R_B
        retlw   #2,w0

DO_EOR_B_DPG:
        AM_DPG
        OP_EOR  R_B
        retlw   #3,w0

DO_EOR_B_IDX:
        AM_IDX
        OP_EOR  R_B
        retlw   #5,w0

DO_EOR_B_EXT:
        AM_EXT
        OP_EOR  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_INC_A_INH:
        AM_INH
        OP_INC  R_A
        retlw   #2,w0

DO_INC_B_INH:
        AM_INH
        OP_INC  R_B
        retlw   #2,w0

DO_INC_IDX:
        AM_IDX
        OP_DECM
        retlw   #7,w0

DO_INC_EXT:
        AM_EXT
        OP_DECM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_INS_INH:
        AM_INH
        OP_INS
        retlw   #4,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_INX_INH:
        AM_INH
        OP_INX
        retlw   #4,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_JMP_IDX:
        AM_IDX
        OP_JMP
        retlw   #4,w0

DO_JMP_EXT:
        AM_EXT
        OP_JMP
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_JSR_IDX:
        AM_IDX
        OP_JSR
        retlw   #8,w0

DO_JSR_EXT:
        AM_EXT
        OP_JSR
        retlw   #9,w0

;-------------------------------------------------------------------------------

DO_LDA_A_IMM:
        AM_IMM  1
        OP_LDA  R_A
        retlw   #2,w0

DO_LDA_A_DPG:
        AM_DPG
        OP_LDA  R_A
        retlw   #3,w0

DO_LDA_A_IDX:
        AM_IDX
        OP_LDA  R_A
        retlw   #5,w0

DO_LDA_A_EXT:
        AM_EXT
        OP_LDA  R_A
        retlw   #4,w0

DO_LDA_B_IMM:
        AM_IMM  1
        op_LDA  R_B
        retlw   #2,w0

DO_LDA_B_DPG:
        AM_DPG
        OP_LDA  R_B
        retlw   #3,w0

DO_LDA_B_IDX:
        AM_IDX
        OP_LDA  R_B
        retlw   #5,w0

DO_LDA_B_EXT:
        AM_EXT
        OP_LDA  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_LDS_IMM:
        AM_IMM  2
        OP_LDS
        retlw   #3,w0

DO_LDS_DPG:
        AM_DPG
        OP_LDS
        retlw   #2,w0

DO_LDS_IDX:
        AM_IDX
        OP_LDS
        retlw   #6,w0

DO_LDS_EXT:
        AM_EXT
        OP_LDS
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_LDX_IMM:
        AM_IMM  2
        OP_LDX
        retlw   #3,w0

DO_LDX_DPG:
        AM_DPG
        OP_LDX
        retlw   #2,w0

DO_LDX_IDX:
        AM_IDX
        OP_LDX
        retlw   #6,w0

DO_LDX_EXT:
        AM_EXT
        OP_LDX
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_LSR_A_INH:
        AM_INH
        OP_LSR  R_A
        retlw   #2,w0

DO_LSR_B_INH:
        AM_INH
        OP_LSR  R_B
        retlw   #2,w0

DO_LSR_IDX:
        AM_IDX
        OP_LSRM
        retlw   #7,w0

DO_LSR_EXT:
        AM_EXT
        OP_LSRM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_NEG_A_INH:
        AM_INH
        OP_NEG  R_A
        retlw   #2,w0

DO_NEG_B_INH:
        AM_INH
        OP_NEG  R_B
        retlw   #2,w0

DO_NEG_IDX:
        AM_IDX
        OP_NEGM
        retlw   #7,w0

DO_NEG_EXT:
        AM_EXT
        OP_NEGM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_NOP_INH:
        AM_INH
        OP_NOP
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_ORA_A_IMM:
        AM_IMM  1
        OP_ORA  R_A
        retlw   #2,w0

DO_ORA_A_DPG:
        AM_DPG
        OP_ORA  R_A
        retlw   #3,w0

DO_ORA_A_IDX:
        AM_IDX
        OP_ORA  R_A
        retlw   #5,w0

DO_ORA_A_EXT:
        AM_EXT
        OP_ORA  R_A
        retlw   #4,w0

DO_ORA_B_IMM:
        AM_IMM  1
        OP_ORA  R_B
        retlw   #2,w0

DO_ORA_B_DPG:
        AM_DPG
        OP_ORA  R_B
        retlw   #3,w0

DO_ORA_B_IDX:
        AM_IDX
        OP_ORA  R_B
        retlw   #5,w0

DO_ORA_B_EXT:
        AM_EXT
        OP_ORA  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_PSH_A_INH:
        AM_INH
        OP_PSH  R_A
        retlw   #4,w0

DO_PSH_B_INH:
        AM_INH
        OP_PSH  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_PUL_A_INH:
        AM_INH
        OP_PUL  R_A
        retlw   #4,w0

DO_PUL_B_INH:
        AM_INH
        OP_PUL  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ROL_A_INH:
        AM_INH
        OP_ROL  R_A
        retlw   #2,w0

DO_ROL_B_INH:
        AM_INH
        OP_ROL  R_B
        retlw   #2,w0

DO_ROL_IDX:
        AM_IDX
        OP_ROLM
        retlw   #7,w0

DO_ROL_EXT:
        AM_EXT
        OP_ROLM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_ROR_A_INH:
        AM_INH
        OP_ROR  R_A
        retlw   #2,w0

DO_ROR_B_INH:
        AM_INH
        OP_ROR  R_B
        retlw   #2,w0

DO_ROR_IDX:
        AM_IDX
        OP_RORM
        retlw   #7,w0

DO_ROR_EXT:
        AM_EXT
        OP_RORM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_RTI_INH:
        AM_INH
        OP_RTI
        retlw   #10,w0

;-------------------------------------------------------------------------------

DO_RTS_INH:
        AM_INH
        OP_RTS
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_SBA_INH:
        AM_INH
        OP_SBA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_SBC_A_IMM:
        AM_IMM  1
        OP_SBC  R_A
        retlw   #2,w0

DO_SBC_A_DPG:
        AM_DPG
        OP_SBC  R_A
        retlw   #3,w0

DO_SBC_A_IDX:
        AM_IDX
        OP_SBC  R_A
        retlw   #6,w0

DO_SBC_A_EXT:
        AM_EXT
        OP_SBC  R_A
        retlw   #4,w0

DO_SBC_B_IMM:
        AM_IMM  1
        OP_SBC  R_B
        retlw   #2,w0

DO_SBC_B_DPG:
        AM_DPG
        OP_SBC  R_B
        retlw   #3,w0

DO_SBC_B_IDX:
        AM_IDX
        OP_SBC  R_B
        retlw   #5,w0

DO_SBC_B_EXT:
        AM_EXT
        OP_SBC  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_SEC_INH:
        AM_INH
        OP_SEC
        retlw   #2,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_SEI_INH:
        AM_INH
        OP_SEI
        retlw   #2,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_SEV_INH:
        AM_INH
        OP_SEV
        retlw   #2,w0                   ; Return cycle count

;-------------------------------------------------------------------------------

DO_STA_A_DPG:
        AM_DPG
        OP_STA    R_A
        retlw   #4,w0

DO_STA_A_IDX:
        AM_IDX
        OP_STA  R_A
        retlw   #6,w0

DO_STA_A_EXT:
        AM_EXT
        OP_STA    R_A
        retlw   #5,w0

DO_STA_B_DPG:
        AM_DPG
        OP_STA  R_B
        retlw   #4,w0

DO_STA_B_IDX:
        AM_IDX
        OP_STA  R_B
        retlw   #6,w0

DO_STA_B_EXT:
        AM_EXT
        OP_STA  R_B
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_STS_DPG:
        AM_DPG
        OP_STS
        retlw   #5,w0

DO_STS_IDX:
        AM_IDX
        OP_STS
        retlw   #7,w0

DO_STS_EXT:
        AM_EXT
        OP_STS
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_STX_DPG:
        AM_DPG
        OP_STX
        retlw   #5,w0

DO_STX_IDX:
        AM_IDX
        OP_STX
        retlw   #7,w0

DO_STX_EXT:
        AM_EXT
        OP_STX
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_SUB_A_IMM:
        AM_IMM  1
        OP_SUB  R_A
        retlw   #2,w0

DO_SUB_A_DPG:
        AM_DPG
        OP_SUB  R_A
        retlw   #3,w0

DO_SUB_A_IDX:
        AM_IDX
        OP_SUB  R_A
        retlw   #5,w0

DO_SUB_A_EXT:
        AM_EXT
        OP_SUB  R_A
        retlw   #4,w0

DO_SUB_B_IMM:
        AM_IMM  1
        OP_SUB  R_B
        retlw   #2,w0

DO_SUB_B_DPG:
        AM_DPG
        OP_SUB  R_B
        retlw   #3,w0

DO_SUB_B_IDX:
        AM_IDX
        OP_SUB  R_B
        retlw   #5,w0

DO_SUB_B_EXT:
        AM_EXT
        OP_SUB  R_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_SWI_INH:
        AM_INH
        OP_SWI
        retlw   #12,w0

;-------------------------------------------------------------------------------

DO_TAB_INH:
        AM_INH
        OP_TAB
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TAP_INH:
        AM_INH
        OP_TAP
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TBA_INH:
        AM_INH
        OP_TBA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TPA_INH:
        AM_INH
        OP_TPA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TST_A_INH:
        AM_INH
        OP_TST    R_A
        retlw   #2,w0

DO_TST_B_INH:
        AM_INH
        OP_TST    R_X
        retlw   #2,w0

DO_TST_IDX:
        AM_IDX
        OP_TSTM
        retlw   #7,w0

DO_TST_EXT:
        AM_EXT
        OP_TSTM
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_TSX_INH:
        AM_INH
        OP_TSX
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_TXS_INH:
        AM_INH
        OP_TXS
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_WAI_INH:
        AM_INH
        OP_WAI
        retlw   #9,w0

;-------------------------------------------------------------------------------

DO_ERR:
        AM_INH
        OP_NOP
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_SYS_A_IMM:
        AM_IMM  1
        OP_SYS  R_A
        retlw   #3,w0

DO_SYS_B_IMM:
        AM_IMM  1
        OP_SYS  R_B
        retlw   #3,w0

;===============================================================================
; WEEVIL (Debugger)
;-------------------------------------------------------------------------------
; A 8K ROM that is mapped to pages E/F

        .section .weevil_6800,code,align(0x1000)
WEEVIL:
        .incbin "code/6800/weevil/weevil.bin"

        .end
