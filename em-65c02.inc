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

;===============================================================================
; Definitions
;-------------------------------------------------------------------------------

; Status Register Flags

        .equiv  F_N,            7
        .equiv  F_V,            6
        .equiv  F_B,            4
        .equiv  F_D,            3
        .equiv  F_I,            2
        .equiv  F_Z,            1
        .equiv  F_C,            0

; Native Register Allocation

        .equiv  R_SR,           w7
        .equiv  R_PC,           w8
        .equiv  R_SP,           w9
        .equiv  R_A,            w10
        .equiv  R_X,            w11
        .equiv  R_Y,            w12
        .equiv  R_P,            w13

        .equiv  R_FLAGS,        w14

        .equiv  TRACE,          0

;===============================================================================
; Flag Macros
;-------------------------------------------------------------------------------

; Saves full set of flags following the execution of an instruction.

        .macro  _SET_NVZC
        mov     SR,w0
        xor     w0,R_SR,w0
        and     #(1<<N)|(1<<Z)|(1<<C)|(1<<OV),w0
        xor     w0,R_SR,R_SR
        .endm

; Saves all the flags except overflow following the execution of an instruction.

        .macro  _SET_NZC
        mov     SR,w0
        xor     w0,R_SR,w0
        and     #(1<<N)|(1<<Z)|(1<<C),w0
        xor     w0,R_SR,R_SR
        .endm

; Saves the negative and zero flags following the execution of an instruction.

        .macro  _SET_NZ
        mov     SR,w0
        xor     w0,R_SR,w0
        and     #(1<<N)|(1<<Z),w0
        xor     w0,R_SR,R_SR
        .endm

;===============================================================================
; Addressing Modes
;-------------------------------------------------------------------------------

; Implied address

        .macro  AM_IMP
        .endm

; Absolute

        .macro  AM_ABS
        RD_ADDR R_PC,ze,w3              ; Fetch EA LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; Fetch EA MSB
        inc     R_PC,R_PC
        swap    w2                      ; Combine
        ior     w2,w3,w2
        .endm

; Absolute indexed by X

        .macro  AM_ABX
        RD_ADDR R_PC,ze,w3              ; Fetch EA LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; Fetch EA MSB
        inc     R_PC,R_PC
        swap    w2                      ; Combine
        ior     w2,w3,w3
        add     R_X,w3,w2               ; And add X register
        xor     w2,w3,w3                ; Did the MSB change?
        lsr     w3,#8,w3
        btsc    SR,#Z
        inc     CYCLE                   ; Yes, add an extra cycle
        .endm

; Absolute indexed by Y

        .macro  AM_ABY
        RD_ADDR R_PC,ze,w3              ; Fetch EA LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; Fetch EA MSB
        inc     R_PC,R_PC
        swap    w2                      ; Combine
        ior     w2,w3,w3
        add     R_Y,w3,w2               ; And add Y register
        xor     w2,w3,w3                ; Did the MSB change?
        lsr     w3,#8,w3
        btsc    SR,#Z
        inc     CYCLE                   ; Yes, add an extra cycle
        .endm

; Absolute Indirect

        .macro  AM_IAB
        RD_ADDR R_PC,ze,w3              ; Fetch LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; Fetch MSB
        inc     R_PC,R_PC
        swap    w2                      ; Combine
        ior     w2,w3,w2

        RD_ADDR w2,ze,w3                ; Fetch EA LSB
        inc     w2,w2
        RD_ADDR w2,ze,w2                ; Fetch EA MSB
        swap    w2                      ; Combine
        ior     w2,w3,w2
        .endm

; Zero page - $ZZ

        .macro  AM_ZPG
        RD_ADDR R_PC,ze,w2              ; Fetch EA LSB
        inc     R_PC,R_PC
        .endm

; Zero page indexed by X - $ZZ,X

        .macro  AM_ZPX
        RD_ADDR R_PC,ze,w2              ; Fetch EA LSB
        inc     R_PC,R_PC
        add.b   R_X,w2,w2               ; Add X index
        .endm

; Zero page indexed by Y - $ZZ,Y

        .macro  AM_ZPY
        RD_ADDR R_PC,ze,w2              ; Fetch EA LSB
        inc     R_PC,R_PC
        add.b   R_Y,w2,w2               ; Add X index
        .endm

; Zero page indexed indirect - ($ZZ,X)

        .macro  AM_IZX
        RD_ADDR R_PC,ze,w2              ; Fetch LSB
        inc     R_PC,R_PC
        add.b   R_X,w2,w2               ; Add X index

        RD_ADDR w2,ze,w3                ; Fetch EA LSB
        inc.b   w2,w2
        RD_ADDR w2,ze,w2                ; Fetch EA MSB
        swap    w2                      ; Combine
        ior     w2,w3,w2
        .endm

; Zero page indirect indexed - ($ZZ),Y

        .macro  AM_IZY
        RD_ADDR R_PC,ze,w2              ; Fetch LSB
        inc     R_PC,R_PC

        RD_ADDR w2,ze,w3                ; Fetch EA LSB
        inc     w2,w2
        RD_ADDR w2,ze,w2                ; Fetch EA MSB
        swap    w2                      ; Combine
        ior     w2,w3,w3
        add     R_Y,w3,w2               ; And add Y register
        xor     w2,w3,w3                ; Did the MSB change?
        lsr     w3,#8,w3
        btsc    SR,#Z
        inc     CYCLE                   ; Yes, add an extra cycle
        .endm

; Zero page indirect ($ZZ)

        .macro  AM_IZP
        RD_ADDR R_PC,ze,w2              ; Fetch ZP
        inc     R_PC,R_PC
        RD_ADDR w2,ze,w3                ; Fetch EA LSB
        inc     w2,w2
        RD_ADDR w2,ze,w2                ; Fetch EA MSB
        swap    w2
        ior     w2,w3,w2
        .endm

; Immediate - #$XX

        .macro  AM_IMM
        mov     R_PC,w2                 ; Use PC as EA
        inc     R_PC,R_PC               ; Then bump the PC
        .endm

; Relative - $RR

        .macro  AM_REL
        RD_ADDR R_PC,se,w2              ; Fetch the relative offset
        inc     R_PC,R_PC               ; Bump the program counter
        add     R_PC,w2,w2              ; And work out EA
        .endm

; Bit Test and Branch - $ZZ,$RR

        .macro  AM_BRL
        RD_ADDR R_PC,ze,w2              ; Fetch the data address
        inc     R_PC,R_PC
        RD_ADDR R_PC,se,w3              ; fetch the relative offset
        inc     R_PC,R_PC
        add     R_PC,w3,w3              ; And work out EA
        .endm

; Absolute indexed indirect - ($AAAA,X)

        .macro  AM_IAX
        RD_ADDR R_PC,ze,w3              ; Fetch LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; Fetch MSB
        inc     R_PC,R_PC
        swap    w2                      ; Combine
        ior     w2,w3,w2
        add     R_X,w2,w2               ; Add X register

        RD_ADDR w2,ze,w3                ; Fetch EA LSB
        inc     w2,w2
        RD_ADDR w2,ze,w2                ; Fetch EA MSB
        swap    w2                      ; Combine
        ior     w2,w3,w2
        .endm

;===============================================================================
; Opcode Macros
;-------------------------------------------------------------------------------

        .macro  OP_ADC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        btst.c  R_SR,#C                 ; Restore the carry
        addc.b  R_A,w3,R_A              ; Add the data to A
        btsc    R_P,#F_D                ; Decimal mode?
        daw.b   R_A                     ; Yes, correct
        ior.b   R_A,#0,R_A              ; Set flags
        _SET_NVZC                       ; Then save new flags
        .endm

        .macro  OP_AND
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        and.b   R_A,w3,R_A              ; Perform the AND
        _SET_NZ                         ; Set flags
        .endm

        .macro  OP_ASL
        RD_ADDR w2,ze,w3                ; Read memory byte
        sl.b    w3,w3                   ; Shift left
        _SET_NZC                        ; Set flags
        WR_ADDR w2,w3                   ; And write back
        .endm

        .macro  OP_ASLA
        sl.b    R_A,R_A
        _SET_NZC
        .endm

        .macro  OP_BBR,BIT
        RD_ADDR w2,ze,w0                ; Read the data byte
        btss    w0,#\BIT                ; Test the bit
        mov     w3,R_PC                 ; Update PC if clear
        .endm

        .macro  OP_BBS,BIT
        RD_ADDR w2,ze,w0                ; Read the data byte
        btsc    w0,#\BIT                ; Test the bit
        mov     w3,R_PC                 ; Update PC if set
       .endm

        .macro  OP_BCC
        btst.c  R_SR,#C                 ; Fetch the carry flag
        bra     c,0f                    ; Skip if set
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle
0:
        .endm

        .macro  OP_BCS
        btst.c  R_SR,#C                 ; Fetch the carry flag
        bra     nc,0f                   ; Skip if clear
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle
0:
        .endm

        .macro  OP_BEQ
        btst.c  R_SR,#Z                 ; Fetch the zero flag
        bra     nc,0f                   ; Skip if clear
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle
0:
        .endm

        .macro  OP_BIT
        RD_ADDR w2,ze,w3
        and.b   #(1<<C),R_SR
        and.b   R_A,w3,w0
        btsc    SR,#Z
        bset    R_SR,#Z
        btsc    w3,#F_N
        bset    R_SR,#N
        btsc    w3,#F_V
        bset    R_SR,#OV
        .endm

        .macro  OP_BMI
        btst.c  R_SR,#N                 ; Fetch the negative flag
        bra     nc,0f                   ; Skip if clear
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle
0:
        .endm

        .macro  OP_BNE
        btst.c  R_SR,#Z                 ; Fetch the zero flag
        bra     c,0f                    ; Skip if set
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle
0:
        .endm

        .macro  OP_BPL
        btst.c  R_SR,#N                 ; Fetch the negative flag
        bra     c,0f                    ; Skip if set
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle
0:
        .endm

        .macro  OP_BRA
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle        add     R_PC,w3,R_PC
        .endm

        .macro  OP_BRK
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
        bset    R_P,#F_I                ; Set interrupt flag and

        mov     #0xfffe,w2              ; Read the vector address
        RD_ADDR w2,ze,w3
        inc     w2,w2
        RD_ADDR w2,ze,R_PC
        swap    R_PC
        ior     R_PC,w3,R_PC
        .endm

        .macro  OP_BVC
        btst.c  R_SR,#OV                ; Fetch the overflow flag
        bra     c,0f                    ; Skip if set
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle
0:
        .endm

        .macro  OP_BVS
        btst.c  R_SR,#OV                ; Fetch the overflow flag
        bra     nc,0f                   ; Skip if clear
        xor     w2,R_PC,w3              ; Work out bit changes
        mov     w2,R_PC                 ; Update PC to new address
        inc     CYCLE                   ; Add extra cycle
        lsr     w3,#8,w3                ; Did the page change?
        btss    SR,#Z
        inc     CYCLE                   ; Yes, add extra cycle
0:
        .endm

        .macro  OP_CLC
        bclr.b  R_SR,#C
        .endm

        .macro  OP_CLD
        bclr.b  R_P,#F_D
        .endm

        .macro  OP_CLI
        bclr.b  R_P,#F_I                ; Clear the interrupt disable
       .endm

        .macro  OP_CLV
        bclr.b  R_SR,#OV
        .endm

        .macro  OP_CMP
        RD_ADDR w2,ze,w3
        sub.b   R_A,w3,w3
        _SET_NZC
        .endm

        .macro  OP_CPX
        RD_ADDR w2,ze,w3
        sub.b   R_X,w3,w3
        _SET_NZC
        .endm

        .macro  OP_CPY
        RD_ADDR w2,ze,w3
        sub.b   R_Y,w3,w3
        _SET_NZC
        .endm

        .macro  OP_DEC
        RD_ADDR w2,ze,w3
        dec.b   w3,w3
        _SET_NZ
        WR_ADDR w2,w3
        .endm

        .macro  OP_DECA
        dec.b   R_A,R_A
        _SET_NZ
        .endm

        .macro  OP_DEX
        dec.b   R_X,R_X
        _SET_NZ
        .endm

        .macro  OP_DEY
        dec.b   R_Y,R_Y
        _SET_NZ
        .endm

        .macro  OP_EOR
        RD_ADDR w2,ze,w3
        xor.b   R_A,w3,R_A
        _SET_NZ
        .endm

        .macro  OP_INC
        RD_ADDR w2,ze,w3
        inc.b   w3,w3
        _SET_NZ
        WR_ADDR w2,w3
        .endm

        .macro  OP_INCA
        inc.b   R_A,R_A
        _SET_NZ
        .endm

        .macro  OP_INX
        inc.b   R_X,R_X
        _SET_NZ
        .endm

        .macro  OP_INY
        inc.b   R_Y,R_Y
        _SET_NZ
        .endm

        .macro  OP_JMP
        mov     w2,R_PC                 ; Update the PC
        .endm

        .macro  OP_JSR
        dec     R_PC,R_PC               ; Push PC-1 on the stack
        swap    R_PC
        WR_ADDR R_SP,R_PC
        dec.b   R_SP,R_SP
        swap    R_PC
        WR_ADDR R_SP,R_PC
        dec.b   R_SP,R_SP
        mov     w2,R_PC
        .endm

        .macro  OP_LDA
        RD_ADDR w2,ze,R_A
        ior.b   R_A,R_A,R_A
        _SET_NZ
        .endm

        .macro  OP_LDX
        RD_ADDR w2,ze,R_X
        ior.b   R_X,R_X,R_X
        _SET_NZ
        .endm

        .macro  OP_LDY
        RD_ADDR w2,ze,R_Y
        ior.b   R_Y,R_Y,R_Y
        _SET_NZ
        .endm

        .macro  OP_LSR
        RD_ADDR w2,ze,w3
        lsr.b   w3,w3
        _SET_NZC
        WR_ADDR w2,w3
        .endm

        .macro  OP_LSRA
        lsr.b   R_A,R_A
        _SET_NZC
        .endm

        .macro  OP_NOP
        nop
        nop
        .endm

        .macro  OP_ORA
        RD_ADDR w2,ze,w3
        ior.b   R_A,w3,R_A
        _SET_NZ
        .endm

        .macro  OP_PHA
        WR_ADDR R_SP,R_A
        dec.b   R_SP,R_SP
        .endm

        .macro  OP_PHP
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
        WR_ADDR R_SP,w3
        dec.b   R_SP,R_SP
        .endm

        .macro  OP_PHX
        WR_ADDR R_SP,R_X
        dec.b   R_SP,R_SP
        .endm

        .macro  OP_PHY
        WR_ADDR R_SP,R_Y
        dec.b   R_SP,R_SP
        .endm

        .macro  OP_PLA
        inc.b   R_SP,R_SP
        RD_ADDR R_SP,ze,R_A
        ior.b   R_A,R_A,R_A
        _SET_NZ
        .endm

        .macro  OP_PLP
        inc.b   R_SP,R_SP
        RD_ADDR R_SP,ze,w3
        and.b   #0xf0,R_SR              ; Clear N,V,Z,C flags in SR
        btsc    w3,#F_C                 ; Set up C bit
        bset    R_SR,#C
        btsc    w3,#F_Z                 ; Set up Z bit
        bset    R_SR,#Z
        btsc    w3,#F_N                 ; Set up N bit
        bset    R_SR,#N
        btsc    w3,#F_V                 ; Set up OV bit
        bset    R_SR,#OV
        and     #0x0c,w3                ; Strip down to just I & D
        mov     w3,R_P                  ; .. and save
        .endm

        .macro  OP_PLX
        inc.b   R_SP,R_SP
        RD_ADDR R_SP,ze,R_X
        ior.b   R_X,R_X,R_X
        _SET_NZ
        .endm

        .macro  OP_PLY
        inc.b   R_SP,R_SP
        RD_ADDR R_SP,ze,R_Y
        ior.b   R_Y,R_Y,R_Y
        _SET_NZ
        .endm

        .macro  OP_RMB,BIT
        RD_ADDR w2,ze,w3
        bclr    w2,#\BIT
        WR_ADDR w2,w3
        .endm

        .macro  OP_ROL
        RD_ADDR w2,ze,w3
        btst.c  R_SR,#C
        rlc.b   w3,w3
        _SET_NZC
        WR_ADDR w2,w3
        .endm

        .macro  OP_ROLA
        btst.c  R_SR,#C
        rlc.b   R_A,R_A
        _SET_NZC
        .endm

        .macro  OP_ROR
        RD_ADDR w2,ze,w3
        btst.c  R_SR,#C
        rrc.b   w3,w3
        _SET_NZC
        WR_ADDR w2,w3
        .endm

        .macro  OP_RORA
        btst.c  R_SR,#C
        rrc.b   R_A,R_A
        _SET_NZC
        .endm

        .macro  OP_RTI
        inc.b   R_SP,R_SP               ; Remove P from stack
        RD_ADDR R_SP,ze,w3
        and.b   #0xf0,R_SR              ; Clear N,V,Z,C flags in SR
        btsc    w3,#F_C                 ; Set up C bit
        bset    R_SR,#C
        btsc    w3,#F_Z                 ; Set up Z bit
        bset    R_SR,#Z
        btsc    w3,#F_N                 ; Set up N bit
        bset    R_SR,#N
        btsc    w3,#F_V                 ; Set up OV bit
        bset    R_SR,#OV
        and     #(1<<F_D)|(1<<F_I),w3   ; Strip down to D & I
        mov     w3,R_P                  ; .. and save

        inc.b   R_SP,R_SP               ; Remove PC Lo from stack
        RD_ADDR R_SP,ze,w3
        inc.b   R_SP,R_SP
        RD_ADDR R_SP,ze,R_PC
        swap    R_PC
        ior     R_PC,w3,R_PC
        .endm

        .macro  OP_RTS
        inc.b   R_SP,R_SP               ; Fetch PC stack
        RD_ADDR R_SP,ze,w3
        inc.b   R_SP,R_SP
        RD_ADDR R_SP,ze,R_PC
        swap    R_PC
        ior     R_PC,w3,R_PC
        inc     R_PC,R_PC               ; And add one
        .endm

        .macro  OP_SBC
        RD_ADDR w2,ze,w3
        btst.c  R_SR,#C
        subb.b  R_A,w3,R_A
        btss    R_P,#F_D                ; Decimal mode?
        bra     1f
        mov     SR,w1                   ; Yes, do correction
        btss    w1,#DC
        sub.b   #0x06,R_A
        btss    w1,#C
        sub.b   #0x60,R_A
        mov     w1,SR
1:      ior.b   R_A,R_A,R_A
        _SET_NVZC
        .endm

        .macro  OP_SEC
        bset.b  R_SR,#C
        .endm

        .macro  OP_SED
        bset.b  R_P,#F_D
        .endm

        .macro  OP_SEI
        bset.b  R_P,#F_I
        .endm

        .macro  OP_SMB,BIT
        RD_ADDR w2,ze,w3
        bset    w2,#\BIT
        WR_ADDR w2,w3
        .endm

        .macro  OP_STA
        WR_ADDR w2,R_A
        .endm

        .macro  OP_STP
        dec     R_PC,R_PC
        .endm

        .macro  OP_STX
        WR_ADDR w2,R_X
        .endm

        .macro  OP_STY
        WR_ADDR w2,R_Y
        .endm

        .macro  OP_STZ
        clr     w3
        WR_ADDR w2,w3
        .endm

        .macro  OP_TAX
        ior.b   R_A,R_A,R_X
        _SET_NZ
        .endm

        .macro  OP_TAY
        ior.b   R_A,R_A,R_Y
        _SET_NZ
        .endm

        .macro  OP_TRB
        RD_ADDR w2,ze,w3
        bclr    R_SR,#Z
        and.b   R_A,w3,w0
        btsc    SR,#Z
        bset    R_SR,#Z
        com.b   R_A,w0
        and.b   w0,w3,w3
        WR_ADDR w2,w3
        .endm

        .macro  OP_TSB
        RD_ADDR w2,ze,w3
        bclr    R_SR,#Z
        and.b   R_A,w3,w0
        btsc    SR,#Z
        bset    R_SR,#Z
        ior.b   R_A,w3,w3
        WR_ADDR w2,w3
        .endm

        .macro  OP_TSX
        ior.b   R_SP,R_SP,R_X
        _SET_NZ
        .endm

        .macro  OP_TXA
        ior.b   R_X,R_X,R_A
        _SET_NZ
        .endm

        .macro  OP_TXS
        mov.b   R_X,R_SP
        .endm

        .macro  OP_TYA
        ior.b   R_Y,R_Y,R_A
        _SET_NZ
        .endm

        .macro  OP_WAI
	btss	INT_FLAGS,#INT_DETECTED	; Has an interrupt been detected?
	bra	1f			; No.
	bclr	INT_FLAGS,#INT_WAITING	; Yes, no longer waiting
	bra	2f

1:	bclr	INT_FLAGS,#INT_DETECTED	; Clear detection flag
	bset	INT_FLAGS,#INT_WAITING	; .. and mark as waiting
	dec     R_PC,R_PC		; Repeat WAI until detection
2:
        .endm

        .macro  OP_COP
        RD_ADDR w2,ze,w3                ; Read the immediate byte
        and     w3,#7,w3
        bra     w3                      ; And branch to operation

        bra     0f                      ; Read interrupt flags
        bra     1f                      ; Write interrupt flags
        bra     2f                      ; Read enable flags
        bra     3f                      ; Write enable flags
        bra     4f                      ; Transmit character
        bra     5f                      ; Receive character
        bra     6f                      ; Clear interrupt flag
        bra     7f

0:      mov.b   INT_FLAGS,WREG		; Read the interrupt flags
        ze      w0,R_A
        bra     99f

1:      mov     R_A,w0			; Write the interrupt flags
        mov.b   WREG,INT_FLAGS
        bra     99f

2:      mov.b   INT_ENABLE,WREG		; Read the enable flags
        ze      w0,R_A
        bra     99f

3:      mov     R_A,w0			; Write the enable flags
        mov.b   WREG,INT_ENABLE
        bra     99f

4:      bclr    INT_FLAGS,#INT_UART_TX	; Clear the interrupt
        ze      R_A,w0			; Transmit from A
	mov     w0,U1TXREG
        bset    IEC0,#U1TXIE            ; Ensure TX enabled
        bra     99f

5:	bclr    INT_FLAGS,#INT_UART_RX  ; Clear the interrupt
        mov     U1RXREG,w0		; Receive into A
        ze      w0,R_A
        bra     99f

6:      com     R_A,w0			; Clear interrupt flag(s)
        and.b   INT_FLAGS
        bra     99f

7:
99:
        .endm
