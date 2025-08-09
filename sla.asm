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

    call r_arquivo  ; chama a função que abre e lê o arquivo

    mov rax, 60  ; chama a função que abre e lê o arquivo
    mov rdi, 0 ; exit code 0
    syscall

r_arquivo:
    push rbp
    mov rbp, rsp

    push r12 ; salvar r12 (callee-saved)
    push r13 ; salvar r13 (callee-saved)

    sub rsp, 32 ; salvar r12 (callee-saved)
    ;stack frame caga com a pilha ent tem que pegar o parâmetro pelo rdi
    cmp rdi, 2  
    jl erro ; exige argc >= 2 (programa + 1 argumento)

    mov rdx, [rsi + 8]  ;rdx = filename
    mov rdi, rdx        ;passa como parâmetro
    lea rsi, [rmode]    ;modo de leitura
    xor rax, rax
    call fopen ; FILE *fopen(const char *filename, const char *mode)

    mov r12, rax        ;r12 = *file
    xor r13, r13        ;r13 = índice
    
    jmp laco_r

laco_r:
    xor rax, rax
    mov rdi, r12 ; primeiro parâmetro de fscanf: FILE*
    lea rsi, [strctr] ; formato "%f %f"
    lea rdx, [x + r13*4]    ;endereço de x[i]
    lea rcx, [y + r13*4]    ;endereço de y[i]
    call fscanf ; fscanf(file, "%f %f", &x[i], &y[i])

    cmp rax, 2              ;rax = qtd de valores lidos
    jne  fim_r               ;se for menor que 2, na teoria leu todos

    movss xmm0, dword [x + r13*4] ; carrega float x[i] em xmm0
    cvtss2sd xmm0, xmm0 ; converte float->double (printf espera double nos xmm)
    movss xmm1, dword [y + r13*4]
    cvtss2sd xmm1, xmm1

    mov rax, 2 ; <-- intenção: informar nº de XMM usados
    lea rdi, [pdstrctr] ; fmt para printf: "Lidos: %f %f"
    call printf ; fmt para printf: "Lidos: %f %f"

    inc r13 ; i++
    cmp r13, 64
    jl laco_r ; i++


fim_r:
    mov rdi, r12 ; FILE* em r12
    call fclose ; fecha o arquivo
    jmp fim

erro:
    lea rdi, [pstrctr] ; mensagem de erro
    xor rax, rax
    call printf ; imprime erro

fim:
    add rsp, 32 ; desfaz sub rsp,32
    pop r13 ; restaura r13
    pop r12 ; restaura r12
    mov rsp, rbp
    pop rbp
    ret
