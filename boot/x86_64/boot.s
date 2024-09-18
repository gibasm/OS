[bits 16]

%define ST_STAGE_ORG       0x7c00
%define ND_STAGE_ORG       0x7e00
%define ND_STAGE_SIZE      1024

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

    ; enable A20 line
    in al, 0x92
    or al, 2
    out 0x92, al

    ; set address and appropriate segment to load sectors
    mov ax, 0
    mov es, ax
    mov bx, ND_STAGE_ORG
    ; 0x0000:7e00

    ; number of sectors per 2nd stage
    mov al, (ND_STAGE_SIZE >> 9)

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
decl_min_gdt_32 pmode

align 4
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

    xor eax, eax
    cpuid
    mov dword [pmode_greeter_data], ebx
    mov dword [pmode_greeter_data+4], edx
    mov dword [pmode_greeter_data+8], ecx

    mov esi, pmode_greeter
    call bprint32

    mov eax, 0x80000001
    cpuid
    test edx, (1 << 29)
    jz no_long_mode_panic

    ; set up 4-level paging
    ; PML4T will reside at 0x1000 (512 entries up to 0x2000)
    ; PML4T[0] -> PDPT (from 0x2000 to 0x3000)
    ; PDPT[0] -> PT (from 0x3000 to 0x4000)
    ; PT[0] -> 512 pages (from 0x4000 to 0x5000)

    ; clear 0x1000 - 0x4000
    xor eax, eax
    mov edi, 0x1000
clr_paging_structs:
    mov dword [edi], eax
    add edi, 4
    cmp edi, 0x3ff8
    jne clr_paging_structs

    mov eax, 0x1000
    mov cr3, eax
    mov dword [eax], 0x2003 ; (P) (R/W) PML4T[0]
    mov eax, 0x2000
    mov dword [eax], 0x3003 ; (P) (R/W) PDPT[0]
    mov eax, 0x3000
    mov dword [eax], 0x4003 ; (P) (R/W) PDT[0]

    ; do identity mapping of 512 pages (2MB)
    mov edi, 0x4000
    mov ebx, 0x0003
    mov ecx, 512
ident_map_2MB:
    mov dword [edi], ebx
    add ebx, 0x1000
    add edi, 8
    loop ident_map_2MB

    mov eax, cr4
    or eax, 0x20 ; (PAE)
    mov cr4, eax

    ; IA32_EFER
    mov ecx, 0xC0000080
    rdmsr

    or eax, (1 << 8) ; (Long Mode Enable)
    wrmsr

    mov eax, cr0
    or eax, 1 << 31 ; PG
    mov cr0, eax

    lgdt [gdtr_lmode]
    jmp 0x08:lmode_start

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
        mov WORD [edi], ax

        add edi, 2
        inc esi
        jmp bprint32_loop

    bprint32_ret:
        pop eax
        pop edi
        pop esi
        ret

no_long_mode_panic:
    mov esi, no_lmode_str
    call bprint32
    hlt

pmode_greeter: db 'ENTERED PMODE. DETECTED CPU VENDOR', 0x3A, 0x20
pmode_greeter_data: dd 0, 0, 0, 0
no_lmode_str: db 'BOOTLADER PANIC. LONG MODE NOT SUPPORTED BY THE TARGET CPU. HALTING.', 0x00

decl_min_gdt_64 lmode

align 4
[bits 64]
lmode_start:
    cli
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    int3

    mov rdi, lmode_greeter
    call bprint64

    hlt

lmode_greeter: db 'ENTERED LMODE.', 0x00

; bprint64([rdi] - null terminated string)
bprint64:
    push rbx

    mov rbx, 0x000B8000 ; VGA base

    bprint64_loop:
        mov al, [rdi]
        cmp al, 0
        je bprint64_ret

        mov ah, 0x0F
        mov WORD [rbx], ax

        add rbx, 2
        inc rdi
        jmp bprint64_loop

    bprint64_ret:
        pop rbx
        ret
