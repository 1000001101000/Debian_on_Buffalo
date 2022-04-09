
//		.syntax unified
//		.section .start, "ax"
//		.type	_start, #function
//		.globl	_start

// suppose uboot had a stack, could look at where that was. might be safe ish to use?

_start:
	adr	sp, data					@ use data section as our stack (no OS yet)
	pop	{r7,r8}						@ pull ATAG_INITRD2 and ATAG_CORE off stack
	mov	r9, r2						@ copy of atag ptr for walking
	ldm	r9, {r3-r4}					@ r3 = ATAG size (words) r4 = ATAG type
	teq	r4, r8						@ is it ATAG_CORE?
	bne	done						@ if not we're lost, quit.
	add	r8, #8						@ convert r8 to ATAG_CMDLINE
	add	r9, r9, r3, lsl #2			@ add atag size * 4 (byte->word) to pointer

atagscan:
	ldm	r9, {r3-r6}					@ r3 = tag size, r4 = tag type, r5 = first word, r6 = second word
	teq	r3, #0						@ check for ATAG_NONE at the end
	beq	endscan						@ reached end, move to next phase

	teq		r4, r7					@ check for ATAG_INITRD2
	popeq   {r7}					@ load new initrd address to r7
	streq	r7, [r9, #8]			@ update address in ATAG second word (size in first word unchanged)
	pusheq	{r5,r6,r7}				@ push address/size/new address to stack

	teq		r4, r8					@ check for ATAG_CMDLINE tag
	bne		nexttag					@ easier as long as we keep this as last tag check
	mov		r12, #cmdsize			@ load size of cmdline string
	//test if cmdsize larger than the tag
	//either quit or grow the atag tree somehow.
	adr		r11, cmdline			@ load the address of the cmdline string
	add		lr, r9, #8				@ load the address of atag cmline value
copycmdline:
	ldmia	r11!, {r5,r6}			@ move 8-bytes at a time
	stmia   lr!, {r5,r6}
	subs	r12, r12, #8
    bcs		copycmdline
	// can we check the length and quit if is too short?


	// guess if we unset the eq flag or whatever convert to lt 
	//ldreq	r5, [r9,#28]			@ load the word we want to change in r5
	//mvneq	r6, #0x0000FF			@ load and invert bitmask (0xFFFFFF00) to r6
	//andeq	r5, r5, r6				@ apply bitmask to r5, creates null terminator
	//streq	r5, [r9,#28]			@ store the modified word back where it came
	// suppose if we never find it we assume that's fine?
	// either already uses ATAG which is good....or compiled into kernel which would be bad.
nexttag:
	add		r9, r9, r3, lsl #2		@ add atag size * 4 (byte->word) to pointer	
	b		atagscan				@ loop to next
endscan:

	pop		{r11, r12, lr}			@ r11 = old address, r12 = size, lr= new address
copyinitrd:
	ldmia	r11!, {r3 - r10}		@ move 32-bytes at a time
	stmia   lr!, {r3 - r10}
	subs	r12, r12, #32
    bcs		copyinitrd

	b	done
data:
	.word	0x54420005				@ ATAG_INITRD2
	.word	0x54410001				@ ATAG_CORE;
	.word	0x02600040				@ New INITRD ADDR
cmdline:
	.asciz	"console=ttyS0,115200 bootshim=1"	@ hardcoded cmdline (need one without INITRD=)
	.set	cmdsize, .-cmdline
.balign 16

done:

