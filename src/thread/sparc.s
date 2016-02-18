#ifdef	SVR4
#define	THRJUMPTHREAD	thrJumpThread
#define	ARGPUSH	(16*4+4)
	.section	".text"
	.align	4
	.type	THRJUMPTHREAD, #function
#else
#define	THRJUMPTHREAD	_thrJumpThread
#include <sparc/asm_linkage.h>
	.seg	"text"
	.proc 04
#endif	SVR4
	.global	THRJUMPTHREAD
THRJUMPTHREAD:
	ta	3
	mov	0, %fp
	sub	%o3, ARGPUSH, %sp
	mov	%o0, %l0
	mov	%o1, %l1
	mov	%o2, %l2
	call	%l0
	nop
	ld	[%sp+ARGPUSH+0x00], %o0
	ld	[%sp+ARGPUSH+0x04], %o1
	ld	[%sp+ARGPUSH+0x08], %o2
	ld	[%sp+ARGPUSH+0x0c], %o3
	ld	[%sp+ARGPUSH+0x10], %o4
	call	%l1
	ld	[%sp+ARGPUSH+0x14], %o5
	call	%l2
	nop
