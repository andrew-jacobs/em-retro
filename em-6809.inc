;===============================================================================
;  _____ __  __        __    ___   ___   ___
; | ____|  \/  |      / /_  ( _ ) / _ \ / _ \
; |  _| | |\/| |_____| '_ \ / _ \| | | | (_) |
; | |___| |  | |_____| (_) | (_) | |_| |\__, |
; |_____|_|  |_|      \___/ \___/ \___/   /_/
;
; A Motorola 6809 Emulator
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

        .equiv  F_E,            7
        .equiv  F_F,            6
        .equiv  F_H,            5
        .equiv  F_I,            4
        .equiv  F_N,            3
        .equiv  F_Z,            2
        .equiv  F_V,            1
        .equiv  F_C,            0

; Native Register Allocation

        .equiv  R_SR,           w7
        .equiv  R_PC,           w8
        .equiv  R_S,            w9
        .equiv  R_U,            w10
        .equiv  R_D,            w11
        .equiv  R_DP,           w12
        .equiv  R_X,            w13
        .equiv  R_Y,            w14

        .equiv  M_PC,           WREG8
        .equiv  M_S,            WREG9
        .equiv  M_U,            WREG10
        .equiv  M_D,            WREG11
        .equiv  M_A,            WREG11+1
        .equiv  M_B,            WREG11+0
        .equiv  M_DP,           WREG12
        .equiv  M_X,            WREG13
        .equiv  M_Y,            WREG14

;===============================================================================
; Register Flag Macros
;-------------------------------------------------------------------------------

; Set the P bits in WREG to match M_P and R_SR

        .macro  _GETP
        mov.b   M_CC,WREG               ; Start with the M_CC bits
        btsc    R_SR,#DC                ; And add in H,N,Z,V,C from R_SR
        bset    w0,#F_H
        btsc    R_SR,#N
        bset    w0,#F_N
        btsc    R_SR,#Z
        bset    w0,#F_Z
        btsc    R_SR,#OV
        bset    w0,#F_V
        btsc    R_SR,#Z
        bset    w0,#F_Z
        .endm

; Set R_P amd R_SR to match the P bits in WREG

        .macro  _SETP
        bclr    R_SR,#DC                ; Strip old CC bits from R_SR
        and.b   #0xf0,R_SR
        btsc    w0,#F_H                 ; And add in DC,N,Z,OV,C from CC
        bset    R_SR,#DC
        btsc    w0,#F_N
        bset    R_SR,#N
        btsc    w0,#F_Z
        bset    R_SR,#Z
        btsc    w0,#F_V
        bset    R_SR,#OV
        btsc    w0,#F_C
        bset    R_SR,#C
        and     #0x00d0,w0              ; Strip copied bits from P
        mov.b   WREG,M_CC               ; And save in M_CC
        .endm

;===============================================================================
; Addressing Modes
;-------------------------------------------------------------------------------

        .macro  AM_INH
        .endm

        .macro  AM_IMM,SIZ
        mov     R_PC,w2                 ; Point data address at immediate value
        add     R_PC,#\SIZ,R_PC         ; And bump the program counter
        .endm

        .macro  AM_EXT
        RD_ADDR R_PC,ze,w3              ; Read the MSB of the extended address
        inc     R_PC,R_PC
        swap    w3
        RD_ADDR R_PC,ze,w2              ; And combine with the LSB
        inc     R_PC,R_PC
        ior     w3,w2,w2
        .endm

        .macro  AM_DIR
        RD_ADDR R_PC,ze,w2              ; Read the LSB of the direct address
        inc     R_PC,R_PC
        ior     R_DP,w2,w2              ; And combine with direct page
        .endm

        .macro  AM_IDX
        .endm

        .macro  AM_REL
        RD_ADDR R_PC,se,w2              ; Read the displacement byte
        inc     R_PC,R_PC
        add     R_PC,w2,w2              ; And calculate relative address
        .endm

        .macro  AM_LNG
        RD_ADDR R_PC,ze,w3              ; Read the MSB of the displacement
        inc     R_PC,R_PC
        swap    w3
        RD_ADDR R_PC,ze,w2              ; And combine with the LSB
        inc     R_PC,R_PC
        ior     w3,w2,w2
        add     R_PC,w2,w2              ; And calculate relative address
        .endm

;===============================================================================
; Opcode Macros
;-------------------------------------------------------------------------------

        .macro  OP_ABX
        ze      R_D,w0                  ; Extract unsigned B value
        add     R_X,w0,R_X              ; And add to X
        .endm

        .macro  OP_ADCA
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #M_A,w0                 ; Load a pointer to A
        mov     R_SR,SR                 ; Restore the carry flag
        addc.b  w3,[w0],[w0]            ; Perform the addition
        mov     SR,R_SR                 ; And save the revised flags
        .endm

        .macro  OP_ADCB
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #M_B,w0                 ; Load a pointer to A
        mov     R_SR,SR                 ; Restore the carry flag
        addc.b  w3,[w0],[w0]            ; Perform the addition
        mov     SR,R_SR                 ; And save the revised flags
        .endm

        .macro  OP_ADDA
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #M_A,w0                 ; Load a pointer to A
        add.b   w3,[w0],[w0]            ; Perform the addition
        mov     SR,R_SR                 ; And save the revised flags
        .endm

        .macro  OP_ADDB
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #M_B,w0                 ; Load a pointer to B
        add.b   w3,[w0],[w0]            ; Perform the addition
        mov     SR,R_SR                 ; And save the revised flags
        .endm

        .macro  OP_ADDD
        RD_ADDR w2,ze,w3                ; Read the MSB of data word
        inc     w2,w2
        swap    w3
        RD_ADDR w2,ze,w2                ; And combine with the LSB
        ior     w3,w2,w2
        add     R_D,w2,R_D              ; Add data to D
        mov     SR,w0                   ; And save N,Z,V,C flags
        xor     w0,R_SR,w0
        and     #0x000f,w0
        xor     w0,R_SR,R_SR
        .endm

        .macro  OP_ANDA
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #M_A,w0                 ; Load a pointer to A
        and.b   w3,[w0],[w0]            ; Perform the AND
        mov     SR,w0                   ; And save N,Z flags
        xor     w0,R_SR,w0
        and     #(1<<N)|(1<<Z),w0
        xor     w0,R_SR,R_SR
        bclr    R_SR,#OV                ; And always clear V
        .endm

        .macro  OP_ANDB
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #M_B,w0                 ; Load a pointer to B
        and.b   w3,[w0],[w0]            ; Perform the AND
        mov     SR,w0                   ; And save N,Z flags
        xor     w0,R_SR,w0
        and     #(1<<N)|(1<<Z),w0
        xor     w0,R_SR,R_SR
        bclr    R_SR,#OV                ; And always clear V
        .endm

        .macro  OP_ANDCC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        _GETP
        and     w0,w3,w0                ; AND with CC
        _SETP
        .endm

        .macro  OP_ASLA
        mov     #M_A,w0                 ; Load pointer to A
        mov.b   [w0],w1
        add.b   w1,[w0],[w0]            ; Perform ASL
        mov     SR,R_SR                 ; And save N,Z,V,C
        .endm

        .macro  OP_ASLB
        mov     #M_B,w0                 ; Load pointer to B
        mov.b   [w0],w1
        add.b   w1,[w0],[w0]            ; Perform ASL
        mov     SR,R_SR                 ; And save N,Z,V,C
        .endm

        .macro  OP_ASL
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        add.b   w3,w3,w3                ; Perform ASL
        mov     SR,R_SR
        WR_ADDR w2,w3                   ; And write back result
        .endm

        .macro  OP_ASRA
        mov     #M_A,w0                 ; Load pointer to A
        asr.b   [w0],[w0]               ; Perform ASR
        mov     SR,R_SR                 ; And save N,Z,V,C
         .endm

        .macro  OP_ASRB
        mov     #M_B,w0                 ; Load pointer to B
        sl.b    [w0],[w0]               ; Perform ASR
        mov     SR,R_SR                 ; And save N,Z,V,C
        .endm

        .macro  OP_ASR
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        asr.b   w3,w3                   ; Perform ASR
        mov     SR,R_SR
        WR_ADDR w2,w3                   ; And write back result
        .endm

        .macro  OP_BCC
        btss    R_SR,#C                 ; If the carry flag is clear
        mov     w2,R_PC                 ; .. change the PC
        .endm

        .macro  OP_BCS
        btsc    R_SR,#C                 ; If the carry flag is set
        mov     w2,R_PC                 ; .. change the PC
        .endm

        .macro  OP_BEQ
        .endm

        .macro  OP_BGE
        .endm

        .macro  OP_BGT
        .endm

        .macro  OP_BHI
        .endm

        .macro  OP_BHS
        .endm

        .macro  OP_BIT
        .endm

        .macro  OP_BLE
        .endm

        .macro  OP_BLO
        .endm

        .macro  OP_BLS
        .endm

        .macro  OP_BLT
        .endm

        .macro  OP_BMI
        .endm

        .macro  OP_BNE
        .endm

        .macro  OP_BPL
        .endm

        .macro  OP_BRA
        .endm

        .macro  OP_BRN
        .endm

        .macro  OP_BSR
        .endm

        .macro  OP_BVC
        .endm

        .macro  OP_BVS
        .endm

        .macro  OP_CLR
        .endm

        .macro  OP_CMP
        .endm

        .macro  OP_CMP_W
        .endm

        .macro  OP_COM,ACC
        .endm

        .macro  OP_COMM
        .endm

        .macro  OP_CWAI
        .endm

        .macro  OP_DAA
        .endm

        .macro  OP_DEC,ACC
        .endm

        .macro  OP_DEC_M
        .endm

        .macro  OP_EOR,ACC
        .endm

        .macro  OP_EXG
        .endm

        .macro  OP_INC,ACC
        .endm

        .macro  OP_INC_M
        .endm

        .macro  OP_JMP
        .endm

        .macro  OP_JSR
        .endm

        .macro  OP_LBCC
        bra     c,0f
        mov     w2,R_PC
        inc     CYCLE
0:
        .endm

        .macro  OP_LBCS
        bra     nc,0f
        mov     w2,R_PC
        inc     CYCLE
0:
       .endm

        .macro  OP_LDA
        .endm

        .macro  OP_LDB
        .endm

        .macro  OP_LD,REG
        .endm

        .macro  OP_LEA
        .endm

        .macro  OP_LSRA
        mov     #M_A,w0
        lsr.b   [w0],[w0]
        .endm

        .macro  OP_LSRB
        mov     #M_B,w0
        lsr.b   [w0],[w0]
        .endm

        .macro  OP_LSR_M
        .endm

        .macro  OP_MUL
        .endm

        .macro  OP_NEGA
        mov     #M_A,w0                 ; Negate the value in A
        com.b   [w0],[w0]
        .endm

        .macro  OP_NEGB
        mov     #M_B,w0                 ; Negate the value in B
        com.b   [w0],[w0]
        .endm

        .macro  OP_NEG
        RD_ADDR w2,ze,w3                ; Negate the value in memory
        com     w3,w3
        WR_ADDR w2,w3                   ; And write back
        .endm

        .macro  OP_NOP
        nop
        nop
        .endm

        .macro  OP_OR,ACC
        .endm

        .macro  OP_ORCC
        .endm

        .macro  OP_PSH,STK
        .endm

        .macro  OP_PUL,STK
        .endm

        .macro  OP_ROL,ACC
        .endm

        .macro  OP_ROLM
        .endm

        .macro  OP_ROR,ACC
        .endm

        .macro  OP_RORM
        .endm

        .macro  OP_RTI
        .endm

        .macro  OP_RTS
        .endm

        .macro  OP_SBC,ACC
        .endm

        .macro  OP_SEX
        se      R_D,R_D                 ; Sign extend B into A
        .endm

        .macro  OP_STA
        mov     #M_A,w0                 ; Store the value of A
        ze      [w0],w0
        WR_ADDR w2,w3
        .endm

        .macro  OP_STB
        mov     #M_B,w0                 ; Store the value of B
        ze      [w0],w0
        WR_ADDR w2,w3
        .endm

        .macro  OP_ST,REG
        .endm

        .macro  OP_SUB
        .endm

        .macro  OP_SUBD
        .endm

        .macro  OP_SWI,VEC
        .endm

        .macro  OP_SYNC
        .endm

        .macro  OP_TFR
        .endm

        .macro  OP_TSTA
        .endm

        .macro  OP_TSTB
        .endm

        .macro  OP_TST
        .endm
