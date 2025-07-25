extern tcgetattr
extern tcsetattr
extern read
extern write
extern exit

section .data
  map_size    equ 40
  fd_stdin    equ 0
  TCSANOW     equ 0
  buf_size    equ 1
  ;message     db "[Alex]: This is where it happened. My life's work... gone in a flash drive."
  ;message_len equ $ - message

  buf_len     db 1
  buffer      db 0
  buf         db 0
  line_buf    db 0
  line_len    db 0
  player_x    db 0
  player_y    db 0
  clear_seq   db 0x1B, '[', '2', 'J', 0x1B, '[', 'H'
  clear_seq_len equ $ - clear_seq
  welcome_msg db "Welcome to my game!"
  welcome_msg_len equ $ - welcome_msg
  
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

print_buf:
  mov rax, 1
  mov rdi, 1
  mov rsi, buf
  movzx rdx, byte [buf_len]
  syscall

  ret

read_input:
  mov rax, 0
  mov rdi, 0
  mov rsi, buffer
  mov rdx, 1
  syscall

  ret

clear_screen:
  mov rax, 1
  mov rdi, 1
  mov rsi, clear_seq
  mov rdx, clear_seq_len
  syscall
  ret


; Build map functions
print_dot: 
  mov byte [buf], "."
  mov byte [buf_len], 1
  call print_buf
  ret

print_newline:
  mov byte [buf], 0x0A
  mov byte [buf_len], 1
  call print_buf
  ret


fill_line:
  movzx rcx, byte [line_len]
  sub rcx, 2

  .loop:
    push rcx
    mov rax, 1
    mov rdi, 1 
    mov rsi, line_buf
    mov rdx, 1
    syscall
    pop rcx 
    loop .loop
  
  .done:
    ret

print_player:
  mov byte [buf], "@"
  mov byte [buf_len], 1
  call print_buf
  ret

print_map:
  mov rbx, 0                ; rbx = current row (Y)

  .row_loop:
    cmp rbx, map_size
    jge .done                 ; if row >= 10, exit

    mov rcx, 0                ; rcx = current column (X)

    .column_loop:
      cmp rcx, map_size
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

;    mov byte [message_len], 76 
;    mov byte [message], "[Alex]: This is where it happened. My life's work... gone in a flash drive."
    call message_box
    ret

; Update the player_x and player_y variables based on the read_input function
movement: 
  call read_input
 
  mov al, [buffer]

  cmp al, 'w'
  je .move_up

  cmp al, 's'
  je .move_down

  cmp al, 'a'
  je .move_left

  cmp al, 'd'
  je .move_right

  jmp .done

  .move_up:
    dec byte [player_y]
    cmp byte [player_y], -1
    je .fail_up
    
    jmp .done

  .move_down:
    inc byte [player_y]
    cmp byte [player_y], map_size
    je .fail_down

    jmp .done

  .move_left:
    dec byte [player_x]
    cmp byte [player_x], -1
    je .fail_left

    jmp .done

  .move_right:
    inc byte [player_x]
    cmp byte [player_x], map_size
    je .fail_right

    jmp .done

  .fail_up:
    inc byte [player_y]
    jmp .done

  .fail_down:
    dec byte [player_y]
    jmp .done
  
  .fail_left:
    inc byte [player_x]
    jmp .done

  .fail_right:
    dec byte [player_x]
    jmp .done

  .done:
    ret

message_box:
  ; Print top line of the message box
  ; print top left slash
  mov byte [buf], "/"
  mov byte [buf_len], 1
  call print_buf
  
  ; Print the whole line of dashes
  mov byte [line_buf], "-"
  mov byte [line_len], map_size
  call fill_line

  ; Print top right corner
  mov byte [buf], "\"
  mov byte [buf_len], 1
  call print_buf

  ; Make a new line
  call print_newline

  ; Print new left vertical marker
  mov byte [buf], "|"
  mov byte [buf_len], 1
  call print_buf
 
  ; Print an empty line to give extra spacing 
  ; between the text and top bar
  mov byte [line_buf], " "
  call fill_line
  
  ; Print the right vertical marker
  mov byte [buf], "|"
  mov byte [buf_len], 1
  call print_buf
  
  ; Make new line
  call print_newline
  
  ; Make left marker
  mov byte [buf], "|"
  mov byte [buf_len], 1
  call print_buf 
 
  ; Print the text and the following whitespace to 
  ; make sure the walls on the box line up
  ; Print the text
  mov rax, 1
  mov rdi, 1
  mov rsi, welcome_msg
  mov rdx, welcome_msg_len
  syscall
  ; Calculate the length of spaces, map size - the length of the message
  mov r9, map_size
  sub r9, welcome_msg_len
  mov byte [line_len], r9b
  mov byte [line_buf], " "

  ; Fill the line with space
  call fill_line

  ; Draw right marker
  mov byte [buf], "|"
  mov byte [buf_len], 1
  call print_buf

  ret

_start: 
  ; Get current terminal settings
  mov rdi, fd_stdin
  mov rsi, termios_old
  call tcgetattr

  ; Remove the need for enter and the echoing of keys
  call change_terminal_settings

  ; Main game loop
  .game_loop:
    ; Clear screen
    call clear_screen
  
    ; Build the first map
    call print_map
    call movement
    jmp .game_loop 

  ; Restore terminal settings
  mov rdi, fd_stdin
  mov rsi, TCSANOW
  mov rdx, termios_old
  call tcsetattr

  mov rax, 60
  xor rdi, rdi
  syscall

