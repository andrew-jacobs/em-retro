#===============================================================================
# Forth - Build Rules
#-------------------------------------------------------------------------------
# Copyright (C)2016 HandCoded Software Ltd.
# All rights reserved.
#
# This work is made available under the terms of the Creative Commons
# Attribution-NonCommercial 2.0 license. Open the following URL to see the
# details.
#
# http://creativecommons.org/licenses/by-nc/2.0/
#-------------------------------------------------------------------------------
#
# Notes:
#
#
#
#===============================================================================
# Revision History:
#
# 2016-09-13 AJ Initial version
#-------------------------------------------------------------------------------

include ..\Makefile

#===============================================================================
# Targets
#-------------------------------------------------------------------------------

all:		forth.bin

forth.bin:	forth.obj
		$(LK) -code $$c000-$$dfff -bss $$1000-$$1fff -bin -output $@ forth.obj

#===============================================================================
# Dependencies
#-------------------------------------------------------------------------------

forth.obj:	forth.asm
