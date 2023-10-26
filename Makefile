NASM:=nasm	

all: stage1 
	cat stage1 > img.bin
	
.PHONY: stage1
stage1:
	$(NASM) boot.s -o stage1
