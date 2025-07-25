section .data
  prompt  db "Enter one char"
  map_data db "1234"
section .bss
  user_input resb 1
  active_char resb 1

section .text
  global _start

_start:
  ; syscall: write(1, message, length)
  ; Print prompt
  ;mov rax, 1      ; syscall number for write
  ;mov rdi, 1      ; stdout
  ;mov rsi, prompt  ; pointer to the message
  ;mov rdx, 14     ; message length
  ;syscall

  ; syscall: read(0, message, length)
  ; Take user input and print it.
  ;mov rax, 0      ; syscall for read
  ;mov rdi, 0      ; stdin is 0
  ;mov rsi, user_input ; save input as the user input pointer, reserved 4 bytes for this. 
  ;syscall

  ; Echo the user input back to stdout
  ;mov rax, 1
  ;mov rdi, 1
  ;mov rsi, user_input
  ;mov rdx, 1
  ;syscall

  xor rbx, rbx
  .outside_loop:
  cmp rbx, 2
  jge .done

  xor rcx, rcx
  .internal_loop:
  cmp rcx, 2
  jge .new_line
  

  mov rax, rbx
  imul rax, 2
  add rax, rcx
  mov al, [map_data + rax]
  mov [active_char], al

  mov rax, 1
  mov rdi, 1
  mov rsi, active_char
  mov rdx, 1
  syscall
  jmp .next
  
  .next:
    inc rcx
    jmp .internal_loop
  
  .new_line:
    mov rax, 1
    mov rdi, 1
    mov rsi, 0x0A
    mov rdx, 1
    syscall
    
    inc rbx
    jmp .outside_loop

  .done:

  ; syscall exit(0)
  mov rax, 60     ; syscall number for exit
  xor rdi, rdi    ; exit code 0
  syscall
