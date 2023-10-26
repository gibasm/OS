[bits 16]

[org 0x7c00]
jmp word 0x00000:start

start:
	mov ax, 0
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax

	; source: Ralf Brown's Interrupt List
	; set video mode
	mov ah, 0x00
	; 80x25  9x14  720x350  monochromatic
	mov al, 0x07
	int 0x10
	
	jmp 0:rst_cs

rst_cs:
	mov sp, 0x9000

	push welcome_str
	call bprint

	; and loop forever for now
	jmp $-2



; bputc(al = ASCII code of the character to be printed)
bputc:
	push bx

	mov ah, 0x0e ; teletype
	mov bh, 0    ; page number
	mov bl, 0    ; foreground color
	int 0x10

	pop bx
	ret


; bprint([sp] = pointer to the null terminated string to be printed)
bprint:
	push bp
	mov bp, sp
	add bp, 4
	mov bx, [bp]

	bprint_loop:
		mov al, [bx]
		test al, al
		jz bprint_return
		call bputc
		add bx, 1
		jmp bprint_loop

	bprint_return:
		pop bp
		ret


welcome_str: db 'Booting up...', 0x0A, 0x0D, 0x00


times 510-($-$$) db 0
db 0x55
db 0xaa
