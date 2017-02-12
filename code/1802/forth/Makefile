#===============================================================================
# CDP 1802 ANS Forth
#-------------------------------------------------------------------------------
# Copyright (C)2015 HandCoded Software Ltd.
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
# 2015-03-14 AJ Initial version
#-------------------------------------------------------------------------------
# $Id$
#-------------------------------------------------------------------------------

include	../Makefile

#===============================================================================
# Targets
#-------------------------------------------------------------------------------

OBJS	= \
	forth.obj

all:	forth.bin

clean:
	$(RM) $(OBJS)
	$(RM) forth.bin
	$(RM) forth.lst
	$(RM) forth.map

forth.bin: $(OBJS)
	$(LK1802) -bss $$2000-$$EFFF -code $$0000-$$1FFF -bin -output $@ $(OBJS)

#===============================================================================
# Dependencies
#-------------------------------------------------------------------------------

forth.obj: \
	forth.asm ..\em-1802.inc