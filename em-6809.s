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
        bra     DO_ROR_DIR              ; 06 - ROR dir
        bra     DO_ASR_DIR              ; 07 - ASR dir
        bra     DO_ASL_DIR              ; 08 - ASL dir
        bra     DO_ROL_DIR              ; 09 - ROL dir
        bra     DO_DEC_DIR              ; 0a - DEC dir
        bra     DO_ERR                  ; 0b -
        bra     DO_INC_DIR              ; 0c - INC dir
        bra     DO_TST_DIR              ; 0d - TST_dir
        bra     DO_JMP_DIR              ; 0e - JMP dir
        bra     DO_CLR_DIR              ; 0f - CLR dir

        bra     Prefix10                ; 10 - Prefix
        bra     Prefix11                ; 11 - Prefix
        bra     DO_NOP_INH              ; 12 - NOP
        bra     DO_SYNC_INH             ; 13 - SYNC
        bra     DO_ERR                  ; 14 -
        bra     DO_ERR                  ; 15 -
        bra     DO_LBRA_REL             ; 16 - LBRA rel
        bra     DO_LBSR_REL             ; 17 - LBSR rel
        bra     DO_ERR                  ; 18 -
        bra     DO_DAA_INH              ; 19 - DAA
        bra     DO_ORCC_IMM             ; 1a - ORCC #imm
        bra     DO_ERR                  ; 1b -
        bra     DO_ANDCC_IMM            ; 1c - ANDCC #imm
        bra     DO_SEX_INH              ; 1d - SEX
        bra     DO_EXG_IMM              ; 1e - EXG r1,r2
        bra     DO_TFR_IMM              ; 1f - TFR r1,r2

        bra     DO_BRA_REL              ; 20 - BRA rel
        bra     DO_BRN_REL              ; 21 - BRN rel
        bra     DO_BHI_REL              ; 22 - BHI rel
        bra     DO_BLS_REL              ; 23 - BLS rel
        bra     DO_BCC_REL              ; 24 - BCC rel
        bra     DO_BCS_REL              ; 25 - BCS rel
        bra     DO_BNE_REL              ; 26 - BNE rel
        bra     DO_BEQ_REL              ; 27 - BEQ rel
        bra     DO_BVC_REL              ; 28 - BVC rel
        bra     DO_BVS_REL              ; 29 - BVS rel
        bra     DO_BPL_REL              ; 2a - BPL rel
        bra     DO_BMI_REL              ; 2b - BMI rel
        bra     DO_BGE_REL              ; 2c - BGE rel
        bra     DO_BLT_REL              ; 2d - BLT rel
        bra     DO_BGT_REL              ; 2e - BGT rel
        bra     DO_BLE_REL              ; 2f - BLE rel

        bra     DO_LEAX_IDX             ; 30 - LEAX idx
        bra     DO_LEAY_IDX             ; 31 - LEAY idx
        bra     DO_LEAS_IDX             ; 32 - LEAS idx
        bra     DO_LEAU_IDX             ; 33 - LEAU idx
        bra     DO_PSHS_IMM             ; 34 - PSHS regs
        bra     DO_PULS_IMM             ; 35 - PULS regs
        bra     DO_PSHU_IMM             ; 36 - PSHU regs
        bra     DO_PULU_IMM             ; 37 - PULU regs
        bra     DO_ERR                  ; 38 -
        bra     DO_RTS_INH              ; 39 - RTS
        bra     DO_ABX_INH              ; 3a - ABX
        bra     DO_RTI_INH              ; 3b - RTI
        bra     DO_CWAI_IMM             ; 3c - CWAI #imm
        bra     DO_MUL_INH              ; 3d - MUL
        bra     DO_ERR                  ; 3e -
        bra     DO_SWI_INH              ; 3f - SWI

        bra     DO_NEGA_INH             ; 40 - NEGA
        bra     DO_ERR                  ; 41 -
        bra     DO_ERR                  ; 42 -
        bra     DO_COMA_INH             ; 43 - COMA
        bra     DO_LSRA_INH             ; 44 - LSRA
        bra     DO_ERR                  ; 45 -
        bra     DO_RORA_INH             ; 46 - RORA
        bra     DO_ASRA_INH             ; 47 - ASRA
        bra     DO_ASLA_INH             ; 48 - ASLA
        bra     DO_ROLA_INH             ; 49 - ROLA
        bra     DO_DECA_INH             ; 4a - DECA
        bra     DO_ERR                  ; 4b -
        bra     DO_INCA_INH             ; 4c - INCA
        bra     DO_TSTA_INH             ; 4d - TSTA
        bra     DO_ERR                  ; 4e -
        bra     DO_CLRA_INH             ; 4f - CLRA

        bra     DO_NEGB_INH             ; 50 - NEGB
        bra     DO_ERR                  ; 51 -
        bra     DO_ERR                  ; 52 -
        bra     DO_COMB_INH             ; 53 - COMB
        bra     DO_LSRB_INH             ; 54 - LSRB
        bra     DO_ERR                  ; 55 -
        bra     DO_RORB_INH             ; 56 - RORB
        bra     DO_ASRB_INH             ; 57 - ASRB
        bra     DO_ASLB_INH             ; 58 - ASLB
        bra     DO_ROLB_INH             ; 59 - ROLB
        bra     DO_DECB_INH             ; 5a - DECB
        bra     DO_ERR                  ; 5b -
        bra     DO_INCB_INH             ; 5c - INCB
        bra     DO_TSTB_INH             ; 5d - TSTB
        bra     DO_ERR                  ; 5e -
        bra     DO_CLRB_INH             ; 5f - CLRB

        bra     DO_NEG_IDX              ; 60 - NEG idx
        bra     DO_ERR                  ; 61 -
        bra     DO_ERR                  ; 62 -
        bra     DO_COM_IDX              ; 63 - COM idx
        bra     DO_LSR_IDX              ; 64 - LSR idx
        bra     DO_ERR                  ; 65 -
        bra     DO_ROR_IDX              ; 66 - ROR idx
        bra     DO_ASR_IDX              ; 67 - ASR idx
        bra     DO_ASL_IDX              ; 68 - ASL idx
        bra     DO_ROL_IDX              ; 69 - ROL idx
        bra     DO_DEC_IDX              ; 6a - DEC idx
        bra     DO_ERR                  ; 6b -
        bra     DO_INC_IDX              ; 6c - INC idx
        bra     DO_TST_IDX              ; 6d - TST idx
        bra     DO_JMP_IDX              ; 6e - JMP idx
        bra     DO_CLR_IDX              ; 6f - CLR idx

        bra     DO_NEG_EXT              ; 70 - NEG ext
        bra     DO_ERR                  ; 71 -
        bra     DO_ERR                  ; 72 -
        bra     DO_COM_EXT              ; 73 - COM ext
        bra     DO_LSR_EXT              ; 74 - LSR ext
        bra     DO_ERR                  ; 75 -
        bra     DO_ROR_EXT              ; 76 - ROR ext
        bra     DO_ASR_EXT              ; 77 - ASR ext
        bra     DO_ASL_EXT              ; 78 - ASL ext
        bra     DO_ROL_EXT              ; 79 - ROL ext
        bra     DO_DEC_EXT              ; 7a - DEC ext
        bra     DO_ERR                  ; 7b -
        bra     DO_INC_EXT              ; 7c - INC ext
        bra     DO_TST_EXT              ; 7d - TST ext
        bra     DO_JMP_EXT              ; 7e - JMP ext
        bra     DO_CLR_EXT              ; 7f - CLR ext

        bra     DO_SUBA_IMM             ; 80 - SUBA #imm
        bra     DO_CMPA_IMM             ; 81 - CMPA #imm
        bra     DO_SBCA_IMM             ; 82 - SBCA #imm
        bra     DO_SUBD_IMM             ; 83 - SUBD #imm
        bra     DO_ANDA_IMM             ; 84 - ANDA #imm
        bra     DO_BITA_IMM             ; 85 - BITA #imm
        bra     DO_LDA_IMM              ; 86 - LDA #imm
        bra     DO_ERR                  ; 87 -
        bra     DO_EORA_IMM             ; 88 - EORA #imm
        bra     DO_ADCA_IMM             ; 89 - ADCA #imm
        bra     DO_ORA_IMM              ; 8a - ORA #imm
        bra     DO_ADDA_IMM             ; 8b - ADDA #imm
        bra     DO_CMPX_IMM             ; 8c - CMPX #imm
        bra     DO_BSR_REL              ; 8d - BSR rel
        bra     DO_LDX_IMM              ; 8e - LDX #imm
        bra     DO_ERR                  ; 8f -

        bra     DO_SUBA_DIR             ; 90 - SUBA dir
        bra     DO_CMPA_DIR             ; 91 - CMPA dir
        bra     DO_SBCA_DIR             ; 92 - SCBA dir
        bra     DO_SUBD_DIR             ; 93 - SUBD dir
        bra     DO_ANDA_DIR             ; 94 - ANDA dir
        bra     DO_BITA_DIR             ; 95 - BITA dir
        bra     DO_LDA_DIR              ; 96 - LDA dir
        bra     DO_STA_DIR              ; 97 - STA dir
        bra     DO_EORA_DIR             ; 98 - EORA dir
        bra     DO_ADCA_DIR             ; 99 - ADCA dir
        bra     DO_ORA_DIR              ; 9a - ORA dir
        bra     DO_ADDA_DIR             ; 9b - ADDA dir
        bra     DO_CMPX_DIR             ; 9c - CMPX dir
        bra     DO_JSR_DIR              ; 9d - JSR dir
        bra     DO_LDX_DIR              ; 9e - LDX dir
        bra     DO_STX_DIR              ; 9f - STX dir

        bra     DO_SUBA_IDX             ; a0 - SUBA idx
        bra     DO_CMPA_IDX             ; a1 - CMPA idx
        bra     DO_SBCA_IDX             ; a2 - SBCA idx
        bra     DO_SUBD_IDX             ; a3 - SUBD idx
        bra     DO_ANDA_IDX             ; a4 - ANDA idx
        bra     DO_BITA_IDX             ; a5 - BITA idx
        bra     DO_LDA_IDX              ; a6 - LDA idx
        bra     DO_STA_IDX              ; a7 - STA idx
        bra     DO_EORA_IDX             ; a8 - EORA idx
        bra     DO_ADCA_IDX             ; a9 - ADCA idx
        bra     DO_ORA_IDX              ; aa - ORA idx
        bra     DO_ADDA_IDX             ; ab - ADDA idx
        bra     DO_CMPX_IDX             ; ac - CMPX idx
        bra     DO_JSR_IDX              ; ad - JSR idx
        bra     DO_LDX_IDX              ; ae - LDX idx
        bra     DO_STX_IDX              ; af - STX idx

        bra     DO_SUBA_EXT             ; b0 - SUBA ext
        bra     DO_CMPA_EXT             ; b1 - CMPA ext
        bra     DO_SBCA_EXT             ; b2 - SBCA ext
        bra     DO_SUBD_EXT             ; b3 - SUBD ext
        bra     DO_ANDA_EXT             ; b4 - ANDA ext
        bra     DO_BITA_EXT             ; b5 - BITA ext
        bra     DO_LDA_EXT              ; b6 - LDA ext
        bra     DO_STA_EXT              ; b7 - STA ext
        bra     DO_EORA_EXT             ; b8 - EORA ext
        bra     DO_ADCA_EXT             ; b9 - ADCA ext
        bra     DO_ORA_EXT              ; ba - ORA ext
        bra     DO_ADDA_EXT             ; bb - ADDA ext
        bra     DO_CMPX_EXT             ; bc - CMPX ext
        bra     DO_JSR_EXT              ; bd - JSR ext
        bra     DO_LDX_EXT              ; be - LDX ext
        bra     DO_STX_EXT              ; bf - STX ext

        bra     DO_SUBB_IMM             ; c0 - SUBB imm
        bra     DO_CMPB_IMM             ; c1 - CMPB imm
        bra     DO_SBCB_IMM             ; c2 - SBCB imm
        bra     DO_ADDD_IMM             ; c3 - ADDD imm
        bra     DO_ANDB_IMM             ; c4 - ANDB imm
        bra     DO_BITB_IMM             ; c5 - BITB imm
        bra     DO_LDB_IMM              ; c6 - LDB imm
        bra     DO_ERR                  ; c7 -
        bra     DO_EORB_IMM             ; c8 - EORB imm
        bra     DO_ADCB_IMM             ; c9 - ADCB imm
        bra     DO_ORB_IMM              ; ca - ORB imm
        bra     DO_ADDB_IMM             ; cb - ADDB imm
        bra     DO_LDD_IMM              ; cc - LDD imm
        bra     DO_ERR                  ; cd -
        bra     DO_LDU_IMM              ; ce - LDU imm
        bra     DO_ERR                  ; cf -

        bra     DO_SUBB_DIR             ; d0 - SUBB dir
        bra     DO_CMPB_DIR             ; d1 - CMPB dir
        bra     DO_SBCB_DIR             ; d2 - SBCD dir
        bra     DO_ADDD_DIR             ; d3 - ADDD dir
        bra     DO_ANDB_DIR             ; d4 - ANDB dir
        bra     DO_BITB_DIR             ; d5 - BITB dir
        bra     DO_LDB_DIR              ; d6 - LDB dir
        bra     DO_STB_DIR              ; d7 - STB dir
        bra     DO_EORB_DIR             ; d8 - EORB dir
        bra     DO_ADCB_DIR             ; d9 - ADCB dir
        bra     DO_ORB_DIR              ; da - ORB dir
        bra     DO_ADDB_DIR             ; db - ADDB dir
        bra     DO_LDD_DIR              ; dc - LDD dir
        bra     DO_STD_DIR              ; dd - STD dir
        bra     DO_LDU_DIR              ; de - LDU dir
        bra     DO_STU_DIR              ; df - STU dir

        bra     DO_SUBB_IDX             ; e0 - SUBB idx
        bra     DO_CMPB_IDX             ; e1 - CMPB idx
        bra     DO_SBCB_IDX             ; e2 - SBCB idx
        bra     DO_ADDD_IDX             ; e3 - ADDD idx
        bra     DO_ANDB_IDX             ; e4 - ANDB idx
        bra     DO_BITB_IDX             ; e5 - BITB idx
        bra     DO_LDB_IDX              ; e6 - LDB idx
        bra     DO_STB_IDX              ; e7 - STB idx
        bra     DO_EORB_IDX             ; e8 - EORB idx
        bra     DO_ADCB_IDX             ; e9 - ADCN idx
        bra     DO_ORB_IDX              ; ea - ORB idx
        bra     DO_ADDB_IDX             ; eb - ADDB idx
        bra     DO_LDD_IDX              ; ec - LDD idx
        bra     DO_STD_IDX              ; ed - STD idx
        bra     DO_LDU_IDX              ; ee - LDU idx
        bra     DO_STU_IDX              ; ef - STU idx

        bra     DO_SUBB_EXT             ; f0 - SUBB ext
        bra     DO_CMPB_EXT             ; f1 - CMPN ext
        bra     DO_SBCB_EXT             ; f2 - SBCB ext
        bra     DO_ADDD_EXT             ; f3 - ADDD ext
        bra     DO_ANDB_EXT             ; f4 - ANDB ext
        bra     DO_BITB_EXT             ; f5 - BITB ext
        bra     DO_LDB_EXT              ; f6 - LDB ext
        bra     DO_STB_EXT              ; f7 - STB ext
        bra     DO_EORB_EXT             ; f8 - EORB ext
        bra     DO_ADCB_EXT             ; f9 - ADCB ext
        bra     DO_ORB_EXT              ; fa - ORB ext
        bra     DO_ADDB_EXT             ; fb - ADDB ext
        bra     DO_LDD_EXT              ; fc - LDD ext
        bra     DO_STD_EXT              ; fd - STD ext
        bra     DO_LDU_EXT              ; fe - LDU ext
        bra     DO_STU_EXT              ; ff - STU ext

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
        bra     DO_LBRN_REL             ; 21 - LBRN rel
        bra     DO_LBHI_REL             ; 22 - LBHI rel
        bra     DO_LBLS_REL             ; 23 - LBLS rel
        bra     DO_LBCC_REL             ; 24 - LBCC rel
        bra     DO_LBCS_REL             ; 25 - LBCS rel
        bra     DO_LBNE_REL             ; 26 - LBNE rel
        bra     DO_LBEQ_REL             ; 27 - LBEQ rel
        bra     DO_LBVC_REL             ; 28 - LBVC rel
        bra     DO_LBVS_REL             ; 29 - LBVS rel
        bra     DO_LBPL_REL             ; 2a - LBPL rel
        bra     DO_LBMI_REL             ; 2b - LBMI rel
        bra     DO_LBGE_REL             ; 2c - LBGE rel
        bra     DO_LBLT_REL             ; 2d - LBLT rel
        bra     DO_LBGT_REL             ; 2e - LBGT rel
        bra     DO_LBLE_REL             ; 2f - LBLE rel

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
        bra     DO_SWI2_INH             ; 3f - SWI2

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
        bra     DO_CMPD_IMM             ; 83 - CMPD #imm
        bra     DO_ERR                  ; 84 -
        bra     DO_ERR                  ; 85 -
        bra     DO_ERR                  ; 86 -
        bra     DO_ERR                  ; 87 -
        bra     DO_ERR                  ; 88 -
        bra     DO_ERR                  ; 89 -
        bra     DO_ERR                  ; 8a -
        bra     DO_ERR                  ; 8b -
        bra     DO_CMPY_IMM             ; 8c - CMPY #imm
        bra     DO_ERR                  ; 8d -
        bra     DO_LDY_IMM              ; 8e - LDY #imm
        bra     DO_ERR                  ; 8f -

        bra     DO_ERR                  ; 90 -
        bra     DO_ERR                  ; 91 -
        bra     DO_ERR                  ; 92 -
        bra     DO_CMPD_DIR             ; 93 - CMPD dir
        bra     DO_ERR                  ; 94 -
        bra     DO_ERR                  ; 95 -
        bra     DO_ERR                  ; 96 -
        bra     DO_ERR                  ; 97 -
        bra     DO_ERR                  ; 98 -
        bra     DO_ERR                  ; 99 -
        bra     DO_ERR                  ; 9a -
        bra     DO_ERR                  ; 9b -
        bra     DO_CMPY_DIR             ; 9c - CMPY dir
        bra     DO_ERR                  ; 9d -
        bra     DO_LDY_DIR              ; 9e - LDY dir
        bra     DO_STY_DIR              ; 9f - STY dir

        bra     DO_ERR                  ; a0 -
        bra     DO_ERR                  ; a1 -
        bra     DO_ERR                  ; a2 -
        bra     DO_CMPD_IDX             ; a3 - CMPD idx
        bra     DO_ERR                  ; a4 -
        bra     DO_ERR                  ; a5 -
        bra     DO_ERR                  ; a6 -
        bra     DO_ERR                  ; a7 -
        bra     DO_ERR                  ; a8 -
        bra     DO_ERR                  ; a9 -
        bra     DO_ERR                  ; aa -
        bra     DO_ERR                  ; ab -
        bra     DO_CMPY_IDX             ; ac - CMPY idx
        bra     DO_ERR                  ; ad -
        bra     DO_LDY_IDX              ; ae - LDY idx
        bra     DO_STY_IDX              ; af - STY idx

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_CMPD_EXT             ; b3 - CMPD ext
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_CMPY_EXT             ; bc - CMPY ext
        bra     DO_ERR                  ; bd -
        bra     DO_LDY_EXT              ; be - LDY ext
        bra     DO_STY_EXT              ; bf - STY ext

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
        bra     DO_LDS_IMM              ; ce - LDS #imm
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
        bra     DO_LDS_DIR              ; de - LDS dir
        bra     DO_STS_DIR              ; df - STS dir

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
        bra     DO_LDS_IDX              ; ee - LDS idx
        bra     DO_STS_IDX              ; ef - STS idx

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
        bra     DO_LDS_EXT              ; fe - LDS ext
        bra     DO_STS_EXT              ; ff - STS ext

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
        bra     DO_SWI3_INH             ; 3f - SWI3

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
        bra     DO_CMPU_IMM             ; 83 - CMPU #imm
        bra     DO_ERR                  ; 84 -
        bra     DO_ERR                  ; 85 -
        bra     DO_ERR                  ; 86 -
        bra     DO_ERR                  ; 87 -
        bra     DO_ERR                  ; 88 -
        bra     DO_ERR                  ; 89 -
        bra     DO_ERR                  ; 8a -
        bra     DO_ERR                  ; 8b -
        bra     DO_CMPS_IMM             ; 8c - CMPS #imm
        bra     DO_ERR                  ; 8d -
        bra     DO_ERR                  ; 8e -
        bra     DO_ERR                  ; 8f -

        bra     DO_ERR                  ; 90 -
        bra     DO_ERR                  ; 91 -
        bra     DO_ERR                  ; 92 -
        bra     DO_CMPU_DIR             ; 93 - CMPU dir
        bra     DO_ERR                  ; 94 -
        bra     DO_ERR                  ; 95 -
        bra     DO_ERR                  ; 96 -
        bra     DO_ERR                  ; 97 -
        bra     DO_ERR                  ; 98 -
        bra     DO_ERR                  ; 99 -
        bra     DO_ERR                  ; 9a -
        bra     DO_ERR                  ; 9b -
        bra     DO_CMPS_DIR             ; 9c - CMPS dir
        bra     DO_ERR                  ; 9d -
        bra     DO_ERR                  ; 9e -
        bra     DO_ERR                  ; 9f -

        bra     DO_ERR                  ; a0 -
        bra     DO_ERR                  ; a1 -
        bra     DO_ERR                  ; a2 -
        bra     DO_CMPU_IDX             ; a3 - CMPU idx
        bra     DO_ERR                  ; a4 -
        bra     DO_ERR                  ; a5 -
        bra     DO_ERR                  ; a6 -
        bra     DO_ERR                  ; a7 -
        bra     DO_ERR                  ; a8 -
        bra     DO_ERR                  ; a9 -
        bra     DO_ERR                  ; aa -
        bra     DO_ERR                  ; ab -
        bra     DO_CMPS_IDX             ; ac - CMPS_IDX
        bra     DO_ERR                  ; ad -
        bra     DO_ERR                  ; ae -
        bra     DO_ERR                  ; af -

        bra     DO_ERR                  ; b0 -
        bra     DO_ERR                  ; b1 -
        bra     DO_ERR                  ; b2 -
        bra     DO_CMPU_EXT             ; b3 - CMPU ext
        bra     DO_ERR                  ; b4 -
        bra     DO_ERR                  ; b5 -
        bra     DO_ERR                  ; b6 -
        bra     DO_ERR                  ; b7 -
        bra     DO_ERR                  ; b8 -
        bra     DO_ERR                  ; b9 -
        bra     DO_ERR                  ; ba -
        bra     DO_ERR                  ; bb -
        bra     DO_CMPS_EXT             ; bc - CMPS ext
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
        OP_ADC  M_A
        retlw   #2,w0

DO_ADCA_EXT:
        AM_EXT
        OP_ADC  M_A
        retlw   #5,w0

DO_ADCA_DIR:
        AM_DIR
        OP_ADC  M_A
        retlw   #4,w0

DO_ADCA_IDX:
        AM_IDX
        OP_ADC  M_A
        retlw   #4,w0

DO_ADCB_IMM:
        AM_IMM  1
        OP_ADC  M_B
        retlw   #2,w0

DO_ADCB_EXT:
        AM_EXT
        OP_ADC  M_B
        retlw   #5,w0

DO_ADCB_DIR:
        AM_DIR
        OP_ADC  M_B
        retlw   #4,w0

DO_ADCB_IDX:
        AM_IDX
        OP_ADC  M_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ADDA_IMM:
        AM_IMM  1
        OP_ADD  M_A
        retlw   #2,w0

DO_ADDA_EXT:
        AM_EXT
        OP_ADD  M_A
        retlw   #5,w0

DO_ADDA_DIR:
        AM_DIR
        OP_ADD  M_A
        retlw   #4,w0

DO_ADDA_IDX:
        AM_IDX
        OP_ADD  M_A
        retlw   #4,w0

DO_ADDB_IMM:
        AM_IMM  1
        OP_ADD  M_B
        retlw   #2,w0

DO_ADDB_EXT:
        AM_EXT
        OP_ADD  M_B
        retlw   #5,w0

DO_ADDB_DIR:
        AM_DIR
        OP_ADD  M_B
        retlw   #4,w0

DO_ADDB_IDX:
        AM_IDX
        OP_ADD  M_B
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
        OP_AND  M_A
        retlw   #2,w0

DO_ANDA_EXT:
        AM_EXT
        OP_AND  M_A
        retlw   #5,w0

DO_ANDA_DIR:
        AM_DIR
        OP_AND  M_A
        retlw   #4,w0

DO_ANDA_IDX:
        AM_IDX
        OP_AND  M_A
        retlw   #4,w0

DO_ANDB_IMM:
        AM_IMM  1
        OP_AND  M_B
        retlw   #2,w0

DO_ANDB_EXT:
        AM_EXT
        OP_AND  M_B
        retlw   #5,w0

DO_ANDB_DIR:
        AM_DIR
        OP_AND  M_B
        retlw   #4,w0

DO_ANDB_IDX:
        AM_IDX
        OP_AND  M_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ANDCC_IMM:
        AM_IMM  1
        OP_ANDCC
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_ASLA_INH:
        AM_INH
        OP_ASL  M_A
        retlw   #2,w0

DO_ASLB_INH:
        AM_INH
        OP_ASL  M_B
        retlw   #2,w0

DO_ASL_EXT:
        AM_EXT
        OP_ASL_M
        retlw   #7,w0

DO_ASL_DIR:
        AM_DIR
        OP_ASL_M
        retlw   #6,w0

DO_ASL_IDX:
        AM_IDX
        OP_ASL_M
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_ASRA_INH:
        AM_INH
        OP_ASR  M_A
        retlw   #2,w0

DO_ASRB_INH:
        AM_INH
        OP_ASR  M_B
        retlw   #2,w0

DO_ASR_EXT:
        AM_EXT
        OP_ASR_M
        retlw   #7,w0

DO_ASR_DIR:
        AM_DIR
        OP_ASR_M
        retlw   #6,w0

DO_ASR_IDX:
        AM_IDX
        OP_ASR_M
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_BCC_REL:
        AM_REL
        OP_BCC
        retlw   #3,w0

DO_LBCC_REL:
        AM_LNG
        OP_BCC
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BCS_REL:
        AM_REL
        OP_BCS
        retlw   #3,w0

DO_LBCS_REL:
        AM_LNG
        OP_BCS
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BEQ_REL:
        AM_REL
        OP_BEQ
        retlw   #3,w0

DO_LBEQ_REL:
        AM_LNG
        OP_BEQ
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BGE_REL:
        AM_REL
        OP_BGE
        retlw   #3,w0

DO_LBGE_REL:
        AM_LNG
        OP_BGE
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BGT_REL:
        AM_REL
        OP_BGT
        retlw   #3,w0

DO_LBGT_REL:
        AM_LNG
        OP_BGT
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BHI_REL:
        AM_REL
        OP_BHI
        retlw   #3,w0

DO_LBHI_REL:
        AM_LNG
        OP_BHI
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BITA_IMM:
        AM_IMM  1
        OP_BIT  M_A
        retlw   #3,w0

DO_BITA_EXT:
        AM_EXT
        OP_BIT  M_A
        retlw   #3,w0

DO_BITA_DIR:
        AM_DIR
        OP_BIT  M_A
        retlw   #3,w0

DO_BITA_IDX:
        AM_IDX
        OP_BIT  M_A
        retlw   #3,w0

DO_BITB_IMM:
        AM_IMM  1
        OP_BIT  M_B
        retlw   #3,w0

DO_BITB_EXT:
        AM_EXT
        OP_BIT  M_B
        retlw   #3,w0

DO_BITB_DIR:
        AM_DIR
        OP_BIT  M_B
        retlw   #3,w0

DO_BITB_IDX:
        AM_IDX
        OP_BIT  M_B
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BLE_REL:
        AM_REL
        OP_BLE
        retlw   #3,w0

DO_LBLE_REL:
        AM_LNG
        OP_BLE
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BLS_REL:
        AM_REL
        OP_BLS
        retlw   #3,w0

DO_LBLS_REL:
        AM_LNG
        OP_BLS
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BLT_REL:
        AM_REL
        OP_BLT
        retlw   #3,w0

DO_LBLT_REL:
        AM_LNG
        OP_BLT
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BMI_REL:
        AM_REL
        OP_BMI
        retlw   #3,w0

DO_LBMI_REL:
        AM_LNG
        OP_BMI
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BNE_REL:
        AM_REL
        OP_BNE
        retlw   #3,w0

DO_LBNE_REL:
        AM_LNG
        OP_BNE
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BPL_REL:
        AM_REL
        OP_BPL
        retlw   #3,w0

DO_LBPL_REL:
        AM_LNG
        OP_BPL
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BRA_REL:
        AM_REL
        OP_BRA
        retlw   #3,w0

DO_LBRA_REL:
        AM_LNG
        OP_BRA
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BRN_REL:
        AM_REL
        OP_BRN
        retlw   #3,w0

DO_LBRN_REL:
        AM_LNG
        OP_BRN
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BSR_REL:
        AM_REL
        OP_BSR
        retlw   #3,w0

DO_LBSR_REL:
        AM_LNG
        OP_BSR
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BVC_REL:
        AM_REL
        OP_BVC
        retlw   #3,w0

DO_LBVC_REL:
        AM_LNG
        OP_BVC
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_BVS_REL:
        AM_REL
        OP_BVS
        retlw   #3,w0

DO_LBVS_REL:
        AM_LNG
        OP_BVS
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_CLRA_INH:
        AM_INH
        OP_CLR  M_A
        retlw   #6,w0

DO_CLRB_INH:
        AM_INH
        OP_CLR  M_B
        retlw   #6,w0

DO_CLR_EXT:
        AM_EXT
        OP_CLR_M
        retlw   #6,w0

DO_CLR_DIR:
        AM_DIR
        OP_CLR_M
        retlw   #6,w0

DO_CLR_IDX:
        AM_DIR
        OP_CLR_M
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_CMPA_IMM:
        AM_IMM  1
        OP_CMP  M_A
        retlw   #6,w0

DO_CMPA_EXT:
        AM_EXT
        OP_CMP  M_A
        retlw   #6,w0

DO_CMPA_DIR:
        AM_DIR
        OP_CMP  M_A
        retlw   #6,w0

DO_CMPA_IDX:
        AM_DIR
        OP_CMP  M_A
        retlw   #6,w0

DO_CMPB_IMM:
        AM_IMM  1
        OP_CMP  M_B
        retlw   #6,w0

DO_CMPB_EXT:
        AM_EXT
        OP_CMP  M_B
        retlw   #6,w0

DO_CMPB_DIR:
        AM_DIR
        OP_CMP  M_B
        retlw   #6,w0

DO_CMPB_IDX:
        AM_DIR
        OP_CMP  M_B
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_CMPD_IMM:
        AM_IMM  2
        OP_CMP_W R_D
        retlw   #6,w0
        
DO_CMPD_EXT:
        AM_EXT
        OP_CMP_W R_D
        retlw   #6,w0
        
DO_CMPD_DIR:
        AM_DIR
        OP_CMP_W R_D
        retlw   #6,w0
        
DO_CMPD_IDX:
        AM_IDX
        OP_CMP_W R_D
        retlw   #6,w0

;-------------------------------------------------------------------------------
        
DO_CMPS_IMM:
        AM_IMM  2
        OP_CMP_W R_S
        retlw   #6,w0
        
DO_CMPS_EXT:
        AM_EXT
        OP_CMP_W R_S
        retlw   #6,w0
        
DO_CMPS_DIR:
        AM_DIR
        OP_CMP_W R_S
        retlw   #6,w0
        
DO_CMPS_IDX:
        AM_IDX
        OP_CMP_W R_S
        retlw   #6,w0

;-------------------------------------------------------------------------------
        
DO_CMPU_IMM:
        AM_IMM  2
        OP_CMP_W R_U
        retlw   #6,w0
        
DO_CMPU_EXT:
        AM_EXT
        OP_CMP_W R_U
        retlw   #6,w0
        
DO_CMPU_DIR:
        AM_DIR
        OP_CMP_W R_U
        retlw   #6,w0
        
DO_CMPU_IDX:
        AM_IDX
        OP_CMP_W R_U
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_CMPX_IMM:
        AM_IMM  2
        OP_CMP_W R_X
        retlw   #6,w0
        
DO_CMPX_EXT:
        AM_EXT
        OP_CMP_W R_X
        retlw   #6,w0
        
DO_CMPX_DIR:
        AM_DIR
        OP_CMP_W R_X
        retlw   #6,w0
        
DO_CMPX_IDX:
        AM_IDX
        OP_CMP_W R_X
        retlw   #6,w0
        
;-------------------------------------------------------------------------------

DO_CMPY_IMM:
        AM_IMM  2
        OP_CMP_W R_Y
        retlw   #6,w0
        
DO_CMPY_EXT:
        AM_EXT
        OP_CMP_W R_Y
        retlw   #6,w0
        
DO_CMPY_DIR:
        AM_DIR
        OP_CMP_W R_Y
        retlw   #6,w0
        
DO_CMPY_IDX:
        AM_IDX
        OP_CMP_W R_Y
        retlw   #6,w0
       
;-------------------------------------------------------------------------------

DO_COMA_INH:
        AM_INH
        OP_COM  M_A
        retlw   #2,w0

DO_COMB_INH:
        AM_INH
        OP_COM  M_B
        retlw   #2,w0

DO_COM_EXT:
        AM_EXT
        OP_COM_M
        retlw   #6,w0

DO_COM_DIR:
        AM_DIR
        OP_COM_M
        retlw   #6,w0

DO_COM_IDX:
        AM_IDX
        OP_COM_M
        retlw   #6,w0

;-------------------------------------------------------------------------------
        
DO_CWAI_IMM:
        AM_IMM  1
        OP_CWAI
        retlw   #4,w0
        
;-------------------------------------------------------------------------------
        
DO_DAA_INH:
        AM_INH
        OP_DAA
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_DECA_INH:
        AM_INH
        OP_DEC  M_A
        retlw   #2,w0

DO_DECB_INH:
        AM_INH
        OP_DEC  M_B
        retlw   #2,w0

DO_DEC_EXT:
        AM_EXT
        OP_DEC_M
        retlw   #5,w0

DO_DEC_DIR:
        AM_DIR
        OP_DEC_M
        retlw   #4,w0

DO_DEC_IDX:
        AM_IDX
        OP_DEC_M
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_EORA_IMM:
        AM_IMM  1
        OP_EOR  M_A
        retlw   #3,w0
        
DO_EORA_EXT:
        AM_EXT
        OP_EOR  M_A
        retlw   #3,w0
        
DO_EORA_DIR:
        AM_DIR
        OP_EOR  M_A
        retlw   #3,w0
        
DO_EORA_IDX:
        AM_IDX
        OP_EOR  M_A
        retlw   #3,w0
        
DO_EORB_IMM:
        AM_IMM  1
        OP_EOR  M_B
        retlw   #3,w0
        
DO_EORB_EXT:
        AM_EXT
        OP_EOR  M_B
        retlw   #3,w0
        
DO_EORB_DIR:
        AM_DIR
        OP_EOR  M_B
        retlw   #3,w0
        
DO_EORB_IDX:
        AM_IDX
        OP_EOR  M_B
        retlw   #3,w0
               
;-------------------------------------------------------------------------------
        
DO_EXG_IMM:
        AM_IMM  1
        OP_EXG
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_INCA_INH:
        AM_INH
        OP_INC  M_A
        retlw   #2,w0

DO_INCB_INH:
        AM_INH
        OP_INC  M_B
        retlw   #2,w0

DO_INC_EXT:
        AM_EXT
        OP_INC_M
        retlw   #5,w0

DO_INC_DIR:
        AM_DIR
        OP_INC_M
        retlw   #4,w0

DO_INC_IDX:
        AM_IDX
        OP_INC_M
        retlw   #4,w0
        
;-------------------------------------------------------------------------------
        
DO_JMP_EXT:
        AM_EXT
        OP_JMP
        retlw   #4,w0
        
DO_JMP_DIR:
        AM_DIR
        OP_JMP
        retlw   #4,w0
        
DO_JMP_IDX:
        AM_IDX
        OP_JMP
        retlw   #4,w0
        
;-------------------------------------------------------------------------------

DO_JSR_EXT:
        AM_EXT
        OP_JSR
        retlw   #4,w0
        
DO_JSR_DIR:
        AM_DIR
        OP_JSR
        retlw   #4,w0
        
DO_JSR_IDX:
        AM_IDX
        OP_JSR
        retlw   #4,w0

;-------------------------------------------------------------------------------
        
DO_LDA_IMM:
        AM_IMM  1
        OP_LDA
        retlw   #4,w0
        
DO_LDA_EXT:
        AM_EXT
        OP_LDA
        retlw   #4,w0
        
DO_LDA_DIR:
        AM_DIR
        OP_LDA
        retlw   #4,w0
        
DO_LDA_IDX:
        AM_IDX
        OP_LDA
        retlw   #4,w0
        
DO_LDB_IMM:
        AM_IMM  1
        OP_LDB
        retlw   #4,w0
        
DO_LDB_EXT:
        AM_EXT
        OP_LDB
        retlw   #4,w0
        
DO_LDB_DIR:
        AM_DIR
        OP_LDB
        retlw   #4,w0
        
DO_LDB_IDX:
        AM_IDX
        OP_LDB
        retlw   #4,w0
        
;-------------------------------------------------------------------------------
        
DO_LDD_IMM:
        AM_IMM  2
        OP_LD   R_D
        retlw   #3,w0
        
DO_LDD_EXT:
        AM_EXT
        OP_LD   R_D
        retlw   #3,w0
        
DO_LDD_DIR:
        AM_DIR
        OP_LD   R_D
        retlw   #3,w0
        
DO_LDD_IDX:
        AM_IDX
        OP_LD   R_D
        retlw   #3,w0
        
;-------------------------------------------------------------------------------
        
DO_LDS_IMM:
        AM_IMM  2
        OP_LD   R_S
        retlw   #3,w0
        
DO_LDS_EXT:
        AM_EXT
        OP_LD   R_S
        retlw   #3,w0
        
DO_LDS_DIR:
        AM_DIR
        OP_LD   R_S
        retlw   #3,w0
        
DO_LDS_IDX:
        AM_IDX
        OP_LD   R_S
        retlw   #3,w0
        
;-------------------------------------------------------------------------------

DO_LDU_IMM:
        AM_IMM  2
        OP_LD   R_U
        retlw   #3,w0
        
DO_LDU_EXT:
        AM_EXT
        OP_LD   R_U
        retlw   #3,w0
        
DO_LDU_DIR:
        AM_DIR
        OP_LD   R_U
        retlw   #3,w0
        
DO_LDU_IDX:
        AM_IDX
        OP_LD   R_U
        retlw   #3,w0

;-------------------------------------------------------------------------------

DO_LDX_IMM:
        AM_IMM  2
        OP_LD   R_X
        retlw   #3,w0
        
DO_LDX_EXT:
        AM_EXT
        OP_LD   R_X
        retlw   #3,w0
        
DO_LDX_DIR:
        AM_DIR
        OP_LD   R_X
        retlw   #3,w0
        
DO_LDX_IDX:
        AM_IDX
        OP_LD   R_X
        retlw   #3,w0
        
;-------------------------------------------------------------------------------

DO_LDY_IMM:
        AM_IMM  2
        OP_LD   R_Y
        retlw   #3,w0
        
DO_LDY_EXT:
        AM_EXT
        OP_LD   R_Y
        retlw   #3,w0
        
DO_LDY_DIR:
        AM_EXT
        OP_LD   R_Y
        retlw   #3,w0
        
DO_LDY_IDX:
        AM_EXT
        OP_LD   R_Y
        retlw   #3,w0
        
;-------------------------------------------------------------------------------
        
DO_LEAS_IDX:
        AM_IDX
        OP_LEA  R_S
        retlw   #3,w0
        
DO_LEAU_IDX:
        AM_IDX
        OP_LEA  R_U
        retlw   #3,w0
        
DO_LEAX_IDX:
        AM_IDX
        OP_LEA  R_X
        retlw   #3,w0
        
DO_LEAY_IDX:
        AM_IDX
        OP_LEA  R_Y
        retlw   #3,w0
        
;-------------------------------------------------------------------------------

DO_LSRA_INH:
        AM_INH
        OP_LSR  M_A
        retlw   #2,w0

DO_LSRB_INH:
        AM_INH
        OP_LSR  M_B
        retlw   #2,w0

DO_LSR_EXT:
        AM_EXT
        OP_LSR_M
        retlw   #6,w0
        
DO_LSR_DIR:
        AM_DIR
        OP_LSR_M
        retlw   #6,w0
        
DO_LSR_IDX:
        AM_IDX
        OP_LSR_M
        retlw   #6,w0

;-------------------------------------------------------------------------------
        
DO_MUL_INH:
        AM_INH
        OP_MUL
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_NEGA_INH:
        AM_INH
        OP_NEG  M_A
        retlw   #2,w0

DO_NEGB_INH:
        AM_INH
        OP_NEG  M_B
        retlw   #2,w0

DO_NEG_EXT:
        AM_EXT
        OP_NEG_M
        retlw   #6,w0

DO_NEG_DIR:
        AM_DIR
        OP_NEG_M
        retlw   #6,w0

DO_NEG_IDX:
        AM_IDX
        OP_NEG_M
        retlw   #6,w0

;-------------------------------------------------------------------------------
        
DO_NOP_INH:
        AM_INH
        OP_NOP
        retlw   #2,w0

;-------------------------------------------------------------------------------

DO_ORA_IMM:
        AM_IMM  1
        OP_OR   M_A
        retlw   #2,w0

DO_ORA_EXT:
        AM_EXT
        OP_OR   M_A
        retlw   #5,w0

DO_ORA_DIR:
        AM_DIR
        OP_OR   M_A
        retlw   #4,w0

DO_ORA_IDX:
        AM_IDX
        OP_OR   M_A
        retlw   #4,w0

DO_ORB_IMM:
        AM_IMM  1
        OP_OR   M_B
        retlw   #2,w0

DO_ORB_EXT:
        AM_EXT
        OP_OR   M_B
        retlw   #5,w0

DO_ORB_DIR:
        AM_DIR
        OP_OR   M_B
        retlw   #4,w0

DO_ORB_IDX:
        AM_IDX
        OP_OR   M_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_ORCC_IMM:
        AM_IMM  1
        OP_ORCC
        retlw   #3,w0

;-------------------------------------------------------------------------------
        
DO_PSHS_IMM:
        AM_IMM  1
        OP_PSH  R_S
        retlw   #4,w0
        
DO_PSHU_IMM:
        AM_IMM  1
        OP_PSH  R_U
        retlw   #4,w0
        
;-------------------------------------------------------------------------------
        
DO_PULS_IMM:
        AM_IMM  1
        OP_PUL  R_S
        retlw   #4,w0
        
DO_PULU_IMM:
        AM_IMM  1
        OP_PUL  R_U
        retlw   #4,w0
        
;-------------------------------------------------------------------------------

DO_ROLA_INH:
        AM_INH
        OP_ROL  M_A
        retlw   #2,w0

DO_ROLB_INH:
        AM_INH
        OP_ROL  M_B
        retlw   #2,w0

DO_ROL_EXT:
        AM_EXT
        OP_ROL_M
        retlw   #7,w0

DO_ROL_DIR:
        AM_DIR
        OP_ROL_M
        retlw   #6,w0

DO_ROL_IDX:
        AM_IDX
        OP_ROL_M
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_RORA_INH:
        AM_INH
        OP_ROR  M_A
        retlw   #2,w0

DO_RORB_INH:
        AM_INH
        OP_ROR  M_B
        retlw   #2,w0

DO_ROR_EXT:
        AM_EXT
        OP_ROR_M
        retlw   #7,w0

DO_ROR_DIR:
        AM_DIR
        OP_ROR_M
        retlw   #6,w0

DO_ROR_IDX:
        AM_IDX
        OP_ROR_M
        retlw   #6,w0

;-------------------------------------------------------------------------------
        
DO_RTI_INH:
        AM_INH
        OP_RTI
        retlw   #4,w0
        
;-------------------------------------------------------------------------------
        
DO_RTS_INH:
        AM_INH
        OP_RTS
        retlw   #4,w0
        
;-------------------------------------------------------------------------------

DO_SBCA_IMM:
        AM_IMM  1
        OP_SBC  M_A
        retlw   #2,w0

DO_SBCA_EXT:
        AM_EXT
        OP_SBC  M_A
        retlw   #5,w0

DO_SBCA_DIR:
        AM_DIR
        OP_SBC  M_A
        retlw   #4,w0

DO_SBCA_IDX:
        AM_IDX
        OP_SBC  M_A
        retlw   #4,w0

DO_SBCB_IMM:
        AM_IMM  1
        OP_SBC  M_B
        retlw   #2,w0

DO_SBCB_EXT:
        AM_EXT
        OP_SBC  M_B
        retlw   #5,w0

DO_SBCB_DIR:
        AM_DIR
        OP_SBC  M_B
        retlw   #4,w0

DO_SBCB_IDX:
        AM_IDX
        OP_SBC  M_B
        retlw   #4,w0

;-------------------------------------------------------------------------------
        
DO_SEX_INH:
        AM_INH
        OP_SEX
        retlw   #4,w0
      
;-------------------------------------------------------------------------------
        
DO_STA_EXT:
        AM_EXT
        OP_STA
        retlw   #2,w0

DO_STA_DIR:
        AM_DIR
        OP_STA
        retlw   #2,w0

DO_STA_IDX:
        AM_IDX
        OP_STA
        retlw   #2,w0

DO_STB_EXT:
        AM_EXT
        OP_STB
        retlw   #2,w0

DO_STB_DIR:
        AM_DIR
        OP_STB
        retlw   #2,w0

DO_STB_IDX:
        AM_IDX
        OP_STB
        retlw   #2,w0

;-------------------------------------------------------------------------------
        
DO_STD_EXT:
        AM_EXT
        OP_ST   R_D
        retlw   #4,w0
        
DO_STD_DIR:
        AM_DIR
        OP_ST   R_D
        retlw   #4,w0
        
DO_STD_IDX:
        AM_IDX
        OP_ST   R_D
        retlw   #4,w0

;-------------------------------------------------------------------------------
        
DO_STS_EXT:
        AM_EXT
        OP_ST   R_S
        retlw   #4,w0
        
DO_STS_DIR:
        AM_DIR
        OP_ST   R_S
        retlw   #4,w0
        
DO_STS_IDX:
        AM_IDX
        OP_ST   R_S
        retlw   #4,w0

;-------------------------------------------------------------------------------
        
DO_STU_EXT:
        AM_EXT
        OP_ST   R_U
        retlw   #4,w0
        
DO_STU_DIR:
        AM_DIR
        OP_ST   R_U
        retlw   #4,w0
        
DO_STU_IDX:
        AM_IDX
        OP_ST   R_U
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_STX_EXT:
        AM_EXT
        OP_ST   R_X
        retlw   #4,w0
        
DO_STX_DIR:
        AM_DIR
        OP_ST   R_X
        retlw   #4,w0
        
DO_STX_IDX:
        AM_IDX
        OP_ST   R_X
        retlw   #4,w0
        
;-------------------------------------------------------------------------------

DO_STY_EXT:
        AM_EXT
        OP_ST   R_Y
        retlw   #4,w0

DO_STY_DIR:
        AM_DIR
        OP_ST   R_Y
        retlw   #4,w0

DO_STY_IDX:
        AM_IDX
        OP_ST   R_Y
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_SUBA_IMM:
        AM_IMM  1
        OP_SUB  M_A
        retlw   #2,w0

DO_SUBA_EXT:
        AM_EXT
        OP_SUB  M_A
        retlw   #5,w0

DO_SUBA_DIR:
        AM_DIR
        OP_SUB  M_A
        retlw   #4,w0

DO_SUBA_IDX:
        AM_IDX
        OP_SUB  M_A
        retlw   #4,w0

DO_SUBB_IMM:
        AM_IMM  1
        OP_SUB  M_B
        retlw   #2,w0

DO_SUBB_EXT:
        AM_EXT
        OP_SUB  M_B
        retlw   #5,w0

DO_SUBB_DIR:
        AM_DIR
        OP_SUB  M_B
        retlw   #4,w0

DO_SUBB_IDX:
        AM_IDX
        OP_SUB  M_B
        retlw   #4,w0

;-------------------------------------------------------------------------------

DO_SUBD_IMM:
        AM_IMM  2
        OP_SUBD
        retlw   #4,w0

DO_SUBD_EXT:
        AM_EXT
        OP_SUBD
        retlw   #7,w0

DO_SUBD_DIR:
        AM_DIR
        OP_SUBD
        retlw   #6,w0

DO_SUBD_IDX:
        AM_IDX
        OP_SUBD
        retlw   #6,w0

;-------------------------------------------------------------------------------

DO_SWI_INH:
        AM_INH
        OP_SWI  0xfffa
        retlw   #19,w0

DO_SWI2_INH:
        AM_INH
        OP_SWI  0xfff4
        retlw   #19,w0

DO_SWI3_INH:
        AM_INH
        OP_SWI  0xfff2
        retlw   #19,w0

;-------------------------------------------------------------------------------
        
DO_SYNC_INH:
        AM_INH
        OP_SYNC
        retlw   #4,w0
        
;-------------------------------------------------------------------------------
        
DO_TFR_IMM:
        AM_IMM  1
        OP_TFR
        retlw   #4,w0
        
;-------------------------------------------------------------------------------

DO_TSTA_INH:
        AM_INH
        OP_TST  M_A
        retlw   #2,w0

DO_TSTB_INH:
        AM_INH
        OP_TST  M_B
        retlw   #2,w0

DO_TST_EXT:
        AM_EXT
        OP_TST_M
        retlw   #7,w0

DO_TST_DIR:
        AM_DIR
        OP_TST_M
        retlw   #6,w0

DO_TST_IDX:
        AM_IDX
        OP_TST_M
        retlw   #6,w0

;-------------------------------------------------------------------------------
        
DO_ERR:
        retlw   #1,w0

        .end
