extern printf

section .data
    x: dd 1.0, 2.0, 3.0, 4.0, 5.0
    y: dd 2.0, 4.1, 6.0, 8.1, 10.2
    n: dd 5
    strc: db "a = %f, b = %f", 10, 0

section .bss
    a: resd 1
    b: resd 1

section .text
    extern printf
    global main

main:
    push rbp
    mov rbp, rsp

    lea rdi, [x]
    mov esi, [n]            ; ← CORRETO
    call Som_x
    sub rsp, 16
    movss [rsp], xmm0

    lea rdi, [x]
    mov esi, [n]
    call Som_xq
    movss xmm1, [rsp]
    add rsp, 16
    mov edi, [n]
    call Dpx
    sub rsp, 16
    movss [rsp], xmm0

    lea rdi, [y]
    mov esi, [n]
    call Som_y
    sub rsp, 16
    movss [rsp], xmm0

    lea rdi, [x]
    lea rsi, [y]
    mov edx, [n]
    call Som_xy
    sub rsp, 16
    movss [rsp], xmm0

    lea rdi, [x]
    mov esi, [n]
    call Som_x

    movss xmm1, [rsp]
    add rsp, 16
    movss xmm2, [rsp]
    add rsp, 16
    mov edi, [n]
    call Dpy

    movss xmm1, [rsp]
    add rsp, 16
    divss xmm0, xmm1
    movss [a], xmm0

    lea rdi, [x]
    mov esi, [n]
    call Som_x
    sub rsp, 16
    movss [rsp], xmm0

    lea rdi, [y]
    mov esi, [n]
    call Som_y

    movss xmm1, [rsp]
    add rsp, 16
    movss xmm2, dword [a]
    mov edi, [n]
    call alfa
    movss [b], xmm0

    ; Impressão
    cvtss2sd xmm0, [a]
    cvtss2sd xmm1, [b]
    mov rdi, strc
    mov eax, 2
    call printf


fim:
    ;destack-frame
    mov rsp, rbp
    pop rbp

    mov rax, 60
    mov rdi, 0;


;======================================================alfa======================================================

;float alfa(float sy, float b, float sx, int n)
alfa:
    push rbp
    mov rbp, rsp

    cvtsi2ss xmm3, edi
    divss xmm0, xmm3      ; média y
    divss xmm1, xmm3      ; média x
    mulss xmm1, xmm2
    subss xmm0, xmm1

    mov rsp, rbp
    pop rbp
    ret

;======================================================Dpx======================================================

;float Dpx(float sxq, float sx, int n)
Dpx: ;xmm0 = sxq, xmm1 = sx, rdi = n
    push rbp
    mov rbp, rsp

    ;passo 3 acho que não é necessário

    mulss xmm1, xmm1    ;xmm1 = (sumx)^2
    cvtsi2ss xmm2, rdi
    divss xmm1, xmm2    ;xmm1 = xmm1^2/n

    subss xmm0, xmm1      ;xmm0 = xmm0 - xmm1^2/n

    mov rsp, rbp
    pop rbp
    ret

;======================================================Dpy======================================================

;float Dpy(float sx, float sxy, float sy, int n)
Dpy:
    push rbp
    mov rbp, rsp

    ;passo 3 acho que não é necessário

    mulss xmm0, xmm2    ;xmm0 *= xmm2
    cvtsi2ss xmm2, rdi
    divss xmm0, xmm2    ;xmm0 /= n

    vsubss xmm0, xmm1, xmm0      ;xmm0 = xmm1 - xmm0

    mov rsp, rbp
    pop rbp
    ret

;======================================================somx======================================================

;float Som_x(float* x, int n)
Som_x:
    push rbp
    mov rbp, rsp

    ;passo 3 acho que não é necessário

    mov rdx, 0      ;índice do vetor
    xorps xmm0, xmm0

laco_sx:
    cmp rdx, rsi
    jge fim_sx

    addss xmm0, dword [rdi + rdx*4]  ;xmm0 += x[rdx]

    inc rdx
    jmp laco_sx

fim_sx:
    mov rsp, rbp
    pop rbp
    ret

;======================================================somxq======================================================

;float Som_xq(float* x, int n)
Som_xq:
    push rbp
    mov rbp, rsp

    ;passo 3 acho que não é necessário

    mov rdx, 0      ;índice do vetor
    xorps xmm0, xmm0

laco_sxq:
    cmp rdx, rsi
    jge fim_sxq

    movss xmm1, dword [rdi + rdx*4]
    mulss xmm1, xmm1    ;quadrado

    addss xmm0, xmm1    ;xmm0 += x[rdx]^2

    inc rdx
    jmp laco_sxq

fim_sxq:
    mov rsp, rbp
    pop rbp
    ret

;======================================================somy======================================================

;float Som_y(float* y, int n)
Som_y:
    push rbp
    mov rbp, rsp

    ;passo 3 acho que não é necessário

    mov rdx, 0      ;índice do vetor
    xorps xmm0, xmm0

laco_sy:
    cmp rdx, rsi
    jge fim_sy

    addss xmm0, dword [rdi + rdx*4]  ;xmm0 += y[rdx]

    inc rdx
    jmp laco_sy

fim_sy:
    mov rsp, rbp
    pop rbp
    ret

;======================================================somxy======================================================

;float Som_xy(float* x, float* y, int n)
Som_xy:
    push rbp
    mov rbp, rsp

    ;passo 3 acho que não é necessário

    mov rcx, 0      ;índice dos vetores
    xorps xmm0, xmm0

laco_sxy:
    cmp rcx, rdx
    jge fim_sxy

    movss xmm1, dword [rdi + rcx*4]
    mulss xmm1, dword [rsi + rcx*4] ;xmm1 = x[rcx] * y[rcx]

    addss xmm0, xmm1    ;xmm0 += x[rcx] * y[rdx]

    inc rcx
    jmp laco_sxy

fim_sxy:
    mov rsp, rbp
    pop rbp
    ret



