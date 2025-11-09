FILES=boot.o boot.bin boot.elf driver.o driver.elf driver.bin
all:
	rm -rf $(FILES)
	as -g boot.s -o boot.o
	ld -g -Ttext 0x7C00 ./boot.o -o boot.elf
	objcopy -O binary ./boot.elf  boot.bin
	as -g driver.s -o driver.o 
	ld -g -Ttext 0x7E00 driver.o -o driver.elf
	objcopy -O binary driver.elf driver.bin
	dd if=./driver.bin >> boot.bin
	dd if=./bzImage >> boot.bin
	qemu-system-x86_64 -m 2048M -hda ./boot.bin -hdb ./rootfs.cpio -display none -serial stdio

clean:
	rm -rf $(FILES)

