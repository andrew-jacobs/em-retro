;===============================================================================
;  _____ __  __       ____      _
; | ____|  \/  |     |  _ \ ___| |_ _ __ ___
; |  _| | |\/| |_____| |_) / _ \ __| '__/ _ \
; | |___| |  | |_____|  _ <  __/ |_| | | (_) |
; |_____|_|  |_|     |_| \_\___|\__|_|  \___/
;
; Common Emulator Definitions
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
; 2014-10-11 AJ Initial version
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
