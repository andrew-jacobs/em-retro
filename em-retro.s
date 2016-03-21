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
; $Id: em-retro.s 49 2015-07-15 16:47:53Z andrew $
;-------------------------------------------------------------------------------

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

        .section .nbss,bss,near
        .global MEMORY_MAP
MEMORY_MAP:
        .space  16 * 4                  ; 16 pairs of DSR page and offset values

;-------------------------------------------------------------------------------

        .section .ram,bss,align(0x1000)
        .global RAM1
        .global RAM2
        .global RAM3
        .global RAM4
        .global RAM5
        .global RAM6

RAM1:   .space  4096
RAM2:   .space  4096
RAM3:   .space  4096
RAM4:   .space  4096
RAM5:   .space  4096
RAM6:   .space  4096

        .section .eds,bss,eds,address(0x08000)
        .global RAM7
        .global RAM8
        .global RAM9
        .global RAMA
        .global RAMB
RAM7:   .space  4096
RAM8:   .space  4096
RAM9:   .space  4096
RAMA:   .space  4096
RAMB:   .space  4096

;===============================================================================
; Blank ROM
;-------------------------------------------------------------------------------
; A 4K block of zeros used to fill reserved areas in device memory blocks.

        .section .blank_page,code,align(0x1000)
        .global BLANK
BLANK:
        .rept   4 * 1024 / 8
        .byte   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
        .endr
	
        .end
