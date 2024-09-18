; ref: Intel SDM vol. 3, 3.4.5 Segment Descriptors
; %1 - BASE
; %2 - LIMIT
; %3 - L
; %4 - D/B
; %5 - DPL
; %6 - G
; %7 - P
; %8 - S
; %9 - TYPE
; %10 - AVL
%macro segdesc 10
    dw (%2 & 0xFFFF), (%1 & 0xFFFF)
    db (%1 >> 16), ((%7 << 7) | (%5 << 5) | (%8 << 4) | %9)
    db ((%2 >> 16) & 0xF) | (%10 << 4) | (%3 << 5) | (%4 << 6) | (%6 << 7)
    db ((%1 >> 24) & 0xFF)
%endmacro

; declare minimal GDT for flat memory model
; %1 - GDT name (str)
%macro decl_min_gdt_32 1
    align 4
    gdt_%1:               ; base   limit    L  D/B DPL  G   P   S     TYPE AVL
                 segdesc 0,     0,          0,  0,  0,  0,  0,  0,      0,  0 ;      off=0
                 segdesc 0,     0xFFFFF,    0,  1,  0,  1,  1,  1,     10,  0 ; R/X, off=8  <code>
                 segdesc 0,     0xFFFFF,    0,  1,  0,  1,  1,  1,      2,  0 ; R/W, off=16 <data>

    gdtr_%1:
        dw gdtr_%1 - gdt_%1
        dd gdt_%1
%endmacro

%macro decl_min_gdt_64 1
    align 4
    gdt_%1:               ; base   limit    L  D/B DPL  G   P   S     TYPE AVL
                 segdesc 0,     0,          0,  0,  0,  0,  0,  0,      0,  0 ;      off=0
                 segdesc 0,     0xFFFFF,    1,  1,  0,  1,  1,  1,     10,  0 ; R/X, off=8  <code>
                 segdesc 0,     0xFFFFF,    1,  1,  0,  1,  1,  1,      2,  0 ; R/W, off=16 <data>

    gdtr_%1:
        dw gdtr_%1 - gdt_%1
        dd gdt_%1
%endmacro
