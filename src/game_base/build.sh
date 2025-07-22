#!/nix/store/p79bgyzmmmddi554ckwzbqlavbkw07zh-bash-5.2p37/bin/sh
nasm -f elf64 -o game.o main.asm
gcc -nostartfiles -o game game.o -lc

./game
