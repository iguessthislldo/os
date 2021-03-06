ISO:=georgios.iso
DISK:=disk.img
USBDRIVE:=usbdrive.img

ROOT_DIR:=tmp/root
BOOT_DIR:=$(ROOT_DIR)/boot
KERNEL:=$(BOOT_DIR)/kernel.elf
ZIG?=zig
GRUB_PREFIX:=/usr
GRUB_LOCATION:=$(GRUB_PREFIX)/lib/grub/i386-pc
GRUB_CFG:=$(BOOT_DIR)/grub/grub.cfg

DEBUGGER:=gdb

zig_build_args="build"
ifdef multiboot_vbe
	zig_build_args+="-Dmultiboot_vbe=$(multiboot_vbe)"
	vbe?=$(multiboot_vbe)
endif
ifdef vbe
	zig_build_args+="-Dvbe=$(vbe)"
endif
ifdef debug_log
	zig_build_args+="-Ddebug_log=$(debug_log)"
endif
ifdef wait_for_anykey
	zig_build_args+="-Dwait_for_anykey=$(wait_for_anykey)"
endif

all: $(ISO) $(DISK) $(USBDRIVE)

.PHONY: build_georgios
build_georgios:
	python3 scripts/lint.py
	$(ZIG) $(zig_build_args)

	grub-file --is-x86-multiboot2 $(KERNEL)
	nm --print-size --numeric-sort $(KERNEL) | grep -v '__' > tmp/annotated_kernel
	objdump -S $(KERNEL) >> tmp/annotated_kernel

.PHONY: test
test:
	$(ZIG) build test

$(GRUB_CFG): misc/grub.cfg
	@mkdir -p $(dir $@)
	cp $< $(GRUB_CFG)

.PHONY: root
root: build_georgios $(GRUB_CFG)

$(ISO): root
	cp $(GRUB_PREFIX)/share/grub/unicode.pf2 $(BOOT_DIR)/grub
	grub-mkrescue --directory=$(GRUB_LOCATION) --output=$(ISO) --modules="$(GRUB_MODULES)" $(ROOT_DIR)

$(DISK): root
	rm -f $(DISK)
	mke2fs -L '' -N 0 -O none -d $(ROOT_DIR) -r 1 -t ext2 $(DISK) 20m

$(USBDRIVE): $(DISK)
	cp $(DISK) $(USBDRIVE)

.PHONY: bochs
bochs:
	bochs -q -f misc/bochs_config -rc misc/bochs_rc

.PHONY: qemu
qemu:
	$(DEBUGGER) -x misc/qemu.gdb

.PHONY: clean
clean:
	rm -fr tmp $(ISO) $(DISK) $(USBDRIVE) zig-cache
