#===============================================================================
# MOS Simulation Makefile
#-------------------------------------------------------------------------------
# Copyright (C)2010-2013 HandCoded Software Ltd.
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
# 2013-02-05 AJ Initial version
#-------------------------------------------------------------------------------
# $Id: Makefile 5 2014-12-17 13:11:09Z andrew $
#-------------------------------------------------------------------------------

include	../Makefile

#===============================================================================
# Targets
#-------------------------------------------------------------------------------

OBJS	= \
	mos.obj

all:	mos.bin

clean:
	$(RM) $(OBJS)
	$(RM) mos.bin
	$(RM) mos.lst
	$(RM) mos.map

mos.bin: $(OBJS)
	$(LK65) -bss $$0200-$$EFFF -code $$C000-$$FFFF -bin -output $@ $(OBJS)

#===============================================================================
# Dependencies
#-------------------------------------------------------------------------------

mos.obj: \
	mos.asm