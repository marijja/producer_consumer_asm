; Implementation of busy-waiting semaphore
; by Magdalena Grodzińska

section .text:

global proberen
global verhogen

align 8

proberen:
  mov eax, dword [edi] ; check if we should fight for semaphore (no problem of semaphore constantly lower than 0)
  test eax, eax
  jle proberen

  mov eax, -1
  lock xadd [edi], eax
  
  test eax, eax
  jle sem_closed

  ret

sem_closed:
  lock inc dword [edi]
  jmp proberen

verhogen:
  lock inc dword [edi]
  ret
