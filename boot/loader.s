.macro  Descriptor base limit attr
    .word   \limit  & 0xFFFF
    .word   \base   & 0xFFFF
    .byte   (\base >> 16) & 0xFF
    .word   ((\limit >> 8) & 0xF00) | (\attr & 0xF0FF)
    .byte   (\base >> 24) & 0xFF
.endm

.code16
.text
jmp _start

GDT:            Descriptor  0,      0,                  0
DESC_CODE32:    Descriptor  0,      (SegCode32Len - 1), 0x4098
DESC_VODEO:     Descriptor  0xb8000, 0xffff,             0x92

.set    GdtLen, (.-GDT)
GdtPtr: .word   (GdtLen-1)      # data struct for ldgt : {2byte length; 4byte address}
        .long   0

.set    SelectorCode32, (DESC_CODE32 - GDT)     # code GDT index
.set    SelectorVideo,  (DESC_VODEO - GDT)      # video GDT index

_start:
mov     %cs,    %ax     # set ds, es, ss stack reg as cs
mov     %ax,    %ds
mov     %ax,    %es
mov     %ax,    %ss

mov     $0x100, %sp
xor     %eax,   %eax
mov     %cs,    %ax
shl     $0x4,   %eax            # get base segment offset for code
addl    $(SEG_CODE32),%eax      # get segment offset for code32
movw    %ax,    (DESC_CODE32+2) # set low 16 bit base in code GDT
shr     $0x10,  %eax
movb    %al,    (DESC_CODE32+4) # set 16~24 bit base in code GDT
movb    %ah,    (DESC_CODE32+7) # set 24~32 bit base in code GDT

xor     %eax,   %eax
mov     %ds,    %ax
shl     $0x4,   %eax
add     $(GDT), %eax
movl    %eax,   (GdtPtr+2)      # set GDT table address in GdtPr
lgdtw   GdtPtr


# enable A20
cli
inb     $0x92,  %al
orb     $0x2,   %al
outb    %al,    $0x92

movl    %cr0,   %eax
orl     $0x1,   %eax
movl    %eax,   %cr0

ljmpl   $SelectorCode32,$0x0
SEG_CODE32:
.code32
mov     $(SelectorVideo),%ax
mov     %ax,    %gs
nop
movl    $((80*10+0)*2),%edi     # line 10, row 0,
movb    $0xc,   %ah             # color
movb    $'P',   %al             # characters
mov     %ax,    %gs:(%edi)      # set color and characters in video display memory
jmp .
.set SegCode32Len, .-SEG_CODE32
