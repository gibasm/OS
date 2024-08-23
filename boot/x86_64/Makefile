NASM:=nasm

all: boot.s
	cat boot.bin > img.bin

.PHONY: boot.s
boot.s:
	$(NASM) boot.s -o boot.bin
