/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <fcntl.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "ot.h"
#include "encode.h"

/*
 *	Prototype declaration for C Library functions
 */
extern	void	bcopy( char *s1, char *s2, int len ) ;

  
#define	ENC_FILE_BUFFSIZE	4096
  
  typedef struct {
    int     fd;
    char    *bufs;
    char    *bufp;
    char    *bufe;
  } ENC_FILE_CTX;

extern int	OzEncodeDMFReset();


int OzEncPutbuff(ENC_FILE_CTX	*f_ctx, char *dt, int size)
{
  int		put_size, free_buf;

#if 0 /* debug print */
OzDebugf("OzEncPutBuff: buffer %x:%x:%x data %x size %d\n",
f_ctx->bufs,f_ctx->bufp,f_ctx->bufe,dt,size);

if(size<0)
  {

    OzDebugf("OzExecCifFlush: strange size %x(hex)\n",size);
  }
#endif  

  free_buf = (int)(f_ctx->bufe - f_ctx->bufp);
  put_size = size;
  while(put_size >= free_buf) {
    bcopy(dt, f_ctx->bufp, free_buf);
    dt += free_buf;
    put_size -= free_buf;
    if(OzWrite(f_ctx->fd, f_ctx->bufs, ENC_FILE_BUFFSIZE) < 0) {
      OzDebugf("CifFlush: write error\n");
      return(ENC_WRITE_ERROR);
    }
    f_ctx->bufp = f_ctx->bufs;
    free_buf = ENC_FILE_BUFFSIZE;
  }
  if(put_size) {
    bcopy(dt, f_ctx->bufp, put_size);
    f_ctx->bufp += put_size;
  }
  return(0);
}

static
int  enc_flushbuffer(ENC_FILE_CTX	*f_ctx)
{
  int		size;
#if 0
  struct stat	st;
#endif
  
  if((size = (int)(f_ctx->bufp - f_ctx->bufs)) == 0) {
    OzClose(f_ctx->fd);
    return(0);
  }
#if 0
  fstat(f_ctx->fd, &st);
  OzDebugf("CifFlush: size before flush = %d\n", st.st_size);
#endif
  if(OzWrite(f_ctx->fd, f_ctx->bufs, size) < 0)
    { OzDebugf("CifFlush: write error\n");
      return(ENC_WRITE_ERROR); }
  
#if 0
  fstat(f_ctx->fd, &st);
  OzDebugf("CifFlush: size after flush = %d\n", st.st_size);
#endif
  
  OzClose(f_ctx->fd);
#if 0
  OzDebugf("CifFlush: size calculated  = %d\n", size);
#endif
  return(0);
}

static int init_cif_flush(ENC_FILE_CTX *ef_con, char *datfile)
{
#if 0
  struct stat	st;
#endif
  
#if	1
  OzUnlink( datfile ) ; /* ignore error */
  if((ef_con->fd = OzOpen(datfile, O_WRONLY|O_CREAT, 0777)) < (int)0) {
  /* O_TRUNC mode is bad when debugger edit object-image */
#else
  if((ef_con->fd = OzOpen(datfile, O_WRONLY|O_CREAT|O_TRUNC, 0777))
     < (int)0) {
#endif
    
    OzDebugf("init_cif_flush: creat failed %s\n", datfile);
    
    return((int)(-1));
  }
#if 0
  fstat(ef_con->fd, &st);
  OzDebugf("CifFlush: size of opened file = %d\n", st.st_size);
#endif
  if(OzEncPutbuff(ef_con, "\000\000\000\001", 4) < 0) {	/* Arch type	(sun4) */
    return(-1);
  }
  return(ef_con->fd);
}

int OzExecCifFlush(char *path, OZ_Header entry)
{
  char	encfile_buf[ENC_FILE_BUFFSIZE];
  int entry_index;

  ENC_FILE_CTX ef_con = {
    0, encfile_buf, encfile_buf, &encfile_buf[ENC_FILE_BUFFSIZE]
    };
  
#if 0
  OzDebugf("OzExecCifFlush:enter 0x%08x\n",sbrk(0));
#endif
  
  if(init_cif_flush(&ef_con, path) < 0)
    return(ENCODE_FAILED);
  
  OzDebugf("OzExecCifFlush:initialized\n");
  
  entry_index = entry->e + 1;

  if(OzEncPutbuff(&ef_con,(char *)(&entry_index),4)<0) { /* dummy index (0) */
    return(-1);
  }

  if(OzEncodeDMFReset(OzEncPutbuff, (void *)&ef_con, entry, ENC_COMM)) {
    return(ENCODE_FAILED);
  }
  
  OzDebugf("OzExecCifFlush:encorded\n");
  
  enc_flushbuffer(&ef_con);
  
#if 0
  OzDebugf("OzExecCifFlush:finished 0x%08x\n",sbrk(0));
#endif
  
  return(0);
}
