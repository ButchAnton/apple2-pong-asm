# Makefile for Pong

ASM = merlin32
SRC = pong.asm
OUT = PONG

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) -V . $(SRC)

clean:
	rm -f $(OUT) PONG_BOOT.dsk hello.bas

dsk: $(OUT)
	# Create bootable disk
	cp dos33mst.dsk PONG_BOOT.dsk
	# Delete existing files
	-ac -d PONG_BOOT.dsk HELLO
	-ac -d PONG_BOOT.dsk APPLESOFT
	-ac -d PONG_BOOT.dsk LOADER.OBJ0
	-ac -d PONG_BOOT.dsk FPBASIC
	-ac -d PONG_BOOT.dsk INTBASIC
	-ac -d PONG_BOOT.dsk "MASTER CREATE"
	-ac -d PONG_BOOT.dsk RENUMBER
	-ac -d PONG_BOOT.dsk COPYA
	-ac -d PONG_BOOT.dsk MASTER
	-ac -d PONG_BOOT.dsk COPY.OBJ0
	-ac -d PONG_BOOT.dsk COPY
	-ac -d PONG_BOOT.dsk CHAIN
	-ac -d PONG_BOOT.dsk FILEM
	-ac -d PONG_BOOT.dsk FID
	-ac -d PONG_BOOT.dsk CONVERT13
	-ac -d PONG_BOOT.dsk MUFFIN
	-ac -d PONG_BOOT.dsk START13
	-ac -d PONG_BOOT.dsk BOOT13
	-ac -d PONG_BOOT.dsk "SLOT#"
	# Add PONG binary
	ac -p PONG_BOOT.dsk PONG BIN 0x8000 < PONG
	# Create and add HELLO loader
	echo '10 PRINT CHR$$(4)"BRUN PONG"' > hello.bas
	ac -bas PONG_BOOT.dsk HELLO < hello.bas
	rm hello.bas
