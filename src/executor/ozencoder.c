/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* encode_file() is encoder to output to file and pointers appeard	*/
/* are converted to offset from begining of first item.		*/
/* encode_comm() is encoder to output via communication		*/
/* and pointers to OZ_HeaderRec are converted to local indicies	*/
/* and pointers to objectParts  are converted to offset from		*/
/* begining of their objectAll. */
/* unix system include */
#include <stdio.h>
/* multithread system include */
#include "thread/monitor.h"

#include "switch.h"
#include "common.h"
#include "oz++/type.h"

#include "encode-subs.h"
#include "encode.h"

/*
 *	Prototype declaration for C Library functions
 */
extern	void	bzero( char *s, int length ) ;
extern	void	bcopy( char *s1, char *s2, int len ) ;

#define	DEBUG

/* Hash and Fifo routine (extern)					*/

/* Fifo is a first-in first-out register of pointers to void.		*/
/* OzCreateFifo,OzPutFifo returns null when error occurs.		*/
/* First argument of OzPutFifo,OzGetFifo,OzFreeFifo is pointer to fifo.*/

/* Hash is an associative pair of (void *)key and (void *)value	*/
/* with hash-search functions.						*/
/* OzCreateHash,OzPutHash returns null when error occurs.		*/
/* First argument of OzPutHash,OzGetHash,OzFreeHash is pointer to hash	*/
/* table.								*/
/* OzSearchHash returns null to indicate NOT_FOUND.			*/

static OZ_MonitorRec zeroMonitor = {0,0,0,0};

static int
  enc_get_localindex(ENC_CONTEXT *e_con, OZ_Header addr)
{
  int		old_value;
  void		*found;
  OZ_Header	h_top;
  
  /* case of object, find top of ObjectAll	*/
  h_top = ((addr->h==LOCAL)? (addr - (addr->e + 1)): addr);
  
  if( (found = OzSearchHash(e_con->hash, (void *)h_top)) != NULL )
    return((int)(found - 1));
  
  if(OzPutFifo((Fifo)(e_con->fifo), (void *)addr) == 0)
    return(-1);
  if(OzEnterHash(e_con->hash, (void *)h_top, (void *)e_con->curr_value)
     == 0)
    return(-1);
  
  old_value = e_con->curr_value;
  if(e_con->kind == ENC_FILE) {
    e_con->curr_value += h_top->e;
  } else {	/* ENCODE_COMM	*/
    e_con->curr_value += ((addr->h==LOCAL)?(addr-(addr->e+1))->h+1:1);
  }
  return(old_value - 1);
}

static int
  enc_pointers(ENC_CONTEXT *e_con, long *pl, int p_c)
{
  long		*ps, *pe;
  OZ_Header	ph;
  int		temp;
  
  for(ps=pl,pe=pl+CEILING(p_c); ps<pe; ps++) {
    if(*ps == (long)0) {
      temp = 0;
    } else {
      ph = (OZ_Header)*ps;
      if((temp = enc_get_localindex(e_con, ph)) < 0)
	return(ENC_MALLOC_ERROR);
      if(ph->h == LOCAL) {
	if(e_con->kind==ENC_FILE) {
	  temp += sizeof(OZ_HeaderRec)*(ph->e+1);
	} else {
	  temp += ph->e + 1;
	}
      }
    }
    if((*(e_con->writefunc))(e_con->arg, (char *)&temp, sizeof(long)) < 0)
      return(ENC_WRITE_ERROR);
  }
  return(0);
}

static int
  enc_allocinfo(ENC_CONTEXT *e_con, OZ_AllocateInfo a1)
{
  long	*pl;
  int	error;
  int i;
  
  /*
    #ifdef	DEBUG
    OzDebugf("  enc_allocinfo: d_size_pro(%d)  ", a1->data_size_protected);
    OzDebugf("d_size_pri(%d)  ", a1->data_size_private);
    OzDebugf("n_poi_pro(%d)  ", a1->number_of_pointer_protected);
    OzDebugf("n_poi_pri(%d)\n", a1->number_of_pointer_private);
    #endif
    */
  
  if((*(e_con->writefunc))(e_con->arg, (char *)a1, sizeof(OZ_AllocateInfoRec)) < 0)
    return(ENC_WRITE_ERROR);
  
  /* protected pointers	*/
  pl = (long *)(a1 + 1);
  if((error=enc_pointers(e_con, pl, a1->number_of_pointer_protected)) < 0)
    return(error);
  pl += CEILING(a1->number_of_pointer_protected);
  
  /* protected data	*/
  if((*(e_con->writefunc))(e_con->arg, (char *)pl, a1->data_size_protected) < 0)
    return(ENC_WRITE_ERROR); /* protected data	*/
  
  /* advance pl by a1->data_size_protected [byte]	*/
  pl += (a1->data_size_protected / sizeof(long));
  
  /* protected zero */
  for(i=0;i<a1->zero_protected;i++)
    if((*(e_con->writefunc))(e_con->arg, (char *)(&zeroMonitor),
			     sizeof(OZ_MonitorRec)) < 0)
      return(ENC_WRITE_ERROR); /* protected zero */
  
  pl += (a1->zero_protected * sizeof(OZ_MonitorRec)/sizeof(long));
  
  /* private pointers	*/
  if((error=enc_pointers(e_con, pl, a1->number_of_pointer_private)) < 0)
    return(error);
  pl += CEILING(a1->number_of_pointer_private);
  
  /* private data		*/
  if((*(e_con->writefunc))(e_con->arg, (char *)pl, a1->data_size_private) < 0)
    return(ENC_WRITE_ERROR);
  
  /* private zero */
  for(i=0;i<a1->zero_private;i++)
    if((*(e_con->writefunc))(e_con->arg, (char *)(&zeroMonitor),
			     sizeof(OZ_MonitorRec)) < 0)
      return(ENC_WRITE_ERROR); /* private zero */
  
  return(0);
}

static int
  enc_header(ENC_CONTEXT *e_con, OZ_Header ph, int member_d, int member_t,
	     unsigned int member_g)
{
  OZ_HeaderRec	head;
  
  (void)bcopy((char *)ph, (char *)&head, sizeof(OZ_HeaderRec));
  head.d = (void *)member_d;
  head.t = member_t;
  head.g = member_g;
  if((*(e_con->writefunc))(e_con->arg, (char *)&head, sizeof(OZ_HeaderRec)) < 0)
    return(ENC_WRITE_ERROR);
  return(0);
}

static int
  enc_local_object(ENC_CONTEXT *e_con, OZ_Header h1)
{
  int		i, offset, h_offset, error,offset_of_monitor;
  OZ_Header	h2, h_top;
  OZ_AllocateInfo	a1;
  
  int diff;
  unsigned int dmflags;
  
  h_top = h1 - (h1->e + 1);	/* find top of objectAll	*/
  
  offset_of_monitor = (char *)(h_top->t)- (char *)h_top;
  
  if(e_con->kind == ENC_FILE) {
    h_offset = enc_get_localindex(e_con, h_top);
    offset = h_offset + (sizeof(OZ_HeaderRec) * (h_top->h + 1));
    offset_of_monitor += h_offset;
  } else {
    offset = sizeof(OZ_HeaderRec) * (h_top->h + 1);
    h_offset = 0 ;
  }
  
  
  /* header of ObjectAll					*/
  /* member .d is used to distinguish object from array	*/
  dmflags = (e_con->dmfResetFlag)? 0 : h_top->g;
  if(enc_header(e_con, h_top, OZ_LOCAL_OBJECT,offset_of_monitor,dmflags))
    return(ENC_WRITE_ERROR);
  
  for(i=0,h2=h_top+1; i<h_top->h; i++,h2++) {
    a1 = h2->d;
    dmflags = (e_con->dmfResetFlag)? 0 : h2->g;
    if(enc_header(e_con, h2, offset,0,dmflags))
      return(ENC_WRITE_ERROR);
    offset += sizeof(OZ_AllocateInfoRec) + sizeof(long)
      * (CEILING(a1->number_of_pointer_private)
	 + CEILING(a1->number_of_pointer_protected))
	+ a1->data_size_private + a1->data_size_protected
	  + sizeof(OZ_MonitorRec)*(a1->zero_private + a1->zero_protected);
  }
  for(i=0,h2=h_top+1; i<h_top->h; i++,h2++) {
    if((error = enc_allocinfo(e_con, (OZ_AllocateInfo)(h2->d))) < 0)
      return(error);
  }
  
  if((*(e_con->writefunc))(e_con->arg, (char *)(&zeroMonitor),
			   sizeof(OZ_MonitorRec)) < 0)
    return(ENC_WRITE_ERROR); /* monitor*/
  
  diff = (e_con->kind == ENC_FILE) ? (h_top->e - offset - 8 + h_offset) : 
    (h_top->e - offset - 8) ;
  
  if (diff)
    {
      int i, dummy = 0;
      
      /*
	OzDebugf ("diff = %d, size = %d\n", diff, h_top->e);
	*/
      
      for (i = 0; i < diff / sizeof (int); i++)
	if((*(e_con->writefunc))(e_con->arg, (char *)&dummy,
				 sizeof (int)) < 0)
	  return(ENC_WRITE_ERROR); /*  diff */
    }
  
  
  return(0);
}

static int
  enc_static_object(ENC_CONTEXT *e_con, OZ_Header h1)
{
  int	error;
  int offset_of_monitor,h_offset;
  unsigned int dmflags;
  
  offset_of_monitor = (char *)(h1->t)- (char *)h1;
  if(e_con->kind == ENC_FILE) {
    h_offset = enc_get_localindex(e_con, h1);
    offset_of_monitor += h_offset;
  }
  dmflags = (e_con->dmfResetFlag)? 0 : h1->g;
  if(enc_header(e_con, h1, OZ_STATIC_OBJECT,offset_of_monitor,dmflags))
    return(ENC_WRITE_ERROR);
  if((error = enc_allocinfo(e_con, (OZ_AllocateInfo)(h1 + 1))) < 0)
    return(error);
  if((*(e_con->writefunc))(e_con->arg, (char *)(&zeroMonitor),
			   sizeof(OZ_MonitorRec)) < 0)
    return(ENC_WRITE_ERROR); /* monitor*/
  
  return(0);
}

static int
  enc_record(ENC_CONTEXT *e_con, OZ_Header h1)
{
  unsigned int dmflags;
  
  dmflags = (e_con->dmfResetFlag)? 0 : h1->g;
  if(enc_header(e_con, h1, (int)h1->d, h1->t ,dmflags))
    return(ENC_WRITE_ERROR);
  
  if((*(e_con->writefunc))(e_con->arg, (char *)(h1+1), (h1->e)-sizeof(OZ_HeaderRec)) < 0)
    return(ENC_WRITE_ERROR);
  return(0);
}

static int
  enc_object_array(ENC_CONTEXT *e_con, OZ_Header h1)
{
  int	arraysize, error;
  int diff;
  unsigned int dmflags;
  
  /* member .d is used to distinguish array from object */
  dmflags = (e_con->dmfResetFlag)? 0 : h1->g;
  if(enc_header(e_con, h1, OZ_ARRAY,0,dmflags))
    return(ENC_WRITE_ERROR);
  
  if(NOT_POINTERARRAY(h1->a)) {
    arraysize = h1->e - sizeof(OZ_HeaderRec);
    if((*(e_con->writefunc))(e_con->arg, (char *)(h1 + 1), arraysize) < 0)
      return(ENC_WRITE_ERROR);
  } else {	/* pointers	*/
    if((error = enc_pointers(e_con, (long *)(h1 + 1), h1->h)) < 0)
      return(error);
    
    
    diff = ( (h1->e - (sizeof(OZ_HeaderRec)
		       + ((h1->h + (h1->h & 1)) * sizeof(int *)))) );
    if (diff)
      {
	int i, dummy = 0;
	
	/*
	OzDebugf ("diff = %d, size = %d\n", diff, h1->e);
	*/
	
	for (i = 0; i < diff / sizeof (int); i++)
	  if((*(e_con->writefunc))(e_con->arg, (char *)&dummy,
				   sizeof (int)) < 0)
	    return(ENC_WRITE_ERROR); /*  diff */
      }
    
  }
  return(0);
}

static int
  init_encode(ENC_CONTEXT *e_con, 
	      int (*writefunc)(), void *func_arg, int kind,
	      int dmfResetFlag)
{
  e_con->fifo = OzCreateFifo();
  e_con->hash = OzCreateHash();
  if((e_con->fifo == (void *)0) || (e_con->hash == (void *)0))
    return(ENC_MALLOC_ERROR);
  
  e_con->writefunc = writefunc;
  e_con->arg = func_arg;
  e_con->kind = kind;
  e_con->dmfResetFlag = dmfResetFlag;
  e_con->curr_value = 1;
  return(0);
}

/* First arguments specify function to output encoded data		*/
/* *writefunc should have interface bellow and should be function to output */
/* (size)-byte of data from *buf					*/
/* int *writefunc(void *arg, unsigned char *buf, int size);		*/
/* *writefunc() returns negative value to  indicate error		*/
/* encode returns non-negative value if successed,	*/
/* and returns negative value in a case error.		*/
/* Error type is defined below				*/



int	OzEncodeDM(int (*writefunc)(), 
		   void *func_arg, OZ_Header entry, int kind,
		   int dmfResetFlag)
{
  ENC_CONTEXT	e_con;
  OZ_Header	h1;
  int		status;
  
  status = init_encode(&e_con, writefunc, func_arg, kind,dmfResetFlag);
  if(status)
    goto ENC_ERROR;
  
  /* register first entry	*/
  if(enc_get_localindex(&e_con, entry) == (-1)) {
    status = ENC_MALLOC_ERROR;
    goto ENC_ERROR;
  }
  
  /* main loop	*/
  while( (h1 = OzGetFifo(e_con.fifo)) != NULL ) {
    
    switch(h1->h) {
    case LOCAL:
      status = enc_local_object(&e_con, h1);
      if (status)
	goto ENC_ERROR;
      continue;
    case STATIC:
      status = enc_static_object(&e_con, h1);
      if (status)
	goto ENC_ERROR;
      continue;
    case RECORD:	/* ENCODE_COMM Only	*/
      status = enc_record(&e_con, h1);
      if (status)
	goto ENC_ERROR;
      continue;
    default:	/* array	*/
      status = enc_object_array(&e_con, h1);
      if (status)
	goto ENC_ERROR;
      continue;
    }
  }	/* end of main loop	*/
  
 ENC_ERROR:
  /* free tables		*/
  OzFreeHash(e_con.hash);
  OzFreeFifo(e_con.fifo);
  return(status);
}

int	OzEncode(int (*writefunc)(), void *func_arg, OZ_Header entry, int kind)
{
  return(
	 OzEncodeDM(*writefunc, func_arg, entry, kind, 0)
	 );
}

int	OzEncodeDMFReset(int (*writefunc)(), void *func_arg, OZ_Header entry, int kind)
{
  return(
	 OzEncodeDM(writefunc, func_arg, entry, kind, 1)
	 );
}
