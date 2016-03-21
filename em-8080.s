;===============================================================================
;  _____ __  __        ___   ___   ___   ___
; | ____|  \/  |      ( _ ) / _ \ ( _ ) / _ \
; |  _| | |\/| |_____ / _ \| | | |/ _ \| | | |
; | |___| |  | |_____| (_) | |_| | (_) | |_| |
; |_____|_|  |_|      \___/ \___/ \___/ \___/
;
; An Intel 8080 Emulator
;-------------------------------------------------------------------------------
; Copyright (C)2015 HandCoded Software Ltd.
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
; Calculation of the parity bit in the status flags is delayed until it is
; actually accessed.
;
;===============================================================================
; Revision History:
;
; 2015-01-16 AJ Initial version
;-------------------------------------------------------------------------------
; $Id: em-8080.s 52 2015-10-09 22:46:45Z andrew $
;-------------------------------------------------------------------------------

        .include "hardware.inc"
        .include "em-retro.inc"
        .include "em-8080.inc"
        
;===============================================================================
; Emulator
;-------------------------------------------------------------------------------

        .section .8080,code
        
        .global EM_8080
        .extern CYCLE
        .extern INT_ENABLE
        .extern INT_FLAGS
        .extern PutStr
EM_8080:
        call    PutStr
        .asciz  "EM-8080 [15.10]\r\n"

        mov     #MEMORY_MAP,M_BASE      ; Initialise memory map
        mov     #0xf800,M_FLAG          ; .. and read-only flags
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

        mov     #edspage(BLANK),w1      ; EMPTY 0xb000-0bfff
        mov     #edsoffset(BLANK),w2
        mov     w1,[M_BASE+44]
        mov     w2,[M_BASE+46]
        mov     #edspage(BLANK),w1      ; EMPTY 0xc000-0cfff
        mov     #edsoffset(BLANK),w2
        mov     w1,[M_BASE+48]
        mov     w2,[M_BASE+50]
        mov     #edspage(BLANK),w1      ; EMPTY 0xd000-0dfff
        mov     #edsoffset(BLANK),w2
        mov     w1,[M_BASE+52]
        mov     w2,[M_BASE+54]
        mov     #edspage(BLANK),w1      ; EMPTY 0xe000-0efff
        mov     #edsoffset(BLANK),w2
        mov     w1,[M_BASE+56]
        mov     w2,[M_BASE+58]
        mov     #edspage(BLANK),w1      ; EMPTY 0xf000-0ffff
        mov     #edsoffset(BLANK),w2
        mov     w1,[M_BASE+60]
        mov     w2,[M_BASE+62]

Reset:
        ; Copy boot rom to 0000

        clr     R_PC
        

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

        bra     DO_NOP                  ; 00 - NOP
        bra     DO_LXI_B                ; 01 - LXI  B,i
        bra     DO_STAX_B               ; 02 - STAX B
        bra     DO_INX_B                ; 03 - INX  B
        bra     DO_INR_B                ; 04 - INR  B
        bra     DO_DCR_B                ; 05 - DCR  B
        bra     DO_MVI_B                ; 06 - MVI  B,i
        bra     DO_RLC                  ; 07 - RLC
        bra     DO_ERR                  ; 08 -
        bra     DO_DAD_B                ; 09 - DAD  B
        bra     DO_LDAX_B               ; 0a - LDAX B
        bra     DO_DCX_B                ; 0b - DCX  B
        bra     DO_INR_C                ; 0c - INR  C
        bra     DO_DCR_C                ; 0d - DCR  C
        bra     DO_MVI_C                ; 0e - MVI  C,i
        bra     DO_RRC                  ; 0f - RRC

        bra     DO_ERR                  ; 10 -
        bra     DO_LXI_D                ; 11 - LXI  D,i
        bra     DO_STAX_D               ; 12 - STAX D
        bra     DO_INX_D                ; 13 - INX  D
        bra     DO_INR_D                ; 14 - INR  D
        bra     DO_DCR_D                ; 15 - DCR  D
        bra     DO_MVI_D                ; 16 - MVI  D,i
        bra     DO_RAL                  ; 17 - RAL
        bra     DO_ERR                  ; 18 -
        bra     DO_DAD_B                ; 19 - DAD  D
        bra     DO_LDAX_B               ; 1a - LDAX D
        bra     DO_DCX_B                ; 1b - DCX  D
        bra     DO_INR_C                ; 1c - INR  E
        bra     DO_DCR_C                ; 1d - DCR  E
        bra     DO_MVI_C                ; 1e - MVI  E,i
        bra     DO_RAR                  ; 1f - RAR

        bra     DO_ERR                  ; 20 -
        bra     DO_LXI_H                ; 21 - LXI  H,i
        bra     DO_SHLD                 ; 22 - SHLD addr
        bra     DO_INX_H                ; 23 - INX  H
        bra     DO_INR_H                ; 24 - INR  H
        bra     DO_DCR_H                ; 25 - DCR  H
        bra     DO_MVI_H                ; 26 - MVI  H,i
        bra     DO_DAA                  ; 27 - DAA
        bra     DO_ERR                  ; 28 -
        bra     DO_DAD_H                ; 29 - DAD  H
        bra     DO_LHLD                 ; 2a - LHLD
        bra     DO_DCX_H                ; 2b - DCX  H
        bra     DO_INR_L                ; 2c - INR  L
        bra     DO_DCR_L                ; 2d - DCR  L
        bra     DO_MVI_L                ; 2e - MVI  L,i
        bra     DO_CMA                  ; 2f - CMA

        bra     DO_ERR                  ; 30 -
        bra     DO_LXI_SP               ; 31 - LXI  SP,i
        bra     DO_STA                  ; 32 - STA  addr
        bra     DO_INX_SP               ; 33 - INX  SP
        bra     DO_INR_M                ; 34 - INR  M
        bra     DO_DCR_M                ; 35 - DCR  M
        bra     DO_MVI_M                ; 36 - MVI  M,i
        bra     DO_STC                  ; 37 - STC
        bra     DO_ERR                  ; 38 -
        bra     DO_DAD_SP               ; 39 - DAD  SP
        bra     DO_LDA                  ; 3a - LDA  addr
        bra     DO_DCX_SP               ; 3b - DCX  SP
        bra     DO_INR_A                ; 3c - INR  A
        bra     DO_DCR_A                ; 3d - DCR  A
        bra     DO_MVI_A                ; 3e - MVI  A,i
        bra     DO_CMC                  ; 3f - CMC

        bra     DO_MOV_B_B              ; 40 - MOV  B,B
        bra     DO_MOV_B_C              ; 41 - MOV  B,C
        bra     DO_MOV_B_D              ; 42 - MOV  B,D
        bra     DO_MOV_B_E              ; 43 - MOV  B,E
        bra     DO_MOV_B_H              ; 44 - MOV  B,H
        bra     DO_MOV_B_L              ; 45 - MOV  B,L
        bra     DO_MOV_B_M              ; 46 - MOV  B,M
        bra     DO_MOV_B_A              ; 47 - MOV  B,A
        bra     DO_MOV_C_B              ; 48 - MOV  C,B
        bra     DO_MOV_C_C              ; 49 - MOV  C,C
        bra     DO_MOV_C_D              ; 4a - MOV  C,D
        bra     DO_MOV_C_E              ; 4b - MOV  C,E
        bra     DO_MOV_C_H              ; 4c - MOV  C,H
        bra     DO_MOV_C_L              ; 4d - MOV  C,L
        bra     DO_MOV_C_M              ; 4e - MOV  C,M
        bra     DO_MOV_C_A              ; 4f - MOV  C,A

        bra     DO_MOV_D_B              ; 50 - MOV  D,B
        bra     DO_MOV_D_C              ; 51 - MOV  D,C
        bra     DO_MOV_D_D              ; 52 - MOV  D,D
        bra     DO_MOV_D_E              ; 53 - MOV  D,E
        bra     DO_MOV_D_H              ; 54 - MOV  D,H
        bra     DO_MOV_D_L              ; 55 - MOV  D,L
        bra     DO_MOV_D_M              ; 56 - MOV  D,M
        bra     DO_MOV_D_A              ; 57 - MOV  D,A
        bra     DO_MOV_E_B              ; 58 - MOV  E,B
        bra     DO_MOV_E_C              ; 59 - MOV  E,C
        bra     DO_MOV_E_D              ; 5a - MOV  E,D
        bra     DO_MOV_E_E              ; 5b - MOV  E,E
        bra     DO_MOV_E_H              ; 5c - MOV  E,H
        bra     DO_MOV_E_L              ; 5d - MOV  E,L
        bra     DO_MOV_E_M              ; 5e - MOV  E,M
        bra     DO_MOV_E_A              ; 5f - MOV  E,A

        bra     DO_MOV_H_B              ; 60 - MOV  H,B
        bra     DO_MOV_H_C              ; 61 - MOV  H,C
        bra     DO_MOV_H_D              ; 62 - MOV  H,D
        bra     DO_MOV_H_E              ; 63 - MOV  H,E
        bra     DO_MOV_H_H              ; 64 - MOV  H,H
        bra     DO_MOV_H_L              ; 65 - MOV  H,L
        bra     DO_MOV_H_M              ; 66 - MOV  H,M
        bra     DO_MOV_H_A              ; 67 - MOV  H,A
        bra     DO_MOV_L_B              ; 68 - MOV  L,B
        bra     DO_MOV_L_C              ; 69 - MOV  L,C
        bra     DO_MOV_L_D              ; 6a - MOV  L,D
        bra     DO_MOV_L_E              ; 6b - MOV  L,E
        bra     DO_MOV_L_H              ; 6c - MOV  L,H
        bra     DO_MOV_L_L              ; 6d - MOV  L,L
        bra     DO_MOV_L_M              ; 6e - MOV  L,M
        bra     DO_MOV_L_A              ; 6f - MOV  L,A

        bra     DO_MOV_M_B              ; 70 - MOV  M,B
        bra     DO_MOV_M_C              ; 71 - MOV  M,C
        bra     DO_MOV_M_D              ; 72 - MOV  M,D
        bra     DO_MOV_M_E              ; 73 - MOV  M,E
        bra     DO_MOV_M_H              ; 74 - MOV  M,H
        bra     DO_MOV_M_L              ; 75 - MOV  M,L
        bra     DO_HLT                  ; 76 - HLT
        bra     DO_MOV_M_A              ; 77 - MOV  M,A
        bra     DO_MOV_A_B              ; 78 - MOV  A,B
        bra     DO_MOV_A_C              ; 79 - MOV  A,C
        bra     DO_MOV_A_D              ; 7a - MOV  A,D
        bra     DO_MOV_A_E              ; 7b - MOV  A,E
        bra     DO_MOV_A_H              ; 7c - MOV  A,H
        bra     DO_MOV_A_L              ; 7d - MOV  A,L
        bra     DO_MOV_A_M              ; 7e - MOV  A,M
        bra     DO_MOV_A_A              ; 7f - MOV  A,A

        bra     DO_ADD_B                ; 80 - ADD  B
        bra     DO_ADD_C                ; 81 - ADD  C
        bra     DO_ADD_D                ; 82 - ADD  D
        bra     DO_ADD_E                ; 83 - ADD  E
        bra     DO_ADD_H                ; 84 - ADD  H
        bra     DO_ADD_L                ; 85 - ADD  L
        bra     DO_ADD_M                ; 86 - ADD  M
        bra     DO_ADD_A                ; 87 - ADD  A
        bra     DO_ADC_B                ; 88 - ADC  B
        bra     DO_ADC_C                ; 89 - ADC  C
        bra     DO_ADC_D                ; 8a - ADC  D
        bra     DO_ADC_E                ; 8b - ADC  E
        bra     DO_ADC_H                ; 8c - ADC  H
        bra     DO_ADC_L                ; 8d - ADC  L
        bra     DO_ADC_M                ; 8e - ADC  M
        bra     DO_ADC_A                ; 8f - ADC  A

        bra     DO_SUB_B                ; 90 - SUB  B
        bra     DO_SUB_C                ; 91 - SUB  C
        bra     DO_SUB_D                ; 92 - SUB  D
        bra     DO_SUB_E                ; 93 - SUB  E
        bra     DO_SUB_H                ; 94 - SUB  H
        bra     DO_SUB_L                ; 95 - SUB  L
        bra     DO_SUB_M                ; 96 - SUB  M
        bra     DO_SUB_A                ; 97 - SUB  A
        bra     DO_SBB_B                ; 98 - SBB  B
        bra     DO_SBB_C                ; 99 - SBB  C
        bra     DO_SBB_D                ; 9a - SBB  D
        bra     DO_SBB_E                ; 9b - SBB  E
        bra     DO_SBB_H                ; 9c - SBB  H
        bra     DO_SBB_L                ; 9d - SBB  L
        bra     DO_SBB_M                ; 9e - SBB  M
        bra     DO_SBB_A                ; 9f - SBB  A

        bra     DO_ANA_B                ; a0 - ANA  B
        bra     DO_ANA_C                ; a1 - ANA  C
        bra     DO_ANA_D                ; a2 - ANA  D
        bra     DO_ANA_E                ; a3 - ANA  E
        bra     DO_ANA_H                ; a4 - ANA  H
        bra     DO_ANA_L                ; a5 - ANA  L
        bra     DO_ANA_M                ; a6 - ANA  M
        bra     DO_ANA_A                ; a7 - ANA  A
        bra     DO_XRA_B                ; a8 - XRA  B
        bra     DO_XRA_C                ; a9 - XRA  C
        bra     DO_XRA_D                ; aa - XRA  D
        bra     DO_XRA_E                ; ab - XRA  E
        bra     DO_XRA_H                ; ac - XRA  H
        bra     DO_XRA_L                ; ad - XRA  L
        bra     DO_XRA_M                ; ae - XRA  M
        bra     DO_XRA_A                ; af - XRA  A

        bra     DO_ORA_B                ; b0 - ORA  B
        bra     DO_ORA_C                ; b1 - ORA  C
        bra     DO_ORA_D                ; b2 - ORA  D
        bra     DO_ORA_E                ; b3 - ORA  E
        bra     DO_ORA_H                ; b4 - ORA  H
        bra     DO_ORA_L                ; b5 - ORA  L
        bra     DO_ORA_M                ; b6 - ORA  M
        bra     DO_ORA_A                ; b7 - ORA  A
        bra     DO_CMP_B                ; b8 - CMP  B
        bra     DO_CMP_C                ; b9 - CMP  C
        bra     DO_CMP_D                ; ba - CMP  D
        bra     DO_CMP_E                ; bb - CMP  E
        bra     DO_CMP_H                ; bc - CMP  H
        bra     DO_CMP_L                ; bd - CMP  L
        bra     DO_CMP_M                ; be - CMP  M
        bra     DO_CMP_A                ; bf - CMP  A

        bra     DO_RNZ                  ; c0 - RNZ
        bra     DO_POP_B                ; c1 - POP  B
        bra     DO_JNZ                  ; c2 - JNZ  addr
        bra     DO_JMP                  ; c3 - JMP  addr
        bra     DO_CNZ                  ; c4 - CNZ  addr
        bra     DO_PUSH_B               ; c5 - PUSH B
        bra     DO_ADI                  ; c6 - ADI  i
        bra     DO_RST_0                ; c7 - RST  0
        bra     DO_RZ                   ; c8 - RZ
        bra     DO_RET                  ; c9 - RET
        bra     DO_JZ                   ; ca - JZ   addr
        bra     DO_ERR                  ; cb -
        bra     DO_CZ                   ; cc - CZ   addr
        bra     DO_CALL                 ; cd - CALL addr
        bra     DO_ACI                  ; ce - ACI  i
        bra     DO_ERR                  ; cf - RST  1

        bra     DO_RNC                  ; d0 - RNC
        bra     DO_POP_D                ; d1 - POP  D
        bra     DO_JNC                  ; d2 - JNC  addr
        bra     DO_OUT                  ; d3 - OUT  i
        bra     DO_CNC                  ; d4 - CNC  addr
        bra     DO_PUSH_D               ; d5 - PUSH D
        bra     DO_SUI                  ; d6 - SUI  i
        bra     DO_RST_2                ; d7 - RST  2
        bra     DO_RC                   ; d8 - RC
        bra     DO_ERR                  ; d9 -
        bra     DO_JC                   ; da - JC   addr
        bra     DO_IN                   ; db - IN   i
        bra     DO_CC                   ; dc - CC   addr
        bra     DO_ERR                  ; dd -
        bra     DO_SBI                  ; de - SBI  i
        bra     DO_RST_3                ; df - RST  3

        bra     DO_RPO                  ; e0 - RPO
        bra     DO_POP_H                ; e1 - POP  H
        bra     DO_JPO                  ; e2 - JPO  addr
        bra     DO_XTHL                 ; e3 - XTHL
        bra     DO_CPO                  ; e4 - CPO  addr
        bra     DO_PUSH_H               ; e5 - PUSH H
        bra     DO_ANI                  ; e6 - ANI  i
        bra     DO_RST_4                ; e7 - RST  4
        bra     DO_RPE                  ; e8 - RPE
        bra     DO_PCHL                 ; e9 - PCHL
        bra     DO_JPE                  ; ea - JPE  addr
        bra     DO_XCHG                 ; eb - XCHG
        bra     DO_CPE                  ; ec - CPE  addr
        bra     DO_ERR                  ; ed -
        bra     DO_XRI                  ; ee - XRI  i
        bra     DO_RST_5                ; ef - RST  5

        bra     DO_RP                   ; f0 - RP
        bra     DO_POP_PSW              ; f1 - POP  PSW
        bra     DO_JP                   ; f2 - JP   addr
        bra     DO_DI                   ; f3 - DI
        bra     DO_CP                   ; f4 - CP   addr
        bra     DO_PUSH_PSW             ; f5 - PUSH PSW
        bra     DO_ORI                  ; f6 - ORI  i
        bra     DO_RST_6                ; f7 - RST  6
        bra     DO_RM                   ; f8 - RM
        bra     DO_SPHL                 ; f9 - SPHL
        bra     DO_JM                   ; fa - JM   addr
        bra     DO_EI                   ; fb - EI
        bra     DO_CM                   ; fc - CM   addr
        bra     DO_ERR                  ; fd -
        bra     DO_CPI                  ; fe - CPI  i
        bra     DO_RST_7                ; ff - RST  7

;-------------------------------------------------------------------------------

DO_ACI:
        OP_ACI
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_ADC_A:
        mov	#M_A,w2
        bra	DO_ADC_R

DO_ADC_B:
        mov	#M_B,w2
        bra	DO_ADC_R

DO_ADC_C:
        mov	#M_C,w2
        bra	DO_ADC_R

DO_ADC_D:
        mov	#M_D,w2
        bra	DO_ADC_R

DO_ADC_E:
        mov	#M_E,w2
        bra	DO_ADC_R

DO_ADC_H:
        mov	#M_H,w2
        bra	DO_ADC_R

DO_ADC_L:
	mov	#M_L,w2
	
DO_ADC_R:
        OP_ADC_R
        retlw   #4,w0
	
;-------------------------------------------------------------------------------

DO_ADC_M:
        OP_ADC_M
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_ADD_A:
        mov	#M_A,w2
        bra	DO_ADD_R

DO_ADD_B:
        mov	#M_B,w2
        bra	DO_ADD_R

DO_ADD_C:
        mov	#M_C,w2
        bra	DO_ADD_R

DO_ADD_D:
        mov	#M_D,w2
        bra	DO_ADD_R

DO_ADD_E:
        mov	#M_E,w2
        bra	DO_ADD_R

DO_ADD_H:
        mov	#M_H,w2
        bra	DO_ADD_R

DO_ADD_L:
        mov	#M_L,w2

DO_ADD_R:
	OP_ADD_R
        retlw   #4,w0

;-------------------------------------------------------------------------------
	
DO_ADD_M:
        OP_ADD_M
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_ADI:
        OP_ADI
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_ANA_A:
        mov	#M_A,w2
        bra	_ANA_R

DO_ANA_B:
        mov	#M_B,w2
        bra	_ANA_R

DO_ANA_C:
        mov	#M_C,w2
        bra	_ANA_R

DO_ANA_D:
        mov	#M_D,w2
        bra	_ANA_R

DO_ANA_E:
        mov	#M_E,w2
        bra	_ANA_R

DO_ANA_H:
        mov	#M_H,w2
        bra	_ANA_R

DO_ANA_L:
	mov	#M_L,w2
	
_ANA_R:
        OP_ANA_R
        retlw   #4,w0
	
;-------------------------------------------------------------------------------

DO_ANA_M:
        OP_ANA_M
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_ANI:
        OP_ANI
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_CALL:
        OP_CALL
        retlw   #17,w0

;-------------------------------------------------------------------------------

DO_CC:
        OP_CC
        retlw   #17,w0

;-------------------------------------------------------------------------------

DO_CM:
        OP_CM
        retlw   #17,w0

;-------------------------------------------------------------------------------

DO_CMA:
        OP_CMA
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_CMC:
        OP_CMC
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_CMP_A:
        OP_CMP_R M_A
        retlw   #4,w0

DO_CMP_B:
        OP_CMP_R M_B
        retlw   #4,w0

DO_CMP_C:
        OP_CMP_R M_C
        retlw   #4,w0

DO_CMP_D:
        OP_CMP_R M_D
        retlw   #4,w0

DO_CMP_E:
        OP_CMP_R M_E
        retlw   #4,w0

DO_CMP_H:
        OP_CMP_R M_H
        retlw   #4,w0

DO_CMP_L:
        OP_CMP_R M_L
        retlw   #4,w0

;-------------------------------------------------------------------------------
	
DO_CMP_M:
        OP_CMP_M
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_CNC:
        OP_CNC
        retlw   #17,w0

;-------------------------------------------------------------------------------

DO_CNZ:
        OP_CNZ
        retlw   #17,w0

;-------------------------------------------------------------------------------

DO_CP:
        OP_CP
        retlw   #17,w0

;-------------------------------------------------------------------------------

DO_CPE:
        OP_CPE
        retlw   #17,w0

;-------------------------------------------------------------------------------
	
DO_CPI:
	OP_CPI
	retlw	#7,w0
	
;-------------------------------------------------------------------------------

DO_CPO:
        OP_CPO
        retlw   #17,w0

;-------------------------------------------------------------------------------

DO_CZ:
        OP_CZ
        retlw   #17,w0
	
;-------------------------------------------------------------------------------
	
DO_DAA:
	OP_DAA
	retlw	#4,w0
	
;-------------------------------------------------------------------------------
	
DO_DAD_B:
	OP_DAD	R_BC
	retlw	#10,w0
	
DO_DAD_D:
	OP_DAD	R_DE
	retlw	#10,w0
	
DO_DAD_H:
	OP_DAD	R_HL
	retlw	#10,w0
	
DO_DAD_SP:
	OP_DAD	R_SP
	retlw	#10,w0

;-------------------------------------------------------------------------------
	
DO_DCR_A:
	OP_DCR_R M_A
	retlw	#5,w0
		
DO_DCR_B:
	OP_DCR_R M_B
	retlw	#5,w0
	
DO_DCR_C:
	OP_DCR_R M_C
	retlw	#5,w0
	
DO_DCR_D:
	OP_DCR_R M_D
	retlw	#5,w0
	
DO_DCR_E:
	OP_DCR_R M_E
	retlw	#5,w0
	
DO_DCR_H:
	OP_DCR_R M_H
	retlw	#5,w0
	
DO_DCR_L:
	OP_DCR_R M_L
	retlw	#5,w0

;-------------------------------------------------------------------------------
	
DO_DCR_M:
	OP_DCR_M
	retlw	#10,w0
	
;-------------------------------------------------------------------------------
	
DO_DCX_B:
	OP_DCX	R_BC
	retlw	#5,w0
	
DO_DCX_D:
	OP_DCX	R_DE
	retlw	#5,w0
	
DO_DCX_H:
	OP_DCX	R_DE
	retlw	#5,w0

DO_DCX_SP:
	OP_DCX	R_SP
	retlw	#5,w0

;-------------------------------------------------------------------------------

DO_DI:
	OP_DI
	retlw	#0,w0

;-------------------------------------------------------------------------------

DO_EI:
	OP_EI
	retlw	#0,w0

;-------------------------------------------------------------------------------
	
DO_HLT:
	OP_HLT
	retlw	#7,w0
	
;-------------------------------------------------------------------------------
	
DO_IN:
	OP_IN
	retlw	#0,w0
	
;-------------------------------------------------------------------------------
	
DO_INR_A:
	OP_INR_R M_A
	retlw	#5,w0
		
DO_INR_B:
	OP_INR_R M_B
	retlw	#5,w0
	
DO_INR_C:
	OP_INR_R M_C
	retlw	#5,w0
	
DO_INR_D:
	OP_INR_R M_D
	retlw	#5,w0
	
DO_INR_E:
	OP_INR_R M_E
	retlw	#5,w0
	
DO_INR_H:
	OP_INR_R M_H
	retlw	#5,w0
	
DO_INR_L:
	OP_INR_R M_L
	retlw	#5,w0

;-------------------------------------------------------------------------------
	
DO_INR_M:
	OP_INR_M
	retlw	#10,w0

;-------------------------------------------------------------------------------
	
DO_INX_B:
	OP_INX	R_BC
	retlw	#5,w0
	
DO_INX_D:
	OP_INX	R_DE
	retlw	#5,w0
	
DO_INX_H:
	OP_INX	R_DE
	retlw	#5,w0

DO_INX_SP:
	OP_INX	R_SP
	retlw	#5,w0
	
;-------------------------------------------------------------------------------

DO_JC:
	OP_JC
	retlw	#10,w0
        
;-------------------------------------------------------------------------------

DO_JM:
	OP_JM
	retlw	#10,w0

;-------------------------------------------------------------------------------

DO_JMP:
	OP_JMP
	retlw	#10,w0

;-------------------------------------------------------------------------------

DO_JNC:
	OP_JNC
	retlw	#10,w0

;-------------------------------------------------------------------------------

DO_JNZ:
	OP_JNZ
	retlw	#10,w0

;-------------------------------------------------------------------------------

DO_JP:
	OP_JP
	retlw	#10,w0

;-------------------------------------------------------------------------------

DO_JPE:
	OP_JPE
	retlw	#10,w0

;-------------------------------------------------------------------------------

DO_JPO:
	OP_JPO
	retlw	#10,w0

;-------------------------------------------------------------------------------

DO_JZ:
	OP_JZ
	retlw	#10,w0

;-------------------------------------------------------------------------------
	
DO_LDA:
	OP_LDA
	retlw	#13,w0
	
;-------------------------------------------------------------------------------

DO_LDAX_B:
	mov	R_BC,w2
	bra	_LDAX
	
DO_LDAX_D:
	mov	R_DE,w2
	
_LDAX:
	OP_LDAX
	retlw	#7,w0
        
;-------------------------------------------------------------------------------
        
DO_LHLD:
        OP_LHLD
        retlw   #16,w0
        
;-------------------------------------------------------------------------------
	
DO_LXI_B:
	mov	#M_BC,w2
	bra	_LXI
	
DO_LXI_D:
	mov	#M_DE,w2
	bra	_LXI
	
DO_LXI_H:
	mov	#M_HL,w2
	bra	_LXI
	
DO_LXI_SP:
	mov	#M_SP,w2
	
_LXI:
	OP_LXI
	retlw	#10,w0
	
;-------------------------------------------------------------------------------
	
DO_MOV_A_A:
	OP_MOV_R_R M_A,M_A
	retlw	#5,w0
	
DO_MOV_A_B:
	OP_MOV_R_R M_A,M_B
	retlw	#5,w0
	
DO_MOV_A_C:
	OP_MOV_R_R M_A,M_C
	retlw	#5,w0
	
DO_MOV_A_D:
	OP_MOV_R_R M_A,M_D
	retlw	#5,w0
	
DO_MOV_A_E:
	OP_MOV_R_R M_A,M_E
	retlw	#5,w0
	
DO_MOV_A_H:
	OP_MOV_R_R M_A,M_H
	retlw	#5,w0
	
DO_MOV_A_L:
	OP_MOV_R_R M_A,M_L
	retlw	#5,w0
	
DO_MOV_B_A:
	OP_MOV_R_R M_B,M_A
	retlw	#5,w0
	
DO_MOV_B_B:
	OP_MOV_R_R M_B,M_B
	retlw	#5,w0
	
DO_MOV_B_C:
	OP_MOV_R_R M_B,M_C
	retlw	#5,w0
	
DO_MOV_B_D:
	OP_MOV_R_R M_B,M_D
	retlw	#5,w0
	
DO_MOV_B_E:
	OP_MOV_R_R M_B,M_E
	retlw	#5,w0
	
DO_MOV_B_H:
	OP_MOV_R_R M_B,M_H
	retlw	#5,w0
	
DO_MOV_B_L:
	OP_MOV_R_R M_B,M_L
	retlw	#5,w0

DO_MOV_C_A:
	OP_MOV_R_R M_C,M_A
	retlw	#5,w0
	
DO_MOV_C_B:
	OP_MOV_R_R M_C,M_B
	retlw	#5,w0
	
DO_MOV_C_C:
	OP_MOV_R_R M_C,M_C
	retlw	#5,w0
	
DO_MOV_C_D:
	OP_MOV_R_R M_C,M_D
	retlw	#5,w0
	
DO_MOV_C_E:
	OP_MOV_R_R M_C,M_E
	retlw	#5,w0
	
DO_MOV_C_H:
	OP_MOV_R_R M_C,M_H
	retlw	#5,w0
	
DO_MOV_C_L:
	OP_MOV_R_R M_C,M_L
	retlw	#5,w0
	
DO_MOV_D_A:
	OP_MOV_R_R M_D,M_A
	retlw	#5,w0
	
DO_MOV_D_B:
	OP_MOV_R_R M_D,M_B
	retlw	#5,w0
	
DO_MOV_D_C:
	OP_MOV_R_R M_D,M_C
	retlw	#5,w0
	
DO_MOV_D_D:
	OP_MOV_R_R M_D,M_D
	retlw	#5,w0
	
DO_MOV_D_E:
	OP_MOV_R_R M_D,M_E
	retlw	#5,w0
	
DO_MOV_D_H:
	OP_MOV_R_R M_D,M_H
	retlw	#5,w0
	
DO_MOV_D_L:
	OP_MOV_R_R M_D,M_L
	retlw	#5,w0
	
DO_MOV_E_A:
	OP_MOV_R_R M_E,M_A
	retlw	#5,w0
	
DO_MOV_E_B:
	OP_MOV_R_R M_E,M_B
	retlw	#5,w0
	
DO_MOV_E_C:
	OP_MOV_R_R M_E,M_C
	retlw	#5,w0
	
DO_MOV_E_D:
	OP_MOV_R_R M_E,M_D
	retlw	#5,w0
	
DO_MOV_E_E:
	OP_MOV_R_R M_E,M_E
	retlw	#5,w0
	
DO_MOV_E_H:
	OP_MOV_R_R M_E,M_H
	retlw	#5,w0
	
DO_MOV_E_L:
	OP_MOV_R_R M_E,M_L
	retlw	#5,w0
	
DO_MOV_H_A:
	OP_MOV_R_R M_H,M_A
	retlw	#5,w0
	
DO_MOV_H_B:
	OP_MOV_R_R M_H,M_B
	retlw	#5,w0
	
DO_MOV_H_C:
	OP_MOV_R_R M_H,M_C
	retlw	#5,w0
	
DO_MOV_H_D:
	OP_MOV_R_R M_H,M_D
	retlw	#5,w0
	
DO_MOV_H_E:
	OP_MOV_R_R M_H,M_E
	retlw	#5,w0
	
DO_MOV_H_H:
	OP_MOV_R_R M_H,M_H
	retlw	#5,w0
	
DO_MOV_H_L:
	OP_MOV_R_R M_H,M_L
	retlw	#5,w0
	
DO_MOV_L_A:
	OP_MOV_R_R M_L,M_A
	retlw	#5,w0
	
DO_MOV_L_B:
	OP_MOV_R_R M_L,M_B
	retlw	#5,w0
	
DO_MOV_L_C:
	OP_MOV_R_R M_L,M_C
	retlw	#5,w0
	
DO_MOV_L_D:
	OP_MOV_R_R M_L,M_D
	retlw	#5,w0
	
DO_MOV_L_E:
	OP_MOV_R_R M_L,M_E
	retlw	#5,w0
	
DO_MOV_L_H:
	OP_MOV_R_R M_L,M_H
	retlw	#5,w0
	
DO_MOV_L_L:
	OP_MOV_R_R M_L,M_L
	retlw	#5,w0
	

;-------------------------------------------------------------------------------
	
DO_MOV_A_M:
        mov     #M_A,w2
        bra     _MOV_R_M
        
DO_MOV_B_M:
        mov     #M_B,w2
        bra     _MOV_R_M
        
DO_MOV_C_M:
        mov     #M_C,w2
        bra     _MOV_R_M
        
DO_MOV_D_M:
        mov     #M_D,w2
        bra     _MOV_R_M
        
DO_MOV_E_M:
        mov     #M_E,w2
        bra     _MOV_R_M
        
DO_MOV_H_M:
        mov     #M_H,w2
        bra     _MOV_R_M
        
DO_MOV_L_M:
        mov     #M_L,w2
        
_MOV_R_M:
        OP_MOV_R_M
        retlw	#7,w0

;-------------------------------------------------------------------------------
	
DO_MOV_M_A:
        mov     #M_A,w2
        bra     _MOV_M_R
        
DO_MOV_M_B:
        mov     #M_B,w2
        bra     _MOV_M_R
        
DO_MOV_M_C:
        mov     #M_C,w2
        bra     _MOV_M_R
        
DO_MOV_M_D:
        mov     #M_D,w2
        bra     _MOV_M_R
        
DO_MOV_M_E:
        mov     #M_E,w2
        bra     _MOV_M_R
        
DO_MOV_M_H:
        mov     #M_H,w2
        bra     _MOV_M_R
        
DO_MOV_M_L:
        mov     #M_L,w2

_MOV_M_R:
        OP_MOV_M_R
	retlw	#7,w0
	
;-------------------------------------------------------------------------------

DO_MVI_A:
DO_MVI_B:
DO_MVI_C:
DO_MVI_D:
DO_MVI_E:
DO_MVI_H:
DO_MVI_L:
	
DO_MVI_M:
	
;-------------------------------------------------------------------------------
	
DO_NOP:
	OP_NOP
	retlw	#4,w0
	
;-------------------------------------------------------------------------------

DO_ORA_A:
        mov	#M_A,w2
        bra	_ORA_R

DO_ORA_B:
        mov	#M_B,w2
        bra	_ORA_R

DO_ORA_C:
        mov	#M_C,w2
        bra	_ORA_R

DO_ORA_D:
        mov	#M_D,w2
        bra	_ORA_R

DO_ORA_E:
        mov	#M_E,w2
        bra	_ORA_R

DO_ORA_H:
        mov	#M_H,w2
        bra	_ORA_R

DO_ORA_L:
	mov	#M_L,w2
	
_ORA_R:
        OP_ORA_R
        retlw   #4,w0
	
;-------------------------------------------------------------------------------

DO_ORA_M:
        OP_ORA_M
        retlw   #7,w0

;-------------------------------------------------------------------------------
	
DO_ORI:
	OP_ORI
	retlw	#7,w0
	
;-------------------------------------------------------------------------------
	
DO_OUT:
	OP_OUT
	retlw	#0,w0
	
;-------------------------------------------------------------------------------
	
DO_PCHL:
	OP_PCHL
	retlw	#5,w0
	
;-------------------------------------------------------------------------------
        
DO_POP_B:
        mov     #M_BC,w2
        bra     _POP
        
DO_POP_D:
        mov     #M_DE,w2
        bra     _POP

DO_POP_H:
        mov     #M_HL,w2

_POP:
        OP_POP
        retlw   #11,w0
        
DO_POP_PSW:
        mov     #M_AF,w2
        OP_PUSH
        clr.b   R_SR
        btsc    R_AF,#F_S
        bset    R_SR,#N
        btsc    R_AF,#F_Z
        bset    R_SR,#Z
        btsc    R_AF,#F_AC
        bset    R_SR,#DC
        btsc    R_AF,#F_P
        bset    R_SR,#OV
        btsc    R_AF,#F_CY
        bset    R_SR,#C
        
        retlw   #0,w0

;-------------------------------------------------------------------------------
        
DO_PUSH_B:
        mov     R_BC,w2
        bra     _PUSH
        
DO_PUSH_D:
        mov     R_DE,w2
        bra     _PUSH
        
DO_PUSH_H:
        mov     R_HL,w2
        bra     _PUSH
        
DO_PUSH_PSW:
        mov     R_AF,w2
        clr.b   w2
        btsc    R_SR,#N
        bset    w2,#F_S
        btsc    R_SR,#Z
        bset    w2,#F_Z
        btsc    R_SR,#DC
        bset    w2,#F_AC
        btsc    R_SR,#OV
        bset    w2,#F_P
        btsc    R_SR,#C
        bset    w2,#F_CY

_PUSH:
        OP_PUSH
        retlw   #11,w0
        
;-------------------------------------------------------------------------------

DO_RAL:
	OP_RAL
	retlw	#4,w0
	
;-------------------------------------------------------------------------------
	
DO_RAR:
	OP_RAR
	retlw	#4,w0
	
;-------------------------------------------------------------------------------
	
DO_RC:
	OP_RC
	retlw	#4,w0
	
;-------------------------------------------------------------------------------
	
DO_RET:
	OP_RET
	retlw	#4,w0

;-------------------------------------------------------------------------------
	
DO_RLC:
	OP_RLC
	retlw	#4,w0
	
;-------------------------------------------------------------------------------
        
DO_RM:
        OP_RM
        retlw   #5,w0
        
;-------------------------------------------------------------------------------
	
DO_RNC:
	OP_RNC
	retlw	#4,w0

;-------------------------------------------------------------------------------
        
DO_RNZ:
        OP_RNZ
        retlw   #5,w0
        
;-------------------------------------------------------------------------------
        
DO_RP:
        OP_RP
        retlw   #5,w0
        
;-------------------------------------------------------------------------------
        
DO_RPE:
        OP_RPE
        retlw   #5,w0
        
;-------------------------------------------------------------------------------
        
DO_RPO:
        OP_RPO
        retlw   #5,w0
        
;-------------------------------------------------------------------------------
	
DO_RRC:
	OP_RRC
	retlw	#4,w0

;-------------------------------------------------------------------------------

DO_RST_0:
        mov     #0*8,w2
        bra     _RST
        
DO_RST_1:
        mov     #1*8,w2
        bra     _RST
        
DO_RST_2:
        mov     #2*8,w2
        bra     _RST
        
DO_RST_3:
        mov     #3*8,w2
        bra     _RST
        
DO_RST_4:
        mov     #4*8,w2
        bra     _RST
        
DO_RST_5:
        mov     #5*8,w2
        bra     _RST
        
DO_RST_6:
        mov     #6*8,w2
        bra     _RST
        
DO_RST_7:
        mov     #7*8,w2
      
_RST:
        OP_RST
        retlw   #11,w0
        
;-------------------------------------------------------------------------------
	
DO_RZ:
	OP_RZ
	retlw	#4,w0

;-------------------------------------------------------------------------------

DO_SBB_A:
        mov	#M_A,w2
        bra	DO_SBB_R

DO_SBB_B:
        mov	#M_B,w2
        bra	DO_SBB_R

DO_SBB_C:
        mov	#M_C,w2
        bra	DO_SBB_R

DO_SBB_D:
        mov	#M_D,w2
        bra	DO_SBB_R

DO_SBB_E:
        mov	#M_E,w2
        bra	DO_SBB_R

DO_SBB_H:
        mov	#M_H,w2
        bra	DO_SBB_R

DO_SBB_L:
	mov	#M_L,w2
	
DO_SBB_R:
        OP_SBB_R
        retlw   #4,w0
	
;-------------------------------------------------------------------------------

DO_SBB_M:
        OP_SBB_M
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_SBI:
        OP_SBI
        retlw   #0,w0

;-------------------------------------------------------------------------------
        
DO_SHLD:
        OP_SHLD
        retlw   #16,w0
        
;-------------------------------------------------------------------------------
	
DO_SPHL:
	OP_SPHL
	retlw	#0,w0
	
;-------------------------------------------------------------------------------
	
DO_STA:
	OP_STA
	retlw	#13,w0
	
;-------------------------------------------------------------------------------

DO_STAX_B:
	mov	R_BC,w2
	bra	_STAX
	
DO_STAX_D:
	mov	R_DE,w2
	
_STAX:
	OP_STAX
	retlw	#7,w0

;-------------------------------------------------------------------------------
	
DO_STC:
	OP_STC
	retlw	#4,w0
	
;-------------------------------------------------------------------------------

DO_SUB_A:
        mov	#M_A,w2
        bra	DO_SUB_R

DO_SUB_B:
        mov	#M_B,w2
        bra	DO_SUB_R

DO_SUB_C:
        mov	#M_C,w2
        bra	DO_SUB_R

DO_SUB_D:
        mov	#M_D,w2
        bra	DO_SUB_R

DO_SUB_E:
        mov	#M_E,w2
        bra	DO_SUB_R

DO_SUB_H:
        mov	#M_H,w2
        bra	DO_SUB_R

DO_SUB_L:
	mov	#M_L,w2
	
DO_SUB_R:
        OP_SUB_R
        retlw   #4,w0
	
;-------------------------------------------------------------------------------

DO_SUB_M:
        OP_SUB_M
        retlw   #7,w0

;-------------------------------------------------------------------------------

DO_SUI:
        OP_SUI
        retlw   #0,w0

;-------------------------------------------------------------------------------
	
DO_XCHG:
	OP_XCHG
	retlw	#0,w0
	
;-------------------------------------------------------------------------------

DO_XRA_A:
        mov	#M_A,w2
        bra	_XRA_R

DO_XRA_B:
        mov	#M_B,w2
        bra	_XRA_R

DO_XRA_C:
        mov	#M_C,w2
        bra	_XRA_R

DO_XRA_D:
        mov	#M_D,w2
        bra	_XRA_R

DO_XRA_E:
        mov	#M_E,w2
        bra	_XRA_R

DO_XRA_H:
        mov	#M_H,w2
        bra	_XRA_R

DO_XRA_L:
	mov	#M_L,w2
	
_XRA_R:
        OP_XRA_R
        retlw   #4,w0
	
;-------------------------------------------------------------------------------

DO_XRA_M:
        OP_XRA_M
        retlw   #7,w0

;-------------------------------------------------------------------------------
	
DO_XRI:
	OP_XRI
	retlw	#7,w0
	
;-------------------------------------------------------------------------------
	
DO_XTHL:
	OP_XTHL
	retlw	#0,w0
	
;-------------------------------------------------------------------------------

DO_ERR:
        retlw   #1,w0

        .end
