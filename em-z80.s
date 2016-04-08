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

        .include "hardware.inc"
        .include "em-retro.inc"
        .include "em-z80.inc"

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

        .section .nbss,bss,near
AF:
        .space  2
BC:
        .space  2
DE:
        .space  2
HL:
        .space  2
IX:
        .space  2
IY:
        .space  2
IR:
        .space  1
PARITY:
        .space  1                       ; The last result that affected parity

;===============================================================================
;-------------------------------------------------------------------------------

        .section .z80,code
        
        .global EM_Z80
        .extern CYCLE
        .extern INT_ENABLE
        .extern INT_FLAGS
        .extern PutStr
EM_Z80:
        call    PutStr
        .asciz  "EM-Z80 [15.10]\r\n"

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
        bra     DO_ERR                  ; 01 -
        bra     DO_ERR                  ; 02 -
        bra     DO_INC_BC               ; 03 - INC BC
        bra     DO_INC_B                ; 04 - INC B
        bra     DO_ERR                  ; 05 -
        bra     DO_ERR                  ; 06 -
        bra     DO_ERR                  ; 07 -
        bra     DO_ERR                  ; 08 -
        bra     DO_ADD_HL_BC            ; 09 - ADD HL,BC
        bra     DO_ERR                  ; 0a -
        bra     DO_ERR                  ; 0b -
        bra     DO_INC_C                ; 0c - INC C
        bra     DO_ERR                  ; 0d -
        bra     DO_ERR                  ; 0e -
        bra     DO_ERR                  ; 0f -

        bra     DO_DJNZ                 ; 10 - DJNZ rr
        bra     DO_ERR                  ; 11 -
        bra     DO_ERR                  ; 12 -
        bra     DO_INC_DE               ; 13 - INC DE
        bra     DO_INC_D                ; 14 - INC D
        bra     DO_ERR                  ; 15 -
        bra     DO_ERR                  ; 16 -
        bra     DO_ERR                  ; 17 -
        bra     DO_ERR                  ; 18 -
        bra     DO_ADD_HL_DE            ; 19 - ADD HL,DE
        bra     DO_ERR                  ; 1a -
        bra     DO_ERR                  ; 1b -
        bra     DO_INC_E                ; 1c - INC E
        bra     DO_ERR                  ; 1d -
        bra     DO_ERR                  ; 1e -
        bra     DO_ERR                  ; 1f -

        bra     DO_ERR                  ; 20 -
        bra     DO_ERR                  ; 21 -
        bra     DO_ERR                  ; 22 -
        bra     DO_INC_HL               ; 23 - INC HL
        bra     DO_INC_H                ; 24 - INC H
        bra     DO_ERR                  ; 25 -
        bra     DO_ERR                  ; 26 -
        bra     DO_ERR                  ; 27 -
        bra     DO_ERR                  ; 28 -
        bra     DO_ADD_HL_HL            ; 29 - ADD_HL,HL
        bra     DO_ERR                  ; 2a -
        bra     DO_ERR                  ; 2b -
        bra     DO_INC_L                ; 2c - INC L
        bra     DO_ERR                  ; 2d -
        bra     DO_ERR                  ; 2e -
        bra     DO_ERR                  ; 2f -

        bra     DO_ERR                  ; 30 -
        bra     DO_ERR                  ; 31 -
        bra     DO_ERR                  ; 32 -
        bra     DO_INC_SP               ; 33 - INC SP
        bra     DO_INC_I                ; 34 - INC (HL)
        bra     DO_ERR                  ; 35 -
        bra     DO_ERR                  ; 36 -
        bra     DO_ERR                  ; 37 -
        bra     DO_ERR                  ; 38 -
        bra     DO_ADD_HL_SP            ; 39 - ADD HL,SP
        bra     DO_ERR                  ; 3a -
        bra     DO_ERR                  ; 3b -
        bra     DO_INC_A                ; 3c - INC A
        bra     DO_ERR                  ; 3d -
        bra     DO_ERR                  ; 3e -
        bra     DO_ERR                  ; 3f -

        bra     DO_ERR                  ; 40 -
        bra     DO_ERR                  ; 41 -
        bra     DO_ERR                  ; 42 -
        bra     DO_ERR                  ; 43 -
        bra     DO_ERR                  ; 44 -
        bra     DO_ERR                  ; 45 -
        bra     DO_ERR                  ; 46 -
        bra     DO_ERR                  ; 47 -
        bra     DO_ERR                  ; 48 -
        bra     DO_ERR                  ; 49 -
        bra     DO_ERR                  ; 4a -
        bra     DO_ERR                  ; 4b -
        bra     DO_ERR                  ; 4c -
        bra     DO_ERR                  ; 4d -
        bra     DO_ERR                  ; 4e -
        bra     DO_ERR                  ; 4f -

        bra     DO_ERR                  ; 50 -
        bra     DO_ERR                  ; 51 -
        bra     DO_ERR                  ; 52 -
        bra     DO_ERR                  ; 53 -
        bra     DO_ERR                  ; 54 -
        bra     DO_ERR                  ; 55 -
        bra     DO_ERR                  ; 56 -
        bra     DO_ERR                  ; 57 -
        bra     DO_ERR                  ; 58 -
        bra     DO_ERR                  ; 59 -
        bra     DO_ERR                  ; 5a -
        bra     DO_ERR                  ; 5b -
        bra     DO_ERR                  ; 5c -
        bra     DO_ERR                  ; 5d -
        bra     DO_ERR                  ; 5e -
        bra     DO_ERR                  ; 5f -

        bra     DO_ERR                  ; 60 -
        bra     DO_ERR                  ; 61 -
        bra     DO_ERR                  ; 62 -
        bra     DO_ERR                  ; 63 -
        bra     DO_ERR                  ; 64 -
        bra     DO_ERR                  ; 65 -
        bra     DO_ERR                  ; 66 -
        bra     DO_ERR                  ; 67 -
        bra     DO_ERR                  ; 68 -
        bra     DO_ERR                  ; 69 -
        bra     DO_ERR                  ; 6a -
        bra     DO_ERR                  ; 6b -
        bra     DO_ERR                  ; 6c -
        bra     DO_ERR                  ; 6d -
        bra     DO_ERR                  ; 6e -
        bra     DO_ERR                  ; 6f -

        bra     DO_ERR                  ; 70 -
        bra     DO_ERR                  ; 71 -
        bra     DO_ERR                  ; 72 -
        bra     DO_ERR                  ; 73 -
        bra     DO_ERR                  ; 74 -
        bra     DO_ERR                  ; 75 -
        bra     DO_ERR                  ; 76 -
        bra     DO_ERR                  ; 77 -
        bra     DO_ERR                  ; 78 -
        bra     DO_ERR                  ; 79 -
        bra     DO_ERR                  ; 7a -
        bra     DO_ERR                  ; 7b -
        bra     DO_ERR                  ; 7c -
        bra     DO_ERR                  ; 7d -
        bra     DO_ERR                  ; 7e -
        bra     DO_ERR                  ; 7f -

        bra     DO_ADD_A_B              ; 80 - ADD A,B
        bra     DO_ADD_A_C              ; 81 - ADD A,C
        bra     DO_ADD_A_D              ; 82 - ADD A,D
        bra     DO_ADD_A_E              ; 83 - ADD A,E
        bra     DO_ADD_A_H              ; 84 - ADD A,H
        bra     DO_ADD_A_L              ; 85 - ADD A,L
        bra     DO_ADD_A_I              ; 86 - ADD A,(HL)
        bra     DO_ADD_A_A              ; 87 - ADD A,A
        bra     DO_ADC_A_B              ; 88 - ADC A,B
        bra     DO_ADC_A_C              ; 89 - ADC A,C
        bra     DO_ADC_A_D              ; 8a - ADC A,D
        bra     DO_ADC_A_E              ; 8b - ADC A,E
        bra     DO_ADC_A_H              ; 8c - ADC A,H
        bra     DO_ADC_A_L              ; 8d - ADC A,L
        bra     DO_ADC_A_I              ; 8e - ADC A,(HL)
        bra     DO_ADC_A_A              ; 8f - ADC A,A

        bra     DO_ERR                  ; 90 -
        bra     DO_ERR                  ; 91 -
        bra     DO_ERR                  ; 92 -
        bra     DO_ERR                  ; 93 -
        bra     DO_ERR                  ; 94 -
        bra     DO_ERR                  ; 95 -
        bra     DO_ERR                  ; 96 -
        bra     DO_ERR                  ; 97 -
        bra     DO_ERR                  ; 98 -
        bra     DO_ERR                  ; 99 -
        bra     DO_ERR                  ; 9a -
        bra     DO_ERR                  ; 9b -
        bra     DO_ERR                  ; 9c -
        bra     DO_ERR                  ; 9d -
        bra     DO_ERR                  ; 9e -
        bra     DO_ERR                  ; 9f -

        bra     DO_ERR                  ; a0 -
        bra     DO_ERR                  ; a1 -
        bra     DO_ERR                  ; a2 -
        bra     DO_ERR                  ; a3 -
        bra     DO_ERR                  ; a4 -
        bra     DO_ERR                  ; a5 -
        bra     DO_ERR                  ; a6 -
        bra     DO_ERR                  ; a7 -
        bra     DO_ERR                  ; a8 -
        bra     DO_ERR                  ; a9 -
        bra     DO_ERR                  ; aa -
        bra     DO_ERR                  ; ab -
        bra     DO_ERR                  ; ac -
        bra     DO_ERR                  ; ad -
        bra     DO_ERR                  ; ae -
        bra     DO_ERR                  ; af -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; c0 -
        bra     DO_ERR                  ; c1 -
        bra     DO_JP_NZ                ; c2 - JP NZ,aaaa
        bra     DO_JP                   ; c3 - JP aaaa
        bra     DO_CALL_NZ              ; c4 - CALL NZ,aaaa
        bra     DO_ERR                  ; c5 -
        bra     DO_ADD_A_N              ; c6 - ADD A,N
        bra     DO_RST_00               ; c7 - RST 00H
        bra     DO_ERR                  ; c8 -
        bra     DO_ERR                  ; c9 -
        bra     DO_JP_Z                 ; ca - JP Z,aaaa
        bra     PrefixCB                ; cb - Prefix
        bra     DO_CALL_Z               ; cc - CALL Z,aaaa
        bra     DO_CALL                 ; cd - CALL aaaa
        bra     DO_ADC_A_N              ; ce - ADC A,N
        bra     DO_RST_08               ; cf - RST 08H

        bra     DO_ERR                  ; d0 -
        bra     DO_ERR                  ; d1 -
        bra     DO_JP_NC                ; d2 - JP NC,aaaa
        bra     DO_ERR                  ; d3 -
        bra     DO_CALL_NC              ; d4 - CALL NC,aaaa
        bra     DO_ERR                  ; d5 -
        bra     DO_ERR                  ; d6 -
        bra     DO_RST_10               ; d7 - RST 10H
        bra     DO_ERR                  ; d8 -
        bra     DO_ERR                  ; d9 -
        bra     DO_JP_C                 ; da - JP C,aaaa
        bra     DO_ERR                  ; db -
        bra     DO_CALL_C               ; dc - CALL C,aaaa
        bra     PrefixDD                ; dd - Prefix
        bra     DO_ERR                  ; de -
        bra     DO_RST_18               ; df - RST 18H

        bra     DO_ERR                  ; e0 -
        bra     DO_ERR                  ; e1 -
        bra     DO_JP_PO                ; e2 - JP PO,aaaa
        bra     DO_ERR                  ; e3 -
        bra     DO_CALL_PO              ; e4 - CALL PO,aaaa
        bra     DO_ERR                  ; e5 -
        bra     DO_ERR                  ; e6 -
        bra     DO_RST_20               ; e7 - RST 20H
        bra     DO_ERR                  ; e8 -
        bra     DO_ERR                  ; e9 -
        bra     DO_JP_PE                ; ea - JP PE,aaaa
        bra     DO_ERR                  ; eb -
        bra     DO_CALL_PE              ; ec - CALL PE,aaaa
        bra     PrefixED                ; ed - Prefix
        bra     DO_ERR                  ; ee -
        bra     DO_RST_28               ; ef - RST 28H

        bra     DO_ERR                  ; f0 -
        bra     DO_ERR                  ; f1 -
        bra     DO_JP_P                 ; f2 - JP P,aaaa
        bra     DO_ERR                  ; f3 -
        bra     DO_CALL_P               ; f4 - CALL P,aaaa
        bra     DO_ERR                  ; f5 -
        bra     DO_ERR                  ; f6 -
        bra     DO_RST_30               ; f7 - RST 30H
        bra     DO_ERR                  ; f8 -
        bra     DO_ERR                  ; f9 -
        bra     DO_JP_M                 ; fa - JP M,aaaa
        bra     DO_ERR                  ; fb -
        bra     DO_CALL_M               ; fc - CALL M,aaaa
        bra     PrefixFD                ; fd - Prefix
        bra     DO_ERR                  ; fe -
        bra     DO_RST_38               ; ff - RST 38H

;-------------------------------------------------------------------------------

PrefixCB:
        RD_ADDR R_PC,ze,w3              ; Fetch the next opcode
        inc     R_PC,R_PC               ; .. incrementing the PC
        bra     w3                      ; And execute it

        bra     DO_ERR                  ; cb 00 -
        bra     DO_ERR                  ; cb 01 -
        bra     DO_ERR                  ; cb 02 -
        bra     DO_ERR                  ; cb 03 -
        bra     DO_ERR                  ; cb 04 -
        bra     DO_ERR                  ; cb 05 -
        bra     DO_ERR                  ; cb 06 -
        bra     DO_ERR                  ; cb 07 -
        bra     DO_ERR                  ; cb 08 -
        bra     DO_ERR                  ; cb 09 -
        bra     DO_ERR                  ; cb 0a -
        bra     DO_ERR                  ; cb 0b -
        bra     DO_ERR                  ; cb 0c -
        bra     DO_ERR                  ; cb 0d -
        bra     DO_ERR                  ; cb 0e -
        bra     DO_ERR                  ; cb 0f -

        bra     DO_ERR                  ; 10 -
        bra     DO_ERR                  ; 11 -
        bra     DO_ERR                  ; 12 -
        bra     DO_ERR                  ; 13 -
        bra     DO_ERR                  ; 14 -
        bra     DO_ERR                  ; 15 -
        bra     DO_ERR                  ; 16 -
        bra     DO_ERR                  ; 17 -
        bra     DO_ERR                  ; 18 -
        bra     DO_ERR                  ; 19 -
        bra     DO_ERR                  ; 1a -
        bra     DO_ERR                  ; 1b -
        bra     DO_ERR                  ; 1c -
        bra     DO_ERR                  ; 1d -
        bra     DO_ERR                  ; 1e -
        bra     DO_ERR                  ; 1f -

        bra     DO_ERR                  ; 20 -
        bra     DO_ERR                  ; 21 -
        bra     DO_ERR                  ; 22 -
        bra     DO_ERR                  ; 23 -
        bra     DO_ERR                  ; 24 -
        bra     DO_ERR                  ; 25 -
        bra     DO_ERR                  ; 26 -
        bra     DO_ERR                  ; 27 -
        bra     DO_ERR                  ; 28 -
        bra     DO_ERR                  ; 29 -
        bra     DO_ERR                  ; 2a -
        bra     DO_ERR                  ; 2b -
        bra     DO_ERR                  ; 2c -
        bra     DO_ERR                  ; 2d -
        bra     DO_ERR                  ; 2e -
        bra     DO_ERR                  ; 2f -

        bra     DO_ERR                  ; 30 -
        bra     DO_ERR                  ; 31 -
        bra     DO_ERR                  ; 32 -
        bra     DO_ERR                  ; 33 -
        bra     DO_ERR                  ; 34 -
        bra     DO_ERR                  ; 35 -
        bra     DO_ERR                  ; 36 -
        bra     DO_ERR                  ; 37 -
        bra     DO_ERR                  ; 38 -
        bra     DO_ERR                  ; 39 -
        bra     DO_ERR                  ; 3a -
        bra     DO_ERR                  ; 3b -
        bra     DO_ERR                  ; 3c -
        bra     DO_ERR                  ; 3d -
        bra     DO_ERR                  ; 3e -
        bra     DO_ERR                  ; 3f -

        bra     DO_ERR                  ; 40 -
        bra     DO_ERR                  ; 41 -
        bra     DO_ERR                  ; 42 -
        bra     DO_ERR                  ; 43 -
        bra     DO_ERR                  ; 44 -
        bra     DO_ERR                  ; 45 -
        bra     DO_ERR                  ; 46 -
        bra     DO_ERR                  ; 47 -
        bra     DO_ERR                  ; 48 -
        bra     DO_ERR                  ; 49 -
        bra     DO_ERR                  ; 4a -
        bra     DO_ERR                  ; 4b -
        bra     DO_ERR                  ; 4c -
        bra     DO_ERR                  ; 4d -
        bra     DO_ERR                  ; 4e -
        bra     DO_ERR                  ; 4f -

        bra     DO_ERR                  ; 50 -
        bra     DO_ERR                  ; 51 -
        bra     DO_ERR                  ; 52 -
        bra     DO_ERR                  ; 53 -
        bra     DO_ERR                  ; 54 -
        bra     DO_ERR                  ; 55 -
        bra     DO_ERR                  ; 56 -
        bra     DO_ERR                  ; 57 -
        bra     DO_ERR                  ; 58 -
        bra     DO_ERR                  ; 59 -
        bra     DO_ERR                  ; 5a -
        bra     DO_ERR                  ; 5b -
        bra     DO_ERR                  ; 5c -
        bra     DO_ERR                  ; 5d -
        bra     DO_ERR                  ; 5e -
        bra     DO_ERR                  ; 5f -

        bra     DO_ERR                  ; 60 -
        bra     DO_ERR                  ; 61 -
        bra     DO_ERR                  ; 62 -
        bra     DO_ERR                  ; 63 -
        bra     DO_ERR                  ; 64 -
        bra     DO_ERR                  ; 65 -
        bra     DO_ERR                  ; 66 -
        bra     DO_ERR                  ; 67 -
        bra     DO_ERR                  ; 68 -
        bra     DO_ERR                  ; 69 -
        bra     DO_ERR                  ; 6a -
        bra     DO_ERR                  ; 6b -
        bra     DO_ERR                  ; 6c -
        bra     DO_ERR                  ; 6d -
        bra     DO_ERR                  ; 6e -
        bra     DO_ERR                  ; 6f -

        bra     DO_ERR                  ; 70 -
        bra     DO_ERR                  ; 71 -
        bra     DO_ERR                  ; 72 -
        bra     DO_ERR                  ; 73 -
        bra     DO_ERR                  ; 74 -
        bra     DO_ERR                  ; 75 -
        bra     DO_ERR                  ; 76 -
        bra     DO_ERR                  ; 77 -
        bra     DO_ERR                  ; 78 -
        bra     DO_ERR                  ; 79 -
        bra     DO_ERR                  ; 7a -
        bra     DO_ERR                  ; 7b -
        bra     DO_ERR                  ; 7c -
        bra     DO_ERR                  ; 7d -
        bra     DO_ERR                  ; 7e -
        bra     DO_ERR                  ; 7f -

        bra     DO_ERR                  ; 80 -
        bra     DO_ERR                  ; 81 -
        bra     DO_ERR                  ; 82 -
        bra     DO_ERR                  ; 83 -
        bra     DO_ERR                  ; 84 -
        bra     DO_ERR                  ; 85 -
        bra     DO_ERR                  ; 86 -
        bra     DO_ERR                  ; 87 -
        bra     DO_ERR                  ; 88 -
        bra     DO_ERR                  ; 89 -
        bra     DO_ERR                  ; 8a -
        bra     DO_ERR                  ; 8b -
        bra     DO_ERR                  ; 8c -
        bra     DO_ERR                  ; 8d -
        bra     DO_ERR                  ; 8e -
        bra     DO_ERR                  ; 8f -

        bra     DO_ERR                  ; 90 -
        bra     DO_ERR                  ; 91 -
        bra     DO_ERR                  ; 92 -
        bra     DO_ERR                  ; 93 -
        bra     DO_ERR                  ; 94 -
        bra     DO_ERR                  ; 95 -
        bra     DO_ERR                  ; 96 -
        bra     DO_ERR                  ; 97 -
        bra     DO_ERR                  ; 98 -
        bra     DO_ERR                  ; 99 -
        bra     DO_ERR                  ; 9a -
        bra     DO_ERR                  ; 9b -
        bra     DO_ERR                  ; 9c -
        bra     DO_ERR                  ; 9d -
        bra     DO_ERR                  ; 9e -
        bra     DO_ERR                  ; 9f -

        bra     DO_ERR                  ; a0 -
        bra     DO_ERR                  ; a1 -
        bra     DO_ERR                  ; a2 -
        bra     DO_ERR                  ; a3 -
        bra     DO_ERR                  ; a4 -
        bra     DO_ERR                  ; a5 -
        bra     DO_ERR                  ; a6 -
        bra     DO_ERR                  ; a7 -
        bra     DO_ERR                  ; a8 -
        bra     DO_ERR                  ; a9 -
        bra     DO_ERR                  ; aa -
        bra     DO_ERR                  ; ab -
        bra     DO_ERR                  ; ac -
        bra     DO_ERR                  ; ad -
        bra     DO_ERR                  ; ae -
        bra     DO_ERR                  ; af -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; c0 -
        bra     DO_ERR                  ; c1 -
        bra     DO_ERR                  ; c2 -
        bra     DO_ERR                  ; c3 -
        bra     DO_ERR                  ; c4 -
        bra     DO_ERR                  ; c5 -
        bra     DO_ERR                  ; c6 -
        bra     DO_ERR                  ; c7 -
        bra     DO_ERR                  ; c8 -
        bra     DO_ERR                  ; c9 -
        bra     DO_ERR                  ; ca -
        bra     DO_ERR                  ; cb -
        bra     DO_ERR                  ; cc -
        bra     DO_ERR                  ; cd -
        bra     DO_ERR                  ; ce -
        bra     DO_ERR                  ; cf -

        bra     DO_ERR                  ; d0 -
        bra     DO_ERR                  ; d1 -
        bra     DO_ERR                  ; d2 -
        bra     DO_ERR                  ; d3 -
        bra     DO_ERR                  ; d4 -
        bra     DO_ERR                  ; d5 -
        bra     DO_ERR                  ; d6 -
        bra     DO_ERR                  ; d7 -
        bra     DO_ERR                  ; d8 -
        bra     DO_ERR                  ; d9 -
        bra     DO_ERR                  ; da -
        bra     DO_ERR                  ; db -
        bra     DO_ERR                  ; dc -
        bra     DO_ERR                  ; dd -
        bra     DO_ERR                  ; de -
        bra     DO_ERR                  ; df -

        bra     DO_ERR                  ; e0 -
        bra     DO_ERR                  ; e1 -
        bra     DO_ERR                  ; e2 -
        bra     DO_ERR                  ; e3 -
        bra     DO_ERR                  ; e4 -
        bra     DO_ERR                  ; e5 -
        bra     DO_ERR                  ; e6 -
        bra     DO_ERR                  ; e7 -
        bra     DO_ERR                  ; e8 -
        bra     DO_ERR                  ; e9 -
        bra     DO_ERR                  ; ea -
        bra     DO_ERR                  ; eb -
        bra     DO_ERR                  ; ec -
        bra     DO_ERR                  ; ed -
        bra     DO_ERR                  ; ee -
        bra     DO_ERR                  ; ef -

        bra     DO_ERR                  ; f0 -
        bra     DO_ERR                  ; f1 -
        bra     DO_ERR                  ; f2 -
        bra     DO_ERR                  ; f3 -
        bra     DO_ERR                  ; f4 -
        bra     DO_ERR                  ; f5 -
        bra     DO_ERR                  ; f6 -
        bra     DO_ERR                  ; f7 -
        bra     DO_ERR                  ; f8 -
        bra     DO_ERR                  ; f9 -
        bra     DO_ERR                  ; fa -
        bra     DO_ERR                  ; fb -
        bra     DO_ERR                  ; fc -
        bra     DO_ERR                  ; fd -
        bra     DO_ERR                  ; fe -
        bra     DO_ERR                  ; ff -

;-------------------------------------------------------------------------------

PrefixDD:
        RD_ADDR R_PC,ze,w3              ; Fetch the next opcode
        inc     R_PC,R_PC               ; .. incrementing the PC
        bra     w3                      ; And execute it

        bra     DO_ERR                  ; dd 00 -
        bra     DO_ERR                  ; dd 01 -
        bra     DO_ERR                  ; dd 02 -
        bra     DO_ERR                  ; dd 03 -
        bra     DO_ERR                  ; dd 04 -
        bra     DO_ERR                  ; dd 05 -
        bra     DO_ERR                  ; dd 06 -
        bra     DO_ERR                  ; dd 07 -
        bra     DO_ERR                  ; dd 08 -
        bra     DO_ERR                  ; dd 09 -
        bra     DO_ERR                  ; dd 0a -
        bra     DO_ERR                  ; dd 0b -
        bra     DO_ERR                  ; dd 0c -
        bra     DO_ERR                  ; dd 0d -
        bra     DO_ERR                  ; dd 0e -
        bra     DO_ERR                  ; dd 0f -

        bra     DO_ERR                  ; 10 -
        bra     DO_ERR                  ; 11 -
        bra     DO_ERR                  ; 12 -
        bra     DO_ERR                  ; 13 -
        bra     DO_ERR                  ; 14 -
        bra     DO_ERR                  ; 15 -
        bra     DO_ERR                  ; 16 -
        bra     DO_ERR                  ; 17 -
        bra     DO_ERR                  ; 18 -
        bra     DO_ERR                  ; 19 -
        bra     DO_ERR                  ; 1a -
        bra     DO_ERR                  ; 1b -
        bra     DO_ERR                  ; 1c -
        bra     DO_ERR                  ; 1d -
        bra     DO_ERR                  ; 1e -
        bra     DO_ERR                  ; 1f -

        bra     DO_ERR                  ; 20 -
        bra     DO_ERR                  ; 21 -
        bra     DO_ERR                  ; 22 -
        bra     DO_INC_IX               ; dd 23 - INC IX
        bra     DO_ERR                  ; 24 -
        bra     DO_ERR                  ; 25 -
        bra     DO_ERR                  ; 26 -
        bra     DO_ERR                  ; 27 -
        bra     DO_ERR                  ; 28 -
        bra     DO_ERR                  ; 29 -
        bra     DO_ERR                  ; 2a -
        bra     DO_ERR                  ; 2b -
        bra     DO_ERR                  ; 2c -
        bra     DO_ERR                  ; 2d -
        bra     DO_ERR                  ; 2e -
        bra     DO_ERR                  ; 2f -

        bra     DO_ERR                  ; 30 -
        bra     DO_ERR                  ; 31 -
        bra     DO_ERR                  ; 32 -
        bra     DO_ERR                  ; 33 -
        bra     DO_ERR                  ; 34 -
        bra     DO_ERR                  ; 35 -
        bra     DO_ERR                  ; 36 -
        bra     DO_ERR                  ; 37 -
        bra     DO_ERR                  ; 38 -
        bra     DO_ERR                  ; 39 -
        bra     DO_ERR                  ; 3a -
        bra     DO_ERR                  ; 3b -
        bra     DO_ERR                  ; 3c -
        bra     DO_ERR                  ; 3d -
        bra     DO_ERR                  ; 3e -
        bra     DO_ERR                  ; 3f -

        bra     DO_ERR                  ; 40 -
        bra     DO_ERR                  ; 41 -
        bra     DO_ERR                  ; 42 -
        bra     DO_ERR                  ; 43 -
        bra     DO_ERR                  ; 44 -
        bra     DO_ERR                  ; 45 -
        bra     DO_ERR                  ; 46 -
        bra     DO_ERR                  ; 47 -
        bra     DO_ERR                  ; 48 -
        bra     DO_ERR                  ; 49 -
        bra     DO_ERR                  ; 4a -
        bra     DO_ERR                  ; 4b -
        bra     DO_ERR                  ; 4c -
        bra     DO_ERR                  ; 4d -
        bra     DO_ERR                  ; 4e -
        bra     DO_ERR                  ; 4f -

        bra     DO_ERR                  ; 50 -
        bra     DO_ERR                  ; 51 -
        bra     DO_ERR                  ; 52 -
        bra     DO_ERR                  ; 53 -
        bra     DO_ERR                  ; 54 -
        bra     DO_ERR                  ; 55 -
        bra     DO_ERR                  ; 56 -
        bra     DO_ERR                  ; 57 -
        bra     DO_ERR                  ; 58 -
        bra     DO_ERR                  ; 59 -
        bra     DO_ERR                  ; 5a -
        bra     DO_ERR                  ; 5b -
        bra     DO_ERR                  ; 5c -
        bra     DO_ERR                  ; 5d -
        bra     DO_ERR                  ; 5e -
        bra     DO_ERR                  ; 5f -

        bra     DO_ERR                  ; 60 -
        bra     DO_ERR                  ; 61 -
        bra     DO_ERR                  ; 62 -
        bra     DO_ERR                  ; 63 -
        bra     DO_ERR                  ; 64 -
        bra     DO_ERR                  ; 65 -
        bra     DO_ERR                  ; 66 -
        bra     DO_ERR                  ; 67 -
        bra     DO_ERR                  ; 68 -
        bra     DO_ERR                  ; 69 -
        bra     DO_ERR                  ; 6a -
        bra     DO_ERR                  ; 6b -
        bra     DO_ERR                  ; 6c -
        bra     DO_ERR                  ; 6d -
        bra     DO_ERR                  ; 6e -
        bra     DO_ERR                  ; 6f -

        bra     DO_ERR                  ; 70 -
        bra     DO_ERR                  ; 71 -
        bra     DO_ERR                  ; 72 -
        bra     DO_ERR                  ; 73 -
        bra     DO_ERR                  ; 74 -
        bra     DO_ERR                  ; 75 -
        bra     DO_ERR                  ; 76 -
        bra     DO_ERR                  ; 77 -
        bra     DO_ERR                  ; 78 -
        bra     DO_ERR                  ; 79 -
        bra     DO_ERR                  ; 7a -
        bra     DO_ERR                  ; 7b -
        bra     DO_ERR                  ; 7c -
        bra     DO_ERR                  ; 7d -
        bra     DO_ERR                  ; 7e -
        bra     DO_ERR                  ; 7f -

        bra     DO_ERR                  ; dd 80 -
        bra     DO_ERR                  ; dd 81 -
        bra     DO_ERR                  ; dd 82 -
        bra     DO_ERR                  ; dd 83 -
        bra     DO_ERR                  ; dd 84 -
        bra     DO_ERR                  ; dd 85 -
        bra     DO_ADD_A_IX_N           ; dd 86 - ADD A,(IX+N)
        bra     DO_ERR                  ; dd 87 -
        bra     DO_ERR                  ; dd 88 -
        bra     DO_ERR                  ; dd 89 -
        bra     DO_ERR                  ; dd 8a -
        bra     DO_ERR                  ; dd 8b -
        bra     DO_ERR                  ; dd 8c -
        bra     DO_ERR                  ; dd 8d -
        bra     DO_ADC_A_IX_N           ; dd 8e - ADC A,(IX+N)
        bra     DO_ERR                  ; dd 8f -

        bra     DO_ERR                  ; 90 -
        bra     DO_ERR                  ; 91 -
        bra     DO_ERR                  ; 92 -
        bra     DO_ERR                  ; 93 -
        bra     DO_ERR                  ; 94 -
        bra     DO_ERR                  ; 95 -
        bra     DO_ERR                  ; 96 -
        bra     DO_ERR                  ; 97 -
        bra     DO_ERR                  ; 98 -
        bra     DO_ERR                  ; 99 -
        bra     DO_ERR                  ; 9a -
        bra     DO_ERR                  ; 9b -
        bra     DO_ERR                  ; 9c -
        bra     DO_ERR                  ; 9d -
        bra     DO_ERR                  ; 9e -
        bra     DO_ERR                  ; 9f -

        bra     DO_ERR                  ; a0 -
        bra     DO_ERR                  ; a1 -
        bra     DO_ERR                  ; a2 -
        bra     DO_ERR                  ; a3 -
        bra     DO_ERR                  ; a4 -
        bra     DO_ERR                  ; a5 -
        bra     DO_ERR                  ; a6 -
        bra     DO_ERR                  ; a7 -
        bra     DO_ERR                  ; a8 -
        bra     DO_ERR                  ; a9 -
        bra     DO_ERR                  ; aa -
        bra     DO_ERR                  ; ab -
        bra     DO_ERR                  ; ac -
        bra     DO_ERR                  ; ad -
        bra     DO_ERR                  ; ae -
        bra     DO_ERR                  ; af -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; c0 -
        bra     DO_ERR                  ; c1 -
        bra     DO_ERR                  ; c2 -
        bra     DO_ERR                  ; c3 -
        bra     DO_ERR                  ; c4 -
        bra     DO_ERR                  ; c5 -
        bra     DO_ERR                  ; c6 -
        bra     DO_ERR                  ; c7 -
        bra     DO_ERR                  ; c8 -
        bra     DO_ERR                  ; c9 -
        bra     DO_ERR                  ; ca -
        bra     PrefixDDCB              ; cb -
        bra     DO_ERR                  ; cc -
        bra     DO_ERR                  ; cd -
        bra     DO_ERR                  ; ce -
        bra     DO_ERR                  ; cf -

        bra     DO_ERR                  ; d0 -
        bra     DO_ERR                  ; d1 -
        bra     DO_ERR                  ; d2 -
        bra     DO_ERR                  ; d3 -
        bra     DO_ERR                  ; d4 -
        bra     DO_ERR                  ; d5 -
        bra     DO_ERR                  ; d6 -
        bra     DO_ERR                  ; d7 -
        bra     DO_ERR                  ; d8 -
        bra     DO_ERR                  ; d9 -
        bra     DO_ERR                  ; da -
        bra     DO_ERR                  ; db -
        bra     DO_ERR                  ; dc -
        bra     DO_ERR                  ; dd -
        bra     DO_ERR                  ; de -
        bra     DO_ERR                  ; df -

        bra     DO_ERR                  ; e0 -
        bra     DO_ERR                  ; e1 -
        bra     DO_ERR                  ; e2 -
        bra     DO_ERR                  ; e3 -
        bra     DO_ERR                  ; e4 -
        bra     DO_ERR                  ; e5 -
        bra     DO_ERR                  ; e6 -
        bra     DO_ERR                  ; e7 -
        bra     DO_ERR                  ; e8 -
        bra     DO_ERR                  ; e9 -
        bra     DO_ERR                  ; ea -
        bra     DO_ERR                  ; eb -
        bra     DO_ERR                  ; ec -
        bra     DO_ERR                  ; ed -
        bra     DO_ERR                  ; ee -
        bra     DO_ERR                  ; ef -

        bra     DO_ERR                  ; f0 -
        bra     DO_ERR                  ; f1 -
        bra     DO_ERR                  ; f2 -
        bra     DO_ERR                  ; f3 -
        bra     DO_ERR                  ; f4 -
        bra     DO_ERR                  ; f5 -
        bra     DO_ERR                  ; f6 -
        bra     DO_ERR                  ; f7 -
        bra     DO_ERR                  ; f8 -
        bra     DO_ERR                  ; f9 -
        bra     DO_ERR                  ; fa -
        bra     DO_ERR                  ; fb -
        bra     DO_ERR                  ; fc -
        bra     DO_ERR                  ; fd -
        bra     DO_ERR                  ; fe -
        bra     DO_ERR                  ; ff -

;-------------------------------------------------------------------------------

PrefixDDCB:
        RD_ADDR R_PC,ze,w3              ; Fetch the next opcode
        inc     R_PC,R_PC               ; .. incrementing the PC
        bra     w3                      ; And execute it

        bra     DO_ERR                  ; dd cb 00 -
        bra     DO_ERR                  ; 01 -
        bra     DO_ERR                  ; 02 -
        bra     DO_ERR                  ; 03 -
        bra     DO_ERR                  ; 04 -
        bra     DO_ERR                  ; 05 -
        bra     DO_ERR                  ; 06 -
        bra     DO_ERR                  ; 07 -
        bra     DO_ERR                  ; 08 -
        bra     DO_ERR                  ; 09 -
        bra     DO_ERR                  ; 0a -
        bra     DO_ERR                  ; 0b -
        bra     DO_ERR                  ; 0c -
        bra     DO_ERR                  ; 0d -
        bra     DO_ERR                  ; 0e -
        bra     DO_ERR                  ; 0f -

        bra     DO_ERR                  ; 10 -
        bra     DO_ERR                  ; 11 -
        bra     DO_ERR                  ; 12 -
        bra     DO_ERR                  ; 13 -
        bra     DO_ERR                  ; 14 -
        bra     DO_ERR                  ; 15 -
        bra     DO_ERR                  ; 16 -
        bra     DO_ERR                  ; 17 -
        bra     DO_ERR                  ; 18 -
        bra     DO_ERR                  ; 19 -
        bra     DO_ERR                  ; 1a -
        bra     DO_ERR                  ; 1b -
        bra     DO_ERR                  ; 1c -
        bra     DO_ERR                  ; 1d -
        bra     DO_ERR                  ; 1e -
        bra     DO_ERR                  ; 1f -

        bra     DO_ERR                  ; 20 -
        bra     DO_ERR                  ; 21 -
        bra     DO_ERR                  ; 22 -
        bra     DO_ERR                  ; 23 -
        bra     DO_ERR                  ; 24 -
        bra     DO_ERR                  ; 25 -
        bra     DO_ERR                  ; 26 -
        bra     DO_ERR                  ; 27 -
        bra     DO_ERR                  ; 28 -
        bra     DO_ERR                  ; 29 -
        bra     DO_ERR                  ; 2a -
        bra     DO_ERR                  ; 2b -
        bra     DO_ERR                  ; 2c -
        bra     DO_ERR                  ; 2d -
        bra     DO_ERR                  ; 2e -
        bra     DO_ERR                  ; 2f -

        bra     DO_ERR                  ; 30 -
        bra     DO_ERR                  ; 31 -
        bra     DO_ERR                  ; 32 -
        bra     DO_ERR                  ; 33 -
        bra     DO_ERR                  ; 34 -
        bra     DO_ERR                  ; 35 -
        bra     DO_ERR                  ; 36 -
        bra     DO_ERR                  ; 37 -
        bra     DO_ERR                  ; 38 -
        bra     DO_ERR                  ; 39 -
        bra     DO_ERR                  ; 3a -
        bra     DO_ERR                  ; 3b -
        bra     DO_ERR                  ; 3c -
        bra     DO_ERR                  ; 3d -
        bra     DO_ERR                  ; 3e -
        bra     DO_ERR                  ; 3f -

        bra     DO_ERR                  ; 40 -
        bra     DO_ERR                  ; 41 -
        bra     DO_ERR                  ; 42 -
        bra     DO_ERR                  ; 43 -
        bra     DO_ERR                  ; 44 -
        bra     DO_ERR                  ; 45 -
        bra     DO_ERR                  ; 46 -
        bra     DO_ERR                  ; 47 -
        bra     DO_ERR                  ; 48 -
        bra     DO_ERR                  ; 49 -
        bra     DO_ERR                  ; 4a -
        bra     DO_ERR                  ; 4b -
        bra     DO_ERR                  ; 4c -
        bra     DO_ERR                  ; 4d -
        bra     DO_ERR                  ; 4e -
        bra     DO_ERR                  ; 4f -

        bra     DO_ERR                  ; 50 -
        bra     DO_ERR                  ; 51 -
        bra     DO_ERR                  ; 52 -
        bra     DO_ERR                  ; 53 -
        bra     DO_ERR                  ; 54 -
        bra     DO_ERR                  ; 55 -
        bra     DO_ERR                  ; 56 -
        bra     DO_ERR                  ; 57 -
        bra     DO_ERR                  ; 58 -
        bra     DO_ERR                  ; 59 -
        bra     DO_ERR                  ; 5a -
        bra     DO_ERR                  ; 5b -
        bra     DO_ERR                  ; 5c -
        bra     DO_ERR                  ; 5d -
        bra     DO_ERR                  ; 5e -
        bra     DO_ERR                  ; 5f -

        bra     DO_ERR                  ; 60 -
        bra     DO_ERR                  ; 61 -
        bra     DO_ERR                  ; 62 -
        bra     DO_ERR                  ; 63 -
        bra     DO_ERR                  ; 64 -
        bra     DO_ERR                  ; 65 -
        bra     DO_ERR                  ; 66 -
        bra     DO_ERR                  ; 67 -
        bra     DO_ERR                  ; 68 -
        bra     DO_ERR                  ; 69 -
        bra     DO_ERR                  ; 6a -
        bra     DO_ERR                  ; 6b -
        bra     DO_ERR                  ; 6c -
        bra     DO_ERR                  ; 6d -
        bra     DO_ERR                  ; 6e -
        bra     DO_ERR                  ; 6f -

        bra     DO_ERR                  ; 70 -
        bra     DO_ERR                  ; 71 -
        bra     DO_ERR                  ; 72 -
        bra     DO_ERR                  ; 73 -
        bra     DO_ERR                  ; 74 -
        bra     DO_ERR                  ; 75 -
        bra     DO_ERR                  ; 76 -
        bra     DO_ERR                  ; 77 -
        bra     DO_ERR                  ; 78 -
        bra     DO_ERR                  ; 79 -
        bra     DO_ERR                  ; 7a -
        bra     DO_ERR                  ; 7b -
        bra     DO_ERR                  ; 7c -
        bra     DO_ERR                  ; 7d -
        bra     DO_ERR                  ; 7e -
        bra     DO_ERR                  ; 7f -

        bra     DO_ERR                  ; 80 -
        bra     DO_ERR                  ; 81 -
        bra     DO_ERR                  ; 82 -
        bra     DO_ERR                  ; 83 -
        bra     DO_ERR                  ; 84 -
        bra     DO_ERR                  ; 85 -
        bra     DO_ERR                  ; 86 -
        bra     DO_ERR                  ; 87 -
        bra     DO_ERR                  ; 88 -
        bra     DO_ERR                  ; 89 -
        bra     DO_ERR                  ; 8a -
        bra     DO_ERR                  ; 8b -
        bra     DO_ERR                  ; 8c -
        bra     DO_ERR                  ; 8d -
        bra     DO_ERR                  ; 8e -
        bra     DO_ERR                  ; 8f -

        bra     DO_ERR                  ; 90 -
        bra     DO_ERR                  ; 91 -
        bra     DO_ERR                  ; 92 -
        bra     DO_ERR                  ; 93 -
        bra     DO_ERR                  ; 94 -
        bra     DO_ERR                  ; 95 -
        bra     DO_ERR                  ; 96 -
        bra     DO_ERR                  ; 97 -
        bra     DO_ERR                  ; 98 -
        bra     DO_ERR                  ; 99 -
        bra     DO_ERR                  ; 9a -
        bra     DO_ERR                  ; 9b -
        bra     DO_ERR                  ; 9c -
        bra     DO_ERR                  ; 9d -
        bra     DO_ERR                  ; 9e -
        bra     DO_ERR                  ; 9f -

        bra     DO_ERR                  ; a0 -
        bra     DO_ERR                  ; a1 -
        bra     DO_ERR                  ; a2 -
        bra     DO_ERR                  ; a3 -
        bra     DO_ERR                  ; a4 -
        bra     DO_ERR                  ; a5 -
        bra     DO_ERR                  ; a6 -
        bra     DO_ERR                  ; a7 -
        bra     DO_ERR                  ; a8 -
        bra     DO_ERR                  ; a9 -
        bra     DO_ERR                  ; aa -
        bra     DO_ERR                  ; ab -
        bra     DO_ERR                  ; ac -
        bra     DO_ERR                  ; ad -
        bra     DO_ERR                  ; ae -
        bra     DO_ERR                  ; af -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; c0 -
        bra     DO_ERR                  ; c1 -
        bra     DO_ERR                  ; c2 -
        bra     DO_ERR                  ; c3 -
        bra     DO_ERR                  ; c4 -
        bra     DO_ERR                  ; c5 -
        bra     DO_ERR                  ; c6 -
        bra     DO_ERR                  ; c7 - 
        bra     DO_ERR                  ; c8 -
        bra     DO_ERR                  ; c9 -
        bra     DO_ERR                  ; ca -
        bra     DO_ERR                  ; cb -
        bra     DO_ERR                  ; cc -
        bra     DO_ERR                  ; cd -
        bra     DO_ERR                  ; ce -
        bra     DO_ERR                  ; cf - 

        bra     DO_ERR                  ; d0 -
        bra     DO_ERR                  ; d1 -
        bra     DO_ERR                  ; d2 -
        bra     DO_ERR                  ; d3 -
        bra     DO_ERR                  ; d4 -
        bra     DO_ERR                  ; d5 -
        bra     DO_ERR                  ; d6 -
        bra     DO_ERR                  ; d7 -
        bra     DO_ERR                  ; d8 -
        bra     DO_ERR                  ; d9 -
        bra     DO_ERR                  ; da -
        bra     DO_ERR                  ; db -
        bra     DO_ERR                  ; dc -
        bra     DO_ERR                  ; dd -
        bra     DO_ERR                  ; de -
        bra     DO_ERR                  ; df -

        bra     DO_ERR                  ; e0 -
        bra     DO_ERR                  ; e1 -
        bra     DO_ERR                  ; e2 -
        bra     DO_ERR                  ; e3 -
        bra     DO_ERR                  ; e4 -
        bra     DO_ERR                  ; e5 -
        bra     DO_ERR                  ; e6 -
        bra     DO_ERR                  ; e7 -
        bra     DO_ERR                  ; e8 -
        bra     DO_ERR                  ; e9 -
        bra     DO_ERR                  ; ea -
        bra     DO_ERR                  ; eb -
        bra     DO_ERR                  ; ec -
        bra     DO_ERR                  ; ed -
        bra     DO_ERR                  ; ee -
        bra     DO_ERR                  ; ef -

        bra     DO_ERR                  ; f0 -
        bra     DO_ERR                  ; f1 -
        bra     DO_ERR                  ; f2 -
        bra     DO_ERR                  ; f3 -
        bra     DO_ERR                  ; f4 -
        bra     DO_ERR                  ; f5 -
        bra     DO_ERR                  ; f6 -
        bra     DO_ERR                  ; f7 -
        bra     DO_ERR                  ; f8 -
        bra     DO_ERR                  ; f9 -
        bra     DO_ERR                  ; fa -
        bra     DO_ERR                  ; fb -
        bra     DO_ERR                  ; fc -
        bra     DO_ERR                  ; fd -
        bra     DO_ERR                  ; fe -
        bra     DO_ERR                  ; ff -

;-------------------------------------------------------------------------------

PrefixED:
        RD_ADDR R_PC,ze,w3              ; Fetch the next opcode
        inc     R_PC,R_PC               ; .. incrementing the PC
        bra     w3                      ; And execute it

        bra     DO_ERR                  ; ed 00 -
        bra     DO_ERR                  ; 01 -
        bra     DO_ERR                  ; 02 -
        bra     DO_ERR                  ; 03 -
        bra     DO_ERR                  ; 04 -
        bra     DO_ERR                  ; 05 -
        bra     DO_ERR                  ; 06 -
        bra     DO_ERR                  ; 07 -
        bra     DO_ERR                  ; 08 -
        bra     DO_ERR                  ; 09 -
        bra     DO_ERR                  ; 0a -
        bra     DO_ERR                  ; 0b -
        bra     DO_ERR                  ; 0c -
        bra     DO_ERR                  ; 0d -
        bra     DO_ERR                  ; 0e -
        bra     DO_ERR                  ; 0f -

        bra     DO_ERR                  ; 10 -
        bra     DO_ERR                  ; 11 -
        bra     DO_ERR                  ; 12 -
        bra     DO_ERR                  ; 13 -
        bra     DO_ERR                  ; 14 -
        bra     DO_ERR                  ; 15 -
        bra     DO_ERR                  ; 16 -
        bra     DO_ERR                  ; 17 -
        bra     DO_ERR                  ; 18 -
        bra     DO_ERR                  ; 19 -
        bra     DO_ERR                  ; 1a -
        bra     DO_ERR                  ; 1b -
        bra     DO_ERR                  ; 1c -
        bra     DO_ERR                  ; 1d -
        bra     DO_ERR                  ; 1e -
        bra     DO_ERR                  ; 1f -

        bra     DO_ERR                  ; 20 -
        bra     DO_ERR                  ; 21 -
        bra     DO_ERR                  ; 22 -
        bra     DO_ERR                  ; 23 -
        bra     DO_ERR                  ; 24 -
        bra     DO_ERR                  ; 25 -
        bra     DO_ERR                  ; 26 -
        bra     DO_ERR                  ; 27 -
        bra     DO_ERR                  ; 28 -
        bra     DO_ERR                  ; 29 -
        bra     DO_ERR                  ; 2a -
        bra     DO_ERR                  ; 2b -
        bra     DO_ERR                  ; 2c -
        bra     DO_ERR                  ; 2d -
        bra     DO_ERR                  ; 2e -
        bra     DO_ERR                  ; 2f -

        bra     DO_ERR                  ; 30 -
        bra     DO_ERR                  ; 31 -
        bra     DO_ERR                  ; 32 -
        bra     DO_ERR                  ; 33 -
        bra     DO_ERR                  ; 34 -
        bra     DO_ERR                  ; 35 -
        bra     DO_ERR                  ; 36 -
        bra     DO_ERR                  ; 37 -
        bra     DO_ERR                  ; 38 -
        bra     DO_ERR                  ; 39 -
        bra     DO_ERR                  ; 3a -
        bra     DO_ERR                  ; 3b -
        bra     DO_ERR                  ; 3c -
        bra     DO_ERR                  ; 3d -
        bra     DO_ERR                  ; 3e -
        bra     DO_ERR                  ; 3f -

        bra     DO_ERR                  ; ed 40 -
        bra     DO_ERR                  ; ed 41 -
        bra     DO_ERR                  ; ed 42 -
        bra     DO_ERR                  ; ed 43 -
        bra     DO_ERR                  ; ed 44 -
        bra     DO_ERR                  ; ed 45 -
        bra     DO_ERR                  ; ed 46 -
        bra     DO_ERR                  ; ed 47 -
        bra     DO_ERR                  ; ed 48 -
        bra     DO_ERR                  ; ed 49 -
        bra     DO_ADC_HL_BC            ; ed 4a - ADC HL,BC
        bra     DO_ERR                  ; ed 4b -
        bra     DO_ERR                  ; ed 4c -
        bra     DO_ERR                  ; ed 4d -
        bra     DO_ERR                  ; ed 4e -
        bra     DO_ERR                  ; ed 4f -

        bra     DO_ERR                  ; ed 50 -
        bra     DO_ERR                  ; ed 51 -
        bra     DO_ERR                  ; ed 52 -
        bra     DO_ERR                  ; ed 53 -
        bra     DO_ERR                  ; ed 54 -
        bra     DO_ERR                  ; ed 55 -
        bra     DO_ERR                  ; ed 56 -
        bra     DO_ERR                  ; ed 57 -
        bra     DO_ERR                  ; ed 58 -
        bra     DO_ERR                  ; ed 59 -
        bra     DO_ADC_HL_DE            ; ed 5a - ADC HL,DE
        bra     DO_ERR                  ; ed 5b -
        bra     DO_ERR                  ; ed 5c -
        bra     DO_ERR                  ; ed 5d -
        bra     DO_ERR                  ; ed 5e -
        bra     DO_ERR                  ; ed 5f -

        bra     DO_ERR                  ; ed 60 -
        bra     DO_ERR                  ; ed 61 -
        bra     DO_ERR                  ; ed 62 -
        bra     DO_ERR                  ; ed 63 -
        bra     DO_ERR                  ; ed 64 -
        bra     DO_ERR                  ; ed 65 -
        bra     DO_ERR                  ; ed 66 -
        bra     DO_ERR                  ; ed 67 -
        bra     DO_ERR                  ; ed 68 -
        bra     DO_ERR                  ; ed 69 -
        bra     DO_ADC_HL_HL            ; ed 6a - ADC HL,HL
        bra     DO_ERR                  ; ed 6b -
        bra     DO_ERR                  ; ed 6c -
        bra     DO_ERR                  ; ed 6d -
        bra     DO_ERR                  ; ed 6e -
        bra     DO_ERR                  ; ed 6f -

        bra     DO_ERR                  ; ed 70 -
        bra     DO_ERR                  ; ed 71 -
        bra     DO_ERR                  ; ed 72 -
        bra     DO_ERR                  ; ed 73 -
        bra     DO_ERR                  ; ed 74 -
        bra     DO_ERR                  ; ed 75 -
        bra     DO_ERR                  ; ed 76 -
        bra     DO_ERR                  ; ed 77 -
        bra     DO_ERR                  ; ed 78 -
        bra     DO_ERR                  ; ed 79 -
        bra     DO_ADC_HL_SP            ; ed 7a - ADC HL,SP
        bra     DO_ERR                  ; ed 7b -
        bra     DO_ERR                  ; ed 7c -
        bra     DO_ERR                  ; ed 7d -
        bra     DO_ERR                  ; ed 7e -
        bra     DO_ERR                  ; ed 7f -

        bra     DO_ERR                  ; ed 80 -
        bra     DO_ERR                  ; ed 81 -
        bra     DO_ERR                  ; ed 82 -
        bra     DO_ERR                  ; ed 83 -
        bra     DO_ERR                  ; ed 84 -
        bra     DO_ERR                  ; ed 85 -
        bra     DO_ERR                  ; ed 86 -
        bra     DO_ERR                  ; ed 87 -
        bra     DO_ERR                  ; ed 88 -
        bra     DO_ERR                  ; ed 89 -
        bra     DO_ERR                  ; ed 8a -
        bra     DO_ERR                  ; ed 8b -
        bra     DO_ERR                  ; ed 8c -
        bra     DO_ERR                  ; ed 8d -
        bra     DO_ERR                  ; ed 8e -
        bra     DO_ERR                  ; ed 8f -

        bra     DO_ERR                  ; ed 90 -
        bra     DO_ERR                  ; ed 91 -
        bra     DO_ERR                  ; ed 92 -
        bra     DO_ERR                  ; ed 93 -
        bra     DO_ERR                  ; ed 94 -
        bra     DO_ERR                  ; ed 95 -
        bra     DO_ERR                  ; ed 96 -
        bra     DO_ERR                  ; ed 97 -
        bra     DO_ERR                  ; ed 98 -
        bra     DO_ERR                  ; ed 99 -
        bra     DO_ERR                  ; ed 9a -
        bra     DO_ERR                  ; ed 9b -
        bra     DO_ERR                  ; ed 9c -
        bra     DO_ERR                  ; ed 9d -
        bra     DO_ERR                  ; ed 9e -
        bra     DO_ERR                  ; ed 9f -

        bra     DO_ERR                  ; ed a0 -
        bra     DO_ERR                  ; ed a1 -
        bra     DO_ERR                  ; ed a2 -
        bra     DO_ERR                  ; ed a3 -
        bra     DO_ERR                  ; ed a4 -
        bra     DO_ERR                  ; ed a5 -
        bra     DO_ERR                  ; ed a6 -
        bra     DO_ERR                  ; ed a7 -
        bra     DO_ERR                  ; ed a8 -
        bra     DO_ERR                  ; ed a9 -
        bra     DO_ERR                  ; ed aa -
        bra     DO_ERR                  ; ed ab -
        bra     DO_ERR                  ; ed ac -
        bra     DO_ERR                  ; ed ad -
        bra     DO_ERR                  ; ed ae -
        bra     DO_ERR                  ; ed af -

        bra     DO_ERR                  ; ed b0 -
        bra     DO_ERR                  ; ed b1 -
        bra     DO_ERR                  ; ed b2 -
        bra     DO_ERR                  ; ed b3 -
        bra     DO_ERR                  ; ed b4 -
        bra     DO_ERR                  ; ed b5 -
        bra     DO_ERR                  ; ed b6 -
        bra     DO_ERR                  ; ed b7 -
        bra     DO_ERR                  ; ed b8 -
        bra     DO_ERR                  ; ed b9 -
        bra     DO_ERR                  ; ed ba -
        bra     DO_ERR                  ; ed bb -
        bra     DO_ERR                  ; ed bc -
        bra     DO_ERR                  ; ed bd -
        bra     DO_ERR                  ; ed be -
        bra     DO_ERR                  ; ed bf -

        bra     DO_ERR                  ; ed b0 -
        bra     DO_ERR                  ; ed b1 -
        bra     DO_ERR                  ; ed b2 -
        bra     DO_ERR                  ; ed b3 -
        bra     DO_ERR                  ; ed b4 -
        bra     DO_ERR                  ; ed b5 -
        bra     DO_ERR                  ; ed b6 -
        bra     DO_ERR                  ; ed b7 -
        bra     DO_ERR                  ; ed b8 -
        bra     DO_ERR                  ; ed b9 -
        bra     DO_ERR                  ; ed ba -
        bra     DO_ERR                  ; ed bb -
        bra     DO_ERR                  ; ed bc -
        bra     DO_ERR                  ; ed bd -
        bra     DO_ERR                  ; ed be -
        bra     DO_ERR                  ; ed bf -

        bra     DO_ERR                  ; c0 -
        bra     DO_ERR                  ; c1 -
        bra     DO_ERR                  ; c2 -
        bra     DO_ERR                  ; c3 -
        bra     DO_ERR                  ; c4 -
        bra     DO_ERR                  ; c5 -
        bra     DO_ERR                  ; c6 -
        bra     DO_ERR                  ; c7 -
        bra     DO_ERR                  ; c8 -
        bra     DO_ERR                  ; c9 -
        bra     DO_ERR                  ; ca -
        bra     DO_ERR                  ; cb -
        bra     DO_ERR                  ; cc -
        bra     DO_ERR                  ; cd -
        bra     DO_ERR                  ; ce -
        bra     DO_ERR                  ; cf -

        bra     DO_ERR                  ; d0 -
        bra     DO_ERR                  ; d1 -
        bra     DO_ERR                  ; d2 -
        bra     DO_ERR                  ; d3 -
        bra     DO_ERR                  ; d4 -
        bra     DO_ERR                  ; d5 -
        bra     DO_ERR                  ; d6 -
        bra     DO_ERR                  ; d7 -
        bra     DO_ERR                  ; d8 -
        bra     DO_ERR                  ; d9 -
        bra     DO_ERR                  ; da -
        bra     DO_ERR                  ; db -
        bra     DO_ERR                  ; dc -
        bra     DO_ERR                  ; dd -
        bra     DO_ERR                  ; de -
        bra     DO_ERR                  ; df -

        bra     DO_ERR                  ; e0 -
        bra     DO_ERR                  ; e1 -
        bra     DO_ERR                  ; e2 -
        bra     DO_ERR                  ; e3 -
        bra     DO_ERR                  ; e4 -
        bra     DO_ERR                  ; e5 -
        bra     DO_ERR                  ; e6 -
        bra     DO_ERR                  ; e7 -
        bra     DO_ERR                  ; e8 -
        bra     DO_ERR                  ; e9 -
        bra     DO_ERR                  ; ea -
        bra     DO_ERR                  ; eb -
        bra     DO_ERR                  ; ec -
        bra     DO_ERR                  ; ed -
        bra     DO_ERR                  ; ee -
        bra     DO_ERR                  ; ef -

        bra     DO_ERR                  ; f0 -
        bra     DO_ERR                  ; f1 -
        bra     DO_ERR                  ; f2 -
        bra     DO_ERR                  ; f3 -
        bra     DO_ERR                  ; f4 -
        bra     DO_ERR                  ; f5 -
        bra     DO_ERR                  ; f6 -
        bra     DO_ERR                  ; f7 -
        bra     DO_ERR                  ; f8 -
        bra     DO_ERR                  ; f9 -
        bra     DO_ERR                  ; fa -
        bra     DO_ERR                  ; fb -
        bra     DO_ERR                  ; fc -
        bra     DO_ERR                  ; fd -
        bra     DO_ERR                  ; fe -
        bra     DO_ERR                  ; ff -

;-------------------------------------------------------------------------------

PrefixFD:
        RD_ADDR R_PC,ze,w3              ; Fetch the next opcode
        inc     R_PC,R_PC               ; .. incrementing the PC
        bra     w3                      ; And execute it

        bra     DO_ERR                  ; fd 00 -
        bra     DO_ERR                  ; fd 01 -
        bra     DO_ERR                  ; fd 02 -
        bra     DO_ERR                  ; fd 03 -
        bra     DO_ERR                  ; fd 04 -
        bra     DO_ERR                  ; fd 05 -
        bra     DO_ERR                  ; fd 06 -
        bra     DO_ERR                  ; fd 07 -
        bra     DO_ERR                  ; fd 08 -
        bra     DO_ERR                  ; fd 09 -
        bra     DO_ERR                  ; fd 0a -
        bra     DO_ERR                  ; fd 0b -
        bra     DO_ERR                  ; fd 0c -
        bra     DO_ERR                  ; fd 0d -
        bra     DO_ERR                  ; fd 0e -
        bra     DO_ERR                  ; fd 0f -

        bra     DO_ERR                  ; 10 -
        bra     DO_ERR                  ; 11 -
        bra     DO_ERR                  ; 12 -
        bra     DO_ERR                  ; 13 -
        bra     DO_ERR                  ; 14 -
        bra     DO_ERR                  ; 15 -
        bra     DO_ERR                  ; 16 -
        bra     DO_ERR                  ; 17 -
        bra     DO_ERR                  ; 18 -
        bra     DO_ERR                  ; 19 -
        bra     DO_ERR                  ; 1a -
        bra     DO_ERR                  ; 1b -
        bra     DO_ERR                  ; 1c -
        bra     DO_ERR                  ; 1d -
        bra     DO_ERR                  ; 1e -
        bra     DO_ERR                  ; 1f -

        bra     DO_ERR                  ; 20 -
        bra     DO_ERR                  ; 21 -
        bra     DO_ERR                  ; 22 -
        bra     DO_INC_IY               ; fd 23 - INC IY
        bra     DO_ERR                  ; 24 -
        bra     DO_ERR                  ; 25 -
        bra     DO_ERR                  ; 26 -
        bra     DO_ERR                  ; 27 -
        bra     DO_ERR                  ; 28 -
        bra     DO_ERR                  ; 29 -
        bra     DO_ERR                  ; 2a -
        bra     DO_ERR                  ; 2b -
        bra     DO_ERR                  ; 2c -
        bra     DO_ERR                  ; 2d -
        bra     DO_ERR                  ; 2e -
        bra     DO_ERR                  ; 2f -

        bra     DO_ERR                  ; 30 -
        bra     DO_ERR                  ; 31 -
        bra     DO_ERR                  ; 32 -
        bra     DO_ERR                  ; 33 -
        bra     DO_ERR                  ; 34 -
        bra     DO_ERR                  ; 35 -
        bra     DO_ERR                  ; 36 -
        bra     DO_ERR                  ; 37 -
        bra     DO_ERR                  ; 38 -
        bra     DO_ERR                  ; 39 -
        bra     DO_ERR                  ; 3a -
        bra     DO_ERR                  ; 3b -
        bra     DO_ERR                  ; 3c -
        bra     DO_ERR                  ; 3d -
        bra     DO_ERR                  ; 3e -
        bra     DO_ERR                  ; 3f -

        bra     DO_ERR                  ; 40 -
        bra     DO_ERR                  ; 41 -
        bra     DO_ERR                  ; 42 -
        bra     DO_ERR                  ; 43 -
        bra     DO_ERR                  ; 44 -
        bra     DO_ERR                  ; 45 -
        bra     DO_ERR                  ; 46 -
        bra     DO_ERR                  ; 47 -
        bra     DO_ERR                  ; 48 -
        bra     DO_ERR                  ; 49 -
        bra     DO_ERR                  ; 4a -
        bra     DO_ERR                  ; 4b -
        bra     DO_ERR                  ; 4c -
        bra     DO_ERR                  ; 4d -
        bra     DO_ERR                  ; 4e -
        bra     DO_ERR                  ; 4f -

        bra     DO_ERR                  ; 50 -
        bra     DO_ERR                  ; 51 -
        bra     DO_ERR                  ; 52 -
        bra     DO_ERR                  ; 53 -
        bra     DO_ERR                  ; 54 -
        bra     DO_ERR                  ; 55 -
        bra     DO_ERR                  ; 56 -
        bra     DO_ERR                  ; 57 -
        bra     DO_ERR                  ; 58 -
        bra     DO_ERR                  ; 59 -
        bra     DO_ERR                  ; 5a -
        bra     DO_ERR                  ; 5b -
        bra     DO_ERR                  ; 5c -
        bra     DO_ERR                  ; 5d -
        bra     DO_ERR                  ; 5e -
        bra     DO_ERR                  ; 5f -

        bra     DO_ERR                  ; 60 -
        bra     DO_ERR                  ; 61 -
        bra     DO_ERR                  ; 62 -
        bra     DO_ERR                  ; 63 -
        bra     DO_ERR                  ; 64 -
        bra     DO_ERR                  ; 65 -
        bra     DO_ERR                  ; 66 -
        bra     DO_ERR                  ; 67 -
        bra     DO_ERR                  ; 68 -
        bra     DO_ERR                  ; 69 -
        bra     DO_ERR                  ; 6a -
        bra     DO_ERR                  ; 6b -
        bra     DO_ERR                  ; 6c -
        bra     DO_ERR                  ; 6d -
        bra     DO_ERR                  ; 6e -
        bra     DO_ERR                  ; 6f -

        bra     DO_ERR                  ; 70 -
        bra     DO_ERR                  ; 71 -
        bra     DO_ERR                  ; 72 -
        bra     DO_ERR                  ; 73 -
        bra     DO_ERR                  ; 74 -
        bra     DO_ERR                  ; 75 -
        bra     DO_ERR                  ; 76 -
        bra     DO_ERR                  ; 77 -
        bra     DO_ERR                  ; 78 -
        bra     DO_ERR                  ; 79 -
        bra     DO_ERR                  ; 7a -
        bra     DO_ERR                  ; 7b -
        bra     DO_ERR                  ; 7c -
        bra     DO_ERR                  ; 7d -
        bra     DO_ERR                  ; 7e -
        bra     DO_ERR                  ; 7f -

        bra     DO_ERR                  ; fd 80 -
        bra     DO_ERR                  ; fd 81 -
        bra     DO_ERR                  ; fd 82 -
        bra     DO_ERR                  ; fd 83 -
        bra     DO_ERR                  ; fd 84 -
        bra     DO_ERR                  ; fd 85 -
        bra     DO_ADD_A_IY_N           ; fd 86 - ADD A,(IY+N)
        bra     DO_ERR                  ; fd 87 -
        bra     DO_ERR                  ; fd 88 -
        bra     DO_ERR                  ; fd 89 -
        bra     DO_ERR                  ; fd 8a -
        bra     DO_ERR                  ; fd 8b -
        bra     DO_ERR                  ; fd 8c -
        bra     DO_ERR                  ; fd 8d -
        bra     DO_ADC_A_IY_N           ; fd 8e - ADC A,(IY+N)
        bra     DO_ERR                  ; fd 8f -

        bra     DO_ERR                  ; 90 -
        bra     DO_ERR                  ; 91 -
        bra     DO_ERR                  ; 92 -
        bra     DO_ERR                  ; 93 -
        bra     DO_ERR                  ; 94 -
        bra     DO_ERR                  ; 95 -
        bra     DO_ERR                  ; 96 -
        bra     DO_ERR                  ; 97 -
        bra     DO_ERR                  ; 98 -
        bra     DO_ERR                  ; 99 -
        bra     DO_ERR                  ; 9a -
        bra     DO_ERR                  ; 9b -
        bra     DO_ERR                  ; 9c -
        bra     DO_ERR                  ; 9d -
        bra     DO_ERR                  ; 9e -
        bra     DO_ERR                  ; 9f -

        bra     DO_ERR                  ; a0 -
        bra     DO_ERR                  ; a1 -
        bra     DO_ERR                  ; a2 -
        bra     DO_ERR                  ; a3 -
        bra     DO_ERR                  ; a4 -
        bra     DO_ERR                  ; a5 -
        bra     DO_ERR                  ; a6 -
        bra     DO_ERR                  ; a7 -
        bra     DO_ERR                  ; a8 -
        bra     DO_ERR                  ; a9 -
        bra     DO_ERR                  ; aa -
        bra     DO_ERR                  ; ab -
        bra     DO_ERR                  ; ac -
        bra     DO_ERR                  ; ad -
        bra     DO_ERR                  ; ae -
        bra     DO_ERR                  ; af -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; c0 -
        bra     DO_ERR                  ; c1 -
        bra     DO_ERR                  ; c2 -
        bra     DO_ERR                  ; c3 -
        bra     DO_ERR                  ; c4 -
        bra     DO_ERR                  ; c5 -
        bra     DO_ERR                  ; c6 -
        bra     DO_ERR                  ; c7 -
        bra     DO_ERR                  ; c8 -
        bra     DO_ERR                  ; c9 -
        bra     DO_ERR                  ; ca -
        bra     PrefixFDCB              ; cb -
        bra     DO_ERR                  ; cc -
        bra     DO_ERR                  ; cd -
        bra     DO_ERR                  ; ce -
        bra     DO_ERR                  ; cf -

        bra     DO_ERR                  ; d0 -
        bra     DO_ERR                  ; d1 -
        bra     DO_ERR                  ; d2 -
        bra     DO_ERR                  ; d3 -
        bra     DO_ERR                  ; d4 -
        bra     DO_ERR                  ; d5 -
        bra     DO_ERR                  ; d6 -
        bra     DO_ERR                  ; d7 -
        bra     DO_ERR                  ; d8 -
        bra     DO_ERR                  ; d9 -
        bra     DO_ERR                  ; da -
        bra     DO_ERR                  ; db -
        bra     DO_ERR                  ; dc -
        bra     DO_ERR                  ; dd -
        bra     DO_ERR                  ; de -
        bra     DO_ERR                  ; df -

        bra     DO_ERR                  ; e0 -
        bra     DO_ERR                  ; e1 -
        bra     DO_ERR                  ; e2 -
        bra     DO_ERR                  ; e3 -
        bra     DO_ERR                  ; e4 -
        bra     DO_ERR                  ; e5 -
        bra     DO_ERR                  ; e6 -
        bra     DO_ERR                  ; e7 -
        bra     DO_ERR                  ; e8 -
        bra     DO_ERR                  ; e9 -
        bra     DO_ERR                  ; ea -
        bra     DO_ERR                  ; eb -
        bra     DO_ERR                  ; ec -
        bra     DO_ERR                  ; ed -
        bra     DO_ERR                  ; ee -
        bra     DO_ERR                  ; ef -

        bra     DO_ERR                  ; f0 -
        bra     DO_ERR                  ; f1 -
        bra     DO_ERR                  ; f2 -
        bra     DO_ERR                  ; f3 -
        bra     DO_ERR                  ; f4 -
        bra     DO_ERR                  ; f5 -
        bra     DO_ERR                  ; f6 -
        bra     DO_ERR                  ; f7 -
        bra     DO_ERR                  ; f8 -
        bra     DO_ERR                  ; f9 -
        bra     DO_ERR                  ; fa -
        bra     DO_ERR                  ; fb -
        bra     DO_ERR                  ; fc -
        bra     DO_ERR                  ; fd -
        bra     DO_ERR                  ; fe -
        bra     DO_ERR                  ; ff -

;-------------------------------------------------------------------------------

PrefixFDCB:
        RD_ADDR R_PC,ze,w3              ; Fetch the next opcode
        inc     R_PC,R_PC               ; .. incrementing the PC
        bra     w3                      ; And execute it

        bra     DO_ERR                  ; 00 -
        bra     DO_ERR                  ; 01 -
        bra     DO_ERR                  ; 02 -
        bra     DO_ERR                  ; 03 -
        bra     DO_ERR                  ; 04 -
        bra     DO_ERR                  ; 05 -
        bra     DO_ERR                  ; 06 -
        bra     DO_ERR                  ; 07 -
        bra     DO_ERR                  ; 08 -
        bra     DO_ERR                  ; 09 -
        bra     DO_ERR                  ; 0a -
        bra     DO_ERR                  ; 0b -
        bra     DO_ERR                  ; 0c -
        bra     DO_ERR                  ; 0d -
        bra     DO_ERR                  ; 0e -
        bra     DO_ERR                  ; 0f -

        bra     DO_ERR                  ; 10 -
        bra     DO_ERR                  ; 11 -
        bra     DO_ERR                  ; 12 -
        bra     DO_ERR                  ; 13 -
        bra     DO_ERR                  ; 14 -
        bra     DO_ERR                  ; 15 -
        bra     DO_ERR                  ; 16 -
        bra     DO_ERR                  ; 17 -
        bra     DO_ERR                  ; 18 -
        bra     DO_ERR                  ; 19 -
        bra     DO_ERR                  ; 1a -
        bra     DO_ERR                  ; 1b -
        bra     DO_ERR                  ; 1c -
        bra     DO_ERR                  ; 1d -
        bra     DO_ERR                  ; 1e -
        bra     DO_ERR                  ; 1f -

        bra     DO_ERR                  ; 20 -
        bra     DO_ERR                  ; 21 -
        bra     DO_ERR                  ; 22 -
        bra     DO_ERR                  ; 23 -
        bra     DO_ERR                  ; 24 -
        bra     DO_ERR                  ; 25 -
        bra     DO_ERR                  ; 26 -
        bra     DO_ERR                  ; 27 -
        bra     DO_ERR                  ; 28 -
        bra     DO_ERR                  ; 29 -
        bra     DO_ERR                  ; 2a -
        bra     DO_ERR                  ; 2b -
        bra     DO_ERR                  ; 2c -
        bra     DO_ERR                  ; 2d -
        bra     DO_ERR                  ; 2e -
        bra     DO_ERR                  ; 2f -

        bra     DO_ERR                  ; 30 -
        bra     DO_ERR                  ; 31 -
        bra     DO_ERR                  ; 32 -
        bra     DO_ERR                  ; 33 -
        bra     DO_ERR                  ; 34 -
        bra     DO_ERR                  ; 35 -
        bra     DO_ERR                  ; 36 -
        bra     DO_ERR                  ; 37 -
        bra     DO_ERR                  ; 38 -
        bra     DO_ERR                  ; 39 -
        bra     DO_ERR                  ; 3a -
        bra     DO_ERR                  ; 3b -
        bra     DO_ERR                  ; 3c -
        bra     DO_ERR                  ; 3d -
        bra     DO_ERR                  ; 3e -
        bra     DO_ERR                  ; 3f -

        bra     DO_ERR                  ; 40 -
        bra     DO_ERR                  ; 41 -
        bra     DO_ERR                  ; 42 -
        bra     DO_ERR                  ; 43 -
        bra     DO_ERR                  ; 44 -
        bra     DO_ERR                  ; 45 -
        bra     DO_ERR                  ; 46 -
        bra     DO_ERR                  ; 47 -
        bra     DO_ERR                  ; 48 -
        bra     DO_ERR                  ; 49 -
        bra     DO_ERR                  ; 4a -
        bra     DO_ERR                  ; 4b -
        bra     DO_ERR                  ; 4c -
        bra     DO_ERR                  ; 4d -
        bra     DO_ERR                  ; 4e -
        bra     DO_ERR                  ; 4f -

        bra     DO_ERR                  ; 50 -
        bra     DO_ERR                  ; 51 -
        bra     DO_ERR                  ; 52 -
        bra     DO_ERR                  ; 53 -
        bra     DO_ERR                  ; 54 -
        bra     DO_ERR                  ; 55 -
        bra     DO_ERR                  ; 56 -
        bra     DO_ERR                  ; 57 -
        bra     DO_ERR                  ; 58 -
        bra     DO_ERR                  ; 59 -
        bra     DO_ERR                  ; 5a -
        bra     DO_ERR                  ; 5b -
        bra     DO_ERR                  ; 5c -
        bra     DO_ERR                  ; 5d -
        bra     DO_ERR                  ; 5e -
        bra     DO_ERR                  ; 5f -

        bra     DO_ERR                  ; 60 -
        bra     DO_ERR                  ; 61 -
        bra     DO_ERR                  ; 62 -
        bra     DO_ERR                  ; 63 -
        bra     DO_ERR                  ; 64 -
        bra     DO_ERR                  ; 65 -
        bra     DO_ERR                  ; 66 -
        bra     DO_ERR                  ; 67 -
        bra     DO_ERR                  ; 68 -
        bra     DO_ERR                  ; 69 -
        bra     DO_ERR                  ; 6a -
        bra     DO_ERR                  ; 6b -
        bra     DO_ERR                  ; 6c -
        bra     DO_ERR                  ; 6d -
        bra     DO_ERR                  ; 6e -
        bra     DO_ERR                  ; 6f -

        bra     DO_ERR                  ; 70 -
        bra     DO_ERR                  ; 71 -
        bra     DO_ERR                  ; 72 -
        bra     DO_ERR                  ; 73 -
        bra     DO_ERR                  ; 74 -
        bra     DO_ERR                  ; 75 -
        bra     DO_ERR                  ; 76 -
        bra     DO_ERR                  ; 77 -
        bra     DO_ERR                  ; 78 -
        bra     DO_ERR                  ; 79 -
        bra     DO_ERR                  ; 7a -
        bra     DO_ERR                  ; 7b -
        bra     DO_ERR                  ; 7c -
        bra     DO_ERR                  ; 7d -
        bra     DO_ERR                  ; 7e -
        bra     DO_ERR                  ; 7f -

        bra     DO_ERR                  ; 80 -
        bra     DO_ERR                  ; 81 -
        bra     DO_ERR                  ; 82 -
        bra     DO_ERR                  ; 83 -
        bra     DO_ERR                  ; 84 -
        bra     DO_ERR                  ; 85 -
        bra     DO_ERR                  ; 86 -
        bra     DO_ERR                  ; 87 -
        bra     DO_ERR                  ; 88 -
        bra     DO_ERR                  ; 89 -
        bra     DO_ERR                  ; 8a -
        bra     DO_ERR                  ; 8b -
        bra     DO_ERR                  ; 8c -
        bra     DO_ERR                  ; 8d -
        bra     DO_ERR                  ; 8e -
        bra     DO_ERR                  ; 8f -

        bra     DO_ERR                  ; 90 -
        bra     DO_ERR                  ; 91 -
        bra     DO_ERR                  ; 92 -
        bra     DO_ERR                  ; 93 -
        bra     DO_ERR                  ; 94 -
        bra     DO_ERR                  ; 95 -
        bra     DO_ERR                  ; 96 -
        bra     DO_ERR                  ; 97 -
        bra     DO_ERR                  ; 98 -
        bra     DO_ERR                  ; 99 -
        bra     DO_ERR                  ; 9a -
        bra     DO_ERR                  ; 9b -
        bra     DO_ERR                  ; 9c -
        bra     DO_ERR                  ; 9d -
        bra     DO_ERR                  ; 9e -
        bra     DO_ERR                  ; 9f -

        bra     DO_ERR                  ; a0 -
        bra     DO_ERR                  ; a1 -
        bra     DO_ERR                  ; a2 -
        bra     DO_ERR                  ; a3 -
        bra     DO_ERR                  ; a4 -
        bra     DO_ERR                  ; a5 -
        bra     DO_ERR                  ; a6 -
        bra     DO_ERR                  ; a7 -
        bra     DO_ERR                  ; a8 -
        bra     DO_ERR                  ; a9 -
        bra     DO_ERR                  ; aa -
        bra     DO_ERR                  ; ab -
        bra     DO_ERR                  ; ac -
        bra     DO_ERR                  ; ad -
        bra     DO_ERR                  ; ae -
        bra     DO_ERR                  ; af -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_ERR                  ; b3 -
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_ERR                  ; bc -
        bra     DO_ERR                  ; bd -
        bra     DO_ERR                  ; be -
        bra     DO_ERR                  ; bf -

        bra     DO_ERR                  ; c0 -
        bra     DO_ERR                  ; c1 -
        bra     DO_ERR                  ; c2 -
        bra     DO_ERR                  ; c3 -
        bra     DO_ERR                  ; c4 -
        bra     DO_ERR                  ; c5 -
        bra     DO_ERR                  ; c6 -
        bra     DO_ERR                  ; c7 -
        bra     DO_ERR                  ; c8 -
        bra     DO_ERR                  ; c9 -
        bra     DO_ERR                  ; ca -
        bra     DO_ERR                  ; cb -
        bra     DO_ERR                  ; cc -
        bra     DO_ERR                  ; cd -
        bra     DO_ERR                  ; ce -
        bra     DO_ERR                  ; cf -

        bra     DO_ERR                  ; d0 -
        bra     DO_ERR                  ; d1 -
        bra     DO_ERR                  ; d2 -
        bra     DO_ERR                  ; d3 -
        bra     DO_ERR                  ; d4 -
        bra     DO_ERR                  ; d5 -
        bra     DO_ERR                  ; d6 -
        bra     DO_ERR                  ; d7 -
        bra     DO_ERR                  ; d8 -
        bra     DO_ERR                  ; d9 -
        bra     DO_ERR                  ; da -
        bra     DO_ERR                  ; db -
        bra     DO_ERR                  ; dc -
        bra     DO_ERR                  ; dd -
        bra     DO_ERR                  ; de -
        bra     DO_ERR                  ; df -

        bra     DO_ERR                  ; e0 -
        bra     DO_ERR                  ; e1 -
        bra     DO_ERR                  ; e2 -
        bra     DO_ERR                  ; e3 -
        bra     DO_ERR                  ; e4 -
        bra     DO_ERR                  ; e5 -
        bra     DO_ERR                  ; e6 -
        bra     DO_ERR                  ; e7 -
        bra     DO_ERR                  ; e8 -
        bra     DO_ERR                  ; e9 -
        bra     DO_ERR                  ; ea -
        bra     DO_ERR                  ; eb -
        bra     DO_ERR                  ; ec -
        bra     DO_ERR                  ; ed -
        bra     DO_ERR                  ; ee -
        bra     DO_ERR                  ; ef -

        bra     DO_ERR                  ; f0 -
        bra     DO_ERR                  ; f1 -
        bra     DO_ERR                  ; f2 -
        bra     DO_ERR                  ; f3 -
        bra     DO_ERR                  ; f4 -
        bra     DO_ERR                  ; f5 -
        bra     DO_ERR                  ; f6 -
        bra     DO_ERR                  ; f7 -
        bra     DO_ERR                  ; f8 -
        bra     DO_ERR                  ; f9 -
        bra     DO_ERR                  ; fa -
        bra     DO_ERR                  ; fb -
        bra     DO_ERR                  ; fc -
        bra     DO_ERR                  ; fd -
        bra     DO_ERR                  ; fe -
        bra     DO_ERR                  ; ff -

;-------------------------------------------------------------------------------

DO_ADC_A_A:
        OP_ADC_R M_A
        retlw   #4,w0

DO_ADC_A_B:
        OP_ADC_R M_B
        retlw   #4,w0

DO_ADC_A_C:
        OP_ADC_R M_C
        retlw   #4,w0

DO_ADC_A_D:
        OP_ADC_R M_D
        retlw   #4,w0

DO_ADC_A_E:
        OP_ADC_R M_E
        retlw   #4,w0

DO_ADC_A_H:
        OP_ADC_R M_H
        retlw   #4,w0

DO_ADC_A_L:
        OP_ADC_R M_L
        retlw   #4,w0

DO_ADC_A_N:
        OP_ADC_N
        retlw   #7,w0

DO_ADC_A_I:
        OP_ADC_I
        retlw   #7,w0

DO_ADC_A_IX_N:
        OP_ADC_X IX
        retlw   #19,w0

DO_ADC_A_IY_N:
        OP_ADC_X IY
        retlw   #19,w0

DO_ADC_HL_BC:
        OP_ADC_HL R_BC
        retlw   #15,w0

DO_ADC_HL_DE:
        OP_ADC_HL R_DE
        retlw   #15,w0

DO_ADC_HL_HL:
        OP_ADC_HL R_HL
        retlw   #15,w0

DO_ADC_HL_SP:
        OP_ADC_HL R_SP
        retlw   #15,w0

;-------------------------------------------------------------------------------

DO_ADD_A_A:
        OP_ADD_R M_A
        retlw   #4,w0

DO_ADD_A_B:
        OP_ADD_R M_B
        retlw   #4,w0

DO_ADD_A_C:
        OP_ADD_R M_C
        retlw   #4,w0

DO_ADD_A_D:
        OP_ADD_R M_D
        retlw   #4,w0

DO_ADD_A_E:
        OP_ADD_R M_E
        retlw   #4,w0

DO_ADD_A_H:
        OP_ADD_R M_H
        retlw   #4,w0

DO_ADD_A_L:
        OP_ADD_R M_L
        retlw   #4,w0

DO_ADD_A_N:
        OP_ADD_N
        retlw   #7,w0

DO_ADD_A_I:
        OP_ADD_I
        retlw   #7,w0

DO_ADD_A_IX_N:
        OP_ADD_X IX
        retlw   #19,w0

DO_ADD_A_IY_N:
        OP_ADD_X IY
        retlw   #19,w0

DO_ADD_HL_BC:
        OP_ADD_HL R_BC
        retlw   #15,w0

DO_ADD_HL_DE:
        OP_ADD_HL R_DE
        retlw   #15,w0

DO_ADD_HL_HL:
        OP_ADD_HL R_HL
        retlw   #15,w0

DO_ADD_HL_SP:
        OP_ADD_HL R_SP
        retlw   #15,w0

DO_ADD_IX_BC:
        OP_ADD_IX M_BC
        retlw   #15,w0

DO_ADD_IX_DE:
        OP_ADD_IX M_DE
        retlw   #15,w0

DO_ADD_IX_IX:
        OP_ADD_IX IX
        retlw   #15,w0

DO_ADD_IX_SP:
        OP_ADD_IX M_SP
        retlw   #15,w0

DO_ADD_IY_BC:
        OP_ADD_IY M_BC
        retlw   #15,w0

DO_ADD_IY_DE:
        OP_ADD_IY M_DE
        retlw   #15,w0

DO_ADD_IY_IY:
        OP_ADD_IY IY
        retlw   #15,w0

DO_ADD_IY_SP:
        OP_ADD_IY M_SP
        retlw   #15,w0

;-------------------------------------------------------------------------------

DO_AND_A:
        OP_AND_R M_A
        retlw   #4,w0

DO_AND_B:
        OP_AND_R M_B
        retlw   #4,w0

DO_AND_C:
        OP_AND_R M_C
        retlw   #4,w0

DO_AND_D:
        OP_AND_R M_D
        retlw   #4,w0

DO_AND_E:
        OP_AND_R M_E
        retlw   #4,w0

DO_AND_H:
        OP_AND_R M_H
        retlw   #4,w0

DO_AND_L:
        OP_AND_R M_L
        retlw   #4,w0

DO_AND_N:
        OP_AND_N
        retlw   #7,w0

DO_AND_I:
        OP_AND_I
        retlw   #7,w0

DO_AND_IX_N:
        OP_AND_X IX
        retlw   #19,w0

DO_AND_IY_N:
        OP_AND_X IY
        retlw   #19,w0

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

DO_CALL:
        OP_CALL
        retlw   #17,w0

DO_CALL_C:
        OP_CALL_C
        retlw   #17,w0

DO_CALL_NC:
        OP_CALL_NC
        retlw   #17,w0

DO_CALL_M:
        OP_CALL_M
        retlw   #17,w0

DO_CALL_P:
        OP_CALL_P
        retlw   #17,w0

DO_CALL_Z:
        OP_CALL_Z
        retlw   #17,w0

DO_CALL_NZ:
        OP_CALL_NZ
        retlw   #17,w0

DO_CALL_PE:
        OP_CALL_PE
        retlw   #17,w0

DO_CALL_PO:
        OP_CALL_PO
        retlw   #17,w0

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

DO_DJNZ:
        OP_DJNZ
        retlw   #13,w0

;-------------------------------------------------------------------------------

DO_INC_A:
        OP_INC_R M_A
        retlw   #4,w0

DO_INC_B:
        OP_INC_R M_B
        retlw   #4,w0

DO_INC_C:
        OP_INC_R M_C
        retlw   #4,w0

DO_INC_D:
        OP_INC_R M_D
        retlw   #4,w0

DO_INC_E:
        OP_INC_R M_E
        retlw   #4,w0

DO_INC_H:
        OP_INC_R M_H
        retlw   #4,w0

DO_INC_L:
        OP_INC_R M_L
        retlw   #4,w0

DO_INC_BC:
        OP_INC_M M_BC
        retlw   #6,w0

DO_INC_DE:
        OP_INC_M M_DE
        retlw   #6,w0

DO_INC_HL:
        OP_INC_M M_HL
        retlw   #6,w0

DO_INC_SP:
        OP_INC_M M_SP
        retlw   #6,w0

DO_INC_IX:
        OP_INC_M IX
        retlw   #10,w0

DO_INC_IY:
        OP_INC_M IY
        retlw   #10,w0

DO_INC_I:
        OP_INC_I
        retlw   #11,w0

DO_INC_IX_N:
        OP_INC_X IX
        retlw   #23,w0

DO_INC_IY_N:
        OP_INC_X IY
        retlw   #23,w0

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

DO_JP:
        OP_JP
        retlw   #10,w0

DO_JP_C:
        OP_JP_C
        retlw   #10,w0

DO_JP_NC:
        OP_JP_NC
        retlw   #10,w0

DO_JP_M:
        OP_JP_M
        retlw   #10,w0

DO_JP_P:
        OP_JP_P
        retlw   #10,w0

DO_JP_Z:
        OP_JP_Z
        retlw   #10,w0

DO_JP_NZ:
        OP_JP_NZ
        retlw   #10,w0

DO_JP_PE:
        OP_JP_PE
        retlw   #10,w0

DO_JP_PO:
        OP_JP_PO
        retlw   #10,w0


;-------------------------------------------------------------------------------

DO_NOP:
        OP_NOP
        retlw   #4,w0

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------

DO_RST_00:
        OP_RST  0x00
        retlw   #11,w0

DO_RST_08:
        OP_RST  0x08
        retlw   #11,w0

DO_RST_10:
        OP_RST  0x10
        retlw   #11,w0

DO_RST_18:
        OP_RST  0x18
        retlw   #11,w0

DO_RST_20:
        OP_RST  0x20
        retlw   #11,w0

DO_RST_28:
        OP_RST  0x28
        retlw   #11,w0

DO_RST_30:
        OP_RST  0x30
        retlw   #11,w0

DO_RST_38:
        OP_RST  0x38
        retlw   #11,w0

;-------------------------------------------------------------------------------





DO_ERR:
        retlw   #1,w0

        .end
