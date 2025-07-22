section .data
  prompt db "Enter one char"

section .bss
  user_input resb 1

section .text
  global _start

_start:
  ; syscall: write(1, message, length)
  ; Print prompt
  mov rax, 1      ; syscall number for write
  mov rdi, 1      ; stdout
  mov rsi, prompt  ; pointer to the message
  mov rdx, 14     ; message length
  syscall

  ; syscall: read(0, message, length)
  ; Take user input and print it.
  mov rax, 0      ; syscall for read
  mov rdi, 0      ; stdin is 0
  mov rsi, user_input ; save input as the user input pointer, reserved 4 bytes for this. 
  syscall

  ; Echo the user input back to stdout
  mov rax, 1
  mov rdi, 1
  mov rsi, user_input
  mov rdx, 1
  syscall

  ; syscall exit(0)
  mov rax, 60     ; syscall number for exit
  xor rdi, rdi    ; exit code 0
  syscall
