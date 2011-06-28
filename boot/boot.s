# boot.s
# Boot sector for floppy image boot.img

.code16
.text
jmp     main
nop

# FAT12 BPB header
BS_OEMName:         .ascii  "MyOS.   "
    BytesPerSec     =       512
BPB_BytesPerSec:    .word   BytesPerSec
BPB_secPerClus:     .byte   1
    RsvdSecCnt      =       1   
BPB_RsvdSecCnt:     .word   RsvdSecCnt
    NumFATs         =       2
BPB_NumFATs:        .byte   NumFATs
    RootEntCnt      =       224
BPB_RootEntCnt:     .word   RootEntCnt
BPB_TotSec16:       .word   2880
BPB_Media:          .byte   0xf0
    FATSz16         =       9
BPB_FATSz16:        .word   FATSz16
BPB_SecPerTrk:      .word   18
BPB_NumHeads:       .word   2
BPB_HiddSeci:       .long   0
BPB_TotSec32:       .long   0
BS_DrvNum:          .byte   0
BS_Reserved1:       .byte   0
BS_BootSig:         .byte   0x29
BS_VolID:           .long   0
BS_VolLab:          .ascii  "MyOS-xecle "
BS_FilSysType:      .ascii  "FAT12   "


main:
mov     %cs,    %ax
mov     %ax,    %ds
mov     %ax,    %es
mov     $msg,   %ax
mov     $msg_l, %cx
mov     $1,     %dx   
call    print

call    search_loader
mov     $msg,   %ax
mov     $msg_l, %cx
mov     $0x0401,%dx   
call    print
cli
hlt


# Function print
# Print message store in memory %ax on screen left top, length in %cx,
# and display in line %dh colume %dl
print:
push    %bp
push    %bx
mov     %ax,    %bp
mov     $0x1301,%ax
mov     $0x07,  %bx
int     $0x10
pop     %bx
pop     %bp
ret


# Function for Read Sectors
# Read %cl sectors from %ax sector to memory %es:%bx
read_sec:
push    %ebp
mov     %esp,   %ebp
sub     $2,     %esp
mov     %cl,    -2(%ebp)
push    %bx
mov     (BPB_SecPerTrk),%bl
div     %bl
inc     %ah
mov     %ah,    %cl
mov     %al,    %dh
shr     $1,     %al
mov     %al,    %ch
and     $1,     %dh
pop     %bx
mov     (BS_DrvNum),%dl
try_read:
mov     $2,     %ah
mov     -2(%ebp),%al
int     $0x13
jc      try_read
add     $2,     %esp
pop     %ebp
ret


# Function for Search File
# Search file start sector which file name is $fname
# Return with the file fisrt clus number in %bx
search_loader:
BaseOfStack         =0x7c00
BaseOfLoader        =0x9000
OffsetOfLoader      =0x0100
RootDirSectors      =((RootEntCnt*32) + (BytesPerSec-1))/BytesPerSec
FirstSecOfRootDir   =RsvdSecCnt + NumFATs*FATSz16
push    %ebp
push    %es
mov     %esp,   %ebp
sub     $4,     %esp
movw    $RootDirSectors,-2(%ebp)
movw    $FirstSecOfRootDir,-4(%ebp)

root_search:
mov     (%ebp), %es
mov     $load,  %ax
mov     $load_l,%cx
mov     $0x01,  %dl
mov     -2(%ebp),%dh
call    print
cmpw    $0,     -2(%ebp)
jz      not_found
decw    -2(%ebp)
mov     $BaseOfLoader,%ax
mov     %ax,    %es
mov     $OffsetOfLoader,%bx
mov     -4(%ebp),%ax
mov     $0x01,  %cl
call    read_sec
mov     $BaseOfStack,%ax
mov     %ax,    %ds
mov     $0,     %dx

sec_search:
cmpw    $BytesPerSec,%dx
jl      root_search
mov     $OffsetOfLoader,%ax
add     %dx,    %ax
mov     %ax,    %di
compare:
cld
mov     $fname, %si
mov     $fname_l,%cx
repz    cmpsb
jz      found
addw    $0x20,  %dx
jmp     sec_search

not_found:
mov     (%ebp), %es
mov     $lerr,  %ax
mov     $lerr_l,%cx
mov     $0x0201,%dx
call    print
jmp     search_end

found:
mov     (%ebp), %es
push    %si
mov     $lok,  %ax
mov     $lok_l,%cx
mov     $0x0201,%dx
call    print
pop     %si
mov     0x1a(%si),%bx
search_end:
mov     %ebp,     %esp
pop     %es
pop     %ebp
ret


# Message text
msg:    .ascii  "Welcome to MyOS!"
msg_l   =.-msg
load:   .ascii  "Loading..."
load_l  =.-load
lok:   .ascii  "Loading OK!"
lok_l  =.-lok
lerr:   .ascii  "Loading faled!"
lerr_l  =.-lerr
fname:  .asciz  "LOADER  BIN"
fname_l =.-fname

.org    510
.word   0xaa55

