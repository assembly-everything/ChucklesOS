### ChucklesOS is a micro-OS for any x86 system. It has multiple commands, and more to be added eventually.
Current Release: None

Current Build: B7

# How it works

Basiclly all it does is boot into a shell, all stored into the boot loader. Then it loads the required sectors and accepts input. It checks if your input matches any commands in the loaded sectors.
If it maches it runs, otherwise it throws back "Unknown Command". As indicated by the .s files, this is written in assembly, and compilation is done easily with the shell file.

It doesn't do much right now, but there are multiple image files for multiple floppy disk images, up to 2.88MB.
