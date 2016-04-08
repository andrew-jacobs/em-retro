		.nolist
;===============================================================================
;  _____ __  __        __    ___   ___   ___
; | ____|  \/  |      / /_  ( _ ) / _ \ / _ \
; |  _| | |\/| |_____| '_ \ / _ \| | | | | | |
; | |___| |  | |_____| (_) | (_) | |_| | |_| |
; |_____|_|  |_|      \___/ \___/ \___/ \___/
;
; A Motorola 6800 Emulator
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
; 2015-01-04 AJ Initial version
;-------------------------------------------------------------------------------
; $Id$
;-------------------------------------------------------------------------------

		.list

CMD_NOP		.equ	$00
CMD_RXD		.equ	$01
CMD_RXD_COUNT	.equ	$02
CMD_TXD		.equ	$03
CMD_TXD_COUNT	.equ	$04
CMD_SPI_LO	.equ	$05
CMD_SPI_HI	.equ	$06
CMD_SPI		.equ	$07


SYS_CMDA	.macro	CMD
		.byte	$8F,CMD
		.endm
		
SYS_CMDB	.macro	CMD
		.byte	$CF,CMD
		.endm
