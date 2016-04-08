;===============================================================================
;  _____ __  __      ________   ___
; | ____|  \/  |    |__  ( _ ) / _ \
; |  _| | |\/| |_____ / // _ \| | | |
; | |___| |  | |_____/ /| (_) | |_| |
; |_____|_|  |_|    /____\___/ \___/
;
; A Zilog Z80 Emulator
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

        .equiv  F_S,            7
        .equiv  F_Z,            6
        .equiv  F_H,            4
        .equiv  F_P_V,          2
        .equiv  F_N,            1
        .equiv  F_C,            0

; Native Register Allocation

        .equiv  R_SR,           w7
        .equiv  R_PC,           w8
        .equiv  R_SP,           w9
        .equiv  R_AF,           w10
        .equiv  R_BC,           w11
        .equiv  R_DE,           w12
        .equiv  R_HL,           w13

        .equiv  M_A,            WREG10+1
        .equiv  M_F,            WREG10+0
        .equiv  M_B,            WREG11+1
        .equiv  M_C,            WREG11+0
        .equiv  M_D,            WREG12+1
        .equiv  M_E,            WREG12+0
        .equiv  M_H,            WREG13+1
        .equiv  M_L,            WREG13+0

        .equiv  M_BC,           WREG11
        .equiv  M_DE,           WREG12
        .equiv  M_HL,           WREG13
        .equiv  M_SP,           WREG9

;===============================================================================
; Opcode Macros
;-------------------------------------------------------------------------------

        .macro  OP_ADC_R,REG            ; ADC A,r
        mov     #M_A,w1                 ; Load pointers to registers
        mov     #\REG,w2
        btst.c  R_SR,#C                 ; Restore the carry flag
        ze      [w1],w0                 ; Perform the 8-bit addition
        addc.b  w0,[w2],[w1]
; Flags
        .endm

        .macro  OP_ADC_N                ; ADC A,N
        RD_ADDR R_PC,ze,w2              ; Fetch the immediate data
        inc     R_PC,R_PC
        mov     #M_A,w1
        btst.c  R_SR,#C                 ; Restore the carry flag
        addc.b  w2,[w1],[w1]            ; Perform the 8-bit addition
; Flags
        .endm

        .macro  OP_ADC_I                ; ADC A,(HL)
        RD_ADDR R_HL,ze,w2              ; Fetch the memory byte
        mov     #M_A,w1
        btst.c  R_SR,#C                 ; Restore the carry flag
        addc.b  w2,[w1],[w1]            ; Perform the 8-bit addition
; Flags
        .endm

        .macro  OP_ADC_X,MEM            ; ADC A,(IX+N)
        RD_ADDR R_PC,ze,w2              ; Fetch the offset
        inc     R_PC,R_PC
        mov     \MEM,w0                 ; Add the index register
        add     w0,w2,w2                ; .. to form EA
        RD_ADDR w2,ze,w2                ; And fetch the memory byte
        btst.c  R_SR,#C                 ; Restore the carry flag
        addc.b  w2,[w1],[w1]            ; Perform the 8-bit addition
; Flags
        .endm

        .macro  OP_ADC_HL,REG           ; ADC HL,rr
        btst.c  R_SR,#C                 ; Restore the carry flag
        addc    R_HL,\REG,R_HL          ; Perform 16-bit addition
; Flags
        .endm

        .macro  OP_ADD_R,REG            ; ADD A,r
        mov     #M_A,w1                 ; Load pointers to registers
        mov     #\REG,w2
        ze      [w1],w0                 ; Perform the 8-bit addition
        add.b   w0,[w2],[w1]
; Flags
        .endm

        .macro  OP_ADD_N                ; ADD A,N
        RD_ADDR R_PC,ze,w2              ; Fetch the immediate data
        inc     R_PC,R_PC
        mov     #M_A,w1
        add.b   w2,[w1],[w1]            ; Perform the 8-bit addition
; Flags
        .endm

        .macro  OP_ADD_I                ; ADD A,(HL)
        RD_ADDR R_HL,ze,w2              ; Fetch the memory byte
        mov     #M_A,w1
        add.b   w2,[w1],[w1]            ; Perform the 8-bit addition
; Flags
        .endm

        .macro  OP_ADD_X,MEM            ; ADD A,(IX+N)
        RD_ADDR R_PC,ze,w2              ; Fetch the offset
        inc     R_PC,R_PC
        mov     \MEM,w0                 ; Add the index register
        add     w0,w2,w2                ; .. to form EA
        RD_ADDR w2,ze,w2                ; And fetch the memory byte
        add.b   w2,[w1],[w1]            ; Perform the 8-bit addition
; Flags
        .endm

        .macro  OP_ADD_HL,REG           ; ADD HL,rr
        add     R_HL,\REG,R_HL          ; Perform 16-bit addition
; Flags
        .endm

        .macro  OP_ADD_IX,MEM           ; ADD IX,rr
        mov     \MEM,w0
        add     IX
; Flags
        .endm

        .macro  OP_ADD_IY,MEM           ; ADD IX,rr
        mov     \MEM,w0
        add     IY
; Flags
        .endm

        .macro  OP_AND_R,REG            ; AND r
        mov     #M_A,w1                 ; Load pointers to registers
        mov     #\REG,w2
        ze      [w1],w0
        and.b   w0,[w2],[w1]            ; Perform AND
; Flags
        .endm

        .macro  OP_AND_N                ; AND N
        RD_ADDR R_PC,ze,w2              ; Fetch the immediate data
        inc     R_PC,R_PC
        mov     #M_A,w1
        and.b   w2,[w1],[w1]            ; Perform AND
; Flags
        .endm

        .macro  OP_AND_I                ; AND (HL)
        RD_ADDR R_HL,ze,w2              ; Fetch the memory byte
        mov     #M_A,w1
        and.b   w2,[w1],[w1]            ; Perform AND
; Flags
        .endm

        .macro  OP_AND_X,MEM            ; AND (IX+N)
        RD_ADDR R_PC,ze,w2              ; Fetch the offset
        inc     R_PC,R_PC
        mov     \MEM,w0                 ; Add the index register
        add     w0,w2,w2                ; .. to form EA
        RD_ADDR w2,ze,w2                ; And fetch the memory byte
        mov     #M_A,w0
        and.b   w2,[w0],[w0]            ; Perform AND
; Flags
        .endm

        .macro  OP_BIT
        .endm

        .macro  OP_CALL
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB 
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
        .endm

        .macro  OP_CALL_C
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#C                 ; Is the carry set?
        bra     0f                      ; No.

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
0:
        .endm

        .macro  OP_CALL_NC
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#C                 ; Is the carry clear?
        bra     0f                      ; No.

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
0:
        .endm

        .macro  OP_CALL_M
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#N                 ; Is the negative set?
        bra     0f                      ; No.

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
0:
        .endm

        .macro  OP_CALL_P
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#N                 ; Is the negative clear?
        bra     0f                      ; No.

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
0:
        .endm

        .macro  OP_CALL_Z
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#Z                 ; Is the zero set?
        bra     0f                      ; No.

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
0:
        .endm

        .macro  OP_CALL_NZ
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#Z                 ; Is the zero clear?
        bra     0f                      ; No.

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
0:
        .endm

        .macro  OP_CALL_PE
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#OV                ; Is the parity set?
        bra     0f                      ; No.

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
0:
        .endm

        .macro  OP_CALL_PO
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#OV                ; Is the parity clear?
        bra     0f                      ; No.

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR w3,R_SP
        dec     R_SP,R_SP               ; .. and the LSB
        WR_ADDR R_PC,R_SP
        mov     w2,R_PC                 ; Load new PC
0:
        .endm

        .macro  OP_CCF                  ; CCF
        btg     R_SR,#C                 ; Invert the carry flag
        .endm

        .macro  OP_CP
        .endm

        .macro  OP_CPD
        .endm

        .macro  OP_CPDR
        .endm

        .macro  OP_CPI
        .endm

        .macro  OP_CPIR
        .endm

        .macro  OP_CPL
        .endm

        .macro  OP_DAA
        .endm

        .macro  OP_DEC
        .endm

        .macro  OP_DI
        .endm

        .macro  OP_DJNZ
        RD_ADDR R_PC,se,w2              ; Fetch the relative offset
        inc     R_PC,R_PC
        mov     #M_B,w0                 ; Decrement B
        dec.b   [w0],[w0]
        btsc    SR,#Z                   ; Is the result zero?
        retlw   #8,w0                   ; Yes, no more loops
        add     R_PC,w2,R_PC            ; No, adjust PC for next loop
        .endm

        .macro  OP_EI
        .endm

        .macro  OP_EX
        .endm

        .macro  OP_EXX
        .endm

        .macro  OP_HALT
        .endm

        .macro  OP_IM
        .endm

        .macro  OP_IN
        .endm

        .macro  OP_INC_R,REG
        inc.b   \REG
        .endm

        .macro  OP_INC_I
        RD_ADDR R_HL,ze,w2              ; Read the data byte
        inc.b   w2,w2
; flags
        WR_ADDR R_HL,w2
        .endm

        .macro  OP_INC_M,MEM
        inc     \MEM                    ; Do 16-bit increment
        .endm

        .macro  OP_INC_X,MEM
        RD_ADDR R_PC,ze,w2              ; Read the offset
        inc     R_PC,R_PC
        mov     \MEM,w0                 ; Add the index register
        add     w0,w2,w2                ; .. to form EA
        RD_ADDR w2,ze,w3
        inc.b   w3,w3                   ; Increment the memory byte
; flags
        WR_ADDR w2,w3
        .endm

        .macro  OP_IND
        .endm

        .macro  OP_INDR
        .endm

        .macro  OP_INI
        .endm

        .macro  OP_INIR
        .endm

        .macro  OP_JP
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,R_PC
        .endm

        .macro  OP_JP_C
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#C                 ; Is the carry set?
        mov     w2,R_PC                 ; Yes, change PC
        .endm

        .macro  OP_JP_NC
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#C                 ; Is the carry clear?
        mov     w2,R_PC                 ; Yes, change PC
        .endm

        .macro  OP_JP_M
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#N                 ; Is the negative set?
        mov     w2,R_PC                 ; Yes, change PC
        .endm

        .macro  OP_JP_P
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#N                 ; Is the negative clear?
        mov     w2,R_PC                 ; Yes, change PC
        .endm

        .macro  OP_JP_Z
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#Z                 ; Is the zero set?
        mov     w2,R_PC                 ; Yes, change PC
        .endm

        .macro  OP_JP_NZ
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#Z                 ; Is the zero clear?
        mov     w2,R_PC                 ; Yes, change PC
        .endm

        .macro  OP_JP_PE
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#OV                ; Is the parity set?
        mov     w2,R_PC                 ; Yes, change PC
        .endm

        .macro  OP_JP_PO
        RD_ADDR R_PC,ze,w3              ; Fetch LSB of EA
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; ... and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#OV                ; Is the parity clear?
        mov     w2,R_PC                 ; Yes, change PC
        .endm

        .macro  OP_JR
        .endm

        .macro  OP_LD
        .endm

        .macro  OP_LDD
        .endm

        .macro  OP_LDDR
        .endm

        .macro  OP_LDI
        .endm

        .macro  OP_LDIR
        .endm

        .macro  OP_NEG
        .endm

        .macro  OP_NOP
        nop
        .endm

        .macro  OP_OR
        .endm

        .macro  OP_OUT
        .endm

        .macro  OP_OUTD
        .endm

        .macro  OP_OTDR
        .endm

        .macro  OP_OUTI
        .endm

        .macro  OP_OTIR
        .endm

        .macro  OP_POP
        .endm

        .macro  OP_PUSH
        .endm

        .macro  OP_RES
        .endm

        .macro  OP_RET
        .endm

        .macro  OP_RETI
        .endm

        .macro  OP_RETN
        .endm

        .macro  OP_RLA
        .endm

        .macro  OP_RL
        .endm

        .macro  OP_RLCA
        .endm

        .macro  OP_RLC
        .endm

        .macro  OP_RLD
        .endm

        .macro  OP_RRA
        .endm

        .macro  OP_RR
        .endm

        .macro  OP_RRCA
        .endm

        .macro  OP_RRC
        .endm

        .macro  OP_RRD
        .endm

        .macro  OP_RST,ADR
        lsr     R_PC,#8,w3              ; Push MSB of return address
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_PC               ; .. followed by the LSB
        dec     R_SP,R_SP
        mov     #\ADR,R_PC              ; And load new PC value
        .endm

        .macro  OP_SBC
        .endm

        .macro  OP_SCF
        .endm

        .macro  OP_SET
        .endm

        .macro  OP_SLA
        .endm

        .macro  OP_SRA
        .endm

        .macro  OP_SLL
        .endm

        .macro  OP_SRL
        .endm

        .macro  OP_SUB
        .endm

        .macro  OP_XOR
        .endm
