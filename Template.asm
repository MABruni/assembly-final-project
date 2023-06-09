TITLE Program Template     (template.asm)

; Author: 
; Last Modified:
; OSU email address: ONID_ID@oregonstate.edu
; Course number/section:   CS271 Section ???
; Project Number:                 Due Date:
; Description: This file is provided as a template from which you may work
;              when developing assembly projects in CS271.

INCLUDE Irvine32.inc

mGetString MACRO    promptAddress,  answerAddress,  buffer,   charInput
    ; Saves used registers
    push    edx         
    push    ecx
    push    eax

    mDisplayString  promptAddress
    mov     edx,    answerAddress            ; Display prompt
    mov		ecx,    buffer  
    call    ReadString
    mov     answerAddress,  edx
    mov     charInput,      eax

    ; Restores used registers
    pop     eax
    pop     ecx         
    pop     edx
ENDM

mDisplayString MACRO    stringAddress
    push    edx

    mov     edx,    stringAddress    ; Memory location of the string
    call    WriteString

    pop     edx
ENDM

.data

greeting	    BYTE	"ASSIGNMENT 6: Designing low-level I/O procedures by Miguel Angel Bruni",13,10,0
intro1		    BYTE	"Please provide 10 signed decimal integers. Each number needs to be small enough to fit inside a 32 bit register.",13,10,0
intro2		    BYTE	"After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",13,10,0
userPrompt	    BYTE	"Please, enter a signed integer: ",0
error           BYTE    "Invalid input. Please enter a valid integer.", 0
numbersText     BYTE    "The numbers you inputted were: ",0
sumText         BYTE    "Sum of your numbers: ", 0
averageText     BYTE    "Truncated average of your numbers: ", 0
comma           BYTE    ", "
bytesRead       DWORD   0
inputArray      SDWORD  10 DUP(?)
arraySize       DWORD   TYPE inputArray
userAnswer      DWORD   41 DUP(?)
inputBuffer     DWORD   40
stringResult    DWORD   14 DUP(?)
position        DWORD   0
readValResult   SDWORD  0
sum             SDWORD  0
count           SDWORD  10
average         SDWORD  0

.code
main PROC

    
mDisplayString  OFFSET  greeting
  
mDisplayString  OFFSET  intro1

mDisplayString  OFFSET  intro2

call    Crlf
mov     ecx,    count
mov     edi,    OFFSET  inputArray

_inputs:
push    OFFSET  error               ;[ebp+28]
push    OFFSET  readValResult       ;[ebp+24]
push    OFFSET  userPrompt          ;[ebp+20]
push    OFFSET  userAnswer          ;[ebp+16]
push    inputBuffer                 ;[ebp+12]
push    OFFSET  bytesRead           ;[ebp+8]
call    ReadVal

cmp     readValResult,  2147483648
jne     _addResult
inc     ecx
LOOP    _inputs

_addResult:
mov     eax,    readValResult
cld
stosd
LOOP    _inputs
call    Crlf


; Code to calculate sum
mov     ecx,    count
xor     edx,    edx
mov     esi,    OFFSET inputArray
_calculate:
cld
lodsd 
add     edx,    eax
_continue:
LOOP    _calculate
mov     sum,    edx

; Code to calculate average
mov     eax,    sum
xor     edx,    edx
mov     ebx,    10
cdq
idiv    ebx
mov     average,    eax

; WriteVal calls
mov     ecx,    count
mov     esi,    OFFSET inputArray
mov     edx,    arraySize
mDisplayString  OFFSET numbersText

_printNumbersAsStrings:
push    OFFSET  stringResult        ;[ebp+12]
push    [esi]                       ;[ebp+8]
call    WriteVal
add     esi,    arraySize
cmp     ecx,    1
je      _noComma
mDisplayString  OFFSET comma
_noComma:
LOOP    _printNumbersAsStrings
call    Crlf

mDisplayString  OFFSET  sumText
push    OFFSET stringResult
push    sum
call    WriteVal
call    Crlf

mDisplayString  OFFSET  averageText
push    OFFSET stringResult
push    average
call    WriteVal


	Invoke ExitProcess,0	; exit to operating system
main ENDP

ReadVal PROC
    push    ebp
    mov     ebp,        esp
    push    eax
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi

    mGetString  [ebp+20], [ebp+16], [ebp+12], [ebp+8]

    mov     esi,        [ebp+16]
    xor     edi,        edi
    mov     ecx,        [ebp+8]
    cld
    lodsb
    movsx   eax,        al

    _initialSizeCheck:
    cmp     ecx,        11
    jg      _sizeInputError

    _plusSignCheck:
    cmp     eax,        43
    jne     _minusSignCheck
    dec     ecx
    mov     [ebp+8],    ecx
    mov     ebx,        0           ; Counter to check if we need to do negation
    jmp     _checkLoop

    _minusSignCheck:
    cmp     eax,        45
    jne     _sizeWithoutSign        
    dec     ecx
    mov     [ebp+8],    ecx
    mov     ebx,        1           ; Counter to check if we need to do negation
    jmp     _checkLoop

    _sizeWithoutSign:
    mov     ebx,        0
    cmp     ecx,        10
    jg      _inputError
    jmp     _numbersCheck

    _checkLoop:
    lodsb
    movsx   eax,        al

    ; Rest of numbers check
    _numbersCheck:
    cmp     eax,        48
    jl      _inputError
    cmp     eax,        57
    jg      _inputError
    sub     eax,        48
    push    ebx
    push    eax
    push    ecx
    mov     eax,        1

    _decimalPosition:
    cmp     ecx,        1
    je      _continue
    xor     edx,        edx
    mov     ebx,        10
    mul     ebx
    LOOP    _decimalPosition

    _continue:
    pop     ecx             ; Restore ecx
    pop     ebx             ; eax value to ebx for multiplying
    mul     ebx
    pop     ebx             ; Restore ebx flag
    inc     edi             ; Counter for numbers pushed
    _pushValue:
    push    eax             ; Number stored
    LOOP    _checkLoop

    pop     eax
    cmp     edi,        1
    je      _sign
    mov     ecx,        edi
    dec     ecx

    _getNumber:
    pop     edx
    add     eax,        edx
    LOOP    _getNumber

    _sign:
    cmp     ebx,        1
    jne     _positive
    neg     eax
    mov     ebx,        [ebp+24]
    mov     [ebx],      eax
    cmp     eax,        -2147483648
    jb      _inputError
    jmp     _end

    _positive:
    mov     ebx,        [ebp+24]
    mov     [ebx],      eax
    cmp     eax,        2147483647
    ja      _inputError
    jmp     _end

    _inputError:
    xor     edx,        edx
    mov     eax,        edi
    mov     edi,        4
    mul     edi
    add     esp,        eax

    _sizeInputError:
    mov     eax,        2147483648
    mov     ebx,        [ebp+24]
    mov     [ebx],      eax
    mDisplayString      [ebp+28]
    call    Crlf

    _end:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax
    mov     esp,    ebp
    pop     ebp
    ret     24

ReadVal ENDP

WriteVal PROC
    push    ebp
    mov     ebp,    esp
    push    edi
    push    eax
    push    ebx
    push    ecx
    push    edx

    mov     edi,    [ebp+12]
    mov     ebx,    10
    mov     eax,    [ebp+8]
    xor     ecx,    ecx

    ; Handle 0 value
    cmp     eax,    0
    jne     _signCheck
    push    eax
    xor     eax,    eax
    mov     al,     48
    cld
    stosb
    pop     eax
    inc     ecx
    jmp     _finish

    ; Handle negative values
    _signCheck:
    cmp     eax,    0
    jns     _positive
    neg     eax
    push    eax
    xor     eax,    eax
    mov     al,     45
    cld
    stosb
    inc     ecx
    pop     eax

    _positive:
    xor     edx,    edx
    cdq
    div     ebx
    push    edx
    mov     ecx,    1
    cmp     eax,    0
    je     _getNumbers

    _continue:
    cdq
    div     ebx
    push    edx
    inc     ecx
    cmp     eax,    0
    jne     _continue
    mov     edx,    ecx

    _getNumbers:

    pop     eax
    add     eax,    48
    cld
    stosb
    LOOP    _getNumbers

    _finish:
    mov     eax,    0       ; null terminator
    cld
    stosb

    mDisplayString  [ebp+12]

    pop     edx
    pop     ecx
    pop     ebx
    pop     eax
    pop     edi
    mov     esp,    ebp
    pop     ebp
    ret     8
WriteVal ENDP

END main