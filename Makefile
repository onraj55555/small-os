all:
	$(MAKE) make_fat16_file
	$(MAKE) -C bootloader/stage1
	$(MAKE) inject_stage1
	$(MAKE) launch

make_fat16_file:
	dd if=/dev/zero of=disk bs=1M count=32

inject_stage1:
	dd if=bootloader/stage1/stage1.bin of=disk bs=512 count=1

launch:
	qemu-system-i386 -drive format=raw,file=disk

clean:
	rm disk bootloader/stage1/stage1.bin