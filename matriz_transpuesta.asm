triz transpuesta · ASM
; ============================================================
; Proyecto 2: Captura y Transpuesta de Matriz 3x3
; Ensamblador: NASM x86 (32 bits) - Linux
; Compilar : nasm -f elf32 matriz_transpuesta.asm -o mt.o
; Enlazar  : ld -m elf_i386 mt.o -o mt
; Ejecutar : ./mt
; ============================================================
 
section .data
 
    ; --- Mensajes generales ---
    msg_titulo      db  "====================================", 10
                    db  "  TRANSPUESTA DE MATRIZ 3x3", 10
                    db  "====================================", 10, 0
    msg_titulo_len  equ $ - msg_titulo
 
    msg_ingreso     db  10, "--- Ingreso de elementos ---", 10, 0
    msg_ingreso_len equ $ - msg_ingreso
 
    msg_elemento    db  "Ingrese M[", 0
    msg_elemento_len equ $ - msg_elemento
 
    msg_fila        db  0           ; se sobreescribe con el digito de fila
    msg_fila_len    equ 1
 
    msg_coma        db  "][", 0
    msg_coma_len    equ $ - msg_coma
 
    msg_col         db  0           ; se sobreescribe con el digito de columna
    msg_col_len     equ 1
 
    msg_cierre      db  "]: ", 0
    msg_cierre_len  equ $ - msg_cierre
 
    msg_error       db  "  *** ERROR: Solo se aceptan digitos (0-9). Intente de nuevo.", 10, 0
    msg_error_len   equ $ - msg_error
 
    msg_original    db  10, "--- Matriz Original ---", 10, 0
    msg_original_len equ $ - msg_original
 
    msg_transpuesta db  10, "--- Matriz Transpuesta ---", 10, 0
    msg_transpuesta_len equ $ - msg_transpuesta
 
    msg_espacio     db  "  ", 0
    msg_espacio_len equ $ - msg_espacio
 
    msg_newline     db  10, 0
    msg_newline_len equ 1
 
    msg_fin         db  10, "====================================", 10
                    db  "  Operacion completada.", 10
                    db  "====================================", 10, 0
    msg_fin_len     equ $ - msg_fin
 
    char_fila       db  0           ; buffer para mostrar numero de fila
    char_col        db  0           ; buffer para mostrar numero de columna
 
section .bss
 
    matriz          resb 9          ; Matriz original  [3][3] (1 byte por elemento)
    transpuesta     resb 9          ; Matriz transpuesta[3][3]
    input_buf       resb 32         ; buffer de entrada del teclado
    input_len       resd 1          ; longitud leída
 
; ============================================================
; MACROS
; ============================================================
 
; MACRO: imprimir cadena terminada en 0
%macro PRINT 2
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, %1         ; puntero
    mov edx, %2         ; longitud
    int 0x80
%endmacro
 
; MACRO: leer teclado en buffer, max %2 bytes
%macro READ_INPUT 2
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, %1         ; buffer destino
    mov edx, %2         ; max bytes
    int 0x80
    mov [input_len], eax
%endmacro
 
; MACRO: salida del programa
%macro EXIT 1
    mov eax, 1
    mov ebx, %1
    int 0x80
%endmacro
 
; ============================================================
section .text
global _start
 
; ============================================================
; ETIQUETA PRINCIPAL
; ============================================================
_start:
    PRINT msg_titulo, msg_titulo_len
    PRINT msg_ingreso, msg_ingreso_len
 
    ; --- Captura de elementos ---
    call capturar_matriz
 
    ; --- Mostrar matriz original ---
    PRINT msg_original, msg_original_len
    call mostrar_matriz_original
 
    ; --- Calcular transpuesta ---
    call calcular_transpuesta
 
    ; --- Mostrar transpuesta ---
    PRINT msg_transpuesta, msg_transpuesta_len
    call mostrar_matriz_transpuesta
 
    PRINT msg_fin, msg_fin_len
    EXIT 0
 
; ============================================================
; SUBRUTINA: capturar_matriz
; Recorre i=0..2, j=0..2 y pide cada elemento con validación
; ============================================================
capturar_matriz:
    push ebp
    mov  ebp, esp
    push esi
    push edi
    push ebx
 
    xor esi, esi            ; esi = fila (i)
 
.loop_fila:
    cmp esi, 3
    jge .fin_captura
 
    xor edi, edi            ; edi = columna (j)
 
.loop_col:
    cmp edi, 3
    jge .siguiente_fila
 
    ; Mostrar "Ingrese M[i][j]: "
    call mostrar_prompt
 
.pedir_valor:
    READ_INPUT input_buf, 32
 
    ; Validar entrada
    call validar_entrada
    cmp eax, 0
    je  .error_entrada
 
    ; Guardar dígito en matriz[i*3+j]
    ; EAX ya contiene el valor numérico (0-9) desde validar_entrada
    ; Calculamos índice: esi*3 + edi
    push eax
    mov  eax, esi
    mov  ebx, 3
    imul ebx
    add  eax, edi
    mov  ebx, eax
    pop  eax
    mov  [matriz + ebx], al
 
    inc edi
    jmp .loop_col
 
.error_entrada:
    PRINT msg_error, msg_error_len
    jmp .pedir_valor
 
.siguiente_fila:
    inc esi
    jmp .loop_fila
 
.fin_captura:
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret
 
; ============================================================
; SUBRUTINA: mostrar_prompt
; Imprime "Ingrese M[i][j]: " usando esi (fila) y edi (col)
; ============================================================
mostrar_prompt:
    push eax
    push ebx
    push ecx
    push edx
 
    PRINT msg_elemento, msg_elemento_len
 
    ; Imprimir número de fila (esi+1 para base-1, o esi para base-0)
    mov  al, sil
    add  al, '1'                ; mostrar 1-based
    mov  [char_fila], al
    PRINT char_fila, 1
 
    PRINT msg_coma, msg_coma_len
 
    ; Imprimir número de columna
    mov  al, dil
    add  al, '1'
    mov  [char_col], al
    PRINT char_col, 1
 
    PRINT msg_cierre, msg_cierre_len
 
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
 
; ============================================================
; SUBRUTINA: validar_entrada
; Analiza input_buf con longitud [input_len]
; Acepta: un dígito '0'-'9' seguido de Enter (o solo Enter -> rechaza)
; Retorna: EAX = valor numérico (0-9) si válido
;          EAX = 0 (y ZF=1 por cmp eax,0 en el llamador)  si inválido
; NOTA: para distinguir el dígito '0' válido se usa la etiqueta .valido
; ============================================================
validar_entrada:
    push ebx
    push ecx
 
    mov  ecx, [input_len]   ; longitud leída
    cmp  ecx, 0
    je   .invalido
 
    ; El buffer termina en 0x0A (Enter); la longitud incluye ese byte
    ; Aceptamos exactamente 1 dígito + Enter (longitud == 2)
    ; o solo el dígito sin Enter si longitud == 1
    cmp  ecx, 1
    je   .un_byte
    cmp  ecx, 2
    je   .dos_bytes
    jmp  .invalido           ; más de 2 bytes -> inválido (número de varios dígitos)
 
.dos_bytes:
    ; Verificar que el segundo byte sea Enter
    movzx eax, byte [input_buf + 1]
    cmp  al, 0x0A
    jne  .invalido
 
.un_byte:
    movzx eax, byte [input_buf]
    cmp  al, '0'
    jl   .invalido
    cmp  al, '9'
    jg   .invalido
 
    sub  al, '0'            ; convertir ASCII a número
    ; Si el número es 0 retornamos 10 para diferenciarlo del fallo
    ; (el llamador sólo chequea cmp eax,0)
    cmp  al, 0
    jne  .retornar
    mov  al, 10             ; código especial: dígito '0' válido
 
.retornar:
    pop  ecx
    pop  ebx
    ret
 
.invalido:
    xor  eax, eax           ; retorna 0 = inválido
    pop  ecx
    pop  ebx
    ret
 
; ============================================================
; SUBRUTINA: calcular_transpuesta
; T[j][i] = M[i][j]   para i,j en 0..2
; ============================================================
calcular_transpuesta:
    push esi
    push edi
    push eax
    push ebx
    push ecx
 
    xor esi, esi            ; i
 
.loop_i:
    cmp esi, 3
    jge .fin_transpuesta
 
    xor edi, edi            ; j
 
.loop_j:
    cmp edi, 3
    jge .sig_i
 
    ; src  = matriz[i*3+j]
    mov  eax, esi
    imul eax, 3
    add  eax, edi
    movzx ecx, byte [matriz + eax]
 
    ; dst  = transpuesta[j*3+i]
    mov  eax, edi
    imul eax, 3
    add  eax, esi
    mov  [transpuesta + eax], cl
 
    inc edi
    jmp .loop_j
 
.sig_i:
    inc esi
    jmp .loop_i
 
.fin_transpuesta:
    pop ecx
    pop ebx
    pop eax
    pop edi
    pop esi
    ret
 
; ============================================================
; SUBRUTINA: mostrar_fila_matriz
; ESI = puntero base a la matriz, EDI = índice de fila (0-2)
; ============================================================
mostrar_fila_matriz:
    push eax
    push ebx
    push ecx
    push edx
 
    ; Calcular base de la fila: ESI + EDI*3
    mov  eax, edi
    imul eax, 3
    add  eax, esi           ; EAX = puntero al primer elemento de la fila
 
    mov  ecx, 0             ; contador de columna
 
.col_loop:
    cmp  ecx, 3
    jge  .fin_fila
 
    movzx ebx, byte [eax + ecx]
    ; Si almacenamos 10 para el dígito '0', convertir de vuelta
    cmp  ebx, 10
    jne  .no_cero
    xor  ebx, ebx
 
.no_cero:
    add  bl, '0'
    mov  [char_col], bl
    PRINT char_col, 1
    PRINT msg_espacio, msg_espacio_len
 
    inc ecx
    jmp .col_loop
 
.fin_fila:
    PRINT msg_newline, msg_newline_len
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
 
; ============================================================
; SUBRUTINA: mostrar_matriz_original
; ============================================================
mostrar_matriz_original:
    push esi
    push edi
 
    mov  esi, matriz
    xor  edi, edi
 
.fila_loop_orig:
    cmp  edi, 3
    jge  .fin_orig
    call mostrar_fila_matriz
    inc  edi
    jmp  .fila_loop_orig
 
.fin_orig:
    pop edi
    pop esi
    ret
 
; ============================================================
; SUBRUTINA: mostrar_matriz_transpuesta
; ============================================================
mostrar_matriz_transpuesta:
    push esi
    push edi
 
    mov  esi, transpuesta
    xor  edi, edi
 
.fila_loop_trans:
    cmp  edi, 3
    jge  .fin_trans
    call mostrar_fila_matriz
    inc  edi
    jmp  .fila_loop_trans
 
.fin_trans:
    pop edi
    pop esi
    ret
 