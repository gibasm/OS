[bits 16]

%define ST_STAGE_ORG       0x7c00
%define ND_STAGE_ORG       0x7e00
%define ND_STAGE_SIZE      (nd_stage_end - ND_STAGE_ORG)

[org ST_STAGE_ORG]
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

    ; set address and appropriate segment to load sectors
    mov ax, 0
    mov es, ax
    mov bx, ND_STAGE_ORG
    ; 0x0000:7e00

    ; compute number of sectors per 2nd stage
    mov al, ND_STAGE_SIZE
    shr al, 9
    inc al

    ; load 2nd stage
    mov ah, 0x02
    mov ch, 0
    mov cl, 2
    mov dh, 0

    int 0x13

    jc bpanic

    jmp nd_stage_start

bpanic:
    push panic_str
    call bprint
    ; loop forever
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
panic_str: db 'Bootloader failure', 0x0A, 0x0D, 0x00

times 510-($-$$) db 0
db 0x55
db 0xaa

nd_stage_start:
    push stage2_success
    call bprint

    mov ax, 0x0003      ; set VGA mode to 80x25 text mode (mode 3)
    int 0x10            ; BIOS video interrupt
    
    cli

    lgdt [gdtr_pmode]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 0x08:pmode_start

stage2_success: db 'Entering 2nd stage', 0x0A, 0x0D, 0x00

%include "gdt.s"
decl_min_gdt pmode

align 32
[bits 32]
pmode_start:
    ; setup segment regs
    mov ax, 0x10 ; data seg offset
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000
    mov esp, ebp

    mov esi, pmode_str
    call bprint32

    hlt

; bprint32([esi] = null terminated str)
bprint32:
    push esi
    push edi
    push eax

    mov edi, 0x000B8000 ; VGA base

    bprint32_loop:
        mov al, [esi]
        cmp al, 0
        je bprint32_ret

        mov ah, 0x0F
        stosw

        add edi, 2
        inc esi
        jmp bprint32_loop

    bprint32_ret:
        pop eax
        pop edi
        pop esi
        ret

pmode_str: db 'ENTERED PMODE...', 0x00

nd_stage_end:
