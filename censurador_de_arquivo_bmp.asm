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
    ; Entrada e saída
    fileNameRequest db "Insira o nome do arquivo de entrada .bmp: ", 0h
    fileName db 260 dup(0)  ; string para nome do arquivo
    fileNameLength dd 0

    fileNameOutputRequest db "Insira o nome do arquivo de saida .bmp: ", 0h
    outputFileName db 260 dup(0)  ; string para o nome do arquivo de saída
    outputFileNameLength dd 0
    inputString db 50 dup(0)
    xRequest db "Valor da dimensao X: ", 0h
    X dd ?
    yRequest db "Valor da dimensao Y: ", 0h
    Y dd ?    
    alturaRequest db "Altura da censura: ", 0h
    altura dd ?
    larguraRequest db "Largura da censura: ", 0h
    largura dd ?

    ; Handles
    readFileHandle HANDLE ?
    writeFileHandle HANDLE ?
    inputHandle HANDLE ?
    outputHandle HANDLE ?
    consoleCount dd ?
    readCount dd ?
    writeCount dd ?
    linhaCount dd 0
 
    ; Buffers
    fileHeaderBuffer db 32 dup (0)
    fileImageBuffer db 6480 dup (0)

.code
    tratamento:
        push ebp
        mov ebp, esp

        ; Tratamento de string para localizar o caractere CR e substituí-lo por 0
        mov esi, offset fileName
        
    proximo:
        mov al, [esi]
        inc esi
        cmp al, 13            
        jne proximo

        dec esi
        xor al, al
        mov [esi], al
        mov esp, ebp
        pop ebp
        ret 4

    censura:
        push ebp
        mov ebp, esp
        mov edi, [ebp + 8]
        mov eax, [ebp + 12]
        imul eax, 3
        mov ebx, [ebp + 16]
        imul ebx, 3
        add ebx, eax

        ; Início do loop
        preencheLinha:
            cmp eax, ebx 
            jg fim_preencheLinha

            mov BYTE PTR [edi + eax], 0
            mov BYTE PTR [edi + eax + 1], 0  
            mov BYTE PTR [edi + eax + 2], 0
            add eax, 3
            jmp preencheLinha

        fim_preencheLinha:
            mov esp, ebp
            pop ebp
            ret 0

start:
    ; Obter os handles de entrada e saída padrão
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov inputHandle, eax
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov readFileHandle, eax

    ; Pedir e ler o nome do arquivo .bmp
    invoke WriteConsole, outputHandle, addr fileNameRequest, sizeof fileNameRequest - 1, addr consoleCount, NULL
    invoke ReadConsole, inputHandle, addr fileName, sizeof fileName, addr consoleCount, NULL
    push offset fileNameOutputRequest
    call tratamento

    push offset fileNameOutputRequest
    call StrLen
    mov fileNameLength, eax

    ; Pedir e ler o nome do arquivo de saída
    invoke WriteConsole, outputHandle, addr fileNameOutputRequest, sizeof fileNameOutputRequest, addr consoleCount, NULL
    invoke ReadConsole, inputHandle, addr outputFileName, sizeof outputFileName, addr consoleCount, NULL
    push offset outputFileName
    call tratamento

    ; Abrir o arquivo de entrada .bmp
    invoke CreateFile, addr fileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov readFileHandle, eax
    cmp readFileHandle, INVALID_HANDLE_VALUE

    ; Abrir o arquivo de saída .bmp
    invoke CreateFile, addr outputFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov writeFileHandle, eax

    ; Ler os 18 bytes iniciais do cabeçalho
    invoke ReadFile, readFileHandle, addr fileHeaderBuffer, 18, addr readCount, NULL

    ; Escrever os 18 bytes no arquivo .bmp de saída
    invoke WriteFile, writeFileHandle, addr fileHeaderBuffer, 18, addr writeCount, NULL

    ; Ler os 4 bytes da largura do arquivo de entrada
    invoke ReadFile, readFileHandle, addr fileHeaderBuffer, 4, addr readCount, NULL

    ; Escrever os 4 bytes da largura na saída
    invoke WriteFile, writeFileHandle, addr fileHeaderBuffer, 4, addr writeCount, NULL
    call atodw
    mov largura, eax

    ; Ler os 32 bytes do arquivo
    invoke ReadFile, readFileHandle, addr fileHeaderBuffer, 32, addr readCount, NULL

    ; Escrever os 32 bytes no arquivo .bmp de saída
    invoke WriteFile, writeFileHandle, addr fileHeaderBuffer, 32, addr writeCount, NULL

    ; Pedir e ler a coordenada X
    mov consoleCount, 0
    invoke WriteConsole, outputHandle, addr xRequest, sizeof xRequest-1, consoleCount, NULL
    invoke ReadConsole, inputHandle, addr inputString, sizeof inputString, addr consoleCount, NULL


    ; Tratar a string com a função tratamento e armazenar em X
    mov esi, offset inputString 
    next_x:
    mov al, [esi]
    inc esi
    cmp al, 13
    jne next_x
    dec esi
    xor al, al
    mov [esi], al

    invoke atodw, addr inputString
    mov X, eax

    ; Pedir e ler a coordenada Y
    mov consoleCount, 0
    invoke WriteConsole, outputHandle, addr yRequest, sizeof yRequest-1, consoleCount, NULL
    invoke ReadConsole, inputHandle, addr inputString, sizeof inputString, addr consoleCount, NULL

    ; Tratar a string com a função de tratamento e armazenar em Y
    mov esi, offset inputString
    next_y:
    mov al, [esi]
    inc esi
    cmp al, 13
    jne next_y
    dec esi
    xor al, al
    mov [esi], al

    invoke atodw, addr inputString
    mov Y, eax 

    ; Pedir e ler a largura
    mov consoleCount, 0
    invoke WriteConsole, outputHandle, addr larguraRequest, sizeof larguraRequest-1, consoleCount, NULL
    invoke ReadConsole, inputHandle, addr inputString, sizeof inputString, addr consoleCount, NULL

    ; Tratar a largura com a função de tratamento 
    mov esi, offset inputString
    next_largura:
    mov al, [esi]
    inc esi
    cmp al, 13
    jne next_largura
    dec esi
    xor al, al
    mov [esi], al

    invoke atodw, addr inputString
    mov largura, eax
    

    ; Pedir e ler a altura
    mov consoleCount, 0
    invoke WriteConsole, outputHandle, addr alturaRequest, sizeof alturaRequest-1, consoleCount, NULL
    invoke ReadConsole, inputHandle, addr inputString, sizeof inputString, addr consoleCount, NULL

    ; Tratar a altura com a função de tratamento
    mov esi, offset inputString
    next_altura:
    mov al, [esi]
    inc esi
    cmp al, 13
    jne next_altura
    dec esi
    xor al, al
    mov [esi], al

    invoke atodw, addr inputString
    mov altura, eax

; Laço para cópia na imagem
lacoImagem:
    invoke ReadFile, readFileHandle, addr fileImageBuffer, 2700, addr readCount, NULL
    cmp readCount, 0
    je fim_imagem
    mov esi, linhaCount

    ; Determinar se a censura deve ser aplicada de acordo com a entrada (dentro das coordenadas Y
    cmp esi, Y
    jl reboot_y
    mov eax, Y
    add eax, altura
    cmp esi, eax
    jge reboot_y

    ; Censura
    push largura
    push X
    push offset fileImageBuffer
    call censura

    reboot_y:
    invoke WriteFile, writeFileHandle, addr fileImageBuffer, 2700, addr writeCount, NULL
    inc linhaCount
    jmp lacoImagem

    ; Encerra os handles e o programa
    fim_imagem:
        invoke CloseHandle, readFileHandle
        invoke CloseHandle, writeFileHandle
        invoke ExitProcess, 0

invoke ExitProcess, 0
end start
