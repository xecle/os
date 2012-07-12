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
    SecPerTrk       =       18
BPB_SecPerTrk:      .word   SecPerTrk
BPB_NumHeads:       .word   2
BPB_HiddSeci:       .long   0
BPB_TotSec32:       .long   0
BS_DrvNum:          .byte   0
BS_Reserved1:       .byte   0
BS_BootSig:         .byte   0x29
BS_VolID:           .long   0
BS_VolLab:          .ascii  "MyOS-xecle "
BS_FilSysType:      .ascii  "FAT12   "

# loader memory 
BaseOfStack         =0x7c00
BaseOfLoader        =0x9000
OffsetOfLoader      =0x0100


main:
mov     $0x0600,%ax
mov     $0x0754,%bx
mov     $0x0000,%cx
mov     $0x194f,%dx
int     $0x10
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
mov     $0x0301,%dx   
call    print

jmp     $BaseOfLoader,$OffsetOfLoader

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
mov     $SecPerTrk,%bl
div     %bl
inc     %ah
mov     %ah,    %cl
mov     %al,    %dh
shr     $1,     %al
mov     %al,    %ch
and     $1,     %dh
pop     %bx

try_read:
mov     (BS_DrvNum),%dl
mov     $2,     %ah
mov     -2(%ebp),%al
int     $0x13
jnc     read_ok
xor     %ah,    %ah     # read error, reset and read again 
xor     %dl,    %dl
int     $0x13
jmp     try_read
read_ok:
add     $2,     %esp
pop     %ebp
ret


# Function for Search File
# Search file start sector which file name is $fname
# Return with the file fisrt clus number in %ax
search_loader:
RootDirSectors      =((RootEntCnt*32) + (BytesPerSec-1))/BytesPerSec     # 14
FirstSecOfRootDir   =RsvdSecCnt + NumFATs*FATSz16     # 19
DeltaCluster        =RootDirSectors + FirstSecOfRootDir - 2
xor     %ah,    %ah
xor     %dl,    %dl
int     $0x13
push    %ebp
push    %es
mov     %esp,   %ebp
sub     $4,     %esp
movw    $RootDirSectors,-2(%ebp)
movw    $FirstSecOfRootDir,-4(%ebp)

mov     $load,  %ax
mov     $load_l, %cx
mov     $0x0101,%dx
call    print

root_search:
mov     (%ebp), %es
cmpw    $0,     -2(%ebp)
jz      not_found

mov     $0x0e2e,%ax
int     $0x10

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
jnb      root_search
mov     $OffsetOfLoader,%ax
add     %dx,    %ax
mov     %ax,    %di
compare:
cld
mov     $fname, %si
mov     $fname_l,%cx
repz    cmpsb
jnz     found
addw    $0x20,  %dx
jmp     sec_search

not_found:
mov     (%ebp),    %es
mov     $lerr,  %ax
mov     $lerr_l,%cx
mov     $0x0201,%dx
call    print
jmp     search_end

found:
and     $0xffe0,%di
add     $0x1a,  %di
mov     %es:(%di),%ax
call    load_Loader
search_end:
mov     %ebp,     %esp
pop     %es
pop     %ebp
ret


# Function for get the cluster number of next cluster
# get the FAT entry of sector %ax
# return the next sector number in %ax
getFatEntry:
push    %es
push    %bx
push    %ax
mov     $BaseOfLoader,%ax
sub     $0x100, %ax
mov     %ax,    %es
pop     %ax
mov     $3,     %bx
mul     %bx
mov     $2,     %bx
div     %bx
push    %dx
xor     %dx,    %dx
mov     $BytesPerSec,%bx
div     %bx
push    %dx
xor     %bx,    %bx
add     $RsvdSecCnt,%ax
mov     $2,     %cl
call    read_sec
pop     %bx
add     %dx,    %bx
mov     %es:(%bx),%ax
pop     %dx
cmp     $0,     %dl
jz      lower
shr     $4,     %ax
lower:
and     $0x0fff,%ax
pop     %bx
pop     %es
ret



# load loader.bin to memory
load_Loader:
push    %ax
push    %ax
push    %bx
mov     $0x0e2e,%ax
mov     $0x0f,  %bl
int     $0x10
pop     %bx
pop     %ax

mov     $0x01,  %cl
add     $DeltaCluster,%ax
call    read_sec
pop     %ax
call    getFatEntry
cmp     $0xFFF,%ax
jz      loader_ok
push    %ax
add     $BytesPerSec,%bx
jmp     load_Loader
loader_ok:
mov     (%ebp), %es
mov     $lok,   %ax
mov     $lok_l, %cx
mov     $0x0201,%dx
call    print
ret


# print a ascii char in %al 
dis:
#push    %bx
#mov     $0x0e2e,%ax
#mov     $0x0f,  %bl
#int     $0x10
#pop     %bx


# Message text
msg:    .ascii  "Welcome !"
msg_l   =.-msg
load:   .ascii  "Loading"
load_l  =.-load
lok:   .ascii  "Load OK!"
lok_l  =.-lok
lerr:   .ascii  "Faled!"
lerr_l  =.-lerr
fname:  .asciz  "LOADER  BIN"
fname_l =.-fname

.org    510
.word   0xaa55

