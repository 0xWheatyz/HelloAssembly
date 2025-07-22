section .data
  hello db "Hello, World!", 0x0A  ; Message followed by a newline

section .text
  global _start

_start:
  ; syscall: write(1, messagem length)
  mov rax, 1      ; syscall number for write
  mov rdi, 1      ; stdout
  mov rsi, hello  ; pointer to the message
  mov rdx, 14     ; message length
  syscall

  ; syscall exit(0)
  mov rax, 60     ; syscall number for exit
  xor rdi, rdi    ; exit code 0
  syscall
