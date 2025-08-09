extern fprintf
extern fscanf
extern fopen
extern fclose
extern printf

section .data
    rmode: db "r", 0
    strctr: db "%f %f", 0
    pstrctr: db "Erro na abertura do arquivo. Finalizando programa.", 10, 0
    pdstrctr: db "Lidos: %f %f", 10, 0
    fout: db "resultado.txt", 0

section .bss
    x: resd 64 ;espaço pra até 64 floats
    y: resd 64 ;espaço pra até 64 floats
    a: resq 1
    b: resq 1

section .text
    global main

main:
    push rbp
    mov rbp, rsp

    call r_arquivo

    mov rax, 60
    mov rdi, 0
    syscall

r_arquivo:
    push rbp
    mov rbp, rsp

    push r12
    push r13

    sub rsp, 32
    ;stack frame caga com a pilha ent tem que pegar o parâmetro pelo rdi
    cmp rdi, 2 
    jl erro

    mov rdx, [rsi + 8]  ;rdx = filename
    mov rdi, rdx        ;passa como parâmetro
    lea rsi, [rmode]    ;modo de leitura
    xor rax, rax
    call fopen

    mov r12, rax        ;r12 = *file
    xor r13, r13        ;r13 = índice
    
    jmp laco_r

laco_r:
    xor rax, rax
    mov rdi, r12
    lea rsi, [strctr]
    lea rdx, [x + r13*4]    ;endereço de x[i]
    lea rcx, [y + r13*4]    ;endereço de y[i]
    call fscanf

    cmp rax, 2              ;rax = qtd de valores lidos
    jne  fim_r               ;se for menor que 2, na teoria leu todos

    movss xmm0, dword [x + r13*4]
    cvtss2sd xmm0, xmm0
    movss xmm1, dword [y + r13*4]
    cvtss2sd xmm1, xmm1
    mov rax, 2
    lea rdi, [pdstrctr]
    call printf

    inc r13
    cmp r13, 64
    jl laco_r


fim_r:
    mov rdi, r12
    call fclose
    jmp fim

erro:
    lea rdi, [pstrctr]
    xor rax, rax
    call printf

fim:
    add rsp, 32
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret
