# Projeto Final Assembly
 Censurador de Arquivos BMP desenvolvido para a disciplina de Arquitetura de Computadores da Universidade Federal da Paraíba - UFPB.

 Alunas: Ana Clara Ferreira Epaminondas, Gleice Heloise de Araujo Silva
 
 Funcionamento do código

1.1 Receber como entrada o nome de um arquivo de uma imagem em bitmap (.bmp) 

1.2 Abrir o arquivo BMP e ler o cabeçalho de 54 bytes

1.3 Verificar se o número de pixels por linha (largura) deve ser múltiplo de 4

1.4 Receber como entrada mais 4 números de 4 bytes: uma coordenada inicial x e y, uma largura e uma altura (o usuário determina os bits que serão censurados da imagem)

1.5 O programa deve solicitar o nome de um arquivo de saída ao usuário

1.6 O programa deve produzir como saída uma cópia da imagem recebida contendo um retângulo de cor preta censurando uma determinada área, desenhado a partir da coordenada inicial informada (x,y), largura e altura especificadas (passo 4).

