//***************************************************************
//Universidad del Valle de Guatemala 
//IE2023: Programación de Microcontroladores
//Autor: Héctor Alejandro Martínez Guerra
//Hardware: ATMEGA328P
//Post_Lab 1
//***************************************************************

//***************************************************************
//ENCABEZADO
//***************************************************************
.include "M328PDEF.inc"
.cseg 
.org 0x00

//***************************************************************
//Configuración de la Pila
//***************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R16, HIGH(RAMEND)
OUT SPH, R16
//***************************************************************

SETUP:
    LDI R16, 0b0010_0000
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16				;Habilita el prescaler
    LDI R20, 0
    OUT PORTC, R20
    STS UCSR0B, R20

    LDI R16, 0b00000100
    STS CLKPR, R16				;Se define un prescaler de 8fcpu = 1MHz 


;Configuración  de E/S para contador1 y contador2
	LDI R16, 0b11111111			;Configura PORTD como salida
	OUT DDRD, R16

    LDI R16, 0x00
    OUT DDRC, R16				;Configura PORTC como entrada
	
	LDI R16, 0xFF
    OUT PORTC, R16				;Activa pull-up en PORTC

;Configuración de indicador de resultado
	LDI	R16, 0b11111111			;Configura PORTB como salida (PB0-PB3 para resultado y PB4 para carry)
	OUT DDRB, R16


;bucle principal
MAIN_LOOP:
	RCALL read_sw1				;Leer botones de contador1
	RCALL read_sw2				;Leer botones de contador2

	SBIS PINC, PC4				;Verifica si el botón de suma esta presionado (activo en bajo)
	RCALL SUMA_CONTADORES		;Si esta presionado, realiza la suma de los contadores

	RJMP MAIN_LOOP				;Repite el ciclo continuamente

;Primer contador
read_sw1:
    IN R20, PINC				;Lee el estado de los botones
    ANDI R20, 0x03				;Solo considera los dos botones (0011)

    //Reset
    CPI R20, 0x00				;PC0 y PC1 son 0?
    BREQ reset1					;si es así, salta a reset1

    //Botón Ascendente
    CPI R20, 0x01				;PC0 es 1?
    BREQ ascendente1			;si es así, salta a ascendente1

    //Botón Descendente
    CPI R20, 0x02				;PC1 es 1?
    BREQ descendente1			;si es así, salta a ascendente1

	RET							;Regresar al bucle principal

reset1:
    CLR R26						;Reinicia el contador
    RCALL update_leds1
	RET

ascendente1:
    CPI R26, 0x0F				;Comprobar límite superior
    BREQ read_sw1
    INC R26						;Incrementa el contador
    RCALL delay					;Llama a la función de delay
	RCALL update_leds1
	RET

descendente1:
    CPI R26, 0x00				;Comprobar límite inferior
    BREQ read_sw1
    DEC R26						;Decrementa el contador
    RCALL delay					;Llama a la función de delay
    RCALL update_leds1
	RET

update_leds1:
	IN R24, PORTD				;Leer el estado del puerto actual
	ANDI R24, 0xF0				;Limpiar PD0-PD3, mantener PD4-PD7 intactos
	ANDI R26, 0x0F				;Asegurar que el valor del contador del en el rango de 4 bits
	OR R24, R26					;Combinar con el valor del contador
	OUT PORTD, R24				;Acutalizar el puerto
	RET

;Segundo contador
read_sw2:
    IN R21, PINC				;Lee el estado de los botones
    ANDI R21, 0x0C				;Solo considera los dos botones (1100)

	//Reset
    CPI R21, 0x00				;PC2 y PC3 son 0?
    BREQ reset2					;si es así, salta a reset2

    //Botón Ascendente
    CPI R21, 0x04				;PC2 es 1?
    BREQ ascendente2			;si es así, salta a ascendente2

    //Botón Descendente
    CPI R21, 0x08				;PC3 es 1?
    BREQ descendente2			;si es así, salta a descendente2

	RET

reset2:
    CLR R22						;Reinicia el contador
	RCALL update_leds2
    RET

ascendente2:
    CPI R22, 0x0F				;Comprobar límite superior
    BREQ read_sw2
    INC R22						;Incrementa el contador
    RCALL delay					;Llama a la función de delay
    RCALL update_leds2
	RET

descendente2:
    CPI R22, 0x00				;Comprobar límite inferior
    BREQ read_sw2
    DEC R22						;Decrementa el contador
    RCALL delay					;Llama a la función de delay
	RCALL update_leds2
	RET

update_leds2:
	IN R24, PORTD				;Leer el estado del puerto
	ANDI R24, 0x0F				;Limpiar PD4-PD7, mantener PD0-PD3 intactos
    MOV R25, R22
    SWAP R25					;Mover el valor del contador a PD4-PD7
    ANDI R25, 0xF0				;Asegurar que solo afecte a PD4-PD7
	OR R24, R25					;Combinar con el puerto actual				
    OUT PORTD, R24				;Actualizar el puerto
    RET
	
SUMA_CONTADORES:
    CLR R18						;Limpiar R18 antes de la suma
    MOV R18, R26				;Copiar el contador 1 a R18
    ADD R18, R22				;Sumar el contador 2

    CPI R18, 16					;Comparar si el resultado es mayor a 15
    BRGE CARRY_ON				;Si es mayor o igual a 16, manejar carry

    ;Si NO hay Carry, mostrar el resultado en PB0–PB3
    IN R19, PORTB				;Leer el estado actual de PORTB
    ANDI R19, 0xF0				;Limpiar PB0–PB3, mantener PB4 intacto
    ANDI R18, 0x0F				;Asegurar que solo los 4 bits menos significativos estén activos
    OR R19, R18					;Combinar el resultado con PORTB
    OUT PORTB, R19				;Mostrar el resultado en PB0–PB3

    CBI PORTB, 4				;Apagar el LED de Carry (PB4) si NO hay Carry
    RET							;Retorna al bucle principal

CARRY_ON:
    SBI PORTB, 4				;Enciende el LED de Carry en PB4

    ;Apagar los LEDs de resultado (PB0–PB3) porque hay overflow
    IN R19, PORTB
    ANDI R19, 0xF0				;Limpiar PB0–PB3 sin afectar PB4
    OUT PORTB, R19				;Escribir nuevo valor con PB4 encendido

    RET							;Retorna después de manejar el Carry


delay:
    LDI R17, 120				;Carga el contador de delay

ANT0:
    LDI R18, 100				;Carga el contador de delay interno

ANT1:
    LDI R19, 100				;Carga otro contador de delay interno

ANT2:
    NOP							;No operación
    DEC R19						;Decrementa el contador interno
    BRNE ANT2					;Si no ha llegado a cero, vuelve a ANT2
    DEC R18						;Decrementa el contador interno
    BRNE ANT1					;Si no ha llegado a cero, vuelve a ANT1
    DEC R17						;Decrementa el contador de delay
    BRNE ANT0					;Si no ha llegado a cero, vuelve a ANT0
    RET							;Regresa de la función de delay
