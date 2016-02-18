#include <stdio.h>

int
main()
{
	long long	ll ;
	unsigned long long	ull ;
	ull = 0x8000000000000000ll ;
	printf( "0x%08x%08x\n", (int)(ull>>32), (int)(ull&0x0ffffffff) ) ;
	ll = ull ;
	printf( "0x%08x%08x\n", (int)(ll>>32), (int)(ll&0x0ffffffff) ) ;
	return( 0 ) ;
}
