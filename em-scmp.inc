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
; $Id: em-scmp.inc 49 2015-07-15 16:47:53Z andrew $
;-------------------------------------------------------------------------------

;===============================================================================
; Definitions
;-------------------------------------------------------------------------------

; Status Register Flags

        .equiv  F_CY,           7
        .equiv  F_OV,           6
        .equiv  F_SB,           5
        .equiv  F_SA,           4
        .equiv  F_IE,           3
        .equiv  F_F2,           2
        .equiv  F_F1,           1
        .equiv  F_F0,           0

        .equiv  MSK_CY_OV,      0x3f

        .equiv  M_DISP,         w7      ; Displacement check (-128)

        .equiv  R_P0,           w8
        .equiv  R_P1,           w9
        .equiv  R_P2,           w10
        .equiv  R_P3,           w11
        .equiv  R_AC,           w12
        .equiv  R_ER,           w13
        .equiv  R_SR,           w14

        .equiv  TRACE,          0

;===============================================================================
; I/O Mapping
;-------------------------------------------------------------------------------

; SC/MP Sense Pins

        .equiv  SA_PORT,        IN1_PORT
        .equiv  SA_PIN,         IN1_PIN

        .equiv  SB_PORT,        SW_PORT
        .equiv  SB_PIN,         SW_PIN

; SC/MP Shift In/Out Pins

        .equiv  SI_PORT,        IN2_PORT
        .equiv  SI_PIN,         IN2_PIN

        .equiv  SO_LAT,         OUT1_LAT
        .equiv  SO_PIN,         OUT1_PIN

; SC/MP Flag Pins

        .equiv  F0_LAT,         LED1_LAT
        .equiv  F0_PIN,         LED1_PIN

        .equiv  F1_LAT,         LED2_LAT
        .equiv  F1_PIN,         LED2_PIN

        .equiv  F2_LAT,         LED3_LAT
        .equiv  F2_PIN,         LED3_PIN

;===============================================================================
; Address Arithmetic
;-------------------------------------------------------------------------------

; Add one to the address in REG keeping it within the same 4K page. Use TMP as
; a working space and leave the result in RES.

        .macro  BUMP,REG,TMP,RES
        inc     \REG,\TMP               ; Add one to the address
        WRAP    \REG,\TMP,\RES
        .endm

; Wrap an address by working out which of the least significant 12 bits have
; changed and then apply the difference to the original value to create the
; result.

        .macro  WRAP,PTR,REG,RES
        xor     \PTR,\REG,\REG          ; Work out which bits changed
        and     \REG,M_MASK,\REG        ; Limit to low 12 bits
        xor     \PTR,\REG,\RES          ; And work out the new address
        .endm

;===============================================================================
; Addressing Modes
;-------------------------------------------------------------------------------

; The address mode macros calculate the operand address by reading additional
; bytes from the instruction. The target logical address is left in W2

; Relative

        .macro  AM_REL,REG
        BUMP    R_P0,w0,R_P0            ; Increment PC to the displacement
        RD_ADDR R_P0,se,w0              ; .. and fetch its value
        .if     TRACE
        push    w0
        push    w0
        mov     #' ',w0
        rcall   UartTx
        pop     w0
        rcall   PutHex2
        pop     w0
        .endif
        add     R_P0,w0,w2              ; Work out the target address
        xor     R_P0,w2,w2
        and     w2,M_MASK,w2
        xor     R_P0,w2,w2              ; And leave in W2
        .endm

; Indexed

        .macro  AM_IDX,REG
        BUMP    R_P0,w0,R_P0            ; Increment PC to the displacement
        RD_ADDR R_P0,se,w0              ; .. and fetch its value
        .if     TRACE
        push    w0
        push    w0
        mov     #' ',w0
        rcall   UartTx
        pop     w0
        rcall   PutHex2
        pop     w0
        .endif
        cpsne   w0,M_DISP               ; If the displacment is -128
        se      R_ER,w0                 ; .. the use the E register
        add     \REG,w0,w2              ; Work out the target address
        xor     \REG,w2,w2
        and     w2,M_MASK,w2
        xor     \REG,w2,w2              ; And leave in W2
        .endm

; Auto increment/decrement

        .macro  AM_AIX,REG
        BUMP    R_P0,w0,R_P0            ; Increment PC to the displacement
        RD_ADDR R_P0,se,w0              ; .. and fetch its value
        .if     TRACE
        push    w0
        push    w0
        mov     #' ',w0
        rcall   UartTx
        pop     w0
        rcall   PutHex2
        pop     w0
        .endif
        cpsne   w0,M_DISP               ; If the displacment is -128
        se      R_ER,w0                 ; .. then use the E register
        add     \REG,w0,w2              ; Work out the target address
        WRAP    \REG,w2,w2              ; And leave in W2
        exch    \REG,w2                 ; Assume post-incrment
        btsc    w0,#7
        mov     \REG,w2                 ; Correct if pre-decrement
        .endm

; Immediate

        .macro  AM_IMM
        BUMP    R_P0,w0,R_P0            ; Increment PC to the immediate value
        mov     R_P0,w2                 ; .. and leave address in W2
        .if     TRACE
        RD_ADDR R_P0,se,w0              ; .. and fetch its value
        push    w0
        push    w0
        mov     #' ',w0
        rcall   UartTx
        pop     w0
        rcall   PutHex2
        pop     w0
        .endif
        .endm

; Inherent

        .macro  AM_INH
        .if     TRACE
        rcall   PutStr
        .asciz  "   "
        .endif
        .endm

;===============================================================================
; Opcode Macros
;-------------------------------------------------------------------------------

		.macro  OP_ADD,REG
        .if     TRACE
        rcall   PutStr
        .asciz  " ADD "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the data value
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,w0,R_AC            ; .. and perform the addition
        and     #MSK_CY_OV,R_SR         ; Set the CY and OV flags
        btsc    SR,#C
        bset    R_SR,#F_CY
        btsc    SR,#OV
        bset    R_SR,#F_OV
        retlw   #19,w0                  ; Return cycle count
        .endm

        .macro  OP_ADE
        .if     TRACE
        rcall   PutStr
        .asciz  " ADE "
        .endif
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,R_ER,R_AC          ; .. and perform the addition
        and     #MSK_CY_OV,R_SR         ; Set the CY and OV flags
        btsc    SR,#C
        bset    R_SR,#F_CY
        btsc    SR,#OV
        bset    R_SR,#F_OV
        retlw   #7,w0                   ; Return cycle count
        .endm

        .macro  OP_ADI
        .if     TRACE
        rcall   PutStr
        .asciz  " ADI "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,w0,R_AC            ; .. and perform the addition
        and     #MSK_CY_OV,R_SR         ; Set the CY and OV flags
        btsc    SR,#C
        bset    R_SR,#F_CY
        btsc    SR,#OV
        bset    R_SR,#F_OV
        retlw   #11,w0                  ; Return cycle count
        .endm

        .macro  OP_AND
        .if     TRACE
        rcall   PutStr
        .asciz  " AND "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        and     R_AC,w0,R_AC
        retlw   #18,w0                  ; Return cycle count
        .endm

	.macro	OP_ANE
        .if     TRACE
        rcall   PutStr
        .asciz  " ANE "
        .endif
	and	R_AC,R_ER,R_AC          ; Perform the AND
        retlw   #6,w0                   ; Return cycle count
	.endm

        .macro  OP_ANI
        .if     TRACE
        rcall   PutStr
        .asciz  " ANI "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        and     R_AC,w0,R_AC            ; Perform the AND
        retlw   #10,w0                  ; Return cycle count
        .endm

        .macro  OP_CAD
        .if     TRACE
        rcall   PutStr
        .asciz  " CAD "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the data value
        com.b   w0,w0
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,w0,R_AC            ; .. and perform the addition
        and     #MSK_CY_OV,R_SR         ; Set the CY and OV flags
        btsc    SR,#C
        bset    R_SR,#F_CY
        btsc    SR,#OV
        bset    R_SR,#F_OV
        retlw   #20,w0                  ; Return cycle count
        .endm

        .macro  OP_CAE
        .if     TRACE
        rcall   PutStr
        .asciz  " CAE "
        .endif
        com.b   R_ER,w0
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,w0,R_AC            ; .. and perform the addition
        and     #MSK_CY_OV,R_SR         ; Set the CY and OV flags
        btsc    SR,#C
        bset    R_SR,#F_CY
        btsc    SR,#OV
        bset    R_SR,#F_OV
        retlw   #8,w0                   ; Return cycle count
        .endm

        .macro  OP_CAI
        .if     TRACE
        rcall   PutStr
        .asciz  " CAI "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        com.b   w0,w0
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,w0,R_AC            ; .. and perform the addition
        and     #MSK_CY_OV,R_SR         ; Set the CY and OV flags
        btsc    SR,#C
        bset    R_SR,#F_CY
        btsc    SR,#OV
        bset    R_SR,#F_OV
        retlw   #12,w0                  ; Return cycle count
        .endm

        .macro  OP_CAS
        .if     TRACE
        rcall   PutStr
        .asciz  " CAS "
        .endif
        xor     R_AC,R_SR,w0
        and     #0xcf,w0
        xor     R_SR,w0,R_SR
        and     R_SR,#(1<<F_F2)|(1<<F_F1)|(1<<F_F0),w0
        sl      w0,#F0_PIN,w0
        xor     F0_LAT,WREG
        mov     #(1<<F2_PIN)|(1<<F1_PIN)|(1<<F0_PIN),w1
        and     w0,w1,w0
        xor     F0_LAT
        retlw   #6,w0                   ; Return cycle count
        .endm

        .macro  OP_CCL
        .if     TRACE
        rcall   PutStr
        .asciz  " CCL "
        .endif
        bclr    R_SR,#F_CY
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_CSA
        .if     TRACE
        rcall   PutStr
        .asciz  " CSA "
        .endif
        mov     R_SR,R_AC
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_DAD
        .if     TRACE
        rcall   PutStr
        .asciz  " DAD "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the data value
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,w0,R_AC            ; .. and perform the addition
        daw.b   R_AC
        bclr    R_SR,#F_CY
        btsc    SR,#C
        bset    R_SR,#F_CY
        retlw   #23,w0                  ; Return cycle count
        .endm

        .macro  OP_DAE
        .if     TRACE
        rcall   PutStr
        .asciz  " DAE "
        .endif
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,R_ER,R_AC          ; .. and perform the addition
        daw.b   R_AC
        bclr    R_SR,#F_CY
        btsc    SR,#C
        bset    R_SR,#F_CY
        retlw   #11,w0                  ; Return cycle count
        .endm

        .macro  OP_DAI
        .if     TRACE
        rcall   PutStr
        .asciz  " DAI "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        btst.c  R_SR,#F_CY              ; Recover the carry flag
        addc.b  R_AC,w0,R_AC            ; .. and perform the addition
        daw.b   R_AC
        bclr    R_SR,#F_CY
        btsc    SR,#C
        bset    R_SR,#F_CY
        retlw   #15,w0                  ; Return cycle count
        .endm

        .macro  OP_DINT
        .if     TRACE
        rcall   PutStr
        .asciz  " DINT"
        .endif
        bclr    R_SR,#F_IE
        retlw   #6,w0                   ; Return cycle count
        .endm

        .macro  OP_DLD
        .if     TRACE
        rcall   PutStr
        .asciz  " DLD "
        .endif
        push    w2
        RD_ADDR w2,ze,w3                ; Fetch the operand byte
        dec.b   w3,R_AC
        pop     w2
        WR_ADDR w2,R_AC                 ; And write value back
        retlw   #22,w0                  ; Return cycle count
        .endm

        .macro  OP_DLY
        .if     TRACE
        rcall   PutStr
        .asciz  " DLY "
        .endif
        RD_ADDR w2,ze,w3                ; Read the displacment byte
        mov     #514,w2                 ; And calculate delay
        mul.uu  w2,w3,w0
        add     R_AC,R_AC,w2
        add     w2,w0,w2
        btsc    SR,#C
        inc     w1,w1

        mov     #0x4000,w0

        cp0     w1                      ; Is the HI word zero?
        bra     z,5f

0:      add     CYCLE                   ; Delay 0x10000 cycles
1:      btss    CYCLE,#15
        bra     1b
        add     CYCLE
2:      btss    CYCLE,#15
        bra     2b
        add     CYCLE
3:      btss    CYCLE,#15
        bra     3b
        add     CYCLE
4:      btss    CYCLE,#15
        bra     4b

        dec     w1,w1                   ; Reduce MSW and
        bra     nz,0b                   ; .. repeat until zero

5:      cp      w2,w0                   ; is LSW over chunk size?
        bra     leu,7f                  ; No.

        add     CYCLE                   ; Yes, consume a chunk
6:      btss    CYCLE,#15
        bra     6b
        sub     w2,w0,w2                ; Reduce the target
        bra     5b                      ; And repeat

7:      mov     #0x00ff,R_AC
        add     w2,#13,w0               ; Return cycle count
        return
        .endm

        .macro  OP_HALT
        .if     TRACE
        rcall   PutStr
        .asciz  " HALT"
        .endif
        retlw   #8,w0                   ; Return cycle count
        .endm

        .macro  OP_IEN
        .if     TRACE
        rcall   PutStr
        .asciz  " IEN "
        .endif
        bset    R_SR,#F_IE
        retlw   #6,w0                   ; Return cycle count
        .endm

        .macro  OP_ILD
        .if     TRACE
        rcall   PutStr
        .asciz  " ILD "
        .endif
        push    w2
        RD_ADDR w2,ze,w3                ; Fetch the operand byte
        inc.b   w3,R_AC                 ; Increment
        pop     w2
        WR_ADDR w2,R_AC                 ; And write value back
        retlw   #22,w0                  ; Return cycle count
        .endm

        .macro  OP_JMP
        .if     TRACE
        rcall   PutStr
        .asciz  " JMP "
        .endif
        mov     w2,R_P0
        retlw   #11,w0                  ; Return cycle count
        .endm

        .macro  OP_JNZ
        .if     TRACE
        rcall   PutStr
        .asciz  " JNZ "
        .endif
        cp0.b   R_AC
        btsc    SR,#Z
        retlw   #9,w0                   ; Return cycle count (not taken)
        mov     w2,R_P0
        retlw   #11,w0                  ; Return cycle count (taken)
        .endm

        .macro  OP_JP
        .if     TRACE
        rcall   PutStr
        .asciz  " JP  "
        .endif
        btsc    R_AC,#7
        retlw   #9,w0                   ; Return cycle count (not taken)
        mov     w2,R_P0
        retlw   #11,w0                  ; Return cycle count
        .endm

        .macro  OP_JZ
        .if     TRACE
        rcall   PutStr
        .asciz  " JZ  "
        .endif
        cp0.b   R_AC
        btss    SR,#Z
        retlw   #9,w0                   ; Return cycle count (not taken)
        mov     w2,R_P0
        retlw   #11,w0                  ; Return cycle count (taken)
        .endm

        .macro  OP_LD
        .if     TRACE
        rcall   PutStr
        .asciz  " LD  "
        .endif
        RD_ADDR w2,ze,R_AC
        retlw   #18,w0                  ; Return cycle count
        .endm

        .macro  OP_LDE
        .if     TRACE
        rcall   PutStr
        .asciz  " LDE "
        .endif
	mov	R_ER,R_AC		; Copy ER into AC
        retlw   #6,w0                   ; Return cycle count
        .endm

        .macro  OP_LDI
        .if     TRACE
        rcall   PutStr
        .asciz  " LDI "
        .endif
        RD_ADDR w2,ze,R_AC              ; Load immediate data into AC
        retlw   #10,w0                  ; Return cycle count
        .endm

        .macro  OP_NOP
        .if     TRACE
        rcall   PutStr
        .asciz  " NOP "
        .endif
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_OR
        .if     TRACE
        rcall   PutStr
        .asciz  " OR  "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        ior     R_AC,w0,R_AC
        retlw   #17,w0                  ; Return cycle count
        .endm

		.macro	OP_ORE
        .if     TRACE
        rcall   PutStr
        .asciz  " ORE "
        .endif
	ior	R_AC,R_ER,R_AC
        retlw   #6,w0                   ; Return cycle count
	.endm

        .macro  OP_ORI
        .if     TRACE
        rcall   PutStr
        .asciz  " ORI "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        ior     R_AC,w0,R_AC            ; Perform the OR
        retlw   #10,w0                  ; Return cycle count
        .endm

        .macro  OP_RR
        .if     TRACE
        rcall   PutStr
        .asciz  " RR  "
        .endif
        rrnc.b  R_AC,R_AC
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_RRL
        .if     TRACE
        rcall   PutStr
        .asciz  " RRL "
        .endif
        btst.c  R_SR,#F_CY
        rrc.b   R_AC,R_AC
        mov     #F_CY,w1
        bsw.c   R_SR,w1
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_SCL
        .if     TRACE
        rcall   PutStr
        .asciz  " SCL "
        .endif
        bset    R_SR,#F_CY
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_SIO
        .if     TRACE
        rcall   PutStr
        .asciz  " SIO "
        .endif
        mov     SI_PORT,w0              ; Sample the input pin
        btst.c  w0,#SI_PIN
        lsr.b   R_ER,R_ER               ; Shift into the ER register
        mov     #SO_LAT,w0              ; And set the output pin
        mov     #SO_PIN,w1
        bsw.c   [w0],w1
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_SR
        .if     TRACE
        rcall   PutStr
        .asciz  " SR  "
        .endif
        lsr.b   R_AC,R_AC
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_SRL
        .if     TRACE
        rcall   PutStr
        .asciz  " SRL "
        .endif
        btst.c  R_SR,#F_CY
        rrc.b   R_AC,R_AC
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_ST
        .if     TRACE
        rcall   PutStr
        .asciz  " ST  "
        mov     w2,w3
        .endif
        WR_ADDR w2,R_AC
        retlw   #18,w0                  ; Return cycle count
        .endm

		.macro  OP_XAE
        .if     TRACE
        rcall   PutStr
        .asciz  " XAE "
        .endif
	exch	R_AC,R_ER               ; Exchange AC and ER
        retlw   #7,w0                   ; Return cycle count
        .endm

        .macro  OP_XOR
        .if     TRACE
        rcall   PutStr
        .asciz  " XOR "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        xor     R_AC,w0,R_AC
        retlw   #18,w0                  ; Return cycle count
        .endm

        .macro  OP_XPAH,REG
        .if     TRACE
        rcall   PutStr
        .asciz  " XPAH"
        .endif
        swap    \REG
        xor.b   R_AC,\REG,w0
        ze      w0,w0
        xor.b   \REG,w0,\REG
        xor.b   R_AC,w0,R_AC
        swap    \REG
        retlw   #8,w0                   ; Return cycle count
        .endm

        .macro  OP_XPAL,REG
        .if     TRACE
        rcall   PutStr
        .asciz  " XPAL"
        .endif
        xor.b   R_AC,\REG,w0
        ze      w0,w0
        xor.b   \REG,w0,\REG
        xor.b   R_AC,w0,R_AC
        retlw   #8,w0                   ; Return cycle count
        .endm

        .macro  OP_XPPC,REG
        .if     TRACE
        rcall   PutStr
        .asciz  " XPPC"
        .endif
        exch    R_P0,\REG               ; Exchange PC and target pointer
        retlw   #7,w0                   ; Return cycle count
        .endm

        .macro  OP_XRE
        .if     TRACE
        rcall   PutStr
        .asciz  " XRE "
        .endif
        xor     R_AC,R_ER,R_AC
        retlw   #6,w0                   ; Return cycle count
        .endm

        .macro  OP_XRI
        .if     TRACE
        rcall   PutStr
        .asciz  " XRI "
        .endif
        RD_ADDR w2,ze,w0                ; Fetch the operand byte
        xor     R_AC,w0,R_AC            ; Perform the XOR
        retlw   #10,w0                  ; Return cycle count
        .endm

        .macro  OP_ERR
        .if     TRACE
        rcall   PutStr
        .asciz  " ??? "
        .endif
        nop
        nop
        bra     $
        nop
        nop
        retlw   #5,w0                   ; Return cycle count
        .endm

;-------------------------------------------------------------------------------
; This macros define extended instructions for serial I/O

        .macro  OP_TXD
        .if     TRACE
        call    PutStr
        .asciz  " TXD "
        .endif
0:	btss	INT_FLAGS,#INT_UART_TX	; Wait until ready to transmit
	bra	0b
        ze      R_AC,w0			; Transmit from A
	mov     w0,U1TXREG
        bset    IEC0,#U1TXIE            ; Ensure TX enabled
        retlw   #5,w0                   ; Return cycle count
        .endm

        .macro  OP_RXD
        .if     TRACE
        call    PutStr
        .asciz  " RXD "
        .endif
0:	btss	INT_FLAGS,#INT_UART_RX	; Wait for data to be available
	bra	0b
	bclr    INT_FLAGS,#INT_UART_RX  ; Clear the interrupt
        mov     U1RXREG,w0		; And receive a byte of data
        ze      w0,R_AC
        retlw   #5,w0                   ; Return cycle count
        .endm
