		.nolist
;===============================================================================
;  _____ __  __      ____   ____    ____  __ ____
; | ____|  \/  |    / ___| / ___|  / /  \/  |  _ \
; |  _| | |\/| |____\___ \| |     / /| |\/| | |_) |
; | |___| |  | |_____|__) | |___ / / | |  | |  __/
; |_____|_|  |_|    |____/ \____/_/  |_|  |_|_|
;
; A National Semiconductor SC/MP Emulator
;-------------------------------------------------------------------------------
; Copyright (C)2014 HandCoded Software Ltd.
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
; $Id: em-scmp.inc 3 2014-12-13 12:58:42Z andrew $
;-------------------------------------------------------------------------------

		.list

TXD		.macro
		.byte	X'20
		.endm

RXD		.macro
		.byte	X'21
		.endm
