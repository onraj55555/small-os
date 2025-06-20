all:
	$(MAKE) make_fat16_file
	$(MAKE) -C bootloader/stage1
	$(MAKE) inject_stage1
	$(MAKE) inject_stage2

make_fat16_file:
	dd if=/dev/zero of=disk bs=1M count=32
	mkfs.fat -F16 -n LABEL disk

inject_stage1:
	dd if=bootloader/stage1/stage1.bin of=disk bs=512 count=1 conv=notrunc

inject_stage2:
	mcopy -i disk bootloader/stage2/test.txt ::

launch:
	qemu-system-x86_64 -drive format=raw,file=disk

clean:
	rm disk bootloader/stage1/stage1.bin

monitor:
	qemu-system-x86_64 -drive format=raw,file=disk -s -S -monitor stdio