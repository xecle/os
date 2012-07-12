CC = gcc
LD = ld
OBJCP = objcopy

all: boot.img

boot.img: boot.bin loader.bin
	@echo "Generate boot.img ..."
	@dd if=boot.bin of=boot.img bs=512 count=1
	@dd if=/dev/zero of=boot.img bs=512 skip=1 seek=1 count=2879

boot.bin: boot.s
	@echo "Generate boot.bin ..."
	@$(CC) -c boot.s
	@$(LD) boot.o -o boot.elf  -Ttext 0x7c00
	@$(OBJCP) -R .pdr -R .comment -R .note -S -O binary boot.elf boot.bin
	@rm boot.o boot.elf

loader.bin: loader.s
	@echo "Generate loader ..."
	@$(CC) -c loader.s
	@$(LD) loader.o -o loader.elf -Ttext 0x100
	@$(OBJCP) -R .pdr -R .comment -R .note -S -O binary loader.elf loader.bin
	@rm loader.o loader.elf

clean:
	rm -f boot.bin boot.img loader.bin
