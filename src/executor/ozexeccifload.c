/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* faster version: reduce OzRead by buffering */
/* unix system include */
#include	<sys/types.h>
#include	<sys/stat.h>
#include	<sys/fcntl.h>
/* multithread system include */
#include	"thread/thread.h"
#include	"oz++/ozlibc.h"

#include	"switch.h"
#include	"ot.h"
#include	"encode.h"
#include	"decode.h"

/*
 *	Prototype declaration for C Library functions
 */
extern	void	bcopy( char *s1, char *s2, int len ) ;

#if	0
#define	DEBUG
#define	DEBUG1
#endif

#define SKIPHEADER(h)	((char *)h + sizeof(OZ_HeaderRec))
#define PATCH_LID(v, o)	if(v)(long)v=(long)(o->top_tracep+(int)v)
#define PADDING(n_p)	(n_p & 1)
#define NOT_POINTERARRAY(v) ((v!=OZ_ARRAY)&&(v!=OZ_LOCAL_OBJECT)&&(v!=OZ_STATIC_OBJECT))

#define FileReadBufferSize 4096
typedef struct OzFileDecodeConRec {
  int fd;
  int which_buffer;
  int data_in_buffer[2];
  unsigned char buffer[2][FileReadBufferSize] ;
  unsigned char *bp[2];
} OzFileDecodeConRec, *OzFileDecodeCon;

void 
finish_OIF_load(OzFileDecodeCon f)
{
  OzDebugf("finish_OIF_load \n");
  OzClose(f->fd);
  OzFree(f);
}


 /* file IO */
void
ReadFileBlock(OzFileDecodeCon f,int which)
{
  f->data_in_buffer[which] = OzRead(f->fd,f->buffer[which],FileReadBufferSize);
  f->bp[which]=f->buffer[which];
}


static void
prefetchFile(OzFileDecodeCon f,int offset,int size,unsigned char *dest)
{
#if 0
  OzDebugf("prefetchFile: offset %d, size %d, dest %x\n",offset,size,dest);
  OzDebugf("prefetchFile: data_in_buffer is %d\n",f->data_in_buffer);
#endif
  
  int using,preparing;
  
  using=f->which_buffer;
  preparing = (using)? 0:1;
  
  
  if(f->data_in_buffer[f->which_buffer] <(offset+size))
    {
      
      ReadFileBlock(f,preparing);
      
      if(f->data_in_buffer[using] <= offset)
	{
	  offset -= f->data_in_buffer[using];
	  bcopy((f->bp[preparing])+offset,dest,size);
	}
      else
	{
	  bcopy((f->bp[using])+offset,dest,f->data_in_buffer[using]-offset);
	  dest+= f->data_in_buffer[using]-offset;
	  size-= f->data_in_buffer[using]-offset;
	  bcopy(f->bp[preparing],dest,size);
	}
      
#if 0
      OzDebugf("prefetchFile: read new data, data_in_buffer is %d now \n",f->data_in_buffer);
#endif
    }
  else
    {
      bcopy((f->bp[using])+offset,dest,size);
    }
#if 0
  OzDebugf(" readout is %x\n",(int)(*dest));
#endif
  
  return;
}


/* change on 9-Oct-95 by Y.Hamazaki */
/* recursive call -> do loop */
void
  readFile(OzFileDecodeCon f,int size,unsigned char *dest)
{
  int using,preparing;
#if 0
  OzDebugf("readFile: size %d, dest %x\n",size,dest);
#endif
  
  do {  
    using = f->which_buffer;
    preparing = (using)? 0:1;
    
    if(f->data_in_buffer[using] >= size)
      { /* all of required data exist in prefetch buffer */
	bcopy(f->bp[using],dest,size);
	f->data_in_buffer[using] -= size;
	f->bp[using] += size;
	size=0;
      }
    else
      { /* a part of required data exist in prefetch buffer */
	bcopy(f->bp[using],dest,f->data_in_buffer[using]);
	dest += f->data_in_buffer[using];
	size -= f->data_in_buffer[using];
	f->data_in_buffer[using]=0;
	if(f->data_in_buffer[preparing] == 0)
	  ReadFileBlock(f,preparing);
	f->which_buffer = preparing;
      }
  }while(size>0);
}


OzFileDecodeCon 
init_cif_load(char *datfile)
{
  OzFileDecodeCon		f;
  
  f = (OzFileDecodeCon)OzMalloc(sizeof(OzFileDecodeConRec));

  if((f->fd = OzOpen(datfile, O_RDONLY)) < 0) {
    OzDebugf("init_cif_load: Cannot open object image file %s\n ", datfile);
    return(0);
  }

  ReadFileBlock(f,0);
  f->which_buffer=0;
  f->bp[1]=f->buffer[1];
  f->data_in_buffer[1]=0;
  return(f);
}

static int cif_decode(OzFileDecodeCon f,Heap heap,OZ_Header *result)
{
  OzDecode(prefetchFile, readFile,(void *)f,'O',result,heap
#ifdef INTERSITE
	   ,0
#endif
	   );
  return(0);
}


OZ_Object
OzExecCifLoad(char *path, Heap heap)
{
  OzFileDecodeCon f;
  OZ_Header oh;
  int i;

  OzDebugf( " OzObjectImageFileLoader: %s\n", path ) ;
  if((f=init_cif_load(path))==0)
    { OzDebugf(" OzObjectImageFileLoader: initialize failure \n");
      return((OZ_Object)DECODE_FAILED); }

  readFile(f,4,(unsigned char *)&i);
  OzDebugf(" OzExecCifLoad(v2.0): architecture type is %d\n",i);

  if(cif_decode(f,heap,&oh))
    { OzDebugf(" OzObjectImageFileLoader: decode failure \n");
      return((OZ_Object)DECODE_FAILED); }

  OzDebugf("OzExecCifLoad returns %x \n ",oh);   
  finish_OIF_load(f);

  return((OZ_Object)oh);
}
