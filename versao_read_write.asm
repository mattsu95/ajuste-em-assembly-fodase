extern fprintf
extern fscanf
extern fopen
extern fclose
extern printf

section .data
    rmode: db "r", 0
    amode: db "a", 0
    strctr: db "%f %f", 0
    pstrctr: db "Erro na abertura do arquivo. Finalizando programa.", 10, 0
    pdstrctr: db "Lidos: %f %f", 10, 0
    fout: db "resultado.txt", 0

section .bss
    x: resd 64 ;espaço pra até 64 floats
    y: resd 64 ;espaço pra até 64 floats

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

    ; chama a função que abre o arquivo em "a", grava e fecha
    lea rdi, [fout]    ; RDI = pointer para "resultado.txt"
    call salva_par

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

salva_par:
    push rbp
    mov rbp, rsp
    ; reserva espaço na pilha:
    ; 8 bytes para salvar r12_old, 16+16 para guardar xmm0/xmm1 (movsd)
    ; total = 40 -> arredondamos para múltiplo de 16: 48
    sub rsp, 48

    ; salvar r12 antigo em [rbp-8]
    mov [rbp-8], r12

    ; salvar os doubles recebidos (xmm0/xmm1) em pilha
    movsd [rbp-32], xmm0    ; slot para valor1
    movsd [rbp-24], xmm1    ; slot para valor2

    ; ---------- fopen(filename, "a") ----------
    ; RDI já tem filename (passado pelo chamador)
    lea rsi, [amode]    ; rsi = "a"
    xor rax, rax
    call fopen
    cmp rax, 0
    je err_open

    mov r12, rax            ; r12 = FILE* retornado

    ; ---------- recarregar xmm0/xmm1 antes de fprintf ----------
    movsd xmm0, [rbp-32]
    movsd xmm1, [rbp-24]

    ; ---------- fprintf(FILE*, pdstrctr, xmm0, xmm1) ----------
    mov rdi, r12
    lea rsi, [pdstrctr]
    mov al, 2               ; informar 2 XMM regs usados (variádica)
    call fprintf

    ; ---------- fclose(FILE*) ----------
    mov rdi, r12
    call fclose

    ; restaurar r12 antigo e limpar pilha
    mov r12, [rbp-8]
    add rsp, 48
    mov rax, 0
    pop rbp
    ret

err_open:
    ; não abriu: retorna erro (1)
    mov rax, 1
    add rsp, 8
    pop r12
    pop rbp
    ret