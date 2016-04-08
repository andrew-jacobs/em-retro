#===============================================================================
# Portable SC/MP Assembler Definitions
#-------------------------------------------------------------------------------
# Copyright (C)2014 HandCoded Software Ltd.
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
# $Id: Makefile 3 2014-12-13 12:58:42Z andrew $
#-------------------------------------------------------------------------------

#===============================================================================

JAVA		=	java -cp ..\..\Dev65.jar

AS		=	$(JAVA) uk.co.demon.obelisk.scmp.AsScmp

LK		=	$(JAVA) uk.co.demon.obelisk.scmp.LkScmp

LB		=	$(JAVA) uk.co.demon.obelisk.scmp.LbScmp

RM		=	erase

#===============================================================================
# Rules
#-------------------------------------------------------------------------------

.asm.obj:
		$(AS) $(AS_FLAGS) $<

