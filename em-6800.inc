;===============================================================================
;  _____ __  __        __    ___   ___   ___
; | ____|  \/  |      / /_  ( _ ) / _ \ / _ \
; |  _| | |\/| |_____| '_ \ / _ \| | | | | | |
; | |___| |  | |_____| (_) | (_) | |_| | |_| |
; |_____|_|  |_|      \___/ \___/ \___/ \___/
;
;
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
; The 6800 emulator uses the PIC24 native status flags to hold the Z,V,H,N and
; C flags. The PIC's status register is saved and restored from R_SR as needed
; during emulation. Instructions that transfer to or from the P register must
; translate R_SR.
;
;===============================================================================
; Revision History:
;
; 2014-12-13 AJ Initial version
;-------------------------------------------------------------------------------

;===============================================================================
; Definitions
;-------------------------------------------------------------------------------

; Status Register Flags

        .equiv  F_H,            5
        .equiv  F_I,            4
        .equiv  F_N,            3
        .equiv  F_Z,            2
        .equiv  F_V,            1
        .equiv  F_C,            0

; Native register allocation

        .equiv  R_SR,           w7              ; Saved SR for Z,N,H,C,V
        .equiv  R_PC,           w8
        .equiv  R_SP,           w9
        .equiv  R_A,            w10
        .equiv  R_B,            w11
        .equiv  R_X,            w12
        .equiv  R_P,            w13             ; Only I bit

        .equiv  TRACE,          0

;===============================================================================
; Addressing Modes
;-------------------------------------------------------------------------------

; Direct Page

        .macro  AM_DPG
        RD_ADDR R_PC,ze,w2              ; Read the direct address
        inc     R_PC,R_PC
        .endm

; Extended

        .macro  AM_EXT
        RD_ADDR R_PC,ze,w2              ; Read MSB of address
        inc     R_PC,R_PC
        RD_ADDR R_PC,ze,w3              ; Read LSB of address
        inc     R_PC,R_PC
        swap    w2                      ; Form the full address
        ior     w2,w3,w2
        .endm

; Indexed

        .macro  AM_IDX
        RD_ADDR R_PC,ze,w3              ; Read the offset
        inc     R_PC,R_PC
        add     R_X,w3,w2               ; And calculate the address
        .endm

; Inherent

        .macro  AM_INH
        .endm

; Immediate byte/word

        .macro  AM_IMM,SIZ
        mov     R_PC,w2
        add     R_PC,#\SIZ,R_PC
        .endm

; Relative

        .macro  AM_REL
        RD_ADDR R_PC,se,w2
        inc     R_PC,R_PC
        add     R_PC,w2,w2
        .endm

;===============================================================================
; Opcode Macros
;-------------------------------------------------------------------------------

        .macro  OP_ABA
        mov     R_SR,SR
        add.b   R_A,R_B,R_A
        mov     SR,R_SR
        .endm

        .macro  OP_ADC,ACC
        RD_ADDR w2,ze,w3                ; Read target memory byte
        mov     R_SR,SR                 ; Restore the flags
        addc.b  \ACC,w3,\ACC            ; Perform add with carry
        mov     SR,R_SR                 ; And save the flags
        .endm

        .macro  OP_ADD,ACC
        RD_ADDR w2,ze,w3                ; Read target memory byte
        mov     R_SR,SR                 ; Restore the flags
        add.b   \ACC,w3,\ACC            ; Perform add with no carry
        mov     SR,R_SR                 ; And save the flags
        .endm

        .macro  OP_AND,ACC
        RD_ADDR w2,ze,w3                ; Read target memory byte
        mov     R_SR,SR                 ; Restore the flags
        and.b   \ACC,w3,\ACC            ; Perform bitwise AND
        mov     SR,R_SR                 ; Save changes to N & Z
        bclr    R_SR,#OV                ; And clear V
        .endm

        .macro  OP_ASL,ACC
        mov     R_SR,SR                 ; Restore the flags
        sl.b    \ACC,\ACC               ; Perform left shift
        mov     SR,R_SR                 ; And save the flags
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_ASLM
        RD_ADDR w2,ze,w3                ; Read the target memory byte
        mov     R_SR,SR                 ; Restore the flags
        sl.b    w3,w3                   ; Perform left shift
        mov     SR,R_SR                 ; And save the flags
        WR_ADDR w2,w3                   ; Write result back to memory
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_ASR,ACC
        mov     R_SR,SR                 ; Restore the flags
        sl.b    \ACC,\ACC               ; Perform arithmetic shift
        mov     SR,R_SR                 ; And save the flags
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_ASRM
        RD_ADDR w2,ze,w3                ; Read the target memory byte
        mov     R_SR,SR                 ; Restore the flags
        asr.b   w3,w3                   ; Perform arithmetic shift
        mov     SR,R_SR                 ; And save the flags
        WR_ADDR w2,w3                   ; Write result back to memory
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
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
        btsc    R_SR,#Z                 ; If the zero flag is set
        mov     w2,R_PC                 ; .. change the PC
        .endm

        .macro  OP_BGE
        mov     R_SR,SR
        bra     lt,1f
        mov     w2,R_PC
1:
        .endm

        .macro  OP_BGT
        mov     R_SR,SR
        bra     le,1f
        mov     w2,R_PC
1:
        .endm

        .macro  OP_BHI
        mov     R_SR,SR
        bra     leu,1f
        mov     w2,R_PC
1:
        .endm

        .macro  OP_BIT,ACC
        RD_ADDR w2,ze,w3                ; Read target memory byte
        and.b   \ACC,w3,w3              ; Test mask against byte
        mov     SR,w0                   ; Work out changes to flags
        xor     w0,R_SR,w0
        and     #(1<<N)|(1<<Z),w0
        xor     w0,R_SR,R_SR
        bclr    R_SR,#OV                ; And clear overflow
        .endm

        .macro  OP_BLE
        mov     R_SR,SR
        bra     gt,1f
        mov     w2,R_PC
1:
        .endm

        .macro  OP_BLS
        mov     R_SR,SR
        bra     gtu,1f
        mov     w2,R_PC
1:
        .endm

        .macro  OP_BLT
        mov     R_SR,SR
        bra     ge,1f
        mov     w2,R_PC
1:
        .endm

        .macro  OP_BMI
        btsc    R_SR,#N                 ; If the negative flag is set
        mov     w2,R_PC                 ; .. change the PC
        .endm

        .macro  OP_BNE
        btss    R_SR,#Z                 ; If the zero flag is clear
        mov     w2,R_PC                 ; .. change the PC
        .endm

        .macro  OP_BPL
        btss    R_SR,#N                 ; If the negative flag is clear
        mov     w2,R_PC                 ; .. change the PC
        .endm

        .macro  OP_BRA
        mov     w2,R_PC                 ; Set PC to target address
        .endm

        .macro  OP_BSR
        exch    R_PC,w2                 ; Swap PC and target address
        WR_ADDR R_SP,w2                 ; Push low byte of return address
        dec     R_SP,R_SP
        swap    w2                      ; Push high byte of return address
        WR_ADDR R_SP,w2
        dec     R_SP,R_SP
        .endm

        .macro  OP_BVC
        btss    R_SR,#OV                ; If the overflow flag is clear
        mov     w2,R_PC                 ; .. change the PC
        .endm

        .macro  OP_BVS
        btsc    R_SR,#OV                ; If the overflow flag is set
        mov     w2,R_PC                 ; .. change the PC
        .endm

        .macro  OP_CBA
        cp.b    R_A,R_B                 ; Compare accumulators
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        .endm

        .macro  OP_CLC
        bclr    R_SR,#C                 ; Clear carry in native flags
        .endm

        .macro  OP_CLI
        bclr    R_P,#F_I                ; Clear the interrupt flag
        .endm

        .macro  OP_CLR,ACC
        clr.b   \ACC                    ; Clear the accumulator
        bclr    R_SR,#N                 ; And adjust flags
        bset    R_SR,#Z
        bclr    R_SR,#C
        bclr    R_SR,#OV
        .endm

        .macro  OP_CLRM
        clr     w3                      ; Clear the target memory byte
        WR_ADDR w2,w3
        bclr    R_SR,#N                 ; And adjust flags
        bset    R_SR,#Z
        bclr    R_SR,#C
        bclr    R_SR,#OV
        .endm

        .macro  OP_CLV
        bclr    R_SR,#OV                ; Clear overflow in native flags
        .endm

        .macro  OP_CMP,ACC
        RD_ADDR w2,ze,w3                ; Read the target memory byte
        cp.b    \ACC,w3                 ; Perform the comparison
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        .endm

        .macro  OP_COM,ACC
        mov     R_SR,SR
        com.b   \ACC,\ACC
        mov     SR,R_SR
        bclr    R_SR,#OV
        bset    R_SR,#C
        .endm

        .macro  OP_COMM
        RD_ADDR w2,ze,w3
        mov     R_SR,SR
        com.b   w3,w3
        mov     SR,R_SR
        bclr    R_SR,#OV
        bset    R_SR,#C
        WR_ADDR w2,w3
        .endm

        .macro  OP_CPX
        RD_ADDR w2,ze,w3
        inc     w2,w2
        RD_ADDR w2,ze,w0
        lsr     w3,#8,w3
        ior     w3,w0,w3
        cp      R_X,w3                  ; Perform the comparison
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        .endm

        .macro  OP_DAA
        mov     R_SR,SR                 ; Restore flags
        daw.b   R_A                     ; Perform decimal adjust
        mov     SR,R_SR                 ; And save updated flags
        .endm

        .macro  OP_DEC,ACC
        sub.b   \ACC,#1,\ACC            ; Subtract one from A or B
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        .endm

        .macro  OP_DECM
        RD_ADDR w2,ze,w3                ; Read target memory byte
        sub.b   w3,#1,w3                ; Subtract one
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        WR_ADDR w2,w3                   ; And write the byte back
        .endm

        .macro  OP_DES
        dec     R_SP,R_SP               ; Decrement SP
        .endm

        .macro  OP_DEX
        dec     R_X,R_X                 ; Decrement X
        mov     #Z,w0                   ; And update Z bit
        bsw.z   R_SR,w0                 ; .. in the saved flags
        .endm

        .macro  OP_EOR,ACC
        RD_ADDR w2,ze,w3                ; Read target memory byte
        mov     R_SR,SR                 ; Restore the flags
        xor.b   \ACC,w3,\ACC            ; Perform bitwise XOR
        mov     SR,R_SR                 ; Save changes to N & Z
        bclr    R_SR,#OV                ; And clear V
        .endm

        .macro  OP_INC,ACC
        add.b   \ACC,#1,\ACC            ; Add one to A or B
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        .endm

        .macro  OP_INCM
        RD_ADDR w2,ze,w3                ; Read target memory byte
        add.b   w3,#1,w3                ; Add one
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        WR_ADDR w2,w3                   ; And write the byte back
        .endm

        .macro  OP_INS
        inc     R_SP,R_SP               ; Increment SP
         .endm

        .macro  OP_INX
        inc     R_X,R_X                 ; Increment X
        mov     #Z,w0                   ; And update Z bit
        bsw.z   R_SR,w0                 ; .. in the saved flags
         .endm

        .macro  OP_JMP
        mov     w2,R_PC                 ; Update PC with target address
        .endm

        .macro  OP_JSR
        exch    R_PC,w2                 ; Swap PC and target address
        WR_ADDR R_SP,w2                 ; Push low byte of return address
        dec     R_SP,R_SP
        swap    w2                      ; Push high byte of return address
        WR_ADDR R_SP,w2
        dec     R_SP,R_SP
        .endm

        .macro  OP_LDA,ACC
        RD_ADDR w2,ze,\ACC              ; Read target memory byte
        mov     R_SR,SR                 ; Set N and Z flags
        ior.b   \ACC,\ACC,\ACC
        mov     SR,R_SR
        bclr    R_SR,#OV                ; And clear overflow
        .endm

        .macro  OP_LDS
        RD_ADDR w2,ze,R_SP              ; Read high byte from memory
        inc     w2,w2
        RD_ADDR w2,ze,w3                ; Read low byte from memory
        swap    R_SP                    ; Combine into target address
        mov     R_SR,SR
        ior     R_SP,w3,R_SP
        mov     SR,R_SR
        bclr    R_SR,#OV                ; And clear overflow
        .endm

        .macro  OP_LDX
        RD_ADDR w2,ze,R_X               ; Read high byte from memory
        inc     w2,w2
        RD_ADDR w2,ze,w3                ; Read low byte from memory
        swap    R_X                     ; Combine into target address
        mov     R_SR,SR
        ior     R_X,w3,R_X
        mov     SR,R_SR
        bclr    R_SR,#OV                ; And clear overflow
        .endm

        .macro  OP_LSR,ACC
        mov     R_SR,SR                 ; Restore the flags
        lsr.b   \ACC,\ACC               ; Perform right shift
        mov     SR,R_SR                 ; And save the flags
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_LSRM
        RD_ADDR w2,ze,w3                ; Read the target memory byte
        mov     R_SR,SR                 ; Restore the flags
        lsr.b   w3,w3                   ; Perform logical shift
        mov     SR,R_SR                 ; And save the flags
        WR_ADDR w2,w3                   ; Write result back to memory
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_NEG,ACC
        neg.b   \ACC,\ACC               ; Negate A or B
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        .endm

        .macro  OP_NEGM
        RD_ADDR w2,ze,w3                ; Read target memory byte
        neg.b   w3,w3                   ; And negate it
        mov     SR,w0                   ; Save new flag state
        xor     w0,R_SR,w0              ; Work out difference with last state
        bclr    w0,#DC                  ; .. ignoring DC
        xor     w0,R_SR,R_SR            ; And update saved flags
        WR_ADDR w2,w3                   ; Write back the modified byte
        .endm

        .macro  OP_NOP
        .endm

        .macro  OP_ORA,ACC
        RD_ADDR w2,ze,w3                ; Read target memory byte
        mov     R_SR,SR                 ; Restore the flags
        ior.b   \ACC,w3,\ACC            ; Perform bitwise OR
        mov     SR,R_SR                 ; Save change to N and Z
        bclr    R_SR,#OV                ; And clear V
        .endm

        .macro  OP_PSH,ACC
        WR_ADDR R_SP,\ACC
        dec     R_SP,R_SP
        .endm

        .macro  OP_PUL,ACC
        inc     R_SP,R_SP
        RD_ADDR R_SP,ze,\ACC
        .endm

        .macro  OP_ROL,ACC
        mov     R_SR,SR                 ; Restore the flags
        rlc.b   \ACC,\ACC               ; Perform left rotate
        mov     SR,R_SR                 ; And save the flags
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_ROLM
        RD_ADDR w2,ze,w3                ; Read the target memory byte
        mov     R_SR,SR                 ; Restore the flags
        rlc.b   w3,w3                   ; Perform left rotate
        mov     SR,R_SR                 ; And save the flags
        WR_ADDR w2,w3                   ; Write result back to memory
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_ROR,ACC
        mov     R_SR,SR                 ; Restore the flags
        rrc.b   \ACC,\ACC               ; Perform right rotate
        mov     SR,R_SR                 ; And save the flags
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_RORM
        RD_ADDR w2,ze,w3                ; Read the target memory byte
        mov     R_SR,SR                 ; Restore the flags
        rrc.b   w3,w3                   ; Perform right rotate
        mov     SR,R_SR                 ; And save the flags
        WR_ADDR w2,w3                   ; Write result back to memory
        bclr    R_SR,#OV                ; Work out the overflow
        btsc    R_SR,#N
        btg     R_SR,#OV
        btsc    R_SR,#C
        btg     R_SR,#OV
        .endm

        .macro  OP_RTI
        inc     R_SP,R_SP               ; Pull flags
        RD_ADDR R_SP,ze,R_P
        bclr    R_SR,#C                 ; And copy into SR
        bclr    R_SR,#Z
        bclr    R_SR,#N
        bclr    R_SR,#OV
        bclr    R_SR,#DC
        btsc    R_P,#F_C
        bset    R_SR,#C
        btsc    R_P,#F_Z
        bset    R_SR,#Z
        btsc    R_P,#F_N
        bset    R_SR,#N
        btsc    R_P,#F_V
        bset    R_SR,#OV
        btsc    R_P,#F_H
        bset    R_SR,#DC
        inc     R_SP,R_SP               ; Pull B
        RD_ADDR R_SP,ze,R_B
        inc     R_SP,R_SP               ; Pull A
        RD_ADDR R_SP,ze,R_A
        inc     R_SP,R_SP               ; Pull high byte of X
        RD_ADDR R_SP,ze,R_X
        inc     R_SP,R_SP               ; Pull low byte of
        RD_ADDR R_SP,ze,w3
        swap    R_X                     ; Combine bytes into new X
        ior     R_X,w3,R_X
        inc     R_SP,R_SP               ; Pull high byte of return address
        RD_ADDR R_SP,ze,R_PC
        inc     R_SP,R_SP               ; Pull low byte of return address
        RD_ADDR R_SP,ze,w3
        swap    R_PC                    ; Combine bytes into new PC
        ior     R_PC,w3,R_PC
        .endm

        .macro  OP_RTS
        inc     R_SP,R_SP               ; Pull high byte of return address
        RD_ADDR R_SP,ze,R_PC
        inc     R_SP,R_SP               ; Pull low byte of return address
        RD_ADDR R_SP,ze,w3
        swap    R_PC                    ; Combine bytes into new PC
        ior     R_PC,w3,R_PC
        .endm

        .macro  OP_SBA
        mov     R_SR,SR
        sub.b   R_A,R_B,R_A
        mov     SR,R_SR
        .endm

        .macro  OP_SBC,ACC
        RD_ADDR w2,ze,w3                ; Read target memory byte
        mov     R_SR,SR                 ; Restore the flags
        subb.b  \ACC,w3,\ACC            ; Perform subtract with carry
        mov     SR,R_SR                 ; And save the flags
        .endm

        .macro  OP_SEC
        bset    R_SR,#C                 ; Set carry in the native flags
        .endm

        .macro  OP_SEI
        bset    R_P,#F_I                ; Set interrupt flag
        .endm

        .macro  OP_SEV
        bset    R_SR,#OV                ; Set overflow in the native flags
        .endm

        .macro  OP_STA,ACC
        WR_ADDR w2,\ACC
        mov     R_SR,SR
        ior.b   \ACC,\ACC,\ACC
        mov     SR,R_SR
        bclr    R_SR,#OV
        .endm

        .macro  OP_STS
        lsr     R_SP,#8,w3              ; Shift down MSB
        WR_ADDR w2,w3                   ; And write to memory
        inc     w2,w2
        WR_ADDR w2,R_SP                 ; Followed by LSB
        .endm

        .macro  OP_STX
        lsr     R_X,#8,w3               ; Shift down MSB
        WR_ADDR w2,w3                   ; And write to memory
        inc     w2,w2
        WR_ADDR w2,R_X                  ; Followed by LSB
        .endm

        .macro  OP_SUB,ACC
        RD_ADDR w2,ze,w3                ; Read target memory byte
        mov     R_SR,SR                 ; Restore the flags
        sub.b   \ACC,w3,\ACC            ; Perform subtract
        mov     SR,R_SR                 ; And save the flags
        .endm

        .macro  OP_SWI
        mov     R_PC,w3                 ; Push PC
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        swap    w3
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        mov     R_X,w3                  ; Push X
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        swap    w3
        WR_ADDR R_SP,w3
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_A                ; Push A
        dec     R_SP,R_SP
        WR_ADDR R_SP,R_B                ; Push B
        dec     R_SP,R_SP
        bclr    R_P,#F_C                ; Copy native flags into P
        bclr    R_P,#F_Z
        bclr    R_P,#F_N
        bclr    R_P,#F_V
        bclr    R_P,#F_H
        btsc    R_SR,#C
        bset    R_P,#F_C
        btsc    R_SR,#Z
        bset    R_P,#F_Z
        btsc    R_SR,#N
        bset    R_P,#F_N
        btsc    R_SR,#OV
        bset    R_P,#F_V
        btsc    R_SR,#DC
        bset    R_P,#F_H
        WR_ADDR R_SP,R_P                ; Push P
        dec     R_SP,R_SP
        bset    R_P,#F_I                ; Set interrupt disable
        mov     #0xfffa,w2              ; Read SWI vector
        RD_ADDR w2,ze,R_PC
        inc     w2,w2
	swap	R_PC
        RD_ADDR w2,ze,w3              
        ior     R_PC,w3,R_PC		; Form new PC
        .endm

        .macro  OP_TAB
        mov     R_SR,SR
        ior.b   R_A,R_A,R_B
        mov     SR,R_SR
        bclr    R_SR,#OV
        .endm

        .macro  OP_TAP
        mov     R_A,R_P                 ; Copy A into P
        ior     #0x00c0,R_P             ; And force 1 bits
        bclr    R_SR,#C                 ; Copy P into native flags
        bclr    R_SR,#Z
        bclr    R_SR,#N
        bclr    R_SR,#OV
        bclr    R_SR,#DC
        btsc    R_P,#F_C
        bset    R_SR,#C
        btsc    R_P,#F_Z
        bset    R_SR,#Z
        btsc    R_P,#F_N
        bset    R_SR,#N
        btsc    R_P,#F_V
        bset    R_SR,#OV
        btsc    R_P,#F_H
        bset    R_SR,#DC
        .endm

        .macro  OP_TBA
        mov     R_SR,SR
        ior.b   R_B,R_B,R_A
        mov     SR,R_SR
        bclr    R_SR,#OV
        .endm

        .macro  OP_TPA
        bclr    R_P,#F_C                ; Copy native flags into P
        bclr    R_P,#F_Z
        bclr    R_P,#F_N
        bclr    R_P,#F_V
        bclr    R_P,#F_H
        btsc    R_SR,#C
        bset    R_P,#F_C
        btsc    R_SR,#Z
        bset    R_P,#F_Z
        btsc    R_SR,#N
        bset    R_P,#F_N
        btsc    R_SR,#OV
        bset    R_P,#F_V
        btsc    R_SR,#DC
        bset    R_P,#F_H
        mov     R_P,R_A                 ; Then copy P into A
        .endm

        .macro  OP_TST,ACC
        mov     R_SR,SR
        ior.b   \ACC,\ACC,\ACC          ; Compare with zero
        mov     SR,R_SR
        bclr    R_SR,#C
        bclr    R_SR,#OV
        .endm

        .macro  OP_TSTM
        RD_ADDR w2,ze,w3                ; Read memory byte
        mov     R_SR,SR
        ior.b   w3,w3,w3                ; And compare with zero
        mov     SR,R_SR
        bclr    R_SR,#C
        bclr    R_SR,#OV
        .endm

        .macro  OP_TSX
        inc     R_SP,R_X
        .endm

        .macro  OP_TXS
        dec     R_X,R_SP
        .endm

        .macro  OP_WAI
        dec     R_PC,R_PC
        .endm

;-------------------------------------------------------------------------------

        .macro  OP_SYS,ACC
        RD_ADDR w2,ze,w3                ; Read command byte
        and     #0x07,w3                ; Limit to 16 values
        bra     w3

        bra     99f                     ; NOP
        bra     1f                      ; RXD
        bra     2f
        bra     3f
        bra     4f
        bra     99f
        bra     99f
        bra     99f

1:      call    UartRx                  ; Receive a byte
        ze      w0,\ACC
        bra     99f

2:      bra     99f

3:      ze      \ACC,w0                 ; Transmit a byte
        call    UartTx
        bra     99f

4:

99:
        .endm
