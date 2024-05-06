.PHONY: all
.PHONY: uboot
.PHONY: kernel
.PHONY: headers
.PHONY: ramdisk
.PHONY: modloop
.PHONY: sdcard

all: sdcard

uboot:
	@./uboot.sh

kernel:
	@./kernel.sh

ramdisk: uboot kernel
	@./ramdisk.sh

headers: kernel
	@./headers.sh

modloop: kernel
	@./modloop.sh

sdcard: uboot kernel ramdisk modloop
	@./sdcard.sh

.PHONY: clean
.PHONY: distclean

clean:
	@./clean.sh

distclean: clean
	@./distclean.sh
