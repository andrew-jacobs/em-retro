;===============================================================================
;  _____ __  __        __    ___   ___   ___
; | ____|  \/  |      / /_  ( _ ) / _ \ / _ \
; |  _| | |\/| |_____| '_ \ / _ \| | | | (_) |
; | |___| |  | |_____| (_) | (_) | |_| |\__, |
; |_____|_|  |_|      \___/ \___/ \___/   /_/
;
; A Motorola 6809 Emulator
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
;===============================================================================
; Revision History:
;
; 2015-01-16 AJ Initial version
;-------------------------------------------------------------------------------
; $Id: em-6809.s 52 2015-10-09 22:46:45Z andrew $
;-------------------------------------------------------------------------------

        .include "hardware.inc"
        .include "em-retro.inc"
        .include "em-6809.inc"

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

        .section .nbss,bss,near

JUNK:
        .space  2                       ; Junk area used for invalid registers
M_CC:
        .space  1                       ; Processor status flags not in R_SR

;===============================================================================
;-------------------------------------------------------------------------------

        .section .6809,code
        
        .global EM_6809
        .extern CYCLE
EM_6809:



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

        bra     DO_NEG_DIR              ; 00 - NEG dir
        bra     DO_ERR                  ; 01 -
        bra     DO_ERR                  ; 02 -
        bra     DO_COM_DIR              ; 03 - COM dir
        bra     DO_LSR_DIR              ; 04 - LSR dir
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

        bra     Prefix10                ; 10 - Prefix
        bra     Prefix11                ; 11 - Prefix
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
        bra     DO_ABX_INH              ; 3a - ABX
        bra     DO_ERR                  ; 3b -
        bra     DO_ERR                  ; 3c -
        bra     DO_ERR                  ; 3d -
        bra     DO_ERR                  ; 3e -
        bra     DO_SWI                  ; 3f - SWI

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

Prefix10:
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

Prefix11:
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

MapExch:
        and     #0x000f,w0              ; Extract register number
        add     w0,w0,w0
        bra     w0                      ; And map to pointer

        mov     #M_D,w0
        return
        mov     #M_X,w0
        return
        mov     #M_Y,w0
        return
        mov     #M_U,w0
        return
        mov     #M_S,w0
        return
        mov     #M_PC,w0
        return
        mov     #JUNK,w0
        return
        mov     #JUNK,w0
        return

        mov     #M_A,w0
        return
        mov     #M_B,w0
        return
        mov     #M_CC,w0
        return
        mov     #M_DP,w0
        return
        mov     #JUNK,w0
        return
        mov     #JUNK,w0
        return
        mov     #JUNK,w0
        return
        mov     #JUNK,w0
        return

;-------------------------------------------------------------------------------

DO_ABX_INH:
        AM_INH
        OP_ABX
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_ADCA_IMM:
        AM_IMM  1
        OP_ADCA
        retlw   #2,w0

DO_ADCA_EXT:
        AM_EXT
        OP_ADCA
        retlw   #5,w0

DO_ADCA_DIR:
        AM_DIR
        OP_ADCA
        retlw   #4,w0

DO_ADCA_IDX:
        AM_IDX
        OP_ADCA
        retlw   #4,w0

DO_ADCB_IMM:
        AM_IMM  1
        OP_ADCB
        retlw   #2,w0

DO_ADCB_EXT:
        AM_EXT
        OP_ADCB
        retlw   #5,w0

DO_ADCB_DIR:
        AM_DIR
        OP_ADCB
        retlw   #4,w0

DO_ADCB_IDX:
        AM_IDX
        OP_ADCB
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ADDA_IMM:
        AM_IMM  1
        OP_ADDA
        retlw   #2,w0

DO_ADDA_EXT:
        AM_EXT
        OP_ADDA
        retlw   #5,w0

DO_ADDA_DIR:
        AM_DIR
        OP_ADDA
        retlw   #4,w0

DO_ADDA_IDX:
        AM_IDX
        OP_ADDA
        retlw   #4,w0

DO_ADDB_IMM:
        AM_IMM  1
        OP_ADDB
        retlw   #2,w0

DO_ADDB_EXT:
        AM_EXT
        OP_ADDB
        retlw   #5,w0

DO_ADDB_DIR:
        AM_DIR
        OP_ADDB
        retlw   #4,w0

DO_ADDB_IDX:
        AM_IDX
        OP_ADDB
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ADDD_IMM:
        AM_IMM  2
        OP_ADDD
        retlw   #4,w0

DO_ADDD_EXT:
        AM_EXT
        OP_ADDD
        retlw   #7,w0

DO_ADDD_DIR:
        AM_DIR
        OP_ADDD
        retlw   #6,w0

DO_ADDD_IDX:
        AM_IDX
        OP_ADDD
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_ANDA_IMM:
        AM_IMM  1
        OP_ANDA
        retlw   #2,w0

DO_ANDA_EXT:
        AM_EXT
        OP_ANDA
        retlw   #5,w0

DO_ANDA_DIR:
        AM_DIR
        OP_ANDA
        retlw   #4,w0

DO_ANDA_IDX:
        AM_IDX
        OP_ANDA
        retlw   #4,w0

DO_ANDB_IMM:
        AM_IMM  1
        OP_ANDB
        retlw   #2,w0

DO_ANDB_EXT:
        AM_EXT
        OP_ANDB
        retlw   #5,w0

DO_ANDB_DIR:
        AM_DIR
        OP_ANDB
        retlw   #4,w0

DO_ANDB_IDX:
        AM_IDX
        OP_ANDB
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ANDCC_IMM:
        AM_IMM  1
        OP_ANDCC
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_ASLA_INH:
        AM_INH
        OP_ASLA
        retlw   #2,w0

DO_ASLB_INH:
        AM_INH
        OP_ASLB
        retlw   #2,w0

DO_ASL_EXT:
        AM_EXT
        OP_ASL
        retlw   #7,w0

DO_ASL_DIR:
        AM_DIR
        OP_ASL
        retlw   #6,w0

DO_ASL_IDX:
        AM_IDX
        OP_ASL
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_ASRA_INH:
        AM_INH
        OP_ASRA
        retlw   #2,w0

DO_ASRB_INH:
        AM_INH
        OP_ASRB
        retlw   #2,w0

DO_ASR_EXT:
        AM_EXT
        OP_ASR
        retlw   #7,w0

DO_ASR_DIR:
        AM_DIR
        OP_ASR
        retlw   #6,w0

DO_ASR_IDX:
        AM_IDX
        OP_ASR
        retlw   #6,w0

;-------------------------------------------------------------------------------

OP_BCC_REL:
        AM_REL
        OP_BCC
        retlw   #3,w0

;-------------------------------------------------------------------------------

OP_BCS_REL:
        AM_REL
        OP_BCS
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_COM_DIR:
        AM_DIR
        OP_COM
        retlw   #6,w0

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

OP_LBCC_LNG:
        AM_LNG
        OP_LBCC
        retlw   #5,w0

;-------------------------------------------------------------------------------

OP_LBCS_LNG:
        AM_LNG
        OP_LBCS
        retlw   #5,w0

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

DO_LSRA_INH:
        AM_INH
        OP_LSRA
        retlw   #2,w0

DO_LSRB_INH:
        AM_INH
        OP_LSRB
        retlw   #2,w0

DO_LSR_DIR:
        AM_DIR
        OP_LSR_M
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_NEGA_INH:
        AM_INH
        OP_NEGA
        retlw   #2,w0

DO_NEGB_INH:
        AM_INH
        OP_NEGB
        retlw   #2,w0

DO_NEG_DIR:
        AM_DIR
        OP_NEG
        retlw   #6,w0

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

DO_SWI:
        AM_INH
        OP_SWI  0xfffa
        retlw   #19,w0

DO_SWI2:
        AM_INH
        OP_SWI  0xfff4
        retlw   #19,w0

DO_SWI3:
        AM_INH
        OP_SWI  0xfff2
        retlw   #19,w0

;-------------------------------------------------------------------------------

DO_ERR:
        retlw   #1,w0

        .end
