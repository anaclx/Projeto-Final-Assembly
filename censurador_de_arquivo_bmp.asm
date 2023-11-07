.686
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
include \masm32\include\msvcrt.inc
include \masm32\include\gdi32.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\msvcrt.lib
includelib \masm32\lib\gdi32.lib

.data
    ;entrada e saída 
    file_name_request db "Insira o nome do arquivo de entrada .bmp: ", 0h
    file_name db 260 dup(0)  ; string para nome do arquivo
    file_name_tamanho dd 0

    file_name_output_request db "Insira o nome do arquivo de saida .bmp: ", 0h
    output_file_name db 260 dup(0)  ; string para o nome do arquivo de saída
    output_file_name_length dd 0
    
    x_request db "Valor da dimensao X: ", 0h
    X dd ?
    x_censor db 32 dup(0)
    
    y_request db "Valor da dimensao Y: ", 0h
    Y dd ?
    y_censor db 32 dup(0)
    
    altura_request db "Altura da censura: ", 0h
    altura dd ?
    altura_censor db 32 dup(0)
    
    largura_request db "Largura da censura: ", 0h
    largura dd ?
    largura_censor db 32 dup(0)


    ;handles
    readFileHandle HANDLE ?
    writeFileHandle HANDLE ?
    
    inputHandle HANDLE ?
    outputHandle HANDLE ?

    fileAltura dd ?
    fileLargura dd ?

    console_count dd ?
    read_count dd ?
    write_count dd ?
    linha_count dd 0
    larguraImagem dd 0
    

    fileHeaderBuffer db 32 dup (0)
    fileImageBuffer db 6480 dup (0)

    error byte "houve um erro.", 0h



.code

    removeCR:
        push ebp
        mov ebp, esp

        ;tratamento de string p/ localizar o caractere CR e o substituir por 0
        mov esi, [ebp+8]
        proximo:
            mov al, BYTE PTR [esi]
            inc esi
            cmp al, 13            
            jne proximo

            dec esi
            xor al, al
            mov BYTE PTR [esi], al
            mov esp, ebp
            pop ebp
            ret 4

    ;função censura recebe largura da censura, coord. x inicial e endereço do array
    censura:
            push ebp
            mov ebp, esp
            
            ; argumentos:
            mov edi, [ebp + 8]
            mov eax, [ebp + 12]
            imul eax, 3
            mov ebx, [ebp + 16]
            imul ebx, 3

            add ebx, eax    ;calcula o limite da área a ser censurada  

            ;início do loop         
            preenchePixels:
                cmp eax, ebx 
                jg finish_preenchePixels

                mov BYTE PTR [edi + eax], 0 ;define o valor do byte no array de pixels para 0
                mov BYTE PTR [edi + eax + 1], 0  
                mov BYTE PTR [edi + eax + 2], 0
                add eax, 3  ;move eax p/ próximo trio de bytes
                jmp preenchePixels

                ;restaura o valor original da pilha
                finish_preenchePixels:
                mov esp, ebp
                pop ebp
                ret 0



start:

    ; obtém os handles de entrada e saída padrão
    push STD_INPUT_HANDLE
    call GetStdHandle
    mov inputHandle, eax

    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov outputHandle, eax

    push STD_INPUT_HANDLE
    call GetStdHandle
    mov readFileHandle, eax

    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov writeFileHandle, eax

    ;pede o nome do arquivo .bmp
    push NULL
    push offset console_count
    push sizeof file_name_request
    push offset file_name_request
    push outputHandle
    call WriteConsole

    ;lê nome do arquivo de entrada
    push NULL
    push offset console_count
    push sizeof file_name
    push offset file_name
    push inputHandle
    call ReadConsole

    ;coloca endereço de file_name na pilha e chama a função de tratamento
    push offset file_name
    call removeCR

    ;calcula o tamanho de file_name e armazena em file_name_tamanho
    push offset file_name
    call StrLen
    mov file_name_tamanho, eax

    ;escreve file_name_output_request no stdout
    push NULL
    push offset console_count
    push sizeof file_name_output_request
    push offset file_name_output_request
    push outputHandle
    call WriteConsole

    ;lê a entrada e armazena em output_file_name
    push NULL
    push offset console_count
    push sizeof output_file_name
    push offset output_file_name
    push inputHandle
    call ReadConsole

    ;coloca o endereço de output_file_name na pilha e chama  a função de tratamento
    push offset output_file_name
    call removeCR

    ;abre o arquivo .bmp, se houver erro, pula pra label houve_erro que encerra o programa
    push NULL
    push FILE_ATTRIBUTE_NORMAL
    push OPEN_EXISTING
    push NULL
    push 0
    push GENERIC_READ
    push offset file_name
    call CreateFile
    mov readFileHandle, eax
    cmp readFileHandle, INVALID_HANDLE_VALUE
    je houve_erro

    ;cria arquivo de saída e armazena em writeFileHandle
    push NULL
    push FILE_ATTRIBUTE_NORMAL
    push CREATE_ALWAYS
    push NULL
    push 0
    push GENERIC_WRITE
    push offset output_file_name
    call CreateFile

    mov writeFileHandle, eax

    ;lê 18 bytes de readFileHandle
    push NULL
    push offset read_count
    push 18
    push offset fileHeaderBuffer
    push readFileHandle
    call ReadFile

    ;escreve 18 bytes em writeFileHandle
    push NULL
    push offset write_count
    push 18
    push offset fileHeaderBuffer
    push writeFileHandle
    call WriteFile

    ;lê largura do arquivo de entrada
    push NULL
    push offset read_count
    push 4
    push offset fileHeaderBuffer
    push readFileHandle
    call ReadFile

    ;escreve largura do arquivo de saída
    push NULL
    push offset write_count
    push 4
    push offset fileHeaderBuffer
    push writeFileHandle
    call WriteFile

    push offset fileHeaderBuffer
    call atodw
    mov fileLargura, eax

    ;copia o resto dos 32 bytes
    push NULL
    push offset read_count
    push 32
    push offset fileHeaderBuffer
    push readFileHandle
    call ReadFile

    ;escreve 32 bytes no arq de saída
    push NULL
    push offset write_count
    push 32
    push offset fileHeaderBuffer
    push writeFileHandle
    call WriteFile

    ;pede o tamanho da coordenada X
    push NULL
    push offset console_count
    push sizeof x_request
    push offset x_request
    push outputHandle
    call WriteConsole

    ;lê a entrada de X
    push NULL
    push offset console_count
    push sizeof x_censor
    push offset x_censor
    push inputHandle
    call ReadConsole

    ;trata a string com a função removeCR e armazena em X
    push offset x_censor
    call removeCR 
    push offset x_censor
    call atodw
    mov X, eax  

    ;pede o tamanho da coordenada Y
    push NULL
    push offset console_count
    push sizeof y_request
    push offset y_request
    push outputHandle
    call WriteConsole 

    ;lê a entrada de Y
    push NULL
    push offset console_count
    push sizeof y_censor
    push offset y_censor
    push inputHandle
    call ReadConsole

    ;trata a string com a função removeCR e armazena em Y
    push offset y_censor
    call removeCR
    push offset y_censor
    call atodw
    mov Y, eax

    ;pede a largura
    push NULL
    push offset console_count
    push sizeof largura_request
    push offset largura_request
    push outputHandle
    call WriteConsole

    ;lê a largura
    push NULL
    push offset console_count
    push sizeof largura_censor
    push offset largura_censor
    push inputHandle
    call ReadConsole

    ;trata o array com removeCR e move para "largura"
    push offset largura_censor
    call removeCR
    push offset largura_censor
    call atodw
    mov largura, eax

    ;pede a altura
    push NULL
    push offset console_count
    push sizeof altura_request
    push offset altura_request
    push outputHandle
    call WriteConsole

    ;lê a altura
    push NULL
    push offset console_count
    push sizeof altura_censor
    push offset altura_censor
    push inputHandle
    call ReadConsole

    ;trata o array com removeCR e move para "altura"
    push offset altura_censor
    call removeCR
    push offset altura_censor
    call atodw
    mov altura, eax

    mov eax, fileLargura
    
    mov larguraImagem, eax

    laco_imagem:

    ;lê a linha do arquivo de entrada e armazena no buffer até o final do arquivo (read_count = 0)
    push NULL
    push offset read_count
    push 2700
    push offset fileImageBuffer
    push readFileHandle
    call ReadFile

    cmp read_count, 0
    je fim_imagem

    ;determina se a censura deve ser aplicada de acordo com a entrada (dentro das coordenadas Y)
    mov esi, linha_count
    cmp esi, Y
    jl sem_censuraY

    mov eax, Y
    add eax, altura

    cmp esi, eax
    jge sem_censuraY

    ;censura se estiver dentro da área
    push largura
    push X
    push offset fileImageBuffer
    call censura

    ;verifica se chegou ao fim da linha
    sem_censuraY:
    push NULL
    push offset write_count
    push 2700
    push offset fileImageBuffer
    push writeFileHandle
    call WriteFile

    inc linha_count
    jmp laco_imagem

    ;encerra o handle de entrada
    fim_imagem:
    push inputHandle
    call CloseHandle

    finish:
    push 0
    call ExitProcess

    ;encerra o programa exibindo uma mensagem de erro na tela
    houve_erro:
    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov ecx, eax
    push NULL
    push offset console_count
    push sizeof error
    push offset error
    push ecx
    call WriteConsole
    push -1 ;código de erro
    call ExitProcess

  end start
