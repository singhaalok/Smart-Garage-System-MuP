#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here
jmp     st1
nop
	dw		0000
	dw		0000
	dw		nmi_close_gate
	dw		0000
	db		1012 dup(0)
count		dd		1
gate_status	db		0
divisor		equ		10
lcd0		db		'a'		;to display OR with 00110000b
lcd1		db		'b'
lcd2		db		'c'
lcd3		db		'd'
disp_empty	db		01000101b,	01101101b,	01110000b,	01110100b,	01111001b
disp_full	db		01000110b,	01110101b,	01101100b,	01101100b,	00000010b
disp_init	db		38h,	38h,	0fh,	06h,	01h,	80h

;ports
port_a	equ	00h
port_b	equ	02h
port_c	equ 04h
c_reg	equ 06h

timer_0	equ		08h
timer_1 equ		0ah
timer_2 equ		0ch
timer_reg equ	0eh

;main program

st1:      cli
; intialize ds, es,ss to start of RAM
mov		ax,0200h
mov		ds,ax
mov		es,ax
mov		ss,ax
mov		sp,0FFFEH

;initialize 8255
mov		al,		10000010b
out		c_reg,	al
call	delay_200

;initialise LCD looped
		mov		cx,6
		lea		di, disp_init
		
x1:		mov       al,30h
		out       04h,al
		call      delay_200
		mov       al,20h
		out       04h,al
		call      delay_200
		mov       al,cs:[di]
		out       00h,al
		mov       al,00h
		out       04h,al
		call      delay_200

		inc		di
		loop	x1			


;initialise/test variables
  mov bx, 0
  mov count, bx
mov bl,0
mov gate_status, bl






call	display_empty
;call	display_empty

;initialize timers 0 mode 3; 1 mode 
mov		al, 00110110b
out		0eh, al
mov		al, 01110000b
out		0eh, al


x4:		;wait for remote
		in		al, 02h
		and		al, 01h
		cmp		al, 1
			jne		x4
call	open_gate
call	reset_timer
jmp x7
x5:		;check gate
		mov		al, gate_status
		cmp		al, 1
			je		x6
			
;gate closed>> open gate >>wait>> set gate_status
call	open_gate

;call reset_timer
call	reset_timer

;jmp 
jmp x7

x6:		;close_gate
		call	close_gate
		
x7:		;reading inputs using bl now
		call	delay_200
		in 		al, 02h
		mov		bl, al
		and		bl, 01h
		cmp		bl, 1
			je		x5		;jmp x5 as remote pressed

		;check gate_status
		mov		bl, gate_status
		cmp		bl, 0
			je		x7		;gate closed
		
		;remote not pressed check IR
		mov 	bl, al
		and		bl, 06h
		cmp		bl, 0
			je		x7		;IR not triggered
			
		;IR triggered check IR_IN
		and		al, 02h
		cmp		al, 0
			je		x11		;IR_OUT triggered
			
		;read input till IR_OUT triggered
x8:		in 		al, 02h
		mov		bl, al
		and		al, 04h
		cmp		al, 0
			je		x8
		
	call	delay_200
		
		;read input till IR not triggered
x85:	in		al, 02h
		and		al, 06h
		cmp		al, 0
			jg		x85
		
		;check if car
		and		bl, 08h
		cmp 	bl, 0
			je		x10		;no car >> reset_timer
			
		;decrease count << car out
		mov		ax, count
		cmp		ax, 1
			jle		x9		;jmp if car to be 0
		
		mov		ax, count
		dec 	ax
		mov		count, ax
		call	display_count
			jmp		x10
			
x9:		;set  car 0
		mov		ax,0
		mov		count, ax
		call	display_empty
		
x10:	call	reset_timer
			jmp		x7


			
x11:	;IR_OUT triggered>>read input till IR_IN triggered
		in 		al, 02h
		mov		bl, al
		and		al, 02h
		cmp		al, 0
			je		x11	
			
	call	delay_200
		
		;read input till IR not triggered
x12:	in		al, 02h
		and		al, 06h
		cmp		al, 0
			jg		x12		
		
		;check if car
		and		bl, 08h
		cmp 	bl, 0
			je		x10		;no car >> reset_timer


		;increase count << car in
		mov		ax, count
		cmp		ax, 1999
			jge		x13		;jmp if car to be 0

		mov		ax, count
		inc 	ax
		mov		count, ax
		call	display_count
			jmp		x10

x13:	;set  car 2000
		mov		ax,2000
		mov		count, ax
		call	display_full	
			jmp 	x10

xz: jmp xz


;delay_200

delay_200:     
	push cx
	mov       cx,200
	xn:       loop      xn
	pop cx
        ret

delay_2000:
	push cx
	mov       cx,20000
	xn2:       loop      xn2
	pop cx
        ret

reset_timer:
	;timer 0 to 4*2048
	mov		al, 00h
	out		08h, al
	mov		al, 20h
	out		08h, al
	;timer 1 to 2*2048
	mov		al, 00h
	out		0ah, al
	mov		al, 10h
	out		0ah, al	
		ret

close_gate:

	mov		al, 0
	mov		gate_status, al
		
	mov 	al, 04h
	out		04h, al
	call 	delay_2000

	mov 	al, 0
	out		04h, al
		ret
	
open_gate:	
	mov 	al, 02h
	out		04h, al
	call 	delay_2000

	mov		al, 1
	mov		gate_status, al
	mov 	al, 01h
	out		04h, al
		ret

display_full:
 mov       al,30h
 out       04h,al
 call      delay_200
 mov       al,20h
 out       04h,al
 call      delay_200
 mov       al,80h
 out       00h,al
 mov       al,00h
 out       04h,al
 call      delay_200 
 
	lea		di, disp_full
	mov		cx, 5
x2:		  
	mov       al,30h
	out       04h,al
	mov       al,cs:[di]
	out       00h,al 
	mov       al,10h
	out       04h,al
	call      delay_200

	inc 	di
	loop 	x2
	
	;display gate
	mov		al, gate_status
	out		04h,al
			ret

display_empty:
 mov       al,30h
 out       04h,al
 call      delay_200
 mov       al,20h
 out       04h,al
 call      delay_200
 mov       al,80h
 out       00h,al
 mov       al,00h
 out       04h,al
 call      delay_200  
 
	lea		di, disp_empty
	mov		cx, 5
x3:		  
	mov       al,30h
	out       04h,al
	mov       al,cs:[di]
	out       00h,al 
	mov       al,10h
	out       04h,al
	call      delay_200

	inc 	di
	loop 	x3
	
	;display gate
	mov		al, gate_status
	out		04h,al
			ret


display_count:
 
    mov	al,' '			;clear lcd0 variables
    mov	lcd0, al
    mov	lcd1, al
    mov	lcd2, al
    mov	lcd3, al 

  
  mov	ax, count
  mov 	bl, 10 
  div 	bl
  mov	bl, ah
  or	bl, 30h
  mov	lcd3, bl		;lcd3 set
 
  mov	ah,0
  cmp	ax, 0
	 je 		x15
	
  mov 	bl, 10 
  div 	bl
  mov	bl, ah
  or	bl, 30h
  mov	lcd2, bl		;lcd2 set	
	
  mov	ah,0
  cmp	ax, 0
	 je 		x15

	

  mov 	bl, 10 
  div 	bl
  mov	bl, ah
  or	bl, 30h
  mov	lcd1, bl		;lcd1 set	
	
  mov	ah,0
  cmp	ax, 0
	 je 		x15
	
	

  mov 	bl, 10 
  div 	bl
  mov	bl, ah
  or	bl, 30h
  mov	lcd0, bl		;lcd0 set


 x15:	;clear display
 mov       al,30h		;clear display
 out       04h,al
 call      delay_200
 mov       al,20h
 out       04h,al
 call      delay_200
 mov       al,80h
 out       00h,al
 mov       al,00h
 out       04h,al
 call      delay_200
 
	;display lcd0 to lcd3
;	lea		di, lcd0
;	mov		cx, 4

    mov       dl, lcd0		  
	mov       al,30h
	out       04h,al
	mov       al,dl
	out       00h,al 
	mov       al,10h
	out       04h,al
	call      delay_200 
	
    mov       dl, lcd1		  
	mov       al,30h
	out       04h,al
	mov       al,dl
	out       00h,al 
	mov       al,10h
	out       04h,al
	call      delay_200
	
    mov       dl, lcd2		  
	mov       al,30h
	out       04h,al
	mov       al,dl
	out       00h,al 
	mov       al,10h
	out       04h,al
	call      delay_200
	
    mov       dl, lcd3		  
	mov       al,30h
	out       04h,al
	mov       al,dl
	out       00h,al 
	mov       al,10h
	out       04h,al
	call      delay_200

    mov       dl, ' '		  
	mov       al,30h
	out       04h,al
	mov       al,dl
	out       00h,al 
	mov       al,10h
	out       04h,al
	call      delay_200
	
	;display gate
	mov		al, gate_status
	out		04h,al
	
		ret

nmi_close_gate:
	mov		al, gate_status
	cmp		al,0
		je		xret
	
	mov 	al, 04h
	out		04h, al
	call 	delay_2000

	mov		al, 0
	mov		gate_status, al
	mov 	al, 0
	out		04h, al
xret:			iret
