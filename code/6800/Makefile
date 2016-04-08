#===============================================================================
# Portable 6800 Assembler Definitions
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
# 2014-11-05 AJ Initial version
#-------------------------------------------------------------------------------
# $Id: Makefile 10 2015-01-07 16:27:59Z andrew $
#-------------------------------------------------------------------------------

#===============================================================================

JAVA		=	java -cp ..\..\Dev65.jar

AS		=	$(JAVA) uk.co.demon.obelisk.m6800.As6800

LK		=	$(JAVA) uk.co.demon.obelisk.m6800.Lk6800

LB		=	$(JAVA) uk.co.demon.obelisk.m6800.Lb6800

RM		=	erase

#===============================================================================
# Rules
#-------------------------------------------------------------------------------

.asm.obj:
		$(AS) $(AS_FLAGS) $<

