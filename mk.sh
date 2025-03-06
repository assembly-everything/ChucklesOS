# Create disk image
dd if=/dev/zero of=chucklesos-hda.img bs=512 count=2880

# Compile all files
nasm -f bin boot.s -o boot.bin
nasm -f bin cmd1.s -o cmd1.bin
nasm -f bin cmd2.s -o cmd2.bin
nasm -f bin cmd3.s -o cmd3.bin
nasm -f bin cmd4.s -o cmd4.bin
nasm -f bin cmd5.s -o cmd5.bin
nasm -f bin cmd6.s -o cmd6.bin

# Write them to the disk image
dd if=boot.bin of=chucklesos-hda.img bs=512 count=1 conv=notrunc
dd if=cmd1.bin of=chucklesos-hda.img bs=512 seek=1 count=1 conv=notrunc
dd if=cmd2.bin of=chucklesos-hda.img bs=512 seek=2 count=1 conv=notrunc
dd if=cmd3.bin of=chucklesos-hda.img bs=512 seek=3 count=1 conv=notrunc
dd if=cmd4.bin of=chucklesos-hda.img bs=512 seek=4 count=1 conv=notrunc
dd if=cmd5.bin of=chucklesos-hda.img bs=512 seek=5 count=1 conv=notrunc
dd if=cmd6.bin of=chucklesos-hda.img bs=512 seek=6 count=1 conv=notrunc

# Test in QEMU
qemu-system-i386 -hda chucklesos-hda.img
