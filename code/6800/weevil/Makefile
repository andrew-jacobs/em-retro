#===============================================================================
# Weevil Boot ROM
#-------------------------------------------------------------------------------
# Copyright (C)2014-2015 HandCoded Software Ltd.
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
# 2014-11-29 AJ Initial version
#-------------------------------------------------------------------------------
# $Id: Makefile 35 2015-03-22 23:23:50Z andrew $
#-------------------------------------------------------------------------------

include ..\Makefile

#===============================================================================
# Targets
#-------------------------------------------------------------------------------

all:		weevil.bin weevil.hex

weevil.bin:	weevil.obj
		$(LK) -code $$e000-$$ffff -bss $$0100-$$1fff -bin -output $@ weevil.obj

weevil.hex:	weevil.obj
		$(LK) -code $$e000-$$ffff -bss $$0100-$$1fff -hex -output $@ weevil.obj

#===============================================================================
# Dependencies
#-------------------------------------------------------------------------------

weevil.obj:	weevil.asm
