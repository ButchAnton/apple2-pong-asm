# Makefile for Pong
ASM = merlin32
AC = /opt/homebrew/bin/ac
SRC = pong.asm
OUT = PONG

all: clean $(OUT) dsk

$(OUT): $(SRC)
	$(ASM) -V . $(SRC)

clean:
	rm -f $(OUT) PONG_BOOT.dsk hello.bas PONG_S01_Segment1_Output.txt \
		PONG_S01_Segment1_Output_Error.txt PONG_Symbols.txt _FileInformation.txt

dsk: $(OUT)
	# Create bootable disk
	cp dos33.dsk PONG_BOOT.dsk
	# Delete existing files
	-$(AC) -d PONG_BOOT.dsk HELLO
	# Add PONG binary
	$(AC) -p PONG_BOOT.dsk PONG BIN 0x8000 < PONG
	# Create and add HELLO loader
	echo '10 PRINT CHR$$(4)"BRUN PONG"' > hello.bas
	$(AC) -bas PONG_BOOT.dsk HELLO < hello.bas
	rm hello.bas

run: all
	osascript ./Virtual][Emulation.scpt