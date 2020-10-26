org 100h

;------------------NOTA-------------------
;-----------------------------------------
; El ciclo de ejecucion (loop de juego)
; no puede superar 1 segundo o no se 
; registraria de forma correcta el cambio 
; entre segundos del cronometro.
;------------------------------------------
;------------------------------------------

;MACROS

%macro print 3 		;x0,y0,cadena
	push dx
	push ax
	push di
	push si
	xor ax,ax
    xor dx,dx

	mov ah,02h
	mov dh,%2	;posicion Y
	mov dl,%1	;posicion X
	int 10h

	mov dx,%3	;puntero de la cadena a imprimir
	mov ah,9h
	int 21h
	pop si
	pop di
	pop ax
	pop dx
%endmacro

%macro convertir_ascii 1 	;numero a convertir, el arreglo de asciis se almacena en asciiNum 
	push ax
    push bx
    push di
    push si
    push dx
    xor ax,ax
    xor bx,bx
    xor di,di
    xor si,si
    mov ax,%1
    mov bx,10

	%%dividir:
		xor dx,dx  
		div bx
		add dx,48
		mov pila[di],dx
		inc di 
		cmp ax,1
		jae %%dividir
	%%cargarNum:
		xor ax,ax
		dec di
		mov ax,pila[di]
		mov asciiNum[si],ax
		inc si
		cmp di,0
		je %%mostrar
		jmp %%cargarNum
	%%mostrar:
		mov dx,'$'
		mov asciiNum[si],dx
		pop dx
		pop si	
		pop di
		pop bx
		pop ax
		
%endmacro



;DATA SEGMENT

section .data

pila times 10 db '$'			;variable usada para convertir un numero a ascii
asciiNum times 10 db '$'		;variable que almacena el ascii de los numeros convertidos

init db 0 					;variable que almacena el valor de referencia de los segundos
contador dw 0				;variable que almacena la cantidad de segundos transcurridos
segundos dw 0				;almacena los minutos
minutos dw 0				;almacena los segundos
separador db ':','$'		;separador de segundos y minutos
cero db '0','$'				;cero 0
tiempoInit db '00:00','$'	;tiempo inicial



;CODE SEGMENT

section .text
global _start

_start:
	mov ax,13h
	int 10h
	print 17,10,tiempoInit
	call tiempo_inicial
	jmp ciclo

ciclo:
	call cronometro
	call delay
	jmp ciclo

cronometro:		;verifica si hay un cambio en el tiempo
	xor dx,dx
	xor cx,cx
	xor ax,ax

	mov ah,02h				;la funcion 02h regresa el tiempo actual, dh=segundos cl=minutos ch=horas 
	int 1Ah					;usa la interrupcion 1Ah

	cmp dh,init[0]			;se compara con el valor de init
	je .fin					;si es igual no se deben aumentar los segundos

	xor ax,ax
	mov init[0],ah		;se limpia la variable
	mov init[0],dh		;se le coloca el nuevo valor

	xor ax,ax
	mov ax,1
	add contador[0],ax	;se aumenta en 1 el contador de segundos

	xor ax,ax
	xor bx,bx
	xor dx,dx

	mov ax,contador[0]	
	mov bx,60
	div bx					;se hace una division entre los segundos contados y 
							;60 para saber los minutos transcurridos

	mov cx,cx
	mov segundos[0],cx		;se limpian los segundos
	mov segundos[0],dx		;se le asigna el residuo de la division


	xor cx,cx
	mov minutos[0],cx		;se limpian los minutos
	mov minutos[0],ax		;se le asigna el cociente de la division

	call pintar_cronometro	;se pinta el cronometro

	.fin:
	ret

pintar_cronometro: 	;dibuja el cronometro en las coordenadas que se le indiquen

	convertir_ascii minutos[0] ;se convierten los minutos a ascii

	xor ax,ax
	mov ax,'$'
	cmp ax,asciiNum[1]		;se verifica si es una cifra de 2 digitos 
								;(de no serlo la 2da posicion del arreglo seria '$')
	je .pintarMin				;si la 2da posicion es igual a '$' se salta a 'pintarMin'
	print 17,10,asciiNum	;de no serlo se imprime el numero de 2 cifras.
	.pintarMin:			
	print 17,10,cero			;se imprime un cero antes del digito que contiene la minAscii
	print 18,10,asciiNum	;se imprime minAscii

	.pintarSeparador:
	print 19,10,separador		;se imprime ':' para separar los segundos


	;se repite el mismo proceso de antes pero ahora con los segundos

	convertir_ascii segundos[0]
	xor ax,ax				
	mov ax,'$'
	cmp ax,asciiNum[1]		
	je .pintarSeg
	print 20,10,asciiNum
	jmp .fin
	.pintarSeg:
	print 20,10,cero
	print 21,10,asciiNum

	.fin:
		ret

tiempo_inicial: 	;asigna los valores iniciales o de referencia a init y pone contador en 0
	xor ax,ax
	mov ah,02h
	int 1Ah
	mov init[0],dh		;se le asignan los segundos actuales a init
	xor ax,ax
	mov contador[0],ax	;se limpia el contador

	ret

delay:	;Es un delay xd
	mov cx, 0000h   ;tiempo del delay
  	mov dx, 2fffh  ;tiempo del delay    
  	mov ah,86h
  	int 15h
	ret