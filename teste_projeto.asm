.686
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.data
; entrada e saída 
file_name_request db "Insira o nome do arquivo de entrada .bmp: ", 0
file_name db 260 dup(0)  ; string para nome do arquivo
file_name_output_request db "Insira o nome do arquivo de saida .bmp: ", 0
output_file_name db 260 dup(0)  ; string para o nome do arquivo de saída
x_request db "Valor da dimensao X: ", 0
X dd 0
y_request db "Valor da dimensao Y: ", 0
Y dd 0
altura_request db "Altura da censura: ", 0
altura dw 0
largura_request db "Largura da censura: ", 0
largura dw 0
largura_imagem dd 0


; handles
fileHandle HANDLE 0
inputHandle dd 0
outputHandle dd 0

console_count dd 0

byteCount dd 0
headerBuffer db 54 dup(0)
imageBuffer db 6480 dup(0)

.code
start:
    ; Obtém os handles de entrada e saída padrão
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov inputHandle, eax
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax

    ; Escreve e lê o arquivo .bmp de entrada
    invoke WriteConsole, outputHandle, addr file_name_request, 41, NULL, NULL
    invoke ReadConsole, inputHandle, addr file_name, 260, addr console_count, NULL
    
    ; Extrair o nome do arquivo de entrada (completo)
    mov esi, offset file_name
    proximo:
    mov al, [esi]
    inc esi
    cmp al, 13
    jne proximo
    dec esi
    xor al, al
    mov [esi], al

    ; Extrair o nome do arquivo sem o caminho
    invoke lstrcat, esi, '\\'
    inc esi
    mov edi, offset file_name
    proximo2:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    cmp al, 0
    jnz proximo2
    
    ; Escreve e lê o arquivo. bmp de saida:
    invoke WriteConsole, outputHandle, addr file_name_output_request, 41, NULL, NULL
    invoke ReadConsole, inputHandle, addr output_file_name, 260, addr console_count, NULL

    invoke lstrcat, addr file_name, addr file_name_output_request

    ; Inicializa edi com o endereço do nome do arquivo de saida
    mov edi, offset output_file_name

    ; Tratamento de string

    mov esi, offset file_name ; Armazenar apontador da string em esi
    next:
    mov al, [esi] ; Mover caractere atual para al
    inc esi ; Apontar para o proximo caractere
    cmp al, 13 ; Verificar se eh o caractere ASCII CR - FINALIZAR
    jne next
    dec esi ; Apontar para caractere anterior
    xor al, al ; ASCII 0
    mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CR

    ; Solicita e lê o valor de X
    invoke WriteConsole, outputHandle, addr x_request, 25, NULL, NULL
    invoke ReadConsole, inputHandle, addr X, 4, addr console_count, NULL

    ; Solicita e lê o valor de Y
    invoke WriteConsole, outputHandle, addr y_request, 25, NULL, NULL
    invoke ReadConsole, inputHandle, addr Y, 4, addr console_count, NULL

    ; Solicita e lê o valor da largura
    invoke WriteConsole, outputHandle, addr largura_request, 20, NULL, NULL
    invoke ReadConsole, inputHandle, addr largura, 4, addr console_count, NULL
    
    mov eax, dword ptr largura  ; move o conteúdo de largura pra eax -> move de eax para largura_imagem
    mov [largura_imagem], eax
    
    movzx ecx, word ptr largura_imagem  ; calcula o tamanho da linha de pixels em bytes
    imul ecx, 3


    ; Solicita e lê o valor da altura
    invoke WriteConsole, outputHandle, addr altura_request, 20, NULL, NULL
    invoke ReadConsole, inputHandle, addr altura, 4, addr console_count, NULL

    ; Cria o arquivo novo com os parâmetros fornecidos
    invoke CreateFile, addr file_name, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    mov fileHandle, eax

    ; Abre o arquivo de saída
    invoke CreateFile, addr output_file_name, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    mov outputHandle, eax

    ; Lê os primeiros 18 bytes do arquivo e escreve-os no arquivo de saída
    invoke ReadFile, fileHandle, addr headerBuffer, 18, addr byteCount, 0
    invoke WriteFile, outputHandle, addr headerBuffer, 18, addr byteCount, 0

    ; Lê os próximos 28 bytes do cabeçalho e escreve-os no arquivo de saída
    mov eax, 32
    sub eax, 4
    invoke ReadFile, fileHandle, addr headerBuffer, eax, addr byteCount, 0
    invoke WriteFile, outputHandle, addr headerBuffer, eax, addr byteCount, 0

    ; Converte a altura e a largura em 32 bits e multiplica-as por 3 para obter o número total de bytes a serem lidos
    movzx ecx, word ptr largura
    movzx eax, word ptr altura
    imul ecx, eax
    imul ecx, 3
    mov edx, 0

    ; Mova o ponteiro do arquivo para a posição correta para ler os dados da imagem
    invoke SetFilePointer, fileHandle, 54, NULL, FILE_BEGIN

    readLoop:
    ; Lê uma linha de pixels do arquivo de entrada (tamanho igual a 'ecx' bytes)
    invoke ReadFile, fileHandle, addr imageBuffer, ecx, addr byteCount, 0

    ; Escreve a linha de pixels no arquivo de saída
    invoke WriteFile, outputHandle, addr imageBuffer, byteCount, addr byteCount, 0

    ; Subtrai o tamanho da linha da imagem do número total de bytes a serem lidos e continua o loop se necessário
    sub ecx, byteCount
    jnz readLoop


    ; Fecha o arquivo de entrada
    invoke CloseHandle, fileHandle

    ;Fecha o arquivo de saída
    invoke CloseHandle, outputHandle

    ; Finaliza o processo
    invoke ExitProcess, 0

end start
