/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "p-table.h"
#include <malloc.h>

struct {
	int	maxindex ;
	int	maxref ;
	int	unresolve_count ;
	PointerTable	allocate ;
	PointerTable	unresolved ;
} DecodeStr ;
typedef	struct	DecodeStr	DecodeRec ;
typedef	struct	DecodeStr*	Decode ;


void*
OzMalloc( size_t aSize )
{
	return( malloc( aSize ) ) ;
}

void
OzFree( void *aPtr )
{
	free( aptr ) ;
}


static	int
Read( int fd, void *aData, size_t aSize )
{
	int	ret ;
	ret = read( fd, aData, aSize ) ;
	return( ret == aSize ? 0 : ret ) ;
}

static inline int
isPointerArray(long long type)
{
  return((type==OZ_LOCAL_OBJECT)||(type==OZ_STATIC_OBJECT)||(type==OZ_ARRAY));
}

static	void
traversePointers( Decode decode, int *ip, int count )
{
	int	i ;

	for( i = 0 ; i < count ; i ++, ip ++ ) {
		if ( *ip ) continue ;
		if( *ip <= decode->maxindex ) {
			*ip = (int)readPointerTable( decode->allocate, *ip ) ;
		} else {
			if( *ip > decode->maxref ) decode->maxref = *ip ;
			putPointerTable( decode->unresolved, ip ) ;
			decode->unresolve_count ++ ;
		}
	}
}

static	void
traverseObjectBody( Decode decode, OZ_AllocateInfo info )
{
	int		*ip = (int *)(info+1) ;
	int		i ;

	traversePointers( decode, ip, info->number_of_pointer_protected ) ;
	ip += info->number_of_pointer_protected 
		+ (info->number_of_pointer_protected & 1)
		+ (info->data_size_protected)/sizeof(int *);

	ip += (info->zero_protected)*sizeof(OZ_ConditionRec)/sizeof(int *);

	traversePointers( decode, ip, info->number_of_pointer_private ) ;
	ip += info->number_of_pointer_private 
		+ (info->number_of_pointer_private & 1)
		+ (info->data_size_private)/sizeof(int *);
}

static	void
traverseObject( Decode decode, OZ_Header oh )
{
	int		i ;
	int		offset = (int)oh ;
	OZ_Header	ohp ;

	oh->t = (int)oh->t + offset ;
	for( ohp = oh + 1, i = 0 ; i < oh->h ; i ++, ohp ++ ) {
		decode->maxindex = putPointerTable( decode->allocate, ohp ) ;
		ohp->d = (void *)( offset + (int)ohp->d ) ;
		traverseObjectBody( decode, (OZ_AllocateInfo)ohp->d ) ;
	}
}

static	void
decode(void (*fetchFunction)(),void (*readFunction)(),void *funcArg
       ,char fmt,void *result,Heap heap)
{
  DecodeContextRec context;
  OZ_Header oh, ohp;
  OZ_AllocateInfo al;
  int entry_point;
  int size,kind,offset;
  char *p;
  int *ip, i,ii;
  int firstWord;
  int original_size;

	decode.maxindex = -1 ;
	decode.maxref = 0 ;
	decode.unresolve_count = 0 ;
	decode.allocate = createPointerTable() ;
	decode.unresolved = createPointerTable() ;

	if ( lseek( oi, 8, SEEK_SET ) < 0 ) {
		perror( "lseek(skip)" ) ;
		exit ( 1 ) ;
	}

	while( decode.maxindex < decode.maxref ) {
		if ( lseek( oi, 4, SEEK_CUR ) < 0 ) {
			perror( "lseek(size)" ) ;
			exit ( 1 ) ;
		}
		if ( Read( oi, &size, 4 ) ) {
			perror( "Read(size)" ) ;
			exit( 1 ) ;
		}
		oh = (OZ_Header)p = malloc( size ) ;
		if ( lseek( oi, -8, SEEK_CUR ) < 0 ) {
			perror( "lseek(size)" ) ;
			exit ( 1 ) ;
		}
		if ( Read( oi, oh, size ) {
			perror( "Read(headers)" ) ;
			exit ( 1 ) ;
		}
		decode.maxindex = putPointerTable( decode.allocate, oh ) ;
		kind = oh->d ;

		switch( kind ) {
		case OZ_LOCAL_OBJECT:
	  break;
	case OZ_ARRAY:
	  if(isPointerArray(oh->a))
	    {
	      traversePointers(&context,(int *)(oh+1),oh->h);
	    }
	  break;
	case OZ_STATIC_OBJECT:
	  offset=(int)oh;
	  oh->t = oh->t+offset;
	  traverseObjectBody(&context, (OZ_AllocateInfo)(oh+1));
	  break;

	case OZ_RECORD:
	  /* do nothing */
	  break;
	}
  }
  /* change local index to real address reference */
  for(ii=0;ii<context.unresolve_count;ii++)
    {
      ip=readPointerTable(context.unresolved,ii);
      *ip=(int)readPointerTable(context.allocate,*ip);
    }

  *((void **)result) = readPointerTable(context.allocate,entry_point);

	freePointerTable( decode.allocate ) ;
	freePointerTable( decode.unresolved ) ;

	return ;
}

void*
ObjectImageLoad( char *aFileName )
{
	int	oi ;
	oi = open( aFileName, O_RDONLY ) ;

	close( oi ) ;
}
