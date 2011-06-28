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

clean:
	$(call make_subdir, clean)
