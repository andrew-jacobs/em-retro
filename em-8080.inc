;===============================================================================
;  _____ __  __        ___   ___   ___   ___
; | ____|  \/  |      ( _ ) / _ \ ( _ ) / _ \
; |  _| | |\/| |_____ / _ \| | | |/ _ \| | | |
; | |___| |  | |_____| (_) | |_| | (_) | |_| |
; |_____|_|  |_|      \___/ \___/ \___/ \___/
;
; An Intel 8080 Emulator
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
        .equiv  F_AC,           4
        .equiv  F_P,            3
        .equiv  F_CY,           0

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

        .equiv  M_SP,           WREG9
	.equiv	M_AF,		WREG10
        .equiv  M_BC,           WREG11
        .equiv  M_DE,           WREG12
        .equiv  M_HL,           WREG13

;===============================================================================
; Macro
;-------------------------------------------------------------------------------

        .macro  PARITY,REG,TMP
        lsr     \REG,#4,\TMP            ; Work out the parity
        xor     \REG,\TMP,\REG
        lsr     \REG,#2,\TMP
        xor     \REG,\TMP,\REG
        lsr     \REG,#1,\TMP
        xor     \REG,\TMP,\REG
        bclr    R_SR,#OV                ; And set parity bit
        btsc    \REG,#0
        bset    R_SR,#OV
        .endm

;===============================================================================
; Opcode Macros
;-------------------------------------------------------------------------------

        .macro  OP_ACI
        RD_ADDR R_PC,ze,w3              ; Fetch the immediate byte
        inc     R_PC,R_PC
        mov.b   M_A,WREG                ; Fetch the accumulator
        btst.c  R_SR,#C                 ; Fetch the carry bit
        addc.b  w0,w3,w0                ; Perform the addition
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1
        .endm

        .macro  OP_ADC_R
        mov.b   M_A,WREG                ; Fetch the accumulator
        btst.c  R_SR,#C                 ; Fetch the carry bit
        addc.b  w0,[w2],w0              ; Perform the addition
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_ADC_M
        RD_ADDR R_HL,ze,w3              ; Fetch the memory byte
        mov.b   M_A,WREG                ; Fetch the accumulator
        btst.c  R_SR,#C                 ; Fetch the carry bit
        addc.b  w0,w3,w0                ; Perform the addition
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_ADD_R
        mov.b   M_A,WREG                ; Fetch the accumulator
        add.b   w0,[w2],w0              ; Perform the addition
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_ADD_M
        RD_ADDR R_HL,ze,w3              ; Fetch the memory byte
        mov.b   M_A,WREG                ; Fetch the accumulator
        add.b   w0,w3,w0                ; Perform the addition
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_ADI
        RD_ADDR R_PC,ze,w3              ; Fetch the immediate byte
        inc     R_PC,R_PC
        mov.b   M_A,WREG                ; Fetch the accumulator
        add.b   w0,w3,w0                ; Perform the addition
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1
        .endm

        .macro  OP_ANA_R
        mov.b   M_A,WREG                ; Fetch the accumulator
        and.b   w0,[w2],w0              ; Perform the AND
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_ANA_M
        RD_ADDR R_HL,ze,w3              ; Fetch the memory byte
        mov.b   M_A,WREG                ; Fetch the accumulator
        and.b   w0,w3,w0                ; Perform the AND
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_ANI
        RD_ADDR R_PC,ze,w3              ; Fetch the immediate byte
        inc     R_PC,R_PC
        mov.b   M_A,WREG                ; Fetch the accumulator
        and.b   w0,w3,w0                ; Perform the AND
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1
        .endm

        .macro  OP_CALL
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP               ; .. and LSB
        WR_ADDR R_SP,R_PC
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_CC
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#C                 ; Is the carry set?
        retlw   #11,w0                  ; No

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP               ; .. and LSB
        WR_ADDR R_SP,R_PC
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_CM
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#N                 ; Is the negative flag set?
        retlw   #11,w0                  ; No

        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP               ; .. and LSB
        WR_ADDR R_SP,R_PC
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_CMA
        mov.b   M_A,WREG
        com.b   w0,w0
        mov.b   WREG,M_A
        mov     SR,R_SR
        PARITY  w0,w1
        .endm

        .macro  OP_CMC
        btg     R_SR,#C                 ; Complement the carry flag
        .endm

        .macro  OP_CMP_R,REG
        .endm

        .macro  OP_CMP_M
        .endm

        .macro  OP_CNC
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#C                 ; Is the carry clear?
        retlw   #11,w0                  ; No

        lsr     R_PC,#8,w3              ; Push MSB of return address
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_PC               ; .. and LSB
        dec     R_SP,R_SP
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_CNZ
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#Z                 ; Is the zero clear?
        retlw   #11,w0                  ; No

        lsr     R_PC,#8,w3              ; Push MSB of return address
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_PC               ; .. and LSB
        dec     R_SP,R_SP
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_CP
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#N                 ; Is the negative clear?
        retlw   #11,w0                  ; No

        lsr     R_PC,#8,w3              ; Push MSB of return address
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_PC               ; .. and LSB
        dec     R_SP,R_SP
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_CPE
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#OV                ; Is the parity set?
        retlw   #11,w0                  ; No

        lsr     R_PC,#8,w3              ; Push MSB of return address
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_PC               ; .. and LSB
        dec     R_SP,R_SP
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_CPI
        .endm

        .macro  OP_CPO
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btsc    R_SR,#OV                ; Is the parity clear?
        retlw   #11,w0                  ; No

        lsr     R_PC,#8,w3              ; Push MSB of return address
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_PC               ; .. and LSB
        dec     R_SP,R_SP
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_CZ
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

        btss    R_SR,#Z                 ; Is the zero set?
        retlw   #11,w0                  ; No

        lsr     R_PC,#8,w3              ; Push MSB of return address
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_PC               ; .. and LSB
        dec     R_SP,R_SP
        mov     w2,R_PC                 ; And load new PC
        .endm

        .macro  OP_DAA
        mov.b   M_A,WREG
        btst.c  R_SR,#C
        daw.b   w0
        mov.b   WREG,M_A
        mov     SR,R_SR
        PARITY	w0,w1
        .endm

        .macro  OP_DAD,REG
        add     R_HL,\REG,R_HL		; Perform the addition
	bclr	R_SR,#C			; Copy new carry into SR
	btsc	SR,#C
	bset	R_SR,#C
        .endm

        .macro  OP_DCR_R,MEM
	dec.b	\MEM
	mov	SR,w3
	mov.b	\MEM,WREG
	xor	w3,R_SR,w1
	and	#(1<<N)|(1<<Z)|(1<<DC),w1
	xor	R_SR,w1,R_SR
	PARITY	w0,w1
	.endm

        .macro  OP_DCR_M
	RD_ADDR	R_HL,ze,w2
	dec.b	w2,w2
	mov	SR,w3
	WR_ADDR	R_HL,w0
	
        .endm

        .macro  OP_DCX,REG
	dec	\REG,\REG		; Decrement register
        .endm

        .macro  OP_DI
        .endm

        .macro  OP_EI
        .endm

        .macro  OP_HLT
; TODO repeat until interrupt handled
	dec	R_PC,R_PC
        .endm

        .macro  OP_IN
        .endm
	
        .macro  OP_INR_R,REG
        .endm
	
	.macro	OP_INR_M
	.endm

        .macro  OP_INX,REG
	inc	\REG,\REG
        .endm

        .macro  OP_JC
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2
	
	btsc	R_SR,#C			; Carry set?
	mov	w2,R_PC			; Yes, change PC
        .endm

        .macro  OP_JM
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2
	
	btsc	R_SR,#N			; Negative set?
	mov	w2,R_PC			; Yes, change PC
        .endm

        .macro  OP_JMP
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,R_PC		; .. into new PC
        .endm

        .macro  OP_JNC
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2
	
	btss	R_SR,#C			; Carry clear?
	mov	w2,R_PC			; Yes, change PC
        .endm

        .macro  OP_JNZ
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2
	
	btss	R_SR,#Z			; Zero clear?
	mov	w2,R_PC			; Yes, change PC
        .endm

        .macro  OP_JP
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2

	btss	R_SR,#N			; Negative clear?
	mov	w2,R_PC			; Yes, chnage PC
	.endm

        .macro  OP_JPE
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2
        .endm

        .macro  OP_JPO
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2
        .endm

        .macro  OP_JZ
        RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        inc     R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2
	
	btsc	R_SR,#Z			; Zero set?
	mov	w2,R_PC			; Yes, change PC
        .endm

        .macro  OP_LDA
	RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        swap    w2                      ; And combine
        ior     w2,w3,w2		; .. into new value
	
	RD_ADDR	w2,ze,w3		; Read memory byte
	mov	w3,w0
	mov.b	WREG,M_A		; And update A
       .endm

        .macro  OP_LDAX
	RD_ADDR	w2,ze,w3		; Read memory byte
	mov	w3,w0
	mov.b	WREG,M_A		; And update A
        .endm

        .macro  OP_LHLD
	RD_ADDR	R_PC,ze,w3		; Fetch LSB of target address
	inc	R_PC,R_PC
	RD_ADDR	R_PC,ze,w2		; .. and MSB
	swap	w2			; Combine
	ior	w2,w3,w2
	
	RD_ADDR	w2,ze,w3		; Read the LSB from memory
	inc	w2,w2
	RD_ADDR	w2,ze,w2		; .. and MSB
	swap	w2			; Combine to form
	ior	w2,w3,R_HL		; .. new HL value
        .endm

        .macro  OP_LXI
	push	w2			; Save target register
	RD_ADDR R_PC,ze,w3              ; Fetch the immediate LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
        swap    w2                      ; And combine
        ior     w2,w3,w3		; .. into new value
	pop	w2
	mov	w3,[w2]			; And update BC or DE
        .endm

        .macro  OP_MOV_R_R,DST,SRC
	mov.b	\SRC,WREG		; Copy the register
	mov.b	WREG,\DST
        .endm
	
	.macro	OP_MOV_R_M
        mov.b   [w2],w3			; Fetch the register value
        WR_ADDR R_HL,w3			; And write to memory
	.endm
	
	.macro	OP_MOV_M_R
        RD_ADDR R_HL,ze,w3		; Read from memory
        mov.b   w3,[w2]			; And save in target register
	.endm

        .macro  OP_MVI
        .endm

        .macro  OP_NOP
        .endm
	
        .macro  OP_ORA_R
        mov.b   M_A,WREG                ; Fetch the accumulator
        ior.b   w0,[w2],w0              ; Perform the OR
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm
	
	.macro	OP_ORA_M
	RD_ADDR	R_HL,ze,w3		; Fetch the data byte
	mov.b	M_A,WREG		; Fetch the accumulator
	ior.b	w0,w3,w0		; Perform the OR
	mov.b	WREG,M_A		; Save the result
	mov	SR,R_SR			; .. and flags
	PARITY	w0,w1			; Work out the parity
 	.endm

        .macro  OP_ORI
	RD_ADDR	R_PC,ze,w3		; Fetch the immediate data
	inc	R_PC,R_PC
	mov.b	M_A,WREG		; Fetch the accumulator
	ior.b	w0,w3,w0		; Perform the OR
	mov.b	WREG,M_A		; Save the result
	mov	SR,R_SR			; .. and flags
	PARITY	w0,w1			; Work out the parity
        .endm

        .macro  OP_OUT
        .endm

        .macro  OP_PCHL
	mov	R_HL,R_PC
        .endm

        .macro  OP_POP
	push	w2			; Save target register
	RD_ADDR	R_SP,ze,w3		; Pop the LSB
	inc	R_SP,R_SP
	RD_ADDR	R_SP,ze,w2		; .. and the MSB
	swap	w2
	ior	w2,w3,w3		; And combine
	pop	w2			; And save in target
	mov	w3,[w3]
	.endm

        .macro  OP_PUSH
        lsr     w2,#8,w3		; Push MSB of data
        dec     R_SP,R_SP
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP		; .. and LSB
        WR_ADDR R_SP,w2	
        .endm

        .macro  OP_RAL
        .endm

        .macro  OP_RAR
        .endm

        .macro  OP_RC
	btss	R_SR,#C			; Is the carry clear?
	retlw	#5,w0			; Yes, continue

	RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
	.endm

        .macro  OP_RET
        RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
        .endm

        .macro  OP_RLC
	
        .endm

        .macro  OP_RM
	btss	R_SR,#N			; Is the negative clear?
	retlw	#5,w0			; Yes, continue

	RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
        .endm

        .macro  OP_RNC
	btsc	R_SR,#C			; Is the carry set?
	retlw	#5,w0			; Yes, continue

	RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
        .endm

        .macro  OP_RNZ
	btsc	R_SR,#Z			; Is the zero clear?
	retlw	#5,w0			; Yes, continue

	RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
        .endm

        .macro  OP_RP
	btsc	R_SR,#N			; Is the negative set?
	retlw	#5,w0			; Yes, continue

	RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
        .endm

        .macro  OP_RPE
	btss	R_SR,#OV		; Is the parity clear?
	retlw	#5,w0			; Yes, continue

	RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
        .endm

        .macro  OP_RPO
	btsc	R_SR,#OV		; Is the parity set?
	retlw	#5,w0			; Yes, continue

	RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
        .endm

        .macro  OP_RRC
        .endm

        .macro  OP_RST
        lsr     R_PC,#8,w3              ; Push MSB of return address
        dec     R_SP,R_SP
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP               ; .. and LSB
        WR_ADDR R_SP,R_PC
	
        mov     w2,R_PC			; And load new PC
        .endm

        .macro  OP_RZ
	btss	R_SR,#Z			; Is zero clear?
	retlw	#5,w0			; Yes, continue

	RD_ADDR R_SP,ze,w2              ; Pull LSB of return address
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,w3              ; Followed by the MSB
        inc     R_SP,R_SP
        swap    w3
        ior     w2,w3,R_PC              ; Combine and set PC
        .endm

        .macro  OP_SBB_R
        mov.b   M_A,WREG                ; Fetch the accumulator
        btst.c  R_SR,#C                 ; Fetch the carry bit	
        subb.b  w0,[w2],w0              ; Perform the subtraction
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_SBB_M
        RD_ADDR R_HL,ze,w3              ; Fetch the memory byte
        mov.b   M_A,WREG                ; Fetch the accumulator
        btst.c  R_SR,#C                 ; Fetch the carry bit
        subb.b  w0,w3,w0                ; Perform the subtraction
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_SBI
        RD_ADDR R_PC,ze,w3              ; Fetch the immediate byte
	inc	R_PC,R_PC
        mov.b   M_A,WREG                ; Fetch the accumulator
        btst.c  R_SR,#C                 ; Fetch the carry bit
        subb.b  w0,w3,w0                ; Perform the subtraction
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_SHLD
	RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
	inc	R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2		; .. into new value
	
	WR_ADDR	w2,R_HL			; Write L to memory
	inc	w2,w2
	lsr	R_HL,#8,w3		; .. followed by H
	WR_ADDR	w2,R_HL
        .endm

        .macro  OP_SPHL
        mov     R_HL,R_SP
        .endm

        .macro  OP_STA
	RD_ADDR R_PC,ze,w3              ; Fetch the target LSB
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w2              ; .. and MSB
	inc	R_PC,R_PC
        swap    w2                      ; And combine
        ior     w2,w3,w2		; .. into new value

	lsr	R_AF,#8,w3
	WR_ADDR	w2,w3
        .endm

        .macro  OP_STAX
	lsr	R_AF,#8,w3
	WR_ADDR	w2,w3
        .endm

        .macro  OP_STC
        bset    R_SR,#C                 ; Ser the carry flag
        .endm

        .macro  OP_SUB_R
        mov.b   M_A,WREG                ; Fetch the accumulator
        sub.b   w0,[w2],w0              ; Perform the subtraction
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_SUB_M
        RD_ADDR R_HL,ze,w3              ; Fetch the memory byte
        mov.b   M_A,WREG                ; Fetch the accumulator
        sub.b   w0,w3,w0                ; Perform the addition
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_SUI
        RD_ADDR R_PC,ze,w3              ; Fetch the immediate byte
	inc	R_PC,R_PC
        mov.b   M_A,WREG                ; Fetch the accumulator
        sub.b   w0,w3,w0                ; Perform the addition
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

        .macro  OP_XCHG
        exch    R_DE,R_HL
        .endm

        .macro  OP_XRA_R
        mov.b   M_A,WREG                ; Fetch the accumulator
        xor.b   w0,[w2],w0              ; Perform the XOR
        mov.b   WREG,M_A                ; Save the result
        mov     SR,R_SR                 ; .. and flags
        PARITY  w0,w1                   ; Work out the parity
        .endm

	.macro	OP_XRA_M
	RD_ADDR	R_HL,ze,w3		; Fetch the data byte
	mov.b	M_A,WREG		; Fetch the accumulator
	xor.b	w0,w3,w0		; Perform the OR
	mov.b	WREG,M_A		; Save the result
	mov	SR,R_SR			; .. and flags
	PARITY	w0,w1			; Work out the parity
	.endm
	
        .macro  OP_XRI
	RD_ADDR	R_PC,ze,w3		; Fetch the data byte
	inc	R_PC,R_PC
	mov.b	M_A,WREG		; Fetch the accumulator
	xor.b	w0,w3,w0		; Perform the OR
	mov.b	WREG,M_A		; Save the result
	mov	SR,R_SR			; .. and flags
	PARITY	w0,w1			; Work out the parity
        .endm

        .macro  OP_XTHL
	push	R_HL			; Save the current HL
	mov	#M_HL,w2		; Pull the new value
	OP_POP
	pop	w2			; And replace with the old
	OP_PUSH			
        .endm
