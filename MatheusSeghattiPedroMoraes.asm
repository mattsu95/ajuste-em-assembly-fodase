;nasm -f elf64 MatheusSeghattiPedroMoraes.asm -o MatheusSeghattiPedroMoraes.o
;gcc -m64 -no-pie MatheusSeghattiPedroMoraes.o -o MatheusSeghattiPedroMoraes.x

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
    stresult: db "a = %f, b = %f", 10, 0     
    fout: db "resultado.txt", 0

section .bss
    x: resd 64 ;espaço pra até 64 floats
    y: resd 64 ;espaço pra até 64 floats
    a: resd 1  ;coeficiente angular
    b: resd 1  ;coeficiente linear
    n: resd 1  ;numero de pontos

section .text
    global main

main:
    push rbp
    mov rbp, rsp

    call r_arquivo  ;chama a função que abre e lê o arquivo
    mov dword [n], eax
    xor rax, rax

calc_regressao:
    lea rdi, [x]    ;ponteiro pro vetor dos pontos x
    mov esi, [n]    ;número de pontos
    call Som_x      ;somatório de x -> Som_x(float* x, int n)
    sub rsp, 16     
    movss [rsp], xmm0 ;guarda o somatório de x na pilha pra usar dps

    lea rdi, [x]
    mov esi, [n]
    call Som_xq     ;somatório de x^2 -> Som_xq(float* x, int n)
    ;aqui, xmm0 = somatório(x^2)

    movss xmm1, [rsp]   ;xmm1 = somatório(x)
    add rsp, 16        
    mov edi, [n]
    call Dpx            ;desvio padrao de x -> Dpx(float sxq, float sx, int n)
    sub rsp, 16     
    movss [rsp], xmm0   ;guarda o desvio padrão de x

    lea rdi, [y]        ;ponteiro pro vetor dos pontos y
    mov esi, [n]
    call Som_y          ;somatório de y -> Som_y(float* y, int n)
    sub rsp, 16     
    movss [rsp], xmm0   ;guarda somatório de y

    lea rdi, [x]
    lea rsi, [y]
    mov edx, [n]
    call Som_xy         ;somatório de x*y -> Som_xy(float* x, float* y, int n)
    sub rsp, 16     
    movss [rsp], xmm0   ;guarda

    lea rdi, [x]
    mov esi, [n]
    call Som_x      ;calcula o somatório de x dnv pq não tive vontade o bastante de pensar em uma forma de guardar o q eu fiz antes
    ;aqui, xmm0 = somatório(x)

    movss xmm1, [rsp]   ;xmm1 = somatório(x*y)
    add rsp, 16        
    movss xmm2, [rsp]   ;xmm2 = somatório(y)
    add rsp, 16
    mov edi, [n]
    call Dpy            ;desvio padrão de y -> Dpy(float sx, float sxy, float sy, int n)

    movss xmm1, [rsp]
    add rsp, 16         ;xmm1 = Sx | S == desvio padrão
    divss xmm0, xmm1    ;xmm0 = Sxy / Sx
    movss [a], xmm0

    lea rdi, [x]
    mov esi, [n]
    call Som_x              
    sub rsp, 16
    movss [rsp], xmm0

    lea rdi, [y]
    mov esi, [n]
    call Som_y
    ;xmm0 = som_y

    movss xmm1, [rsp]       ;xmm1 = som_x
    add rsp, 16
    movss xmm2, dword [a]   ;xmm2 = a
    mov edi, [n]
    call coef_linear        ;coef_linear(float sy, float sx, float a, int n)
    movss [b], xmm0

printar_resultado:
    lea rdi, [fout]
    movss xmm0, [a]
    cvtss2sd xmm0, xmm0
    movss xmm1, [b]
    cvtss2sd xmm1, xmm1
    lea rsi, [stresult]
    call presult            ;presult(char* fout, char* stresult, float a, float b)

fim:
    mov rsp, rbp
    pop rbp
    mov rax, 60
    mov rdi, 0
    syscall

;====================================================calculo====================================================

;==================================================coef_linear==================================================

;float coef_linear(float sy, float sx, float a, int n)
coef_linear:
    push rbp
    mov rbp, rsp

    cvtsi2ss xmm3, edi

    divss xmm0, xmm3    ;média y
    divss xmm1, xmm3    ;média x

    mulss xmm1, xmm2    ;a*média de x     
    subss xmm0, xmm1    ;média de y - o resultado do de cima

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

;======================================================ler======================================================
;int r_arquivo(int argc, char* argv[])
r_arquivo:
    push rbp
    mov rbp, rsp

    push r12 ; salvar r12 (callee-saved)
    push r13 ; salvar r13 (callee-saved)

    sub rsp, 32 ;alinhar
    ;stack frame caga com a pilha ent tem que pegar o parâmetro pelo rdzi
    ;cmp rdi, 2  
    ;jl erro ; exige argc >= 2 (programa + 1 argumento)
    ;achei que não valesse a pena ter um caso de erro - prefiro acreditar que o usuário será bem comportado e tudo mais

    mov rdx, [rsi + 8]  ;rdx = filename
    mov rdi, rdx        ;passa como parâmetro
    lea rsi, [rmode]    ;modo de leitura
    xor rax, rax
    call fopen ; FILE *fopen(const char *filename, const char *mode)

    mov r12, rax        ;r12 = *file
    xor r13, r13        ;r13 = índice
    
laco_r:
    xor rax, rax
    mov rdi, r12 ; primeiro parâmetro de fscanf: FILE*
    lea rsi, [strctr] ; formato "%f %f"
    lea rdx, [x + r13*4]    ;endereço de x[i]
    lea rcx, [y + r13*4]    ;endereço de y[i]
    call fscanf ; fscanf(file, "%f %f", &x[i], &y[i])

    cmp rax, 2              ;rax = qtd de valores lidos
    jne  fim_r              ;se for diferente de 2, na teoria leu todos

    inc r13 ;i++
    cmp r13, 64 ;pra evitar loop infinito caso a comparação do rax ali em cima dê algum problema
    jl laco_r

fim_r:
    mov rdi, r12 ; FILE* em r12
    call fclose ; fecha o arquivo

    add rsp, 32 ; desfaz o alinhamento
    mov rax, r13 ; rax = n
    pop r13 ; restaura r13
    pop r12 ; restaura r12

    mov rsp, rbp
    pop rbp
    ret

;====================================================printar====================================================
;void presult(char* fout, char* stresult, float a, float b)
presult:
    push rbp
    mov rbp, rsp
    ;reserva espaço na pilha:
    sub rsp, 48

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

    mov r12, rax            ;r12 = FILE*

    ; ---------- recarregar xmm0/xmm1 antes de fprintf ----------
    movsd xmm0, [rbp-32]
    movsd xmm1, [rbp-24]

    ; ---------- fprintf(FILE*, char* stresult, float a, float b) ----------
    mov rdi, r12
    lea rsi, [stresult]
    mov al, 2               
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
    add rsp, 48
    pop r12
    mov rax, 1
    pop rbp
    ret
