# Makefile for ATmegaBOOT
# E.Lins, 18.7.2005
# $Id$

# Instructions
#
# To build the bootloader for the WASP:
# make wasp
#
# To build the bootloader for the Diecimila:
# make diecimila
#
# To build the bootloader for the NG/Mini:
# make ng
#
# To burn the bootloader:
# make TARGET=wasp isp
# make TARGET=diecimila isp
# make TARGET=ng isp

# bootloader revision
#BOOT_REV = 000

# program name should not be changed...
#PROGRAM    = waspmotePRO-bootloader-v$(BOOT_REV)
PROGRAM    = waspmotePRO-bootloader

# enter the target CPU frequency
#AVR_FREQ   = 8000000L
AVR_FREQ =   14745600L

# enter the parameters for the avrdude isp tool
#ISPTOOL	   = stk500v2
ISPTOOL	   = avrispmkII
ISPPORT	   = usb
ISPSPEED   = -b 115200

#MCU_TARGET = atmega168
#LDSECTION  = --section-start=.text=0x3800

MCU_TARGET = atmega1281
LDSECTION  = --section-start=.text=0x1E000
PRODUCT = WASP1281

# the efuse should really be 0xf8; since, however, only the lower
# three bits of that byte are used on the atmega168, avrdude gets
# confused if you specify 1's for the higher bits, see:
# http://tinker.it/now/2007/02/24/the-tale-of-avrdude-atmega168-and-extended-bits-fuses/
#
# similarly, the lock bits should be 0xff instead of 0x3f (to
# unlock the bootloader section) and 0xcf instead of 0x0f (to
# lock it), but since the high two bits of the lock byte are
# unused, avrdude would get confused.
#ISPFUSES    = avrdude -c $(ISPTOOL) -p m1280 -P $(ISPPORT) $(ISPSPEED) -e -u -U lock:w:0x3f:m -U efuse:w:0x00:m -U hfuse:w:0xdd:m -U lfuse:w:0xff:m
#ISPFLASH    = avrdude -c $(ISPTOOL) -p m1280 -P $(ISPPORT) $(ISPSPEED) -U flash:w:$(PROGRAM)_$(TARGET).hex -U lock:w:0x0f:m
ISPFUSES    = avrdude -c $(ISPTOOL) -p m1281 -P $(ISPPORT) $(ISPSPEED) -e -u -U efuse:w:0xF5:m -U hfuse:w:0xD0:m -U lfuse:w:0xDF:m
ISPFLASH    = avrdude -c $(ISPTOOL) -p m1281 -P $(ISPPORT) $(ISPSPEED) -U flash:w:$(PROGRAM).hex


OBJ        = $(PROGRAM).o
OPTIMIZE   = -O2

DEFS       = 
LIBS       = 

CC         = avr-gcc


# Override is only needed by avr-lib build system.

override CFLAGS        = -g -Wall $(OPTIMIZE) -mmcu=$(MCU_TARGET) -DF_CPU=$(AVR_FREQ) $(DEFS)
override LDFLAGS       = -Wl,$(LDSECTION)
#override LDFLAGS       = -Wl,-Map,$(PROGRAM).map,$(LDSECTION)

OBJCOPY        = avr-objcopy
OBJDUMP        = avr-objdump

all:

wasp: TARGET = wasp
wasp: CFLAGS += '-DMAX_TIME_COUNT=F_CPU>>4' '-DNUM_LED_FLASHES=4' '-D$(PRODUCT)'
wasp: $(PROGRAM).hex

#diecimila: TARGET = diecimila
#diecimila: CFLAGS += '-DMAX_TIME_COUNT=F_CPU>>4' '-DNUM_LED_FLASHES=1' 
#diecimila: $(PROGRAM)_diecimila.hex

#ng: TARGET = ng
#ng: CFLAGS += '-DMAX_TIME_COUNT=F_CPU>>1' '-DNUM_LED_FLASHES=3'
#ng: $(PROGRAM)_ng.hex

#isp: $(PROGRAM)_$(TARGET).hex
isp: $(PROGRAM).hex
	$(ISPFUSES)
	$(ISPFLASH)

%.elf: $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	rm -rf *.o *.elf *.lst *.map *.sym *.lss *.eep *.srec *.bin *.hex

%.lst: %.elf
	$(OBJDUMP) -h -S $< > $@

%.hex: %.elf
	$(OBJCOPY) -j .text -j .data -O ihex $< $@

%.srec: %.elf
	$(OBJCOPY) -j .text -j .data -O srec $< $@

%.bin: %.elf
	$(OBJCOPY) -j .text -j .data -O binary $< $@
