             PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608
SYSCTL_PRGPIO		EQU     0x0A08
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
PORTA_BIT               EQU     000000000000001b ; bit  0 = Port A
UART0_BIT               EQU     00000001b        ; bit  0 = UART 0

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
GPIO_DIR                EQU     0x0400
GPIO_IS                 EQU     0x0404
GPIO_IBE                EQU     0x0408
GPIO_IEV                EQU     0x040C
GPIO_IM                 EQU     0x0410
GPIO_RIS                EQU     0x0414
GPIO_MIS                EQU     0x0418
GPIO_ICR                EQU     0x041C
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_PCTL               EQU     0x052C

; UART Definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8

;UART bit definitions
TXFE_BIT                EQU     10000000b ; TX FIFO full
RXFF_BIT                EQU     01000000b ; RX FIFO empty
BUSY_BIT                EQU     00001000b ; Busy


; PROGRAMA PRINCIPAL

__iar_program_start
        
main:   MOV R2, #(UART0_BIT)
	BL UART_enable ; habilita clock ao port 0 de UART

        MOV R2, #(PORTA_BIT)
	BL GPIO_enable ; habilita clock ao port A de GPIO
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b ; bits 0 e 1 como especiais
        BL GPIO_special

	MOV R1, #0xFF ; máscara das funções especiais no port A (bits 1 e 0)
        MOV R2, #0x11  ; funções especiais RX e TX no port A (UART)
        BL GPIO_select

	LDR R0, =UART_PORT0_BASE
        BL UART_config ; configura periférico UART0
        
        

        
loop:   MOV R3, #0  ; armazena um dos numeros da operação
        MOV R9, #10 ; constante 10 para dividir e multiplicar
        MOV R12, #0 ; negativo 
        MOV R11, #0 ;tamanho dos numeros

wrx:    LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #RXFF_BIT 
        BEQ wrx
        LDR R1, [R0] ; lê do registrador de dados da UART0 (recebe)

        B caracter      

wtx:    LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT 
        BEQ wtx
        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
        
        CMP R1, #43 
        BEQ soma
                
        CMP R1, #45 
        BEQ subt
                
        CMP R1, #42 
        BEQ mul
        
        CMP R1, #47 
        BEQ div
        
        CMP R1, #61
        BEQ resul
        
        MOV R2, R1
        SUBS R2, #48 ; converte para ASCII
        MUL  R3, R9  ; multiplica por 10
        ADD R3, R2   ; soma com o valor multiplicado para construir o numero
        ADD R11, #1  ; incrementa tamanho do numero

        B wrx

; SUB-ROTINAS

soma
      MOV R4, R3
      MOV R10, #1
      B loop

subt
      MOV R4, R3
      MOV R10, #2
      B loop

mul
      MOV R4, R3
      MOV R10, #3
      B loop

div
      MOV R4, R3
      MOV R10, #4
      B loop

resul
      CMP R10, #0
      IT EQ
        BLEQ resultado

      CMP R10, #1
      IT EQ
        BLEQ adicao
      
      CMP R10, #2
      IT EQ
        BLEQ Subtracao
        
      CMP R10, #3
      IT EQ
        BLEQ Multiplicacao 
      CMP R10, #4
      IT EQ
        BLEQ Divisao  
      MOV R8, R1  ;Guarda o resultado em R8 para ver se o número foi printado 
      BL dec
      BL print
      MOV R10, #0 ;reset
      BL pula
      B loop
           
dec
      PUSH {LR}
      BL negativo
      POP {LR}
      PUSH {R1}
      SDIV R1, R9
      CBZ R1, retorna
      B dec
retorna
      BX LR
           
negativo
      AND R5, R1, #10000000000000000000000000000000b
      CMP R5, #10000000000000000000000000000000b
      BEQ neg
      BX LR
      
neg
      MVN R1, R1
      ADD R1, #1
      MOV R8, R1  ;Guarda o resultado em R8 para ver se o número foi printado
      MOV R12, #1
      BX LR
      
      
print
      PUSH {LR}
      CMP R12, #1
      IT EQ
        BLEQ printnegativo
      POP {LR}
      POP {R1} 
      ADD R1, #48
      PUSH {LR}
      BL transmite
      POP {LR}
      SUBS R1, #48
      CMP R1, R8 ;Guarda o resultado em R8 para ver se o número foi printado
      IT EQ
        BXEQ LR 
      
loopp
      POP {R7}
      MUL R1, R9
      SUBS R1, R7, R1
      PUSH {R7}
      PUSH {LR}
      ADD R1, #48 ;converte para ASCII
      BL transmite
      POP {LR}
      SUBS R1, #48 ;converte para ASCII
      POP {R1}
      
      CMP R8, R1  ;Guarda o resultado em R8 para ver se o número foi printado
      IT EQ
        BXEQ LR
        
      B loopp

printnegativo
      PUSH {R1}
      MOV R1, #45 ;simbolo negativo
      PUSH {LR}
      BL transmite
      POP {LR}
      POP {R1}
      BX LR

;Confere se tem só número e caracter

caracter:
        
        CMP R1, #48 
        BEQ tam
        
        CMP R1, #49 
        BEQ tam
                
        CMP R1, #50 
        BEQ tam
                
        CMP R1, #51 
        BEQ tam
                
        CMP R1, #52 
        BEQ tam
                
        CMP R1, #53 
        BEQ tam
        
        CMP R1, #54 
        BEQ tam
                
        CMP R1, #55 
        BEQ tam
                
        CMP R1, #56 
        BEQ tam
                
        CMP R1, #57 
        BEQ tam
                
        CMP R1, #43 
        BEQ wtx
                
        CMP R1, #45 
        BEQ wtx
                
        CMP R1, #42 
        BEQ wtx
        
        CMP R1, #47 
        BEQ wtx
        
        CMP R1, #61
        BEQ wtx
        
        B wrx
        
;Confere o tamanho do número
     
tam
        CMP R11, #3
        BEQ wrx
        
        B wtx
       
resultado
     MOV R1, R3
     BX LR
        
adicao
     MOV R1, R3
     ADD R1, R4
     BX LR
    
Subtracao
     MOV R1, R4
     SUBS R1, R3
     BX LR

Multiplicacao
     MOV R1, R3
     MULS R1, R4
     BX LR 

Divisao
     MOV R1, R4
     SDIV R1, R3
     BX LR   

;----------
; UART_enable: habilita clock para as UARTs selecionadas em R2
; R2 = padrão de bits de habilitação das UARTs
; Destrói: R0 e R1
UART_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCUART]
	ORR R1, R2 ; habilita UARTs selecionados
	STR R1, [R0, #SYSCTL_RCGCUART]

waitu	LDR R1, [R0, #SYSCTL_PRUART]
	TEQ R1, R2 ; clock das UARTs habilitados?
	BNE waitu

        BX LR
        
; UART_config: configura a UART desejada
; R0 = endereço base da UART desejada
; Destrói: R1
UART_config:
        LDR R1, [R0, #UART_CTL]
        BIC R1, #0x01 ; desabilita UART (bit UARTEN = 0)
        STR R1, [R0, #UART_CTL]

         ;  baud rate = 9600 bps
        MOV R1, #104
        STR R1, [R0, #UART_IBRD]
        MOV R1, #11
        STR R1, [R0, #UART_FBRD]
        
        ; 8 bits, 1 stop, parity odd
        MOV R1, #0x6A
        STR R1, [R0, #UART_LCRH]
        
        ; clock source = system clock
        MOV R1, #0x00
        STR R1, [R0, #UART_CC]
        
        LDR R1, [R0, #UART_CTL]
        ORR R1, #0x01 ; habilita UART (bit UARTEN = 1)
        STR R1, [R0, #UART_CTL]

        BX LR


; GPIO_special: habilita funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como funções especiais
; Destrói: R2
GPIO_special:
	LDR R2, [R0, #GPIO_AFSEL]
	ORR R2, R1 ; configura bits especiais
	STR R2, [R0, #GPIO_AFSEL]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_select: seleciona funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem alterados
; R2 = padrão de bits (1) a serem selecionados como funções especiais
; Destrói: R3
GPIO_select:
	LDR R3, [R0, #GPIO_PCTL]
        BIC R3, R1
	ORR R3, R2 ; seleciona bits especiais
	STR R3, [R0, #GPIO_PCTL]

        BX LR
;----------

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R2
; R2 = padrão de bits de habilitação dos ports
; Destrói: R0 e R1
GPIO_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCGPIO]
	ORR R1, R2 ; habilita ports selecionados
	STR R1, [R0, #SYSCTL_RCGCGPIO]

waitg	LDR R1, [R0, #SYSCTL_PRGPIO]
	TEQ R1, R2 ; clock dos ports habilitados?
	BNE waitg

        BX LR

; GPIO_digital_output: habilita saídas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como saídas digitais
; Destrói: R2
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de saída
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_write: escreve nas saídas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits a serem escritos
GPIO_write:
        STR R2, [R0, R1, LSL #2] ; escreve bits com máscara de acesso
        BX LR

; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como entradas digitais
; Destrói: R2
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; GPIO_read: lê as entradas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits lidos
GPIO_read:
        LDR R2, [R0, R1, LSL #2] ; lê bits com máscara de acesso
        BX LR

; SW_delay: atraso de tempo por software
; R0 = valor do atraso
; Destrói: R0
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        BX LR
        
;Para dar um \n depois de cada operação
pula
        PUSH {LR}
        LDR R3, =lf 
        LDR R1, [R3] 
        BL transmite 
        LDR R3, =cr 
        LDR R1, [R3] 
        BL transmite 
        POP {LR}
        BX LR      

transmite
        STR R1, [R0] ; transmite para a UART0
        
        PUSH {R0}
        MOV R0, #0x2000 ; atraso
        PUSH {LR}
        BL SW_delay
        POP {LR}
        POP {R0}
        
        BX LR


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; seção de constantes em ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        SECTION .rodata:CONST(2)
        DATA

lf          DC8  00001010b
cr          DC8  00001101b

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Interrupt vector table.
;;

        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END