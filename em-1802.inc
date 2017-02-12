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

;===============================================================================
; Definitions
;-------------------------------------------------------------------------------

        .equiv  R_REGS,         w7              ; Register base address
        .equiv  R_P,            w8              ; P x2
        .equiv  R_X,            w9              ; X x2
        .equiv  R_D,            w10
        .equiv  R_SR,           w11             ; Saved SR for DF flag
        .equiv  R_IE,           w12             ; IE flag in bit 0

        .equiv  TRACE,          0

;===============================================================================
; I/O Mapping
;-------------------------------------------------------------------------------

; Inputs

        .equiv  EF1_PORT,       IN1_PORT
        .equiv  EF1_PIN,        IN1_PIN

        .equiv  EF2_PORT,       IN2_PORT
        .equiv  EF2_PIN,        IN2_PIN

        .equiv  EF3_PORT,       IN2_PORT
        .equiv  EF3_PIN,        IN2_PIN

        .equiv  EF4_PORT,       SW_PORT
        .equiv  EF4_PIN,        SW_PIN

; Outputs

        .equiv  Q_LAT,          LED1_LAT
        .equiv  Q_PIN,          LED1_PIN

;===============================================================================
; Opcode Macros
;-------------------------------------------------------------------------------

        .macro  OP_ADC
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        btst.c  R_SR,#C
        addc.b  R_D,w3,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_ADCI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        btst.c  R_SR,#C
        addc.b  R_D,w3,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_ADD
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        add.b   R_D,w3,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_ADI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        add     R_D,w3,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_AND
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        and     R_D,w3,R_D
        retlw   #2,w0
        .endm

        .macro  OP_ANI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        and     R_D,w3,R_D
        retlw   #2,w0
        .endm

        .macro  OP_B,PORT,BIT
        mov     [R_REGS+R_P],w2         ; Read the branch address
        btss    \PORT,#\BIT             ; Is input bit set?
        bra     1f                      ; No, skip to next opcode
        RD_ADDR w2,ze,w3
        mov.b   w3,[R_REGS+R_P]         ; And update PC
        retlw   #2,w0                   ; Return cycle count
1:      inc     w2,w2                   ; Bump PC over branch address
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_BDF
        mov     [R_REGS+R_P],w2         ; Read the branch address
        btss    R_SR,#C                 ; Is DF flag set?
        bra     1f                      ; No, skip to next opcode
        RD_ADDR w2,ze,w3
        mov.b   w3,[R_REGS+R_P]         ; And update PC
        retlw   #2,w0                   ; Return cycle count
1:      inc     w2,w2                   ; Bump PC over branch address
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_BN,PORT,BIT
        mov     [R_REGS+R_P],w2         ; Read the branch address
        btsc    \PORT,#\BIT             ; Is input bit clear?
        bra     1f                      ; No, skip to next opcode
        RD_ADDR w2,ze,w3
        mov.b   w3,[R_REGS+R_P]         ; And update PC
        retlw   #2,w0                   ; Return cycle count
1:      inc     w2,w2                   ; Bump PC over branch address
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_BNF
        mov     [R_REGS+R_P],w2         ; Read the branch address
        btsc    R_SR,#C                 ; Is DF flag clear?
        bra     1f                      ; No, skip to next opcode
        RD_ADDR w2,ze,w3
        mov.b   w3,[R_REGS+R_P]         ; And update PC
        retlw   #2,w0                   ; Return cycle count
1:      inc     w2,w2                   ; Bump PC over branch address
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_BNQ
        mov     [R_REGS+R_P],w2         ; Read the branch address
        btsc    Q_LAT,#Q_PIN            ; Is Q clear?
        bra     1f                      ; No, skip to next opcode
        RD_ADDR w2,ze,w3
        mov.b   w3,[R_REGS+R_P]         ; And update PC
        retlw   #2,w0                   ; Return cycle count
1:      inc     w2,w2                   ; Bump PC over branch address
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_BNZ
        mov     [R_REGS+R_P],w2         ; Read the branch address
        cp0.b   R_D                     ; Is D zero?
        bra     z,1f                    ; Yes, skip to next opcode
        RD_ADDR w2,ze,w3
        mov.b   w3,[R_REGS+R_P]         ; And update PC
        retlw   #2,w0                   ; Return cycle count
1:      inc     w2,w2                   ; Bump PC over branch address
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_BQ
        mov     [R_REGS+R_P],w2         ; Read the branch address
        btss    Q_LAT,#Q_PIN            ; Is Q set?
        bra     1f                      ; No, skip to next opcode
        RD_ADDR w2,ze,w3
        mov.b   w3,[R_REGS+R_P]         ; And update PC
        retlw   #2,w0                   ; Return cycle count
1:      inc     w2,w2                   ; Bump PC over branch address
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_BR
        mov     [R_REGS+R_P],w2         ; Fetch the branch LSB
        RD_ADDR w2,ze,w3                
        mov.b   w3,[R_REGS+R_P]
        retlw   #2,w0
        .endm

        .macro  OP_BZ
        mov     [R_REGS+R_P],w2         ; Read the branch address
        cp0.b   R_D                     ; Is D non-zero?
        bra     nz,1f                   ; Yes, skip to next opcode
        RD_ADDR w2,ze,w3
        mov.b   w3,[R_REGS+R_P]         ; And update PC
        retlw   #2,w0                   ; Return cycle count
1:      inc     w2,w2                   ; Bump PC over branch address
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_DEC,REG
        inc     REGS+2*\REG
        retlw   #2,w0
        .endm

        .macro  OP_DIS
        mov     [R_REGS+R_X],w2         ; Pull T value
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_X]
        and     w3,#0x0f,R_P            ; Extract P
        and     R_P,R_P,R_P
        swap.b  w3
        and     w3,#0x0f,R_X            ; Extract X
        add     R_X,R_X,R_X
        bclr    R_IE,#0                 ; Clear IE
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_GHI,REG
        mov.b   [R_REGS+2*\REG+1],R_D
        retlw   #2,w0
        .endm

        .macro  OP_GLO,REG
        mov.b   [R_REGS+2*\REG+0],R_D
        retlw   #2,w0
        .endm

        .macro  OP_IDL
        retlw   #2,w0
        .endm

        .macro  OP_INC,REG
        dec     REGS+2*\REG
        retlw   #2,w0
        .endm

        .macro  OP_INP,NUM
        .if	\NUM == 1
	mov	INT_FLAGS,w0		; Load the interrupt flags
	.endif
	.if	\NUM == 2
	mov	INT_ENABLE,w0		; Load the interrupt enables
	.endif
	.if	\NUM == 3
	bclr    INT_FLAGS,#INT_UART_RX  ; Clear the interrupt
        mov     U1RXREG,w0		; Receive into W0
	.endif
	mov	[R_REGS+R_X],w2		; Write result to D and M[R(X)]
	ze	w0,R_D
	WR_ADDR	w2,R_D
        retlw   #2,w0
        .endm

        .macro  OP_IRX
        mov     [R_REGS+R_X],w2
        inc     w2,w2
        mov     w2,[R_REGS+R_X]
        retlw   #2,w0
        .endm

        .macro  OP_LBDF
        mov     [R_REGS+R_P],w2
        btss    R_SR,#C                 ; Is DF set?
        bra     1f                      ; No.
        RD_ADDR w2,ze,w3                ; Read target address MSB
        inc     w2,w2
        RD_ADDR w2,ze,w0                ; Read target address LSB
        swap    w3                      ; Combine the bytes
        ior     w2,w3,w2
        mov     w2,[R_REGS+R_P]         ; And update PC
        retlw   #3,w0
1:      inc2    w2,w2                   ; Skip over the target address
        mov     w2,[R_REGS+R_P]
        retlw   #3,w0
        .endm

        .macro  OP_LBNF
        mov     [R_REGS+R_P],w2
        btsc    R_SR,#C                 ; Is DF clear?
        bra     1f                      ; No.
        RD_ADDR w2,ze,w3                ; Read target address MSB
        inc     w2,w2
        RD_ADDR w2,ze,w0                ; Read target address LSB
        swap    w3                      ; Combine the bytes
        ior     w2,w3,w2
        mov     w2,[R_REGS+R_P]         ; And update PC
        retlw   #3,w0
1:      inc2    w2,w2                   ; Skip over the target address
        mov     w2,[R_REGS+R_P]
        retlw   #3,w0
        .endm

        .macro  OP_LBNQ
        mov     [R_REGS+R_P],w2
        btsc    Q_LAT,#Q_PIN            ; Is Q clear?
        bra     1f                      ; No.
        RD_ADDR w2,ze,w3                ; Read target address MSB
        inc     w2,w2
        RD_ADDR w2,ze,w0                ; Read target address LSB
        swap    w3                      ; Combine the bytes
        ior     w2,w3,w2
        mov     w2,[R_REGS+R_P]         ; And update PC
        retlw   #3,w0
1:      inc2    w2,w2                   ; Skip over the target address
        mov     w2,[R_REGS+R_P]
        retlw   #3,w0
        .endm

        .macro  OP_LBNZ
        mov     [R_REGS+R_P],w2
        cp0.b   R_D                     ; Is D non-zero?
        bra     z,1f                    ; No.
        RD_ADDR w2,ze,w3                ; Read target address MSB
        inc     w2,w2
        RD_ADDR w2,ze,w0                ; Read target address LSB
        swap    w3                      ; Combine the bytes
        ior     w2,w3,w2
        mov     w2,[R_REGS+R_P]         ; And update PC
        retlw   #3,w0
1:      inc2    w2,w2                   ; Skip over the target address
        mov     w2,[R_REGS+R_P]
        retlw   #3,w0
        .endm

        .macro  OP_LBQ
        mov     [R_REGS+R_P],w2
        btss    Q_LAT,#Q_PIN            ; Is Q set?
        bra     1f                      ; No.
        RD_ADDR w2,ze,w3                ; Read target address MSB
        inc     w2,w2
        RD_ADDR w2,ze,w0                ; Read target address LSB
        swap    w3                      ; Combine the bytes
        ior     w2,w3,w2
        mov     w2,[R_REGS+R_P]         ; And update PC
        retlw   #3,w0
1:      inc2    w2,w2                   ; Skip over the target address
        mov     w2,[R_REGS+R_P]
        retlw   #3,w0
        .endm

        .macro  OP_LBR
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3                ; Read target address MSB
        inc     w2,w2
        RD_ADDR w2,ze,w0                ; Read target address LSB
        swap    w3                      ; Combine the bytes
        ior     w2,w3,w2
        mov     w2,[R_REGS+R_P]         ; And update PC
        retlw   #3,w0
        .endm

        .macro  OP_LBZ
        mov     [R_REGS+R_P],w2
        cp0.b   R_D                     ; Is D zero?
        bra     nz,1f                   ; No.
        RD_ADDR w2,ze,w3                ; Read target address MSB
        inc     w2,w2
        RD_ADDR w2,ze,w0                ; Read target address LSB
        swap    w3                      ; Combine the bytes
        ior     w2,w3,w2
        mov     w2,[R_REGS+R_P]         ; And update PC
        retlw   #3,w0
1:      inc2    w2,w2                   ; Skip over the target address
        mov     w2,[R_REGS+R_P]
        retlw   #3,w0
        .endm

        .macro  OP_LDA,REG
        mov     REGS+2*\REG,w2
        RD_ADDR w2,ze,R_D
        inc     REGS+2*\REG
        retlw   #2,w0
        .endm

        .macro  OP_LDI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,R_D
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0
        .endm

        .macro  OP_LDN,REG
        mov     REGS+2*\REG,w2
        RD_ADDR w2,ze,R_D
        retlw   #2,w0
        .endm

        .macro  OP_LDX
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,R_D
        retlw   #2,w0
        .endm

        .macro  OP_LDXA
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,R_D
        inc     w2,w2
        mov     w2,[R_REGS+R_X]
        retlw   #2,w0
        .endm

        .macro  OP_LSDF
        mov     [R_REGS+R_P],w2
        btss    R_SR,#C                 ; Is DF set?
        bra     1f                      ; No.
        inc2    w2,w2                   ; Yes, skip two bytes
        mov     w2,[R_REGS+R_P]         ; Update the PC
1:      retlw   #3,w0                   ; Return cycle count
        .endm

        .macro  OP_LSIE
        mov     [R_REGS+R_P],w2
        btss    R_IE,#0                 ; Is IE set?
        bra     1f                      ; No.
        inc2    w2,w2                   ; Yes, skip two bytes
        mov     w2,[R_REGS+R_P]         ; Update the PC
1:      retlw   #3,w0                   ; Return cycle count
        .endm

        .macro  OP_LSNF
        mov     [R_REGS+R_P],w2
        btsc    R_SR,#C                 ; Is DF clear?
        bra     1f                      ; No.
        inc2    w2,w2                   ; Yes, skip two bytes
        mov     w2,[R_REGS+R_P]         ; Update the PC
1:      retlw   #3,w0                   ; Return cycle count
        .endm

        .macro  OP_LSNQ
        mov     [R_REGS+R_P],w2
        btsc    Q_LAT,#Q_PIN            ; Is Q clear?
        bra     1f                      ; No.
        inc2    w2,w2                   ; Yes, skip two bytes
        mov     w2,[R_REGS+R_P]         ; Update the PC
1:      retlw   #3,w0                   ; Return cycle count
        .endm

        .macro  OP_LSNZ
        mov     [R_REGS+R_P],w2
        cp0.b   R_D                     ; Is D non-zero?
        bra     z,1f                    ; No.
        inc2    w2,w2                   ; Yes, skip two bytes
        mov     w2,[R_REGS+R_P]         ; Update the PC
1:      retlw   #3,w0                   ; Return cycle count
        .endm

        .macro  OP_LSQ
        mov     [R_REGS+R_P],w2
        btss    Q_LAT,#Q_PIN            ; Is Q set?
        bra     1f                      ; No.
        inc2    w2,w2                   ; Yes, skip two bytes
        mov     w2,[R_REGS+R_P]         ; Update the PC
1:      retlw   #3,w0                   ; Return cycle count
        .endm

        .macro  OP_LSZ
        mov     [R_REGS+R_P],w2
        cp0.b   R_D                     ; Is D zero?
        bra     nz,1f                   ; No.
        inc2    w2,w2                   ; Yes, skip two bytes
        mov     w2,[R_REGS+R_P]         ; Update the PC
1:      retlw   #3,w0                   ; Return cycle count
        .endm

        .macro  OP_MARK
        lsr     R_P,#1,w3               ; Combine X and P into T
        lsr     R_X,#1,w2
        swap.b  w2
        ior     w2,w3,w3
        mov     [R_REGS+2*2],w2         ; And push to R(2) stack
        WR_ADDR w2,w3
        dec     w2,w2
        mov     w2,[R_REGS+2*2]
        mov     R_P,R_X
        retlw   #2,w0
        .endm

        .macro  OP_NBR
        mov     [R_REGS+R_P],w2
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0
        .endm

        .macro  OP_NLBR
        mov     [R_REGS+R_P],w2
        inc2    w2,w2
        mov     w2,[R_REGS+R_P]
        retlw   #2,w0
        .endm

        .macro  OP_NOP
        retlw   #3,w0
        .endm

        .macro  OP_OR
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        ior     R_D,w3,R_D
        retlw   #2,w0
        .endm

        .macro  OP_ORI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        ior     R_D,w3,R_D
        retlw   #2,w0
        .endm

        .macro  OP_OUT,NUM
	mov	[R_REGS+R_X],w2		; Get the data address
	RD_ADDR	w2,ze,w3		; Fetch the data byhte
	inc	w2,w2			; Bump the address
	mov	w2,[R_REGS+R_X]		; .. and update
	.if	\NUM == 1
	mov	w3,w0
	mov.b	WREG,INT_FLAGS		; Set interrupt flags
	.endif
	.if	\NUM == 2
	mov	w3,w0
	mov.b	WREG,INT_ENABLE		; set interrupt enables
	.endif
	.if	\NUM == 3
	bclr	INT_FLAGS,#INT_UART_TX	; Clear 
	mov     w3,U1TXREG
        bset    IEC0,#U1TXIE            ; Ensure TX enabled
	.endif
        retlw   #2,w0
        .endm

        .macro  OP_PHI,REG
        mov.b   R_D,[R_REGS+2*\REG+1]
        retlw   #2,w0
        .endm

        .macro  OP_PLO,REG
        mov.b   R_D,[R_REGS+2*\REG+0]
        retlw   #2,w0
        .endm

        .macro  OP_REQ
        bclr    Q_LAT,#Q_PIN
        retlw   #2,w0
        .endm

        .macro  OP_RET
        mov     [R_REGS+R_X],w2         ; Pull T value
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_X]
        and     w3,#0x0f,R_P            ; Extract P
        and     R_P,R_P,R_P
        swap.b  w3
        and     w3,#0x0f,R_X            ; Extract X
        add     R_X,R_X,R_X
        bset    R_IE,#0                 ; Set IE
        retlw   #2,w0                   ; Return cycle count
        .endm

        .macro  OP_SAV
        lsr     R_P,#1,w3               ; Combine X and P into T
        lsr     R_X,#1,w2
        swap.b  w2
        ior     w2,w3,w3
        mov     [R_REGS+R_X],w2         ; And write to memory
        WR_ADDR w2,w3
        retlw   #2,w0
        .endm

        .macro  OP_SD
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        sub.b   w3,R_D,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SDB
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        btst.c  R_SR,#C
        subb.b  w3,R_D,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SDBI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        btst.c  R_SR,#C
        subb.b  w3,R_D,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SDI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        sub.b   w3,R_D,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SEP,REG
        mov     #2*\REG,R_P
        retlw   #2,w0
        .endm

        .macro  OP_SEQ
        bset    Q_LAT,#Q_PIN
        retlw   #2,w0
        .endm

        .macro  OP_SEX,REG
        mov     #2*\REG,R_X
        retlw   #2,w0
        .endm

        .macro  OP_SHL
        bclr    SR,#C
        rlc.b   R_D,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SHLC
        btst.c  R_SR,#C
        rlc.b   R_D,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SHR
        bclr    SR,#C
        rrc.b   R_D,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SHRC
        btst.c  R_SR,#C
        rrc.b   R_D,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SM
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        sub.b   R_D,w3,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SMB
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        btst.c  R_SR,#C
        subb.b  R_D,w3,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SMBI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        btst.c  R_SR,#C
        subb.b  R_D,w3,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_SMI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        sub.b   R_D,w3,R_D
        mov     SR,R_SR
        retlw   #2,w0
        .endm

        .macro  OP_STR,REG
        mov     REGS+2*\REG,w2
        WR_ADDR w2,R_D
        retlw   #2,w0
        .endm

        .macro  OP_STXD
        mov     [R_REGS+R_X],w2
        WR_ADDR w2,R_D
        dec     w2,w2
        mov     w2,[R_REGS+R_X]
        retlw   #2,w0
        .endm

        .macro  OP_XOR
        mov     [R_REGS+R_X],w2
        RD_ADDR w2,ze,w3
        xor     R_D,w3,R_D
        retlw   #2,w0
        .endm

        .macro  OP_XRI
        mov     [R_REGS+R_P],w2
        RD_ADDR w2,ze,w3
        inc     w2,w2
        mov     w2,[R_REGS+R_P]
        xor     R_D,w3,R_D
        retlw   #2,w0
        .endm

        .macro  OP_ERR
        retlw   #2,w0
        .endm
