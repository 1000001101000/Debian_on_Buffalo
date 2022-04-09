

CROSS_COMPILE ?= arm-linux-gnueabi-

PROG ?= armel_shim

AS  = $(CROSS_COMPILE)as
OBJ = $(CROSS_COMPILE)objcopy

#-mthumb
ASFLAGS  ?= -march=armv5
OBJFLAGS ?= -O binary

#.DEFAULT_GOAL := all

.PHONY : all
all: $(PROG)

$(PROG).o:
	$(AS) $(ASFLAGS) -o $(PROG).o $(PROG).asm

$(PROG): $(PROG).o
	$(OBJ) $(OBJFLAGS) $(PROG).o $(PROG)

clean:
	rm $(PROG).o $(PROG)
