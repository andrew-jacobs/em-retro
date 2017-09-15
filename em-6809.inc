;===============================================================================
;  _____ __  __        __    ___   ___   ___
; | ____|  \/  |      / /_  ( _ ) / _ \ / _ \
; |  _| | |\/| |_____| '_ \ / _ \| | | | (_) |
; | |___| |  | |_____| (_) | (_) | |_| |\__, |
; |_____|_|  |_|      \___/ \___/ \___/   /_/
;
; A Motorola 6809 Emulator
;-------------------------------------------------------------------------------
; Copyright (C)2014-2017 HandCoded Software Ltd.
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
        add     w0,R_X,R_X              ; And add to X
        .endm

        .macro  OP_ADC,ACC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #\ACC,w0                ; Load a pointer to ACC
        mov     R_SR,SR                 ; Restore the carry flag
        addc.b  w3,[w0],[w0]            ; Perform the addition
        mov     SR,R_SR                 ; And save the revised flags
        .endm

        .macro  OP_ADD,ACC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #\ACC,w0                ; Load a pointer to ACC
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

        .macro  OP_AND,ACC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #\ACC,w0                ; Load a pointer to ACC
	mov	R_SR,SR			; Restore the flags
        and.b   w3,[w0],[w0]            ; Perform the AND
        bclr    SR,#OV                  ; And always clear V
        mov     SR,R_SR                 ; And save N,Z flags
        .endm

        .macro  OP_ANDCC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        _GETP
        and     w0,w3,w0                ; AND with CC
        _SETP
        .endm

        .macro  OP_ASL,ACC
        mov     #\ACC,w0                ; Load pointer to ACC
        sl.b	[w0],[w0]		; Perform ASL
        mov     SR,R_SR                 ; And save N,Z,V,C
        .endm

        .macro  OP_ASL_M
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        sl.b	w3,w3			; Perform ASL
        mov     SR,R_SR
        WR_ADDR w2,w3                   ; And write back result
        .endm

        .macro  OP_ASR,ACC
        mov     #\ACC,w0                ; Load pointer to ACC
        asr.b   [w0],[w0]               ; Perform ASR
        mov     SR,R_SR                 ; And save N,Z,V,C
         .endm

        .macro  OP_ASR_M
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        asr.b   w3,w3                   ; Perform ASR
        mov     SR,R_SR			; And save N,Z,V,C
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

        .macro  OP_BIT,ACC
        .endm

        .macro  OP_BLE
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

        .macro  OP_CLR,ACC
	mov	#\ACC,w0
	clr.b	[w0]
        .endm

        .macro  OP_CLR_M
	mov	#0,w3
	WR_ADDR	w2,w3
        .endm

        .macro  OP_CMP,ACC
        .endm

        .macro  OP_CMP_W,REG
	
        .endm

        .macro  OP_COM,ACC
	mov	#\ACC,w0
	com.b	[w0],[w0]
        .endm

        .macro  OP_COM_M
	RD_ADDR	w2,ze,w3
	com	w3,w3
	WR_ADDR	w2,w3
        .endm

        .macro  OP_CWAI
        .endm

        .macro  OP_DAA
        .endm

        .macro  OP_DEC,ACC
	mov	#\ACC,w0
	dec.b	[w0],[w0]
        .endm

        .macro  OP_DEC_M
	RD_ADDR	w2,ze,w3
	dec.b	w3,w3
	WR_ADDR	w2,w3
        .endm

        .macro  OP_EOR,ACC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #\ACC,w0                ; Load a pointer to ACC
	mov	R_SR,SR			; Restore the flags
        xor.b   w3,[w0],[w0]            ; Perform the XOR
        bclr    SR,#OV                  ; And always clear V
        mov     SR,R_SR                 ; And save N,Z flags
        .endm

        .macro  OP_EXG
        .endm

        .macro  OP_INC,ACC
	mov	#\ACC,w0
	inc.b	[w0],[w0]
        .endm

        .macro  OP_INC_M
	RD_ADDR	w2,ze,w3
	inc.b	w3,w3
	WR_ADDR	w2,w3
        .endm

        .macro  OP_JMP
	mov	w2,R_PC
        .endm

        .macro  OP_JSR
        .endm

        .macro  OP_LDA
	RD_ADDR	w2,ze,w3
	mov	#M_A,w0
	mov	R_SR,SR
	ior.b	#0,w3
	mov.b	w3,[w0]
	bclr	SR,#OV
	mov	SR,R_SR	
        .endm

        .macro  OP_LDB
	RD_ADDR	w2,ze,w3
	mov	#M_B,w0
	mov	R_SR,SR
	ior.b	#0,w3
	mov.b	w3,[w0]
	bclr	SR,#OV
	mov	SR,R_SR	
        .endm

        .macro  OP_LD,REG
	RD_ADDR	w2,ze,\REG
	inc	w2,w2
	RD_ADDR	w2,ze,w3
	swap	\REG
	mov	R_SR,SR
	ior	w3,\REG,\REG
	bclr	SR,#OV
	mov	SR,R_SR
        .endm

        .macro  OP_LEA,REG
	mov	w2,\REG
; Set Z if X/Y
        .endm

        .macro  OP_LSR,ACC
        mov     #\ACC,w0                ; Load pointer to ACC
        lsr.b   [w0],[w0]               ; Perform LSR
        mov     SR,R_SR                 ; And save N,Z,V,C
        .endm

        .macro  OP_LSR_M
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        lsr.b   w3,w3                   ; Perform ASR
        mov     SR,R_SR			; And save N,Z,V,C
        WR_ADDR w2,w3                   ; And write back result
        .endm

        .macro  OP_MUL
        .endm

        .macro  OP_NEG,ACC
        mov     #\ACC,w0                ; Negate the value in ACC
        com.b   [w0],[w0]
        .endm

        .macro  OP_NEG_M
        RD_ADDR w2,ze,w3                ; Negate the value in memory
        com     w3,w3
        WR_ADDR w2,w3                   ; And write back
        .endm

        .macro  OP_NOP
        nop
        .endm

        .macro  OP_OR,ACC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #\ACC,w0                ; Load a pointer to ACC
	mov	R_SR,SR			; Restore the flags
        ior.b   w3,[w0],[w0]            ; Perform the OR
        bclr    SR,#OV                  ; And always clear V
        mov     SR,R_SR                 ; And save N,Z flags
        .endm

        .macro  OP_ORCC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        _GETP
        ior     w0,w3,w0                ; OR with CC
        _SETP
        .endm

        .macro  OP_PSH,STK
        .endm

        .macro  OP_PUL,STK
        .endm

        .macro  OP_ROL,ACC
        mov     #\ACC,w0                ; Load pointer to ACC
	mov	R_SR,SR			; Restore flags
        rlc.b	[w0],[w0]               ; Perform ROL
        mov     SR,R_SR                 ; And save N,Z,V,C
        .endm

        .macro  OP_ROL_M
        RD_ADDR w2,ze,w3                ; Fetch the data byte
	mov	R_SR,SR			; Restore flags
        rlc.b   w3,w3                   ; Perform ROL
        mov     SR,R_SR			; And save N,Z,V,C
        WR_ADDR w2,w3                   ; And write back result
        .endm

        .macro  OP_ROR,ACC
        mov     #\ACC,w0                ; Load pointer to ACC
	mov	R_SR,SR			; Restore flags
        rrc.b	[w0],[w0]               ; Perform ROR
        mov     SR,R_SR                 ; And save N,Z,V,C
        .endm

        .macro  OP_ROR_M
        RD_ADDR w2,ze,w3                ; Fetch the data byte
	mov	R_SR,SR			; Restore flags
        rrc.b   w3,w3                   ; Perform ROR
        mov     SR,R_SR			; And save N,Z,V,C
        WR_ADDR w2,w3                   ; And write back result
        .endm

        .macro  OP_RTI
        .endm

        .macro  OP_RTS
        .endm

        .macro  OP_SBC,ACC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #\ACC,w0                ; Load a pointer to ACC
        mov     R_SR,SR                 ; Restore the carry flag
        subbr.b w3,[w0],[w0]            ; Perform the subtraction
        mov     SR,R_SR                 ; And save the revised flags
        .endm

        .macro  OP_SEX
        se      R_D,R_D                 ; Sign extend B into A
        .endm

        .macro  OP_STA
        mov     #M_A,w0                 ; Store the value of A
        ze      [w0],w3
        WR_ADDR w2,w3
        .endm

        .macro  OP_STB
        mov     #M_B,w0                 ; Store the value of B
        ze      [w0],w3
        WR_ADDR w2,w3
        .endm

        .macro  OP_ST,REG
	sl	\REG,#8,w3			; Extract the MSB
	WR_ADDR	w2,w3			; .. and store it
	inc	w2,w2			; Bump target address
	WR_ADDR	w2,\REG			; .. and write LSB
        .endm

        .macro  OP_SUB,ACC
        RD_ADDR w2,ze,w3                ; Fetch the data byte
        mov     #\ACC,w0                ; Load a pointer to ACC
        subr.b  w3,[w0],[w0]            ; Perform the subtraction
        mov     SR,R_SR                 ; And save the revised flags
        .endm

        .macro  OP_SUBD
        RD_ADDR w2,ze,w3                ; Read the MSB of data word
        inc     w2,w2
        swap    w3
        RD_ADDR w2,ze,w2                ; And combine with the LSB
        ior     w3,w2,w2
        sub     R_D,w2,R_D              ; Subtract data from D
        mov     SR,w0                   ; And save N,Z,V,C flags
        xor     w0,R_SR,w0
        and     #0x000f,w0
        xor     w0,R_SR,R_SR
        .endm

        .macro  OP_SWI,VEC
        .endm

        .macro  OP_SYNC
        .endm

        .macro  OP_TFR
        .endm

        .macro  OP_TST,ACC
        .endm

        .macro  OP_TST_M
        .endm
