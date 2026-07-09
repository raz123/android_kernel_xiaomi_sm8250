	.file	"bounds.c"
	.text
	.globl	main                            // -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   // @main
// %bb.0:
	//APP

	.ascii	"->NR_PAGEFLAGS 22 __NR_PAGEFLAGS"
	//NO_APP
	//APP

	.ascii	"->MAX_NR_ZONES 2 __MAX_NR_ZONES"
	//NO_APP
	//APP

	.ascii	"->NR_CPUS_BITS 3 ilog2(CONFIG_NR_CPUS)"
	//NO_APP
	//APP

	.ascii	"->SPINLOCK_SIZE 4 sizeof(spinlock_t)"
	//NO_APP
	//APP

	.ascii	"->LRU_GEN_WIDTH 3 order_base_2(MAX_NR_GENS + 1)"
	//NO_APP
	//APP

	.ascii	"->LRU_REFS_WIDTH 2 MAX_NR_TIERS - 2"
	//NO_APP
	mov	w0, wzr
	ret
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
                                        // -- End function
	.ident	"Homebrew clang version 22.1.7"
	.section	".note.GNU-stack","",@progbits
	.addrsig
