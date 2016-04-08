#===============================================================================
# Portable 8080 Assembler Definitions
#-------------------------------------------------------------------------------
# Copyright (C)2015-2016 HandCoded Software Ltd.
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
# 2015-11-05 AJ Initial version
#-------------------------------------------------------------------------------
# $Id$
#-------------------------------------------------------------------------------

#===============================================================================

JAVA		=	java -cp ..\..\Dev65.jar

AS		=	$(JAVA) uk.co.demon.obelisk.i8080.As8080

LK		=	$(JAVA) uk.co.demon.obelisk.i8080.Lk8080

LB		=	$(JAVA) uk.co.demon.obelisk.i8080.Lb8080

RM		=	erase

#===============================================================================
# Rules
#-------------------------------------------------------------------------------

.asm.obj:
		$(AS) $(AS_FLAGS) $<

