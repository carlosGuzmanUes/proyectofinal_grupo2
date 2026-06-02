; ============================================================
; Proyecto 2: Captura y Transpuesta de Matriz 3x3
; NASM x86 32 bits - Linux
; Compilar: nasm -f elf32 matriz_transpuesta.asm -o mt.o
; Enlazar : ld -m elf_i386 mt.o -o mt
; Ejecutar: ./mt
; ============================================================
 
section .data
 
    ; --- Mensajes (longitudes calculadas sin el byte nulo final) ---
    msg_titulo      db  "====================================", 10,
                    db  "  TRANSPUESTA DE MATRIZ 3x3", 10,
                    db  "====================================", 10
    LEN_TITULO      equ $ - msg_titulo
 
    msg_ingreso     db  10, "--- Ingreso de elementos ---", 10
    LEN_INGRESO     equ $ - msg_ingreso
 
    msg_elem1       db  "Ingrese M["
    LEN_ELEM1       equ $ - msg_elem1
 
    msg_coma        db  "]["
    LEN_COMA        equ $ - msg_coma
 
    msg_cierre      db  "]: "
    LEN_CIERRE      equ $ - msg_cierre
 
    msg_error       db  "  ERROR: Solo digitos 0-9. Intente de nuevo.", 10
    LEN_ERROR       equ $ - msg_error
 
    msg_original    db  10, "--- Matriz Original ---", 10
    LEN_ORIGINAL    equ $ - msg_original
 
    msg_transp      db  10, "--- Matriz Transpuesta ---", 10
    LEN_TRANSP      equ $ - msg_transp
 
    msg_espacio     db  "  "
    LEN_ESPACIO     equ $ - msg_espacio
 
    msg_newline     db  10
    LEN_NEWLINE     equ 1
 
    msg_fin         db  10, "====================================", 10,
                    db  "  Operacion completada.", 10,
                    db  "====================================", 10
    LEN_FIN         equ $ - msg_fin
 
    ; buffers de un caracter para impresion
    buf_fila        db  0
    buf_col         db  0
    buf_digito      db  0
 
section .bss
    matriz          resb 9      ; [3][3] - fila mayor
    transpuesta_m   resb 9      ; [3][3] traspuesta
    input_buf       resb 4      ; buffer de entrada (digito + Enter + extra)
    bytes_leidos    resd 1
    fila_idx        resb 1      ; fila actual (0-2)
    col_idx         resb 1      ; col actual  (0-2)
 
; ============================================================
; MACROS
; ============================================================
 
; Imprimir: direccion y longitud
%macro PRINT 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro
 
; Leer teclado
%macro LEER 2
    mov eax, 3
    mov ebx, 0
    mov ecx, %1
    mov edx, %2
    int 0x80
    mov [bytes_leidos], eax
%endmacro
 
; Salir del programa
%macro SALIR 1
    mov eax, 1
    mov ebx, %1
    int 0x80
%endmacro
 
; ============================================================
section .text
global _start
 
; ============================================================
_start:
    PRINT msg_titulo,   LEN_TITULO
    PRINT msg_ingreso,  LEN_INGRESO
    call  capturar_matriz
 
    PRINT msg_original, LEN_ORIGINAL
    call  imprimir_original
 
    call  calcular_transpuesta
 
    PRINT msg_transp,   LEN_TRANSP
    call  imprimir_transpuesta
 
    PRINT msg_fin,      LEN_FIN
    SALIR 0
 
; ============================================================
; SUBRUTINA: capturar_matriz
; ============================================================
capturar_matriz:
    push ebp
    mov  ebp, esp
    push esi
    push edi
 
    xor esi, esi                ; esi = fila (0..2)
 
.fila:
    cmp esi, 3
    jge .fin
 
    xor edi, edi                ; edi = columna (0..2)
 
.columna:
    cmp edi, 3
    jge .prox_fila
 
    ; guardar indices en memoria (evita usar sil/dil que no existen en 32b)
    mov  eax, esi
    mov  [fila_idx], al
    mov  eax, edi
    mov  [col_idx], al
 
    call mostrar_prompt
 
.reintentar:
    LEER input_buf, 4
    call validar_digito         ; retorna EAX = 0..9, o -1 si invalido
 
    cmp eax, -1
    je  .fallo
 
    ; guardar en matriz[esi*3 + edi]
    push eax                    ; conservar el valor
    mov  ebx, esi
    imul ebx, 3
    add  ebx, edi               ; ebx = indice
    pop  eax
    mov  [matriz + ebx], al     ; guardar byte
 
    inc edi
    jmp .columna
 
.fallo:
    PRINT msg_error, LEN_ERROR
    jmp  .reintentar
 
.prox_fila:
    inc esi
    jmp .fila
 
.fin:
    pop edi
    pop esi
    pop ebp
    ret
 
; ============================================================
; SUBRUTINA: mostrar_prompt  -> "Ingrese M[f][c]: "
; ============================================================
mostrar_prompt:
    push eax
 
    PRINT msg_elem1, LEN_ELEM1
 
    movzx eax, byte [fila_idx]
    add   al, '1'               ; mostrar en base 1
    mov   [buf_fila], al
    PRINT buf_fila, 1
 
    PRINT msg_coma, LEN_COMA
 
    movzx eax, byte [col_idx]
    add   al, '1'
    mov   [buf_col], al
    PRINT buf_col, 1
 
    PRINT msg_cierre, LEN_CIERRE
 
    pop eax
    ret
 
; ============================================================
; SUBRUTINA: validar_digito
; Lee input_buf y bytes_leidos
; Retorna EAX = valor numerico (0-9) si valido
;         EAX = -1 si invalido
; ============================================================
validar_digito:
    push ecx
 
    mov  ecx, [bytes_leidos]
 
    ; sys_read devuelve 0 si EOF (Ctrl+D)
    cmp  ecx, 0
    je   .mal
 
    ; Primer caracter debe ser digito '0'-'9'
    movzx eax, byte [input_buf]
    cmp   al, '0'
    jl    .mal
    cmp   al, '9'
    jg    .mal
 
    ; Si llegaron mas de 2 bytes: el usuario escribio algo como "12\n"
    ; -> rechazar (solo aceptamos un digito)
    cmp  ecx, 2
    jg   .mal           ; mas de digito+Enter -> invalido
 
    ; Puede ser 1 byte (digito sin Enter, raro) o 2 bytes (digito+Enter)
    ; En ambos casos el primer byte ya paso la validacion de arriba
    sub  al, '0'         ; convertir ASCII -> numero
    pop  ecx
    ret
 
.mal:
    ; Vaciar el resto del buffer si quedaron bytes sin leer
    mov eax, -1
    pop ecx
    ret
 
; ============================================================
; SUBRUTINA: calcular_transpuesta  T[j][i] = M[i][j]
; ============================================================
calcular_transpuesta:
    push esi
    push edi
    push eax
    push ebx
    push ecx
 
    xor esi, esi                ; i (fila original)
 
.li:
    cmp esi, 3
    jge .ft
 
    xor edi, edi                ; j (columna original)
 
.lj:
    cmp edi, 3
    jge .si
 
    ; leer M[i][j]
    mov  eax, esi
    imul eax, 3
    add  eax, edi
    movzx ecx, byte [matriz + eax]
 
    ; escribir T[j][i]
    mov  eax, edi
    imul eax, 3
    add  eax, esi
    mov  [transpuesta_m + eax], cl
 
    inc edi
    jmp .lj
 
.si:
    inc esi
    jmp .li
 
.ft:
    pop ecx
    pop ebx
    pop eax
    pop edi
    pop esi
    ret
 
; ============================================================
; SUBRUTINA: imprimir_fila
; Parametros via pila: [esp+4]=puntero base, [esp+8]=nro fila
; ============================================================
imprimir_fila:
    push ebp
    mov  ebp, esp
    push eax
    push ebx
    push ecx
 
    mov  esi, [ebp + 8]         ; puntero base de la matriz
    mov  edi, [ebp + 12]        ; numero de fila
 
    mov  eax, edi
    imul eax, 3
    add  esi, eax               ; esi -> primer elemento de la fila
 
    ; usamos EDI como contador de columna (ECX es destruido por int 0x80)
    xor edi, edi                ; columna = 0
 
.loop:
    cmp edi, 3
    jge .fin_fila
 
    movzx eax, byte [esi + edi]
    add   al, '0'
    mov   [buf_digito], al
    PRINT buf_digito, 1
    PRINT msg_espacio, LEN_ESPACIO
 
    inc edi
    jmp .loop
 
.fin_fila:
    PRINT msg_newline, LEN_NEWLINE
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret
 
; ============================================================
; SUBRUTINA: imprimir_original
; ============================================================
imprimir_original:
    push ebx
    xor  ebx, ebx
 
.loop:
    cmp ebx, 3
    jge .fin
    push ebx            ; segundo parametro: numero de fila
    push matriz         ; primer parametro: puntero base
    call imprimir_fila
    add  esp, 8
    inc  ebx
    jmp  .loop
 
.fin:
    pop ebx
    ret
 
; ============================================================
; SUBRUTINA: imprimir_transpuesta
; ============================================================
imprimir_transpuesta:
    push ebx
    xor  ebx, ebx
 
.loop:
    cmp ebx, 3
    jge .fin
    push ebx            ; segundo parametro: numero de fila
    push transpuesta_m  ; primer parametro: puntero base
    call imprimir_fila
    add  esp, 8
    inc  ebx
    jmp  .loop
 
.fin:
    pop ebx
    ret