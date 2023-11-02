.686
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib ;biblioteca p/ usar CreateFile
includelib \masm32\lib\masm32.lib   ;biblioteca p/ usar StrLen


.data
;entrada e sa�da
file_name_request db "Insira o nome do arquivo .bmp: ", 0h
file_name db 10 dup(0)  ;string p nome de arq
x_request db "Valor de X: ", 0h
X db 0
y_request db "Valor de Y: ", 0h
Y db 0
altura_request db "Altura: ", 0h
altura db 0
largura_request db "Largura: ", 0h
largura db 0

;handles
fileHandle HANDLE 0
inputHandle dd 0
outputHandle dd 0

console_count dd 0

byteCount dd 0
headerBuffer db 54 dup(0)
imageBuffer db 6480 dup(0)

.code
start:
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov inputHandle, eax
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax
    
    invoke WriteConsole, outputHandle, addr file_name_request, sizeof file_name_request, console_count, NULL
    invoke ReadConsole, inputHandle, addr file_name, sizeof file_name, addr console_count, NULL ; recebe o nome do arquivo

    mov esi, offset file_name   ; mov endere�o de file_name pra ESI p/ convers�o em dword

    ; tratamento de string aqui
    
    invoke WriteConsole, outputHandle, addr x_request, sizeof x_request, console_count, NULL
    invoke ReadConsole, inputHandle,  addr X, 4, console_count, NULL ; pede e l� X

    invoke WriteConsole, outputHandle, addr y_request, sizeof y_request, console_count, NULL
    invoke ReadConsole, inputHandle, addr Y, 4, console_count, NULL ; pede e l� Y

    invoke WriteConsole, outputHandle, addr largura, sizeof largura, console_count, NULL
    invoke ReadConsole, inputHandle, addr largura, 4, console_count, NULL ; pede e l� a largura

    invoke WriteConsole, outputHandle, addr altura, sizeof altura, console_count, NULL
    invoke ReadConsole, inputHandle, addr altura, 4, console_count, NULL ; pede e l� a altura

    ; l� o arquivo e passa ele para var fileHandle
    invoke CreateFile, addr file_name, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    mov fileHandle, eax

    invoke ReadFile, fileHandle, addr headerBuffer, 18, addr byteCount, 0 ; l� os primeiros 18 bytes
    invoke WriteFile, eax, addr headerBuffer, 18, addr byteCount, 0 ; escreve no arquivo de sa�da

    invoke ReadFile, fileHandle, addr largura, 4, addr byteCount, 0 ; l� o tamanho da largura
    invoke WriteFile, eax, addr largura, 4, addr byteCount, 0 ; escreve no arquivo de sa�da

    mov eax, 32
    sub eax, 4
    invoke ReadFile, fileHandle, addr headerBuffer, eax, addr byteCount, 0 ; l� os 32 bytes restantes do cabe�alho
    invoke WriteFile, eax, addr headerBuffer, eax, addr byteCount, 0 ; escreve no arquivo de sa�da

    mov ecx, offset largura ; move valor de largura p/ ecx -> multiplica por 3 p/ calcular o n�mero de bytes a serem lidos -> move valor para edx
    imul ecx, 3 ; calcula o n�mero total de bytes a serem lidos
    mov edx, 0
    
 

readLoop:
    invoke ReadFile, fileHandle, addr imageBuffer, 6480, addr byteCount, 0 ; l� os bytes da imagem
    invoke WriteFile, eax, addr imageBuffer, byte_count, addr byteCount, 0 ; escreve no arquivo de sa�da

    sub ecx, byteCount
    jnz readLoop ; repete o loop at� que byteCount e ecx sejam iguais

    invoke CloseHandle, fileHandle

end start
invoke ExitProcess, 0



