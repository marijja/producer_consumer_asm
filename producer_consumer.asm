; Implementation of producer - consumer problem for 1 producer, 1 consumer and fixed-size buffer_size
; Written in assembly 86-x64
; by Magdalena Grodzińska

section .bss
  buffer_size: resq 1
  N: resq 1
  buffer: resq 1
  sem_taken: resd 1
  sem_free: resd 1
  p: resq 1
  it_c: resq 1
  it_p: resq 1

section .text

global init
global producer
global consumer

extern proberen
extern verhogen
extern produce
extern consume
extern malloc

align 8

init:
  cmp rdi, 0x7FFFFFFF ; check if given N is greater than 2^31 -1
  ja case_1

  xor edx, edx ; check if given N is equal to 0
  test rdi, rdi
  jz case_2

  mov dword [sem_free], edi
  mov dword [sem_taken], 0
  mov qword [it_c], 0
  mov qword [it_p], 0
  imul rdi, 8
  mov qword [N], rdi
  call malloc ; call malloc to allocate the memory

  test rax, rax ; check if malloc returned 0
  je case_3

  mov qword [buffer], rax ; success - assign value to buffer variable and return 0
  xor rax, rax
  ret

  case_1: ; -1 when N > 2^{31} - 1
    mov rax, -1
    ret

  case_2: ; -2 when N = 0
    mov rax, -2
    ret

  case_3: ; -3 when memory allocation failed
    mov rax, -3
    ret

producer:
  mov rsi, 0 ; this is iterator over buffer

  p_loop_begin:
    mov rdi, p
    call produce

    test rax, rax ; if producer didn't produce anything he returns 0 and loop ends
    jz exit

    mov rdi, sem_free
    call proberen ; wait on semaphore if there is no free space

    mov rdx, [buffer]
    mov rdi, [p]
    mov rsi, [it_p]
    mov qword [rdx + rsi], rdi ; write to buffer

    mov rdi, sem_taken
    call verhogen ; lift semaphore for consumers

    mov rdi, qword [it_p]
    add rdi, 8
    mov qword [it_p], rdi
    cmp rdi, [N]
    jl p_loop_begin
    mov qword[it_p], 0

    jmp p_loop_begin

consumer:
  mov rsi, 0 ; this is iterator over buffer

  c_loop_begin:
    mov rdi, sem_taken
    call proberen ; wait on semaphore if there are no filled cells in buffer

    mov rdx, [buffer]
    mov rsi, [it_c]
    mov rcx, qword [rdx + rsi] ; read portion from buffer

    mov rdi, sem_free
    call verhogen ; lift semaphore for producers

    mov rdi, rcx
    call consume ; consume portion

    test rax, rax ; if portion not consumed, function returns zero and loop quits
    jz exit

    mov rdi, qword [it_c]
    add rdi, 8
    mov qword [it_c], rdi
    cmp rdi, [N]
    jl c_loop_begin
    mov qword[it_c], 0

    jmp c_loop_begin

increment_iterator: ; increments buffer iterator mod N
  mov rax, 0
  ret

exit:
  ret
