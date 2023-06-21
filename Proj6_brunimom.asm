TITLE Low-level I/O procedures     (Proj6_brunimom.asm)

; Author: Miguel Angel Bruni Montero
; Last Modified: 6/10/23
; OSU email address: brunimom@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: Project 6 - String Primitives and Macros    Due Date: 6/11/23
; Description: The program asks user for number input, registers this input as a string
; and uses low-level I/O procedures to store these strings as integers in an array. Then,
; it calculates the sum and average of these numbers. Finally, it prints back the list of
; numbers as strings, the sum and the average.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Prompts the user to input a number and stores it as a string in answerAddress.
;
; Preconditions: None, saves and restores registers used.
;
; Receives:
; promptAddress = prompt address
; answerAddress = address to store the user's answer
; buffer = maximum size for the user's answer
; charInput = number of characters in the user's input
;
; returns:
; answerAddress = user's answer
; charInput = number of characters in user's answer
; ---------------------------------------------------------------------------------
mGetString MACRO    promptAddress,  answerAddress,  buffer,   charInput
    ; Saves used registers
    push    edx         
    push    ecx
    push    eax

    mDisplayString  promptAddress       ; Display prompt
    mov     edx,    answerAddress        
    mov		ecx,    buffer  
    call    ReadString
    mov     answerAddress,  edx         ; Save user answer      
    mov     charInput,      eax         ; Save characters inputted

    ; Restores used registers
    pop     eax
    pop     ecx         
    pop     edx
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints a string passed as an argument to the console.
;
; Preconditions: None, saves and restores registers used.
;
; Receives:
; stringAddress = address of the string to be printed.
;
; returns: None
; ---------------------------------------------------------------------------------
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
tooBig          DWORD   0
readValResult   SDWORD  0
sum             SDWORD  0
count           SDWORD  10
average         SDWORD  0

.code
main PROC
    
    mDisplayString      OFFSET  greeting
  
    mDisplayString      OFFSET  intro1

    mDisplayString      OFFSET  intro2

    call    Crlf
    mov     ecx,        count
    mov     edi,        OFFSET  inputArray      ; Load the array in edi to store results.

    ; ----------------------------------------------------
    ; Get user's input as a string, performs data validation, converts the result to a signed integer
    ;       and stores that result in inputArray for future calculations.
    ; ----------------------------------------------------
    _inputs:
        ; Passes parameters to ReadVal
        push    OFFSET      tooBig              ;[ebp+32]
        push    OFFSET      error               ;[ebp+28]
        push    OFFSET      readValResult       ;[ebp+24]
        push    OFFSET      userPrompt          ;[ebp+20]
        push    OFFSET      userAnswer          ;[ebp+16]
        push    inputBuffer                     ;[ebp+12]
        push    OFFSET      bytesRead           ;[ebp+8]
        call    ReadVal

         ; If number is too big, prevents ecx from decrementing and asks for new input
        cmp     tooBig,     1
        jne     _addResult
        inc     ecx                            
        mov     tooBig,     0
        LOOP    _inputs

    _addResult:
        ; If number is correct, stores result in inputArray.
        mov     eax,        readValResult
        cld
        stosd
        LOOP    _inputs
        call    Crlf

    ; Code to calculate sum
    mov     ecx,        count
    xor     edx,        edx                 ; Clears edx to hold sum
    mov     esi,        OFFSET inputArray   ; Loads input array in esi

    _calculate:
        cld
        lodsd                               ; Loads array values in eax
        add     edx,        eax             

    _continue:
        LOOP    _calculate
        mov     sum,        edx             ; Saves sum in variable

        ; Code to calculate average
        mov     eax,        sum
        xor     edx,        edx
        mov     ebx,        10
        cdq
        idiv    ebx
        mov     average,    eax             ; Saves average in variable

        ; WriteVal calls
        mov     ecx,        count
        mov     esi,        OFFSET inputArray
        mov     edx,        arraySize
        mDisplayString      OFFSET numbersText  ; Prints text preceding results

    _printNumbersAsStrings:
        push    OFFSET stringResult         ;[ebp+12]
        push    [esi]                       ;[ebp+8]
        call    WriteVal                    ; Prints to screen values in the array.

        add     esi,        arraySize       ; Moves to next object in array.
        cmp     ecx,        1
        je      _noComma
        mDisplayString  OFFSET comma        ; Displays commas between strings.

    _noComma:
        LOOP    _printNumbersAsStrings
        call    Crlf

    mDisplayString  OFFSET  sumText         ; Displays text preceding the sum

    push    OFFSET stringResult
    push    sum
    call    WriteVal                        ; Prints to screen the sum
    call    Crlf

    mDisplayString  OFFSET  averageText

    push    OFFSET stringResult
    push    average
    call    WriteVal                        ; Prints to screen the average

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Calls mGetString to get user input and converts said value to a signed integer using
;   string primitives. Saves and restores registers used.
;
; Preconditions: mGetString needs to be defined.
;
; Receives:
; [ebp+8] = number of characters read from user answer
; [ebp+12] = maximum size for the user's answer
; [ebp+16] = address that stores the user's answer
; [ebp+20] = prompt asking the user for input
; [ebp+24] = variable to store the result of converting the string to a signed integer
; [ebp+28] = prompt informing the user of a wrong input
; [ebp+32] = variable to store if the number inputted is too big
;
; returns:
; [ebp+24] = integer obtained from converting the string.
; [ebp+32] = flag indicating if the number is bigger than 32 bits.
; ---------------------------------------------------------------------------------
ReadVal PROC
    ; Saves registers used by the procedure.
    push    ebp
    mov     ebp,        esp
    push    eax
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi

    ; Gets input from the user
    mGetString  [ebp+20], [ebp+16], [ebp+12], [ebp+8]

    ; Initializes variables for future calculations
    mov     esi,        [ebp+16]
    xor     edi,        edi
    mov     ecx,        [ebp+8]

    ; Loads first character into al
    cld
    lodsb
    movsx   eax,        al          ; Sign extends al to perform calculations.

    ; Checks to see if number inputted is really large.
    _initialSizeCheck:
        cmp     ecx,        11
        jg      _sizeInputError
    
    ; Checks for the presence of a plus sign.
    _plusSignCheck:
        cmp     eax,        43
        jne     _minusSignCheck
        dec     ecx
        mov     [ebp+8],    ecx         ; Updates characters inputted to ignore the sign.
        mov     ebx,        0           ; Counter to check if we need to do negation later.
        lodsb
        movsx   eax,        al

        ; Checks if the number is the maximum length for a 32bit 
        ; and if the first number is higher than 2 (too large)
        cmp     ecx,        10
        jne     _numbersCheck
        cmp     eax,        50
        jg      _inputError  
        jmp     _numbersCheck

    _minusSignCheck:
        cmp     eax,        45
        jne     _sizeWithoutSign        
        dec     ecx
        mov     [ebp+8],    ecx         ; Updates characters inputted to ignore the sign.
        mov     ebx,        1           ; Counter to check if we need to do negation later.
        lodsb
        movsx   eax,        al

        ; Checks if the number is the maximum length for a 32bit 
        ; and if the first number is higher than 2 (too large)
        cmp     ecx,        10
        jne     _numbersCheck
        cmp     eax,        50
        jg      _inputError  
        jmp     _numbersCheck

    _sizeWithoutSign:
        mov     ebx,        0
        cmp     ecx,        10
        jg      _inputError

        ; Checks if the number is the maximum length for a 32bit 
        ; and if the first number is higher than 2 (too large)
        cmp     ecx,        10
        jne     _numbersCheck
        cmp     eax,        50
        jg      _inputError      
        jmp     _numbersCheck
    
    ; Loads a new value to check.
    _checkLoop:
        lodsb
        movsx   eax,        al

    ; Checks characters to see if they are valid inputs.
    _numbersCheck:
        cmp     eax,        48
        jl      _inputError
        cmp     eax,        57
        jg      _inputError
        sub     eax,        48
        ; Saves eax, ebx and ecx to preserve their values.
        push    ebx                 ; Sign flag.
        push    eax                 ; Number obtained from character
        push    ecx                 ; Counter
        mov     eax,        1       ; Initializes eax for multiplication.

    ; Calculates the decimal position of the number.
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
        inc     edi             ; Counter for numbers pushed to the stack.

    _pushValue:
        push    eax             ; Stores the number after multiplying by its decimal position.
        LOOP    _checkLoop

    pop     eax                 ; Gets first number obtained
    cmp     edi,        1       ; Goes to sign if the number only has one integer.
    je      _sign
    ; Copies number of integers pushed to ecx to use as a counter and updates them to rmove
    ; the first number already popped.
    mov     ecx,        edi
    dec     ecx
    dec     edi

    ; Gets the rest of the numbers and adds them to get the actual number.
    _getNumber:
        pop     edx
        add     eax,        edx
        dec     edi
        LOOP    _getNumber

    ; Checks ebx (sign flag) and performs operations as appropriate.
    _sign:
        cmp     ebx,        1
        jne     _positive
        ; If it is negative, negate the value and compare its 2's complement
        neg     eax    
        cmp     eax,        2147483648
        jb      _inputError             ; If it is less than that value, it means it overflowed.
        mov     ebx,        [ebp+24]
        mov     [ebx],      eax
        jmp     _end

    _positive:
        cmp     eax,        2147483647
        ja      _inputError             ; If it is more than that it means it was too large of a positive number.
        mov     ebx,        [ebp+24]
        mov     [ebx],      eax
        jmp     _end

    ; Cleans the stack if at any point an invalid input is found.
    _inputError:
        xor     edx,        edx
        mov     eax,        edi
        mov     edi,        4
        mul     edi
        add     esp,        eax

    ; Prints the error message to the console.
    _sizeInputError:
        mov     eax,        1
        mov     ebx,        [ebp+32]
        mov     [ebx],      eax
        mDisplayString      [ebp+28]
        call    Crlf
    
    ; Restores registers used.
    _end:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        mov     esp,        ebp
        pop     ebp
        ret     28

ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts a signed integer into a string before printing it to the console using
;   mDisplayString. Saves and restores registers used.
;
; Preconditions: mDisplayString needs to be defined.
;
; Receives:
; [ebp+8] = signed integer that is going to be converted into a string.
; [ebp+12] = variable to store the string obtained after converting the signed integer.
;
; returns: None
; ---------------------------------------------------------------------------------
WriteVal PROC
    ; Saves registers used by the procedure.
    push    ebp
    mov     ebp,        esp
    push    edi
    push    eax
    push    ebx
    push    ecx
    push    edx

    ; Initializes variables for future calculations.
    mov     edi,        [ebp+12]
    mov     ebx,        10
    mov     eax,        [ebp+8]
    xor     ecx,        ecx         ; Tracks number of integers in the number.

    ; Handle 0 value.
    cmp     eax,        0
    jne     _signCheck
    push    eax
    xor     eax,        eax
    mov     al,         48
    cld
    stosb
    pop     eax
    inc     ecx
    jmp     _finish

    ; Handle negative values
    _signCheck:
        cmp     eax,        0
        jns     _positive
        ; Adds negative sign to the start of the string.
        push    eax
        xor     eax,        eax
        mov     al,         45
        cld
        stosb

        ; If the number is negative, divides the value by 10
        ; then negate the remainder to store for later, then
        ; negates the quotient for future calculations.
        ; (this handles cases where firs division would overflow)
        inc     ecx
        pop     eax
        xor     edx,        edx
        cdq
        idiv    ebx
        neg     edx
        push    edx
        neg     eax
        cmp     eax,        0       ; Reached the end of the number.
        jne     _continue
        jmp     _getNumbers

    
    _positive:
        xor     edx,        edx
        cdq
        div     ebx
        push    edx
        mov     ecx,        1       
        cmp     eax,        0       ; Reached the end of the number.
        je     _getNumbers

    _continue:
        cdq
        div     ebx
        push    edx
        inc     ecx
        cmp     eax,        0       ; Reached the end of the number.
        jne     _continue
        mov     edx,        ecx

    ; Adds rest of the numbers to the string.
    _getNumbers:
        pop     eax
        add     eax,        48
        cld
        stosb
        LOOP    _getNumbers

    _finish:
        mov     eax,        0       ; null terminator
        cld
        stosb

        mDisplayString  [ebp+12]

        ; Restores registers used.
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        pop     edi
        mov     esp,        ebp
        pop     ebp
        ret     8
WriteVal ENDP

END main