;===============================================================================
;  _____ __  __       ____      _
; | ____|  \/  |     |  _ \ ___| |_ _ __ ___
; |  _| | |\/| |_____| |_) / _ \ __| '__/ _ \
; | |___| |  | |_____|  _ <  __/ |_| | | (_) |
; |_____|_|  |_|     |_| \_\___|\__|_|  \___/
;
; Common Emulator Definitions
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
; $Id: em-retro.inc 49 2015-07-15 16:47:53Z andrew $
;-------------------------------------------------------------------------------

        .extern MEMORY_MAP 

        .extern RAM1
        .extern RAM2
        .extern RAM3
        .extern RAM4
        .extern RAM5
        .extern RAM6
        .extern RAM7
        .extern RAM8
        .extern RAM9
        .extern RAMA
        .extern RAMB
        .extern BLANK
	
;===============================================================================
; Register Usage
;-------------------------------------------------------------------------------

        .equiv  M_FLAG,         w4      ; Read-only page flags
        .equiv  M_BASE,         w5      ; Base address of memory map
        .equiv  M_MASK,         w6      ; Mask for offset (0x0fff)

;===============================================================================
; Memory Access Macros
;-------------------------------------------------------------------------------

        .macro  RD_ADDR,EA,OP,REG
        lsr     \EA,#12,w1              ; Extract the target page number
        sl      w1,#2,w1                ; Map page number to DSR address
        mov     [M_BASE+w1],w0
        mov     w0,DSRPAG               ; And prepare for read
        inc2    w1,w1
        mov     [M_BASE+w1],w1          ; Fetch page offset
        and     \EA,M_MASK,w0           ; And combine with address
        add     w0,w1,w1
        cp0     DSRPAG                  ; If target DSW memory is not
        btss    SR,#Z                   ; .. in first 32K
        bset    w1,#15                  ; Then access via DSR
        \OP     [w1],\REG               ; And finally read data byte
        .endm

        .macro  WR_ADDR,EA,REG
        lsr     \EA,#12,w1              ; Extract the target page number
        btst.z  M_FLAG,w1               ; And check if it is read-only
        bra     nz,0f                   ; .. Skip write if it is
        sl      w1,#2,w1                ; Map page number to DSW address
        mov     [M_BASE+w1],w0
        mov     w0,DSWPAG               ; And prepare for write
        inc2    w1,w1
        mov     [M_BASE+w1],w1          ; Fetch page offset
        and     \EA,M_MASK,w0           ; And combine with address
        add     w0,w1,w1
        cp0     DSWPAG                  ; If target DSW memory is not
        btss    SR,#Z                   ; .. in first 32K
        bset    w1,#15                  ; Then access via DSW
        mov.b   \REG,[w1]               ; And finally write data byte
0:
        .endm
