
	.extern	fread, fwrite


	.data
c:	.byte	0
file:	.long	0
byte:	.byte	0
unicode:	.long	0
status:	.long	0


	.text
	.globl	readbyte
 # Navn:	readbyte
 # Synopsis:	Leser en byte fra en binærfil.
 # C-signatur: 	int readbyte (FILE *f)
 # Registre:

	
readbyte:			# Denne fungerer noe ustabilt uten at det er noen 					# åpenbar grunn for det....
	
	pushl	%ebp		# Standard funksjonsstart
	xorl	%eax,%eax	# 
	xorl	%ebp, %ebp	#
	movl	%esp,%ebp 	#
  
	movl  8(%ebp),%eax	# Pusher fil-lokasjon på stakken
	pushl  %eax 		# Pusher EAX på stakken
	pushl $1		# Pusher 1 for size på stakken
	pushl $1		# Pusher 1 for antall elementer på stakken


	leal  c,%eax
	pushl %eax		# Pusher Byte-adressen på stakken

	call  fread		# Kaller standard C-funksjon med argumenter som på stakken

	movl  %eax,status	# Flytter retur-verdi fra fread til status-variabelen
	addl  $0,status		# Setter nullflagg
	jz done			# Hopper til ferdig om status-variabel er 0 					# og det ikke er flere bytes
	
	movl  c,%eax		# Returnerer c
	
	jmp   rb_x

done:
 	movl  $-1,%eax		# Returnerer -1 siden det ikke er flere b
  	jmp   rb_x
  
rb_x:
  	addl  $16,%esp		# Setter stakk pointer til riktig posisjon
  	popl	%ebp		# Standard
	ret			# retur.


	.globl	readutf8char
 # Navn:	readutf8char
 # Synopsis:	Leser et Unicode-tegn fra en binærfil.
 # C-signatur: 	long readutf8char (FILE *f)
 # Registre:
	
readutf8char:
	pushl	%ebp		# Standard funksjonsstart
	movl	%esp,%ebp	# 
	movl	8(%ebp), %edx	#
	movl	%edx, file	# Lagrer fil-adressen i varabel
	pushl 	file		#	
	call	readbyte	# Leser byte fra fil, med filadrsse som argument
	movl	%eax, unicode	#
	popl 	%eax		#
	movl 	unicode, %eax	#
	cmpl 	$-1, %eax	# Skjekker om filen er tom, ved å se på returverdi
	jz	Complete	# Hvis lik hopper vi til Complete
	

				# Her tar jeg utgangspunkt i bestemelsesbitsene som 					# forteller antal bytes et tegn trenger
	movl	unicode, %eax	# 
	andl	$0xF0, %eax	# Masker unicode tegnet med F0 for 4 bytes tegn
	cmpl	$0xF0, %eax	# Ser om unicode tegnet består av 4 bytes ved å 				# Sammenligne, med F0, ser om nullflagget blir satt
	jz	FourBytes	# hopper da til hvor vi behandler det tilfellet

	movl	unicode, %eax	#
	andl	$0xE0, %eax	# Masker unicode tegnet med E0 for 3 bytes tegn
	cmpl	$0xE0, %eax	# Ser om unicode tegnet består av 3 bytes ved å
				# Sammenligne med E0, ser om nullflagget blir satt
	jz	ThreeBytes	# hopper da til hvor vi behandler det tilfellet	

	movl 	unicode, %eax	#
	andl	$0xC0, %eax	# Masker unicode tegnet med C0 for 2 bytes tegn
	cmpl	$0xC0, %eax	# Ser om unicode tegnet består av 2 bytes ved å
				# Sammenligne med E0, ser om nullflagget blir satt
	jz	TwoBytes	# hopper da til hvor vi behandler det tilfellet

	movl	unicode, %eax	#
	andl	$0x80, %eax	# Masker unicode tegnet med 80 for 1 byte tegn
	cmpl	$0x0, %eax	# Ser om unicode tegnet består av 1 byte ved å
				# Sammenligne med 0, ser om nullflagget blir satt
	jz	OneByte		# og hopper til hvor vi behandler det tilfellet

	jmp 	PopAndReturn	# Dersom tegnet ikke kan identifiseres ignoreres 					# det, vi frigjør plassen på stakken og returnerer

OneByte:	
	xorl	%eax,%eax	# Renser registeret
	movl 	unicode, %eax	# Henter tegnet inn i registeret
	andl	$0x7F, %eax	# masker med 7F for å bare få med bitsene 					# tilhørende den ene byten, som returneres
	jmp	PopAndReturn	# Er ferdig så hopper da til hvor vi returnerer

TwoBytes:
	xorl	%eax,%eax	# Renser registerene
	xorl	%edx, %edx	#
	movl	unicode, %edx	# Henter tegnet inn i arbeidsregisteret EDX
	andl	$0x1F, %edx	# Masker med 1F for å bare få med bakerste byte 
				
	movb	%dl, byte	# Lagrer bakerste byte i varabelen byte
	pushl 	file		# Leser inn fil igjen for å lese inn resten av tegn
	call	readbyte	# bruker da readbyte metode med file som argument
	andl 	$0x3F,%eax	# Masker med 3F for å bare få med fremste byte
	movb	byte, %dl	# Henter bakerste byte fra variabel inn i DL i EDX 
	shll 	$6, %edx	# shifter EDX til venstre slik at første byte 					# havner fremst og siste bakerst 
	orl	%edx, %eax	# Setter sammen bytene, som skal returneres
	pop 	%ecx		# hindrer minnesegmentsfeil..
	jmp 	PopAndReturn	# Er ferdig så hopper da til hvor vi returnerer

ThreeBytes:
	xorl	%eax,%eax	# Renser registerene
	xorl	%edx, %edx	#
	movl	unicode, %edx	# Henter tegnet inn i arbeidsregisteret EDX
	andl	$0x1F,%edx	# Masker med med F for å bare få med 
	movb	%dl,byte		#Lagrer bakerste byte i varabelen byte

	pushl 	file		# Leser inn fil igjen for å lese inn resten av tegn
	call 	readbyte	# bruker da readbyte metode med file som argument
	popl	%ecx		# hindrer minnesegmentsfeil..
	andl	$0x1F,%eax	# Masker for å bare få med bakerste byte bidrag
	movb	byte,%dl		# henter frem første innleste byte inn i EDx
	
	shll	$6,%edx		# Shifter til fremover slik at først innleste 					# havner fremst
	orl	%edx,%eax	# Setter begge bytene sammen
	movl	%eax, unicode	# Lagrer dem midlertidig
	
	pushl 	file		# Leser inn filen igjen for å lese siste byte
	call 	readbyte	# bruker da readbyte metode med file som argument
	popl	%ecx		# hindrer minnesegmentsfeil..
	andl	$0x3F,%eax	# Masker for å bare få med bakerste byte bidrag
	movl	unicode,%edx	# flytter tidligere innlese byte inn i 					# arbeidsregister
	shll	$6,%edx		# Shifter slik at sist innlese byte kommer bakerst
	orl	%edx,%eax	# Setter alle bytene sammen til en sekvens
	jmp 	PopAndReturn	# Er ferdig så hopper da til hvor vi returnerer

FourBytes:
	xorl	%eax,%eax	# Renser registerene
	xorl	%edx, %edx	#
	movl 	unicode, %edx	# Henter tegnet inn i arbeidsregisteret EDX
	andl	$0x7,%edx	#
	movb	%dl,byte		#
	pushl	file		# Pusher filen.
	call	readbyte	# Henter ut en byte til.
	popl	%ecx		# Popper stakken
	andl	$0x3F,%eax	# Masker ut de bitene jeg vil ha
	movb	byte,%dl	

	shll	$6,%edx		#Shifter %edx
	orl	%edx,%eax	#Setter alle bitene sammen
	movl	%eax,unicode	# Flytter den nye byten inn i en variabel
	
	pushl	file		#Pusher filen
	call	readbyte	#Henter ut en byte til.
	popl	%ecx		#Popper stakken
	andl	$0x3F,%eax	#Masker ut de bitene jeg vil ha
	movl	unicode,%edx	#
	
	shll	$6,%edx		#Shifter %edx
	orl	%edx,%eax	#Setter alle bitene sammen
	movl	%eax,unicode	#
	
	pushl	file		#Pusher filen
	call	readbyte	#Henter ut en byte til.
	popl	%ecx		#Popper stakken
	andl	$0x3F,%eax	#Masker ut de bitene jeg vil ha
	movl	unicode,%edx	#
	shll	$6,%edx			#Shifter %edx
	orl		%edx,%eax		#Setter alle bitene sammen




	jmp 	PopAndReturn	#


	popl	%ebp		# Standard
	ret			# retur.

Complete:			# Kalles om det ikke er flere tegn
	movl	$-1,%eax	# Flytter verdien -1 til %eax
	jmp 	PopAndReturn		

PopAndReturn:
	popl	%ebp		# Standard
	ret			# retur.



	.globl	writebyte
 # Navn:	writebyte
 # Synopsis:	Skriver en byte til en binærfil.
 # C-signatur: 	void writebyte (FILE *f, unsigned char b)
 # Registre:
	
writebyte:
	pushl	%ebp		# Standard funksjonsstart
	movl	%esp,%ebp	#
	
	pushl 8(%ebp)		# Push filepointer on stack
	pushl $1		# Push value 1, size on stack
	pushl $1		# Push value 1, number of elements on stack
	leal 12(%ebp), %eax	# Moves Bit pointer to %EAX
	pushl %eax		# Push Bit to write on stack
	call fwrite		# Call standard C-function fwrite with arguments as on stack
	
	leave 
	#popl	%ebp		# Standard
	ret			# retur.

	.globl	writeutf8char
 # Navn:	writeutf8char
 # Synopsis:	Skriver et tegn kodet som unicode-8 til en binærfil.
 # C-signatur: 	void writeutf8char (FILE *f, unsigned long u)
 # Registre:
	
writeutf8char:
	pushl	%ebp		# Standard funksjonsstart
	movl	%esp,%ebp	#
	movl	12(%ebp), %ecx
	movl 	%ecx, unicode	# Lagrer Unicode tegn i variabel for trygg lagring ved beregninger og hopp
	movl	8(%ebp), %edx
	movl	%edx, file	# Lagrer Filadresse i variabel for trygg lagring ved hopp

 # Finner ut hvor mange byte i unicode-8 som trengs
 # Trekker 0x7F, 0x7FF, osv. fra verdien til tegnet for å se om verdien er 	 
 # mindre eller lik og dermed inneholdt i bare 1, 2, 3 eller 4 bytes 
	subl	$0x7F, %ecx	# 
	jz	Byte1		# hopper til hvor vi behandler 1 byte om null flagget er satt
	js	Byte1		# hopper til hvor vi behandler 1 byte om signed flagget er satt
	
	movl 	unicode, %ecx	#
	subl	$0x7FF, %ecx	#
	jz	Byte2		# hopper til hvor vi behandler 1 byte om null flagget er satt
	js	Byte2		# hopper til hvor vi behandler 2 bytes om signed flagget er satt
	
	movl	unicode, %ecx	#
	subl	$0xFFFF, %ecx	#
	jz	Byte3		# hopper til hvor vi behandler 1 byte om null flagget er satt
	js	Byte3		# hopper til hvor vi behandler 3 bytes om signed flagget er satt
	
			
	movl	unicode, %ecx	#
	subl	$0x1FFFF, %ecx	#
	jz	Byte4		# hopper til hvor vi behandler 1 byte om null flagget er satt
	js	Byte4		# hopper til hvor vi behandler 4 bytes om signed flagget er satt
	
	
	jmp wu8_x


Byte1:
	xorl	%eax, %eax	# nuller ut registre
	movl	unicode, %eax	# 
	andl	$0x7F, %eax	# masker slik at det bare er tegnet som er i EAX	
	pushl 	%eax		# pusher unicode tegn på stakken
	pushl 	file		# pusher på fil-lokasjon på stakken
	call	writebyte	# Kjører writebyte funksjonen som tidligere laget med argumenter som på stakken
	popl	%eax
	popl	%eax		# Programeringskotyme
	jmp wu8_x		# Er ferdig så hopper til hvor vi avslutter programmet

Byte2:
	xorl	%eax, %eax	# Nuller ut registre
	movl 	unicode, %eax	# flytter tegn ut til EAX 
	shrl	$6, %eax	# Shifter slik at dette blir fremste byte
	andl 	$0x1F, %eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0xC0, %eax	# Setter de to fremste bitsene til 11, siden vi har 2 bytes
	pushl 	%eax		# pusher unicode tegn på stakken
	pushl	file		# pusher fil-lokasjon på stakken
	call	writebyte	# Kjører writebyte funksjonen som tidligere laget med argumenter som på stakken
	popl	%eax		# fjerner Fjerner EAX fra stakken
	popl	%eax		#
	xorl	%eax, %eax	# nuller ut register
	movl	unicode, %eax	# flytter tegn på EAX
				# Shifter ikke, så dette blir bakerste byte
	andl	$0x3F, %eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0x80, %eax	# Setter fremste bit til 1 
	pushl	%eax		# pusher EAX på stakken for skriving av byte
	pushl	file		# pusher fil-lokasjon på stakken
	call writebyte		# Kjører write byte funksjon igjen for å skrive siste byte
	popl 	%eax		# Fjerner EAX fra stakken og frigjør da plass
	popl	%eax		#
	
	jmp wu8_x		# Er ferdig så hopper til hvor vi avslutter programmet 

Byte3: 
	xorl 	%eax, %eax	# Nuller ut registre
	movl	unicode, %eax	# flytter tegn ut til EAX 	
	shrl	$12, %eax	# Shifter slik at dette blir fremste byte
	andl	$0xF, %eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0xE0, %eax	# Setter de 3 fremste bitsene til 1 for 3 bytes
	pushl 	%eax		# pusher EAX på stakken for skriving av byte
	pushl 	file		# pusher fil-lokasjon på stakken
	call	writebyte	# Kjører write byte funksjon igjen for å skrive
	popl	%eax		# fjerner eax fra stakken for å tømme registre 
	popl	%eax		#
	
	xorl 	%eax, %eax	# Nuller ut registre
	movl	unicode, %eax	# flytter tegn på EAX
	shrl	$6, %eax	# Shifter slik at dette blir midterste byte
	andl	$0x3F, %eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0x80,%eax	# Setter 4 bits til 1 for 4 bytes
	pushl 	%eax		# pusher EAX på stakken for skriving av byte
	pushl 	file		# pusher fil-lokasjon på stakken
	call 	writebyte	# Kjører write byte funksjon igjen for å skrive
	popl	%eax		#
	popl	%eax		#
	
	xorl 	%eax, %eax	# Nuller ut registre
	movl	unicode,%eax	# flytter tegn på EAX
				# Shifter ikke, så dette blir bakerste byte
	andl	$0x3F,%eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0x80,%eax	# 
	pushl	%eax		# pusher EAX på stakken for skriving av byte
	pushl	file		# pusher fil-lokasjon på stakken
	call 	writebyte	# Kjører write byte funksjon igjen for å skrive byte
	popl	%eax		# Fjerner EAX fra stakken og frigjør da plass
	popl	%eax		#

	jmp wu8_x

	

Byte4:
	xorl 	%eax, %eax	# Nuller ut registre			
	movl	unicode,%eax	# flytter tegn ut til EAX 
	shrl	$18,%eax	# Shifter slik at dette blir fremste byte
	andl	$0x7,%eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0xF0,%eax	# Setter 4 bits til 1 for 4 bytes
	pushl	%eax		# pusher EAX på stakken for skriving av byte
	pushl	file		# pusher fil-lokasjon på stakken
	call 	writebyte	# Kjører write byte funksjon igjen for å skrive byte
	popl	%eax		#
	popl	%eax		#

	xorl 	%eax, %eax	# Nuller ut registre			
	movl	unicode,%eax	# flytter tegn ut til EAX 
	shrl	$12,%eax	# Shifter slik at dette blir nest fremste byte
	andl	$0x3F,%eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0x80,%eax	# legger til 1 fremst i byte
	pushl	%eax		# pusher EAX på stakken for skriving av byte
	pushl	file		# pusher fil-lokasjon på stakken
	call 	writebyte	# Kjører write byte funksjon igjen for å skrive byte
	popl	%eax		#
	popl	%eax		#
	
	xorl 	%eax, %eax	# Nuller ut registre			
	movl	unicode,%eax	# flytter tegn ut til EAX 
	shrl	$6,%eax		# Shifter slik at dette blir nest bakerste byte
	andl	$0x3F,%eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0x80,%eax	# legger til 1 fremst i byte
	pushl	%eax		# pusher EAX på stakken for skriving av byte
	pushl	file		# pusher fil-lokasjon på stakken
	call 	writebyte	# Kjører write byte funksjon igjen for å skrive byte
	popl	%eax		#
	popl	%eax		#

	xorl 	%eax, %eax	# Nuller ut registre			
	movl	unicode,%eax	# 
				# Shifter ikke slik at dette blir bakerste byte
	andl	$0x3F,%eax	# masker slik at bare tegnet er lagret på EAX
	orl	$0x80,%eax	# legger til 1 fremst i byte
	pushl	%eax		# pusher EAX på stakken for skriving av byte
	pushl	file		# pusher fil-lokasjon på stakken
	call 	writebyte	# Kjører write byte funksjon igjen for å skrive byte
	popl	%eax		#
	popl	%eax		#



wu8_x:	popl	%ebp		# Standard
	ret			# retur.
