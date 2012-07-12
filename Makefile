#
#
MAKE= make
#SUBDIRS=`ls -d */ | grep -v bin | grep -v lib | grep -v include`

SUBDIRS= boot
		
define make_subdir
	@for subdir in $(SUBDIRS) ; do \
		($(MAKE) -C $$subdir $1) \
	done;
endef

all:
	$(call make_subdir, all)
	$(info "Copy all things to boot.img")
	@mkdir floppy
	@sudo mount -t msdos -o loop boot/boot.img floppy/
	@-sudo cp boot/loader.bin floppy/
	@sync
	@sudo umount floppy/
	@rmdir floppy

clean:
	$(call make_subdir, clean)
	@rm -rf floppy/
