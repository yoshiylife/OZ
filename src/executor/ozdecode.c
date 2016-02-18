/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <sys/types.h>

#include "switch.h"
#include "mem.h"
#include "encode.h"
#include "p-table.h"
#include "decode.h"
#include "oz++/type.h"
#include "oz++/object-type.h"

#define IsEightByteArg(c) (c=='l' || c=='d' || c=='P' || c=='G')
#define IsFourByteArg(c)  (c=='i' || c=='s' || c=='c' || c=='f' || c=='v')
#define IsPointerArg(c)   (c=='A' || c=='O' || c=='S' || c=='R')

typedef struct {
  int maxindex;
  int  maxref;
  int unresolve_count;
  PointerTable allocate;
  PointerTable unresolved;
#ifdef INTERSITE
  int foreign_flag;
#endif
} DecodeContextRec, *DecodeContext;

typedef enum {
  DECODE_FILE,
  DECODE_COMM
} decodeFlag ;

static inline int
isPointerArray(long long type)
{
  return((type==OZ_LOCAL_OBJECT)||(type==OZ_STATIC_OBJECT)||(type==OZ_ARRAY));
}

/* decode_comm decode an item from rbuf with format fmt.
*  if item is object, the object is created on heap and pointer to object
*  is returned. Otherwise, value is returned. */


void
traversePointers(DecodeContext contextp,int *ip,int count)
{
  int ii;

  for(ii=0;ii<count;ii++,ip++)
    {
      if(*ip)
	{
	  if(*ip <= contextp->maxindex)
	    *ip=(int)readPointerTable(contextp->allocate,*ip);
	  else
	    { if(*ip > contextp->maxref)
		contextp->maxref= *ip;
	      putPointerTable(contextp->unresolved,ip);
	      contextp->unresolve_count++;
	    }
	}
    }
}

void
traverseObjectBody(DecodeContext contextp, OZ_AllocateInfo al)
{
  int *ip;
  OZ_Condition zp;
  int i;

  ip=(int *)(al+1);

  traversePointers(contextp,ip,al->number_of_pointer_protected);
  ip+= al->number_of_pointer_protected 
    + (al->number_of_pointer_protected & 1)
      + (al->data_size_protected)/sizeof(int *);
  zp = (OZ_Condition)ip;
  for(i=0;i<al->zero_protected;i++,zp++)
    OzExecInitializeCondition(zp,1);
  ip += (al->zero_protected)*sizeof(OZ_ConditionRec)/sizeof(int *);

  traversePointers(contextp,ip,al->number_of_pointer_private);
  ip+= al->number_of_pointer_private 
    + (al->number_of_pointer_private & 1)
      + (al->data_size_private)/sizeof(int *);
  zp = (OZ_Condition)ip;
  for(i=0;i<al->zero_private;i++,zp++)
    OzExecInitializeCondition(zp,1);
}

/* decode */
/* First two arguments are pointers of fetch function and 
read function. Thired argument is first argument of these functions */


void
OzDecode(void (*fetchFunction)(),void (*readFunction)(),void *funcArg
	 ,char fmt,void *result,Heap heap
#ifdef INTERSITE
	 ,unsigned int foreing_flag
#endif
	 )
{
  DecodeContextRec context;
  OZ_Header oh, ohp;
  int entry_point;
  int size,kind,offset;
  char *p;
  int *ip, i,ii;
  int firstWord;
  int original_size;

#if 1 /* ONI */
  OzExecEnterMonitor(&(heap->lock));
  heap->decoding++;
  OzExecExitMonitor(&(heap->lock));
#endif /* ONI */

  if(IsFourByteArg(fmt))
    {
      (*readFunction)(funcArg,4,(unsigned char *)result);
#if 0 /* ONI */
      return;
#else /* ONI */
      goto end;
#endif /* ONI */
    }
  else if(IsEightByteArg(fmt))
    {
      (*readFunction)(funcArg,8,(unsigned char *)result);
#if 0 /* ONI */
      return;
#else /* ONI */
      goto end;
#endif /* ONI */
    }

  /* initialize decoder context */
  context.maxindex= -1;
  context.maxref=0;
  context.unresolve_count=0;
  context.allocate=createPointerTable();
  context.unresolved=createPointerTable();
#ifdef INTERSITE
  if(foreing_flag)
    context.foreign_flag = 1;
  else
    context.foreign_flag = 0;
#endif

  (*readFunction)(funcArg,4,(unsigned char *)&entry_point);

  (*fetchFunction)(funcArg,0,4,(unsigned char *)&firstWord);
  if(firstWord==0)
    { /* return null of complex type */
      (*readFunction)(funcArg,4,(unsigned char *)&firstWord);
      *((int *)result) = 0;
#if 0 /* ONI */
      return;
#else /* ONI */
      goto end;
#endif /* ONI */
    }

  while(context.maxindex<context.maxref)
    {
      (*fetchFunction)(funcArg,4,4,&size);
      original_size = size;
      oh=(OZ_Header)p=MmAlloc(heap,&size);
      (*readFunction)(funcArg,original_size,(unsigned char *)oh);
      oh->e = size;
      context.maxindex=putPointerTable(context.allocate,oh);
      kind=(int)oh->d;

#if 0
OzDebugf("decode_comm:obj@%x size:%d Byte kind:%d, maxindex %d, maxref %d\n",
oh,size,kind,context.maxindex,context.maxref);
#endif

      switch(kind)
	{
	case OZ_LOCAL_OBJECT:
	  offset=(int)oh;
#if 0
	  OzDebugf("This object consists of %d parts\n",oh->h);
#endif
	  oh->t = (offset + (int)(oh->t));
#ifdef INTERSITE
	  oh->p |= context.foreign_flag;
#endif

	  for(ohp=oh+1,i=0; i<(oh->h);i++,ohp++)
	    { context.maxindex=putPointerTable(context.allocate,ohp);
#if 0
	      OzDebugf(" offset before convert %x\n",ohp->d);
#endif
	      ohp->d = (void *)(offset+(int)(ohp->d));
#if 0
	      OzDebugf(" offset after convert %x\n",ohp->d);
#endif
	      traverseObjectBody(&context, (OZ_AllocateInfo)ohp->d);
#if 0
	      NoPrintf("decode_comm:local_object:maxindex %d maxref %d unresolve_count %d\n",
		       maxindex,maxref,unresolve_count);
#endif
	    }
	  break;
	case OZ_ARRAY:
	  if(isPointerArray(oh->a))
	    {
#if 0
	      NoPrintf("array is pointer array\n");
#endif
	      traversePointers(&context,(int *)(oh+1),oh->h);
	    }
#if 0
NoPrintf("decode_comm:array:maxindex %d maxref %d unresolve_count %d\n",
	 maxindex,maxref,unresolve_count);
#endif
	  break;
	case OZ_STATIC_OBJECT:
	  offset=(int)oh;
	  oh->t = oh->t+offset;
#if 0 /* ONI */
	  traverseObjectBody(&context, (OZ_AllocateInfo)oh+1);
#else
	  traverseObjectBody(&context, (OZ_AllocateInfo)(oh+1));
#endif /* ONI */
	  break;

	case OZ_RECORD:
	  /* do nothing */
	  break;
	}
  }
#if 0
OzDebugf("resolve addresses (%d)\n",context.unresolve_count);
#endif
  /* change local index to real address reference */
  for(ii=0;ii<context.unresolve_count;ii++)
    {
      ip=readPointerTable(context.unresolved,ii);
#if 0
OzDebugf(" contents of address %08x (%08x) -> ",ip,*ip);
#endif
      *ip=(int)readPointerTable(context.allocate,*ip);
#if 0
OzDebugf(" (%08x) changed\n",*ip);
#endif 
    }
#if 0
  OzDebugf("entry_point %d\n",entry_point);
#endif

  *((void **)result) = readPointerTable(context.allocate,entry_point);

#if 0
  OzDebugf(" result is saved at %x (value:%x) \n",result, *((int *)result));
#endif
  freePointerTable(context.allocate);
  freePointerTable(context.unresolved);

#if 1 /* ONI */
 end:
  OzExecEnterMonitor(&(heap->lock));
  heap->decoding--;
  if (heap->decoding == 0)
    OzExecSignalCondition(&(heap->decode_end));
  OzExecExitMonitor(&(heap->lock));
#endif /* ONI */

  return;
}
