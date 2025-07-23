extern tcgetattr
extern tcsetattr
extern read
extern write
extern exit

section .data
  fd_stdin    equ 0
  TCSANOW     equ 0
  question_len db 1
  buf_size    equ 1
  buffer      db 0
  question    db 0
  player_x    db 3
  player_y    db 2

section .bss
  termios_old resb 60
  termios_new resb 60

section .text
  global _start

change_terminal_settings:
  push rcx
  mov rcx, 60
.copy:
  mov al, [termios_old + rcx - 1]
  mov [termios_new + rcx - 1], al
  loop .copy

  ; Modify new settings: disable ICANON and ECHO
  ; termios structure offset 12 (c_lflag) is where we change flags
  ; c_lflag is 8 bytes (for 64-bit)
  ; So we clear ICANON (0x2) and ECHO (0x8)
  mov rax, [termios_new + 12]
  and rax, ~0x0A       ; ~(ICANON | ECHO)
  mov [termios_new + 12], rax

  ; Apply new settings
  mov rdi, fd_stdin
  mov rsi, TCSANOW
  mov rdx, termios_new
  call tcsetattr

  pop rcx
  ret

print_question:
  mov rax, 1
  mov rdi, 1
  mov rsi, question
  movzx rdx, byte [question_len]
  syscall

  ret

read_input:
  mov rax, 0
  mov rdi, 0
  mov rsi, buffer
  mov rdx, 1
  syscall

  ret

; Build map functions
print_dot: 
  mov byte [question], "."
  mov byte [question_len], 1
  call print_question
  ret

print_newline:
  mov byte [question], 0x0A
  mov byte [question_len], 1
  call print_question
  ret

print_player:
  mov byte [question], "@"
  mov byte [question_len], 1
  call print_question
  ret

print_map:
  mov rbx, 0                ; rbx = current row (Y)

  .row_loop:
    cmp rbx, 10
    jge .done                 ; if row >= 10, exit

    mov rcx, 0                ; rcx = current column (X)

    .column_loop:
      cmp rcx, 40
      jge .end_row              ; if col >= 10, go to newline
      
      push rcx

        ; Load player_x and compare to current column (rcx)
      mov al, [player_x]
      cmp cl, al
      jne .not_player

      ; Compare row (rbx) to player_y
      mov al, [player_y]
      mov dl, bl
      cmp dl, al
      jne .not_player

      ; Both match — draw player
      call print_player
      pop rcx
      jmp .next_column

  .not_player:
    call print_dot
    pop rcx
    jmp .next_column

  .next_column:
    inc rcx
    jmp .column_loop

  .end_row:
    call print_newline
    inc rbx
    jmp .row_loop

  .done:
    ret


_start: 
  ; Get current terminal settings
  mov rdi, fd_stdin
  mov rsi, termios_old
  call tcgetattr

  ; Remove the need for enter and the echoing of keys
  call change_terminal_settings

  ; Build the first map
  call print_map

  ; Restore terminal settings
  mov rdi, fd_stdin
  mov rsi, TCSANOW
  mov rdx, termios_old
  call tcsetattr

  mov rax, 60
  xor rdi, rdi
  syscall



