# NSAK

[![made-with-nasm](https://img.shields.io/badge/Made%20with-NASM-0095D5.svg)](https://www.nasm.us/) [![GitHub release](https://img.shields.io/github/release/GitDanyaUser/NSAK.svg)](https://GitHub.com/GitDanyaUser/NSAK/)

A hobby operating system written in x86 Assembly.

## About

NSAK stands for **Not So Amazing Kernel**.

It started as a project to learn how operating systems work from the ground up. Everything is written from scratch including the Assembler

Maybe one day it will deserve to be called **AK**. Who knows?

## Features

- Two stage bootloader
- Boots from ISO9660
- 32-bit Protected Mode
- Loads the kernel at 1 MB
- VGA text mode
- Written in x86 Assembly
- No GRUB

## Screenshots

Coming soon!

## Roadmap

- [x] Bootloader
- [x] ISO9660 loader
- [x] Protected Mode
- [x] Basic kernel
- [ ] IDT
- [ ] Keyboard
- [ ] Memory manager
- [ ] Paging
- [ ] Shell
- [ ] FAT support

## Build

You'll need:

- NASM
- xorriso
- QEMU or another emulator

## Run

Grab a blank CD and make your optical drive useful again

If you don't have one anymore, an emulator works just fine

## Contributing

Pull requests are welcome

If you find a bug or have an idea feel free to open an issue

## License

GPL-3.0 License
