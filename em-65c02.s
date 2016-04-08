;===============================================================================
;  _____ __  __        __  ____   ____ ___ ____
; | ____|  \/  |      / /_| ___| / ___/ _ \___ \
; |  _| | |\/| |_____| '_ \___ \| |  | | | |__) |
; | |___| |  | |_____| (_) |__) | |__| |_| / __/
; |_____|_|  |_|      \___/____/ \____\___/_____|
;
; A Western Design Center 65C02 Emulator
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
; 2015-01-16 AJ Initial version
;-------------------------------------------------------------------------------

        .include "hardware.inc"
        .include "em-retro.inc"
        .include "em-65c02.inc"

;===============================================================================
; Emulator
;-------------------------------------------------------------------------------

        .section .65c02,code
        
        .global EM_65C02
        .extern CYCLE
        .extern INT_ENABLE
        .extern INT_FLAGS
        .extern PutStr
EM_65C02:
        call    PutStr
        .asciz  "EM-65C02 [15.07]\r\n"

        clr     TMR1                    ; Configure the CYCLE Timer
        mov     #TMR1_2MHZ,w0           ; .. for 2MHz
        mov     w0,PR1

        mov     #MEMORY_MAP,M_BASE      ; Initialise memory map
        mov     #0xff00,M_FLAG          ; .. and read-only flags
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
        mov     #edspage(RAM9),w1       ; RAM  0x8000-0x8fff
        mov     #edsoffset(RAM9),w2
        mov     w1,[M_BASE+32]
        mov     w2,[M_BASE+34]
        mov     #edspage(RAMA),w1       ; RAM  0x9000-0x9fff
        mov     #edsoffset(RAMA),w2
        mov     w1,[M_BASE+36]
        mov     w2,[M_BASE+38]
        mov     #edspage(RAMB),w1       ; RAM  0xa000-0xafff
        mov     #edsoffset(RAMB),w2
        mov     w1,[M_BASE+40]
        mov     w2,[M_BASE+42]

        mov     #edspage(FORTH+0x0000),w1 ; FORTH  0xb000-0xbfff R/O
        mov     #edsoffset(FORTH+0x0000),w2
        mov     w1,[M_BASE+44]
        mov     w2,[M_BASE+46]
        mov     #edspage(FORTH+0x1000),w1 ; FORTH  0xc000-0xcfff R/O
        mov     #edsoffset(FORTH+0x1000),w2
        mov     w1,[M_BASE+48]
        mov     w2,[M_BASE+50]
        mov     #edspage(FORTH+0x2000),w1 ; FORTH  0xd000-0xdfff R/O
        mov     #edsoffset(FORTH+0x2000),w2
        mov     w1,[M_BASE+52]
        mov     w2,[M_BASE+54]
        mov     #edspage(FORTH+0x3000),w1 ; FORTH  0xe000-0xefff R/O
        mov     #edsoffset(FORTH+0x3000),w2
        mov     w1,[M_BASE+56]
        mov     w2,[M_BASE+58]
        mov     #edspage(FORTH+0x4000),w1 ; FORTH  0xf000-0xffff R/O
        mov     #edsoffset(FORTH+0x4000),w2
        mov     w1,[M_BASE+60]
        mov     w2,[M_BASE+62]

;===============================================================================

Reset:
        mov     #0xfffc,w2              ; Fetch the RES vector
        RD_ADDR w2,ze,w3
        inc     w2,w2
        RD_ADDR w2,ze,R_PC
        swap    R_PC                    ; .. and load PC
        ior     R_PC,w3,R_PC

        bclr    R_P,#F_D                ; Clear decimal mode flag
        bset    R_P,#F_I                ; .. and set interrupt disable
        mov     #0x0100,R_SP            ; Set initial SP
        clr     R_A                     ; Clear A,X and Y
        clr     R_X
        clr     R_Y
        clr     R_SR                    ; And saved NZVC
        clr     R_FLAGS                 ; And interrupt flags

        clr     CYCLE
Run:
        rcall   Step                    ; Run one instruction
        add     CYCLE                   ; .. and work out cycle delay
1:      cp0     CYCLE                   ; Wait until it has elapsed
        bra     gt,1b
        bra     Run                     ; Done, execute next opcode

;-------------------------------------------------------------------------------

DoNMI:
        bclr    INT_FLAGS,#INT_NMI      ; Clear the NMI flag

        swap    R_PC                    ; Push PC MSB
        WR_ADDR R_SP,R_PC
        dec.b   R_SP,R_SP
        swap    R_PC                    ; Push PC LSB
        WR_ADDR R_SP,R_PC
        dec.b   R_SP,R_SP
        mov     #0x30,w3                ; Load always set bits
        btsc    R_SR,#C                 ; Add in C if set
        bset    w3,#F_C
        btsc    R_SR,#Z                 ; Add in Z if set
        bset    w3,#F_Z
        btsc    R_SR,#N                 ; Add in N if set
        bset    w3,#F_N
        btsc    R_SR,#OV                ; Add in V is set
        bset    w3,#F_V
        ior.b   w3,R_P,w3               ; Combine with ID flags
        WR_ADDR R_SP,w3                 ; Push P
        dec.b   R_SP,R_SP
        bset    R_P,#F_I                ; Set interrupt flag
        bclr    R_P,#F_D                ; And clear decimal mode

        mov     #0xfffa,w2              ; Fetch the NMI vector
        RD_ADDR w2,ze,w3
        inc     w2,w2
        RD_ADDR w2,ze,R_PC
        swap    R_PC                    ; .. and load PC
        ior     R_PC,w3,R_PC
        retlw   #7,w0

DoIRQ:
        swap    R_PC                    ; Push PC MSB
        WR_ADDR R_SP,R_PC
        dec.b   R_SP,R_SP
        swap    R_PC                    ; Push PC LSB
        WR_ADDR R_SP,R_PC
        dec.b   R_SP,R_SP
        mov     #0x20,w3                ; Load always set bits
        btsc    R_SR,#C                 ; Add in C if set
        bset    w3,#F_C
        btsc    R_SR,#Z                 ; Add in Z if set
        bset    w3,#F_Z
        btsc    R_SR,#N                 ; Add in N if set
        bset    w3,#F_N
        btsc    R_SR,#OV                ; Add in V is set
        bset    w3,#F_V
        ior.b   w3,R_P,w3               ; Combine with ID flags
        WR_ADDR R_SP,w3                 ; Push P
        dec.b   R_SP,R_SP
        bset    R_P,#F_I                ; Set interrupt flag
        bclr    R_P,#F_D                ; And clear decimal mode

        mov     #0xfffe,w2              ; Fetch the IRQ vector
        RD_ADDR w2,ze,w3
        inc     w2,w2
        RD_ADDR w2,ze,R_PC
        swap    R_PC                    ; .. and load PC
        ior     R_PC,w3,R_PC
        retlw   #7,w0

;-------------------------------------------------------------------------------

Step:
        mov     INT_FLAGS,WREG          ; Load pseudo interrupt flags
        btsc    w0,#INT_NMI             ; Has there been an NMI?
        bra     DoNMI                   ; Yes, go handle it

        btsc    R_P,#F_I                ; Are interrupts disabled?
        clr     w0                      ; Yes, clear all the flags
        and     INT_ENABLE,WREG         ; Check if any are enabled
        bra     nz,DoIRQ                ; If non-zero, handle them

        RD_ADDR R_PC,ze,w3              ; Fetch the retlw   #0,w0 opcode
        inc     R_PC,R_PC               ; .. incrementing the PC
        bra     w3                      ; And execute it

        bra     DO_BRK_IMM              ; 00 - BRK (#)
        bra     DO_ORA_IZX              ; 01 - ORA (zp,X)
        bra     DO_COP_IMM              ; 02 - *COP (#)
        bra     DO_ERR                  ; 03 -
        bra     DO_TSB_ZPG              ; 04 - TSB zp
        bra     DO_ORA_ZPG              ; 05 - ORA zp
        bra     DO_ASL_ZPG              ; 06 - ASL zp
        bra     DO_RB0_ZPG              ; 07 - RMB0 zp
        bra     DO_PHP_PSH              ; 08 - PHP
        bra     DO_ORA_IMM              ; 09 - ORA #
        bra     DO_ASL_ACC              ; 0a - ASL A
        bra     DO_ERR                  ; 0b -
        bra     DO_TSB_ABS              ; 0c - TSB abs
        bra     DO_ORA_ABS              ; 0d - ORA abs
        bra     DO_ASL_ABS              ; 0e - ASL abs
        bra     DO_BR0_BRL              ; 0f - BBR0 zp,r

        bra     DO_BPL_REL              ; 10 - BPL r
        bra     DO_ORA_IZY              ; 11 - ORA (zp),Y
        bra     DO_ORA_IZP              ; 12 - ORA (zp)
        bra     DO_ERR                  ; 13 -
        bra     DO_TRB_ZPG              ; 14 - TRB zp
        bra     DO_ORA_ZPX              ; 15 - ORA zp,X
        bra     DO_ASL_ZPX              ; 16 - ASL zp,X
        bra     DO_RB1_ZPG              ; 17 - RMB1 zp
        bra     DO_CLC_IMP              ; 18 - CLC
        bra     DO_ORA_ABY              ; 19 - ORA abs,Y
        bra     DO_INC_ACC              ; 1a - INC A
        bra     DO_ERR                  ; 1b -
        bra     DO_TRB_ABS              ; 1c - TRB abs
        bra     DO_ORA_ABX              ; 1d - ORA abs,X
        bra     DO_ASL_ABX              ; 1e - ASL abs,X
        bra     DO_BR1_BRL              ; 1f - BBR1 zp,r

        bra     DO_JSR_ABS              ; 20 - JSR abs
        bra     DO_AND_IZX              ; 21 - AND (zp,X)
        bra     DO_ERR                  ; 22 -
        bra     DO_ERR                  ; 23 -
        bra     DO_BIT_ZPG              ; 24 - BIT zp
        bra     DO_AND_ZPG              ; 25 - AND zp
        bra     DO_ROL_ZPG              ; 26 - ROL zp
        bra     DO_RB2_ZPG              ; 27 - RMB2 zp
        bra     DO_PLP_POP              ; 28 - PLP
        bra     DO_AND_IMM              ; 29 - AND #
        bra     DO_ROL_ACC              ; 2a - ROL A
        bra     DO_ERR                  ; 2b -
        bra     DO_BIT_ABS              ; 2c - BIT abs
        bra     DO_AND_ABS              ; 2d - AND abs
        bra     DO_ROL_ABS              ; 2e - ROL abs
        bra     DO_BR2_BRL              ; 2f - BBR2 zp,r

        bra     DO_BMI_REL              ; 30 - BMI r
        bra     DO_AND_IZY              ; 31 - AND (zp),Y
        bra     DO_AND_IZP              ; 32 - AND (zp)
        bra     DO_ERR                  ; 33 -
        bra     DO_BIT_ZPX              ; 34 - BIT zp,X
        bra     DO_AND_ZPX              ; 35 - AND zp,X
        bra     DO_ROL_ZPX              ; 36 - ROL zp,X
        bra     DO_RB3_ZPG              ; 37 - RMB3 zp
        bra     DO_SEC_IMP              ; 38 - SEC
        bra     DO_AND_ABY              ; 39 - AND abs,Y
        bra     DO_DEC_ACC              ; 3a - DEC A
        bra     DO_ERR                  ; 3b -
        bra     DO_BIT_ABX              ; 3c - BIT abs,X
        bra     DO_AND_ABX              ; 3d - AND abs,X
        bra     DO_ROL_ABX              ; 3e - ROL abs,X
        bra     DO_BR3_BRL              ; 3f - BBR3 zp,r

        bra     DO_RTI_STK              ; 40 - RTI
        bra     DO_EOR_IZX              ; 41 - EOR (zp,X)
        bra     DO_ERR                  ; 42 -
        bra     DO_ERR                  ; 43 -
        bra     DO_ERR                  ; 44 -
        bra     DO_EOR_ZPG              ; 45 - EOR zp
        bra     DO_LSR_ZPG              ; 46 - LSR zp
        bra     DO_RB4_ZPG              ; 47 - RMB4 zp
        bra     DO_PHA_PSH              ; 48 - PHA
        bra     DO_EOR_IMM              ; 49 - EOR #
        bra     DO_LSR_ACC              ; 4a - LSR A
        bra     DO_ERR                  ; 4b -
        bra     DO_JMP_ABS              ; 4c - JMP abs
        bra     DO_EOR_ABS              ; 4d - EOR abs
        bra     DO_LSR_ABS              ; 4e - LSR abs
        bra     DO_BR4_BRL              ; 4f - BBR4 zp,r

        bra     DO_BVC_REL              ; 50 - BVC r
        bra     DO_EOR_IZY              ; 51 - EOR (zp),Y
        bra     DO_EOR_IZP              ; 52 - EOR (zp)
        bra     DO_ERR                  ; 53 -
        bra     DO_ERR                  ; 54 -
        bra     DO_EOR_ZPX              ; 55 - EOR zp,X
        bra     DO_LSR_ZPX              ; 56 - LSR zp,X
        bra     DO_RB5_ZPG              ; 57 - RMB5 zp
        bra     DO_CLI_IMP              ; 58 - CLI
        bra     DO_EOR_ABY              ; 59 - EOR abs,Y
        bra     DO_PHY_PSH              ; 5a - PHY
        bra     DO_ERR                  ; 5b -
        bra     DO_ERR                  ; 5c -
        bra     DO_EOR_ABX              ; 5d - EOR abs,X
        bra     DO_LSR_ABX              ; 5e - LSR abs,X
        bra     DO_BR5_BRL              ; 5f - BBR5 zp,r

        bra     DO_RTS_STK              ; 60 - RTS
        bra     DO_ADC_IZX              ; 61 - ADC (zp,X)
        bra     DO_ERR                  ; 62 -
        bra     DO_ERR                  ; 63 -
        bra     DO_STZ_ZPG              ; 64 - STZ zp
        bra     DO_ADC_ZPG              ; 65 - ADC zp
        bra     DO_ROR_ZPG              ; 66 - ROR zp
        bra     DO_RB6_ZPG              ; 67 - RMB6 zp
        bra     DO_PLA_POP              ; 68 - PLA
        bra     DO_ADC_IMM              ; 69 - ADC #
        bra     DO_ROR_ACC              ; 6a - ROR A
        bra     DO_ERR                  ; 6b -
        bra     DO_JMP_IAB              ; 6c - JMP (abs)
        bra     DO_ADC_ABS              ; 6d - ADC abs
        bra     DO_ROR_ABS              ; 6e - ROR abs
        bra     DO_BR6_BRL              ; 6f - BBR6 zp,r

        bra     DO_BVS_REL              ; 70 - BVS r
        bra     DO_ADC_IZY              ; 71 - ADC (zp),Y
        bra     DO_ADC_IZP              ; 72 - ADC (zp)
        bra     DO_ERR                  ; 73 -
        bra     DO_STZ_ZPX              ; 74 - STZ zp,X
        bra     DO_ADC_ZPX              ; 75 - ADC zp,X
        bra     DO_ROR_ZPX              ; 76 - ROR zp,X
        bra     DO_RB7_ZPG              ; 77 - RMB7 zp
        bra     DO_SEI_IMP              ; 78 - SEI
        bra     DO_ADC_ABY              ; 79 - ADC abs,Y
        bra     DO_PLY_POP              ; 7a - PLY
        bra     DO_ERR                  ; 7b -
        bra     DO_JMP_IAX              ; 7c - JMP (abs,X)
        bra     DO_ADC_ABX              ; 7d - ADC abs,X
        bra     DO_ROR_ABX              ; 7e - ROR abs,X
        bra     DO_BR7_BRL              ; 7f - BBR7 zp,r

        bra     DO_BRA_REL              ; 80 - BRA r
        bra     DO_STA_IZX              ; 81 - STA (zp,X)
        bra     DO_ERR                  ; 82 -
        bra     DO_ERR                  ; 83 -
        bra     DO_STY_ZPG              ; 84 - STY zp
        bra     DO_STA_ZPG              ; 85 - STA zp
        bra     DO_STX_ZPG              ; 86 - STX zp
        bra     DO_SB0_ZPG              ; 87 - SMB0 zp
        bra     DO_DEY_IMP              ; 88 - DEY
        bra     DO_BIT_IMM              ; 89 - BIT #
        bra     DO_TXA_IMP              ; 8a - TXA
        bra     DO_ERR                  ; 8b -
        bra     DO_STY_ABS              ; 8c - STY abs
        bra     DO_STA_ABS              ; 8d - STA abs
        bra     DO_STX_ABS              ; 8e - STX abs
        bra     DO_BS0_BRL              ; 8f - BBS0 zp,r

        bra     DO_BCC_REL              ; 90 - BCC r
        bra     DO_STA_IZY              ; 91 - STA (zp),Y
        bra     DO_STA_IZP              ; 92 - STA (zp)
        bra     DO_ERR                  ; 93 -
        bra     DO_STY_ZPX              ; 94 - STY zp,X
        bra     DO_STA_ZPX              ; 95 - STA zp,X
        bra     DO_STX_ZPY              ; 96 - STX zp,Y
        bra     DO_SB1_ZPG              ; 97 - SMB1 zp
        bra     DO_TYA_IMP              ; 98 - TYA
        bra     DO_STA_ABY              ; 99 - STA abs,Y
        bra     DO_TXS_IMP              ; 9a - TXS
        bra     DO_ERR                  ; 9b -
        bra     DO_STZ_ABS              ; 9c - STZ abs
        bra     DO_STA_ABX              ; 9d - STA abs,X
        bra     DO_STZ_ABX              ; 9e - STZ abs,X
        bra     DO_BS1_BRL              ; 9f - BBS1 zp,r

        bra     DO_LDY_IMM              ; a0 - LDY #
        bra     DO_LDA_IZX              ; a1 - LDA (zp,X)
        bra     DO_LDX_IMM              ; a2 - LDX #
        bra     DO_ERR                  ; a3 -
        bra     DO_LDY_ZPG              ; a4 - LDY zp
        bra     DO_LDA_ZPG              ; a5 - LDA zp
        bra     DO_LDX_ZPG              ; a6 - LDX zp
        bra     DO_SB2_ZPG              ; a7 - SMB2 zp
        bra     DO_TAY_IMP              ; a8 - TAY
        bra     DO_LDA_IMM              ; a9 - LDA #
        bra     DO_TAX_IMP              ; aa - TAX
        bra     DO_ERR                  ; ab -
        bra     DO_LDY_ABS              ; ac - LDY abs
        bra     DO_LDA_ABS              ; ad - LDA abs
        bra     DO_LDX_ABS              ; ae - LDX abs
        bra     DO_BS2_BRL              ; af - BBS2 zp,r

        bra     DO_BCS_REL              ; b0 - BCS r
        bra     DO_LDA_IZY              ; b1 - LDA (zp),Y
        bra     DO_LDA_IZP              ; b2 - LDA (zp)
        bra     DO_ERR                  ; b3 -
        bra     DO_LDY_ZPX              ; b4 - LDY zp,X
        bra     DO_LDA_ZPX              ; b5 - LDA zp,X
        bra     DO_LDX_ZPY              ; b6 - LDX zp,Y
        bra     DO_SB3_ZPG              ; b7 - SMB3 zp
        bra     DO_CLV_IMP              ; b8 - CLV
        bra     DO_LDA_ABY              ; b9 - LDA abs,Y
        bra     DO_TSX_IMP              ; ba - TSX
        bra     DO_ERR                  ; bb -
        bra     DO_LDY_ABX              ; bc - LDY abs,X
        bra     DO_LDA_ABX              ; bd - LDA abs,X
        bra     DO_LDX_ABY              ; be - LDX abs,Y
        bra     DO_BS3_BRL              ; bf - BBS3 zp,r

        bra     DO_CPY_IMM              ; c0 - CPY #
        bra     DO_CMP_IZX              ; c1 - CMP (zp,X)
        bra     DO_ERR                  ; c2 -
        bra     DO_ERR                  ; c3 -
        bra     DO_CPY_ZPG              ; c4 - CPY zp
        bra     DO_CMP_ZPG              ; c5 - CMP zp
        bra     DO_DEC_ZPG              ; c6 - DEC zp
        bra     DO_SB4_ZPG              ; c7 - SMB4 zp
        bra     DO_INY_IMP              ; c8 - INY
        bra     DO_CMP_IMM              ; c9 - CMP #
        bra     DO_DEX_IMP              ; ca - DEX
        bra     DO_WAI_IMP              ; cb - WAI
        bra     DO_CPY_ABS              ; cc - CPY abs
        bra     DO_CMP_ABS              ; cd - CMP abs
        bra     DO_DEC_ABS              ; ce - DEC abs
        bra     DO_BS4_BRL              ; cf - BBS4 zp,r

        bra     DO_BNE_REL              ; d0 - BNE r
        bra     DO_CMP_IZY              ; d1 - CMP (zp),Y
        bra     DO_CMP_IZP              ; d2 - CMP (zp)
        bra     DO_ERR                  ; d3 -
        bra     DO_ERR                  ; d4 -
        bra     DO_CMP_ZPX              ; d5 - CMP zp,X
        bra     DO_DEC_ZPX              ; d6 - DEC zp,X
        bra     DO_SB5_ZPG              ; d7 - SMB5 zp
        bra     DO_CLD_IMP              ; d8 - CLD
        bra     DO_CMP_ABY              ; d9 - CMP abs,Y
        bra     DO_PHX_PSH              ; da - PHX
        bra     DO_STP_IMP              ; db - STP
        bra     DO_ERR                  ; dc -
        bra     DO_CMP_ABX              ; dd - CMP abs,X
        bra     DO_DEC_ABX              ; de - DEC abs,X
        bra     DO_BS5_BRL              ; df - BBS5 zp,r

        bra     DO_CPX_IMM              ; e0 - CPX #
        bra     DO_SBC_IZX              ; e1 - SBC (zp,X)
        bra     DO_ERR                  ; e2 -
        bra     DO_ERR                  ; e3 -
        bra     DO_CPX_ZPG              ; e4 - CPX zp
        bra     DO_SBC_ZPG              ; e5 - SBC zp
        bra     DO_INC_ZPG              ; e6 - INC zp
        bra     DO_SB6_ZPG              ; e7 - SMB6 zp
        bra     DO_INX_IMP              ; e8 - INX
        bra     DO_SBC_IMM              ; e9 - SBC #
        bra     DO_NOP_IMP              ; ea - NOP
        bra     DO_ERR                  ; eb -
        bra     DO_CPX_ABS              ; ec - CPX abs
        bra     DO_SBC_ABS              ; ed - SBC abs
        bra     DO_INC_ABS              ; ee - INC abs
        bra     DO_BS6_BRL              ; ef - BBS6 zp,r

        bra     DO_BEQ_REL              ; f0 - BEQ r
        bra     DO_SBC_IZY              ; f1 - SBC (zp),Y
        bra     DO_SBC_IZP              ; f2 - SBC (zp)
        bra     DO_ERR                  ; f3 -
        bra     DO_ERR                  ; f4 -
        bra     DO_SBC_ZPX              ; f5 - SBC zp,X`
        bra     DO_INC_ZPX              ; f6 - INC zp,X
        bra     DO_SB7_ZPG              ; f7 - SMB7 zp
        bra     DO_SED_IMP              ; f8 - SED
        bra     DO_SBC_ABY              ; f9 - SBC abs,Y
        bra     DO_PLX_POP              ; fa - PLX
        bra     DO_ERR                  ; fb -
        bra     DO_ERR                  ; fc -
        bra     DO_SBC_ABX              ; fd - SBC abs,X
        bra     DO_INC_ABX              ; fe - INC abs,X
        bra     DO_BS7_BRL              ; ff - BBS7 zp,r

;===============================================================================
; Opcode Emulation
;-------------------------------------------------------------------------------

DO_ADC_IMM:
        AM_IMM
        OP_ADC
        retlw   #2,w0

DO_ADC_ABS:
        AM_ABS
        OP_ADC
        retlw   #4,w0

DO_ADC_ZPG:
        AM_ZPG
        OP_ADC
        retlw   #3,w0

DO_ADC_IZP:
        AM_IZP
        OP_ADC
        retlw   #5,w0

DO_ADC_ABX:
        AM_ABX
        OP_ADC
        retlw   #4,w0

DO_ADC_ABY:
        AM_ABY
        OP_ADC
        retlw   #4,w0

DO_ADC_ZPX:
        AM_ZPX
        OP_ADC
        retlw   #4,w0

DO_ADC_IZX:
        AM_IZX
        OP_ADC
        retlw   #6,w0

DO_ADC_IZY:
        AM_IZY
        OP_ADC
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_AND_IMM:
        AM_IMM
        OP_AND
        retlw   #2,w0

DO_AND_ABS:
        AM_ABS
        OP_AND
        retlw   #4,w0

DO_AND_ZPG:
        AM_ZPG
        OP_AND
        retlw   #3,w0

DO_AND_IZP:
        AM_IZP
        OP_AND
        retlw   #5,w0

DO_AND_ABX:
        AM_ABX
        OP_AND
        retlw   #4,w0

DO_AND_ABY:
        AM_ABY
        OP_AND
        retlw   #4,w0

DO_AND_ZPX:
        AM_ZPX
        OP_AND
        retlw   #4,w0

DO_AND_IZX:
        AM_IZX
        OP_AND
        retlw   #6,w0

DO_AND_IZY:
        AM_IZY
        OP_AND
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_ASL_ABS:
        AM_ABS
        OP_ASL
        retlw   #6,w0

DO_ASL_ABX:
        AM_ABX
        OP_ASL
        retlw   #6,w0

DO_ASL_ACC:
        AM_IMP
        OP_ASLA
        retlw   #2,w0

DO_ASL_ZPG:
        AM_ZPG
        OP_ASL
        retlw   #5,w0

DO_ASL_ZPX:
        AM_ZPX
        OP_ASL
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_BR0_BRL:
        AM_BRL
        OP_BBR  0
        retlw   #2,w0

DO_BR1_BRL:
        AM_BRL
        OP_BBR  1
        retlw   #2,w0

DO_BR2_BRL:
        AM_BRL
        OP_BBR  2
        retlw   #2,w0

DO_BR3_BRL:
        AM_BRL
        OP_BBR  3
        retlw   #2,w0

DO_BR4_BRL:
        AM_BRL
        OP_BBR  4
        retlw   #2,w0

DO_BR5_BRL:
        AM_BRL
        OP_BBR  5
        retlw   #2,w0

DO_BR6_BRL:
        AM_BRL
        OP_BBR  6
        retlw   #2,w0

DO_BR7_BRL:
        AM_BRL
        OP_BBR  7
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BS0_BRL:
        AM_BRL
        OP_BBS  0
        retlw   #2,w0

DO_BS1_BRL:
        AM_BRL
        OP_BBS  1
        retlw   #2,w0

DO_BS2_BRL:
        AM_BRL
        OP_BBS  2
        retlw   #2,w0

DO_BS3_BRL:
        AM_BRL
        OP_BBS  3
        retlw   #2,w0

DO_BS4_BRL:
        AM_BRL
        OP_BBS  4
        retlw   #2,w0

DO_BS5_BRL:
        AM_BRL
        OP_BBS  5
        retlw   #2,w0

DO_BS6_BRL:
        AM_BRL
        OP_BBS  6
        retlw   #2,w0

DO_BS7_BRL:
        AM_BRL
        OP_BBS  7
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BCC_REL:
        AM_REL
        OP_BCC
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BCS_REL:
        AM_REL
        OP_BCS
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BEQ_REL:
        AM_REL
        OP_BEQ
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BIT_IMM:
        AM_IMM
        OP_BIT
        retlw   #3,w0

DO_BIT_ABS:
        AM_ABS
        OP_BIT
        retlw   #4,w0

DO_BIT_ABX:
        AM_ABX
        OP_BIT
        retlw   #4,w0

DO_BIT_ZPG:
        AM_ZPG
        OP_BIT
        retlw   #3,w0

DO_BIT_ZPX:
        AM_ZPX
        OP_BIT
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BMI_REL:
        AM_REL
        OP_BMI
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BNE_REL:
        AM_REL
        OP_BNE
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BPL_REL:
        AM_REL
        OP_BPL
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BRA_REL:
        AM_REL
        OP_BRA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BRK_IMM:
        AM_IMM
        OP_BRK
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_BVC_REL:
        AM_REL
        OP_BVC
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_BVS_REL:
        AM_REL
        OP_BVS
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_CLC_IMP:
        AM_IMP
        OP_CLC
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_CLD_IMP:
        AM_IMP
        OP_CLD
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_CLI_IMP:
        AM_IMP
        OP_CLI
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_CLV_IMP:
        AM_IMP
        OP_CLV
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_CMP_ABS:
        AM_ABS
        OP_CMP
        retlw   #4,w0

DO_CMP_ABX:
        AM_ABX
        OP_CMP
        retlw   #4,w0

DO_CMP_ABY:
        AM_ABY
        OP_CMP
        retlw   #4,w0

DO_CMP_IMM:
        AM_IMM
        OP_CMP
        retlw   #2,w0

DO_CMP_ZPG:
        AM_ZPG
        OP_CMP
        retlw   #3,w0

DO_CMP_IZP:
        AM_IZP
        OP_CMP
        retlw   #5,w0

DO_CMP_IZX:
        AM_IZX
        OP_CMP
        retlw   #6,w0

DO_CMP_ZPX:
        AM_ZPX
        OP_CMP
        retlw   #4,w0

DO_CMP_IZY:
        AM_IZY
        OP_CMP
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_CPX_ABS:
        AM_ABS
        OP_CPX
        retlw   #4,w0

DO_CPX_IMM:
        AM_IMM
        OP_CPX
        retlw   #2,w0

DO_CPX_ZPG:
        AM_ZPG
        OP_CPX
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_CPY_ABS:
        AM_ABS
        OP_CPY
        retlw   #4,w0

DO_CPY_IMM:
        AM_IMM
        OP_CPY
        retlw   #2,w0

DO_CPY_ZPG:
        AM_ZPG
        OP_CPY
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_DEC_ABS:
        AM_ABS
        OP_DEC
        retlw   #6,w0

DO_DEC_ABX:
        AM_ABX
        OP_DEC
        retlw   #7,w0

DO_DEC_ACC:
        AM_IMP
        OP_DECA
        retlw   #2,w0

DO_DEC_ZPG:
        AM_ZPG
        OP_DEC
        retlw   #5,w0

DO_DEC_ZPX:
        AM_ZPX
        OP_DEC
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_DEX_IMP:
        AM_IMP
        OP_DEX
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_DEY_IMP:
        AM_IMP
        OP_DEY
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_EOR_ABS:
        AM_ABS
        OP_EOR
        retlw   #4,w0

DO_EOR_ABX:
        AM_ABX
        OP_EOR
        retlw   #4,w0

DO_EOR_ABY:
        AM_ABY
        OP_EOR
        retlw   #4,w0

DO_EOR_IMM:
        AM_IMM
        OP_EOR
        retlw   #2,w0

DO_EOR_ZPG:
        AM_ZPG
        OP_EOR
        retlw   #3,w0

DO_EOR_IZP:
        AM_IZP
        OP_EOR
        retlw   #5,w0

DO_EOR_IZX:
        AM_IZX
        OP_EOR
        retlw   #6,w0

DO_EOR_ZPX:
        AM_ZPX
        OP_EOR
        retlw   #4,w0

DO_EOR_IZY:
        AM_IZY
        OP_EOR
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_INC_ABS:
        AM_ABS
        OP_INC
        retlw   #6,w0

DO_INC_ABX:
        AM_ABX
        OP_INC
        retlw   #7,w0

DO_INC_ACC:
        AM_IMP
        OP_INCA
        retlw   #2,w0

DO_INC_ZPG:
        AM_ZPG
        OP_INC
        retlw   #5,w0

DO_INC_ZPX:
        AM_ZPX
        OP_INC
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_INX_IMP:
        AM_IMP
        OP_INX
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_INY_IMP:
        AM_IMP
        OP_INY
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_JMP_ABS:
        AM_ABS
        OP_JMP
        retlw   #3,w0

DO_JMP_IAB:
        AM_IAB
        OP_JMP
        retlw   #5,w0

DO_JMP_IAX:
        AM_IAX
        OP_JMP
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_JSR_ABS:
        AM_ABS
        OP_JSR
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_LDA_ABS:
        AM_ABS
        OP_LDA
        retlw   #4,w0

DO_LDA_ABX:
        AM_ABX
        OP_LDA
        retlw   #4,w0

DO_LDA_ABY:
        AM_ABY
        OP_LDA
        retlw   #4,w0

DO_LDA_IMM:
        AM_IMM
        OP_LDA
        retlw   #2,w0

DO_LDA_ZPG:
        AM_ZPG
        OP_LDA
        retlw   #3,w0

DO_LDA_IZP:
        AM_IZP
        OP_LDA
        retlw   #5,w0

DO_LDA_IZX:
        AM_IZX
        OP_LDA
        retlw   #6,w0

DO_LDA_ZPX:
        AM_ZPX
        OP_LDA
        retlw   #4,w0

DO_LDA_IZY:
        AM_IZY
        OP_LDA
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_LDX_ABS:
        AM_ABS
        OP_LDX
        retlw   #4,w0

DO_LDX_ABY:
        AM_ABY
        OP_LDX
        retlw   #4,w0

DO_LDX_IMM:
        AM_IMM
        OP_LDX
        retlw   #2,w0

DO_LDX_ZPG:
        AM_ZPG
        OP_LDX
        retlw   #3,w0

DO_LDX_ZPY:
        AM_ZPY
        OP_LDX
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_LDY_ABS:
        AM_ABS
        OP_LDY
        retlw   #4,w0

DO_LDY_ABX:
        AM_ABX
        OP_LDY
        retlw   #4,w0

DO_LDY_IMM:
        AM_IMM
        OP_LDY
        retlw   #2,w0

DO_LDY_ZPG:
        AM_ZPG
        OP_LDY
        retlw   #3,w0

DO_LDY_ZPX:
        AM_ZPX
        OP_LDY
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_LSR_ABS:
        AM_ABS
        OP_LSR
        retlw   #6,w0

DO_LSR_ABX:
        AM_ABX
        OP_LSR
        retlw   #7,w0

DO_LSR_ACC:
        AM_IMP
        OP_LSRA
        retlw   #2,w0

DO_LSR_ZPG:
        AM_ZPG
        OP_LSR
        retlw   #5,w0

DO_LSR_ZPX:
        AM_ZPX
        OP_LSR
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_NOP_IMP:
        AM_IMP
        OP_NOP
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_ORA_ABS:
        AM_ABS
        OP_ORA
        retlw   #4,w0

DO_ORA_ABX:
        AM_ABX
        OP_ORA
        retlw   #4,w0

DO_ORA_ABY:
        AM_ABY
        OP_ORA
        retlw   #4,w0

DO_ORA_IMM:
        AM_IMM
        OP_ORA
        retlw   #2,w0

DO_ORA_ZPG:
        AM_ZPG
        OP_ORA
        retlw   #3,w0

DO_ORA_IZP:
        AM_IZP
        OP_ORA
        retlw   #5,w0

DO_ORA_IZX:
        AM_IZX
        OP_ORA
        retlw   #6,w0

DO_ORA_ZPX:
        AM_ZPX
        OP_ORA
        retlw   #4,w0

DO_ORA_IZY:
        AM_IZY
        OP_ORA
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_PHA_PSH:
        OP_PHA
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_PHP_PSH:
        OP_PHP
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_PHX_PSH:
        OP_PHX
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_PHY_PSH:
        OP_PHY
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_PLA_POP:
        OP_PLA
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_PLP_POP:
        OP_PLP
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_PLX_POP:
        OP_PLX
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_PLY_POP:
        OP_PLY
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_RB0_ZPG:
        AM_ZPG
        OP_RMB  0
        retlw   #5,w0

DO_RB1_ZPG:
        AM_ZPG
        OP_RMB  1
        retlw   #5,w0

DO_RB2_ZPG:
        AM_ZPG
        OP_RMB  2
        retlw   #5,w0

DO_RB3_ZPG:
        AM_ZPG
        OP_RMB  3
        retlw   #5,w0

DO_RB4_ZPG:
        AM_ZPG
        OP_RMB  4
        retlw   #5,w0

DO_RB5_ZPG:
        AM_ZPG
        OP_RMB  5
        retlw   #5,w0

DO_RB6_ZPG:
        AM_ZPG
        OP_RMB  6
        retlw   #5,w0

DO_RB7_ZPG:
        AM_ZPG
        OP_RMB  7
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_ROL_ABS:
        AM_ABS
        OP_ROL
        retlw   #6,w0

DO_ROL_ABX:
        AM_ABX
        OP_ROL
        retlw   #7,w0

DO_ROL_ACC:
        AM_IMP
        OP_ROLA
        retlw   #2,w0

DO_ROL_ZPG:
        AM_ZPG
        OP_ROL
        retlw   #5,w0

DO_ROL_ZPX:
        AM_ZPX
        OP_ROL
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_ROR_ABS:
        AM_ABS
        OP_ROR
        retlw   #6,w0

DO_ROR_ABX:
        AM_ABX
        OP_ROR
        retlw   #7,w0

DO_ROR_ACC:
        AM_IMP
        OP_RORA
        retlw   #2,w0

DO_ROR_ZPG:
        AM_ZPG
        OP_ROR
        retlw   #5,w0

DO_ROR_ZPX:
        AM_ZPX
        OP_ROR
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_RTI_STK:
        OP_RTI
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_RTS_STK:
        OP_RTS
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_SBC_ABS:
        AM_ABS
        OP_SBC
        retlw   #4,w0

DO_SBC_ABX:
        AM_ABX
        OP_SBC
        retlw   #4,w0

DO_SBC_ABY:
        AM_ABY
        OP_SBC
        retlw   #4,w0

DO_SBC_IMM:
        AM_IMM
        OP_SBC
        retlw   #2,w0

DO_SBC_ZPG:
        AM_ZPG
        OP_SBC
        retlw   #3,w0

DO_SBC_IZP:
        AM_IZP
        OP_SBC
        retlw   #5,w0

DO_SBC_IZX:
        AM_IZX
        OP_SBC
        retlw   #6,w0

DO_SBC_ZPX:
        AM_ZPX
        OP_SBC
        retlw   #4,w0

DO_SBC_IZY:
        AM_IZY
        OP_SBC
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_SEC_IMP:
        AM_IMP
        OP_SEC
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_SED_IMP:
        AM_IMP
        OP_SED
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_SEI_IMP:
        AM_IMP
        OP_SEI
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_SB0_ZPG:
        AM_ZPG
        OP_SMB  0
        retlw   #5,w0

DO_SB1_ZPG:
        AM_ZPG
        OP_SMB  1
        retlw   #5,w0

DO_SB2_ZPG:
        AM_ZPG
        OP_SMB  2
        retlw   #5,w0

DO_SB3_ZPG:
        AM_ZPG
        OP_SMB  3
        retlw   #5,w0

DO_SB4_ZPG:
        AM_ZPG
        OP_SMB  4
        retlw   #5,w0

DO_SB5_ZPG:
        AM_ZPG
        OP_SMB  5
        retlw   #5,w0

DO_SB6_ZPG:
        AM_ZPG
        OP_SMB  6
        retlw   #5,w0

DO_SB7_ZPG:
        AM_ZPG
        OP_SMB  7
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_STA_ABS:
        AM_ABS
        OP_STA
        retlw   #4,w0

DO_STA_ABX:
        AM_ABX
        OP_STA
        retlw   #5,w0

DO_STA_ABY:
        AM_ABY
        OP_STA
        retlw   #5,w0

DO_STA_ZPG:
        AM_ZPG
        OP_STA
        retlw   #3,w0

DO_STA_IZX:
        AM_IZX
        OP_STA
        retlw   #6,w0

DO_STA_ZPX:
        AM_ZPX
        OP_STA
        retlw   #4,w0

DO_STA_IZP:
        AM_IZP
        OP_STA
        retlw   #5,w0

DO_STA_IZY:
        AM_IZY
        OP_STA
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_STP_IMP:
        AM_IMP
        OP_STP
        retlw   #0,w0

;-------------------------------------------------------------------------------

DO_STX_ABS:
        AM_ABS
        OP_STX
        retlw   #4,w0

DO_STX_ABY:
        AM_ABY
        OP_STX
        retlw   #5,w0

DO_STX_ZPG:
        AM_ZPG
        OP_STX
        retlw   #3,w0

DO_STX_ZPY:
        AM_ZPY
        OP_STX
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_STY_ABS:
        AM_ABS
        OP_STY
        retlw   #4,w0

DO_STY_ABX:
        AM_ABY
        OP_STY
        retlw   #5,w0

DO_STY_ZPG:
        AM_ZPG
        OP_STY
        retlw   #3,w0

DO_STY_ZPX:
        AM_ZPX
        OP_STY
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_STZ_ABS:
        AM_ABS
        OP_STZ
        retlw   #4,w0

DO_STZ_ABX:
        AM_ABX
        OP_STZ
        retlw   #5,w0

DO_STZ_ZPG:
        AM_ZPG
        OP_STZ
        retlw   #3,w0

DO_STZ_ZPX:
        AM_ZPX
        OP_STZ
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_TAX_IMP:
        AM_IMP
        OP_TAX
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TAY_IMP:
        AM_IMP
        OP_TAY
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TRB_ABS:
        AM_ABS
        OP_TRB
        retlw   #6,w0

DO_TRB_ZPG:
        AM_ZPG
        OP_TRB
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_TSB_ABS:
        AM_ABS
        OP_TSB
        retlw   #6,w0

DO_TSB_ZPG:
        AM_ZPG
        OP_TSB
        retlw   #5,w0

;-------------------------------------------------------------------------------

DO_TSX_IMP:
        AM_IMP
        OP_TSX
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TXA_IMP:
        AM_IMP
        OP_TXA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TXS_IMP:
        AM_IMP
        OP_TXS
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_TYA_IMP:
        AM_IMP
        OP_TYA
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_WAI_IMP:
        AM_IMP
        OP_WAI
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_ERR:
        AM_IMP
        OP_NOP
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_COP_IMM:
        AM_IMM
        OP_COP
        retlw   #2,w0

;===============================================================================
; ROMS
;-------------------------------------------------------------------------------
; 20K Forth ROM

        .section .os_65c02,code,align(0x1000)
FORTH:
        .incbin "code/65c02/forth/forth.bin"

        .end
