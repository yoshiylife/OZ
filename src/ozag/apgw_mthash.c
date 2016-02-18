/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
  
#include "apgw.h"
#include "apgw_mthash.h"
  
  HashTableRec	msg_tbl;

MsgTable	ApgwEnterMtHash(HashTable hp, long long eid, long long caller,
				long long callee);

static int	MtHash(long long mid, int hsize)
{
  unsigned int	eid, oid;
  
  eid	= (unsigned int)((mid >> 32) & MT_HASH_MASK);
  oid	= (unsigned int)(mid & MT_HASH_MASK);
  return((eid * oid) % hsize);
}

int	ApgwInitMtHash(HashTable hp)
{
  hp->size	= INIT_MSG_TABLE_SIZE;
  hp->count = 0;
  hp->tp = (void *)malloc(SZ_MSGTBL * INIT_MSG_TABLE_SIZE);
  if(hp->tp == (void *)0) {
    perror("ApgwInitMtHash: malloc");
    return(1);
  }
  bzero((char *)hp->tp, SZ_MSGTBL * INIT_MSG_TABLE_SIZE);
  return(0);
}

static int	ApgwXpndMtHash(HashTable hp)
{
  HashTableRec	hh;
  MsgTable	sp, ep;
  
  hh.size		= hp->size * 2;
  
  hh.tp = (void *)malloc(SZ_MSGTBL * hh.size);
  if(hh.tp == (void *)0) {
    perror("ApgwXpndMtHash: malloc");
    return(1);
  }
  
  bzero((char *)hh.tp, SZ_MSGTBL * hh.size);
  
  hh.count	= 0;
  ep	= (MsgTable)hh.tp + hh.size;
  for(sp=(MsgTable)hh.tp; sp<ep; sp++) {
    if(sp->mid == 0LL) continue;
    ApgwEnterMtHash(&hh, sp->mid, sp->caller, sp->callee);
  }
  
  free((char *)hp->tp);
  hp->size	= hh.size;
  hp->tp		= hh.tp;
  return(0);
}

MsgTable	
  ApgwEnterMtHash(HashTable hp, long long mid, long long caller, long long callee)
{
  int		sw;
  MsgTable	sp;
  
  if(hp->size < (hp->count * 2)) {
    if(ApgwXpndMtHash(hp))
      return((MsgTable)0);
  }
  
  sw	= 0;
  for (sp=((MsgTable)hp->tp+MtHash(mid, hp->size));sp->mid!=0LL; ) {
    if(sp->mid == mid) {
      sw	= 1;
      printf("Same Message ID is found (0x%08x%08x) in message table, overwritten\n",
       (int)((mid>>32)&INTEGER_MASK),(int)(mid&INTEGER_MASK));
      break;
    }
    if(++sp >= ((MsgTable)hp->tp + hp->size))
      sp	= (MsgTable)hp->tp;
  }
  
  sp->mid	= mid;
  sp->caller = caller;
  sp->callee = callee;
  if(!sw)
    hp->count++;
#ifdef	DEBUG
  printf("ApgwEnterMtHash: entered ID(0x%08x%08x) on Message Table, Count(%d)\n", 
	 (int)((mid>>32)&0xffffffffLL), (int)(mid&0xffffffffLL), hp->count);
#endif
  return(sp);
}

MsgTable	ApgwSearchMtHash(HashTable hp, long long mid)
{
  MsgTable	sp;
  
  for (sp=((MsgTable)hp->tp+MtHash(mid, hp->size));sp->mid!=0LL; ) {
    if(sp->mid == mid)
      return(sp);
    if(++sp >= ((MsgTable)hp->tp + hp->size))
      sp	= (MsgTable)hp->tp;
  }
  return((MsgTable)0);
}

void	ApgwRemoveMtHash(HashTable hp, long long mid)
{
  MsgTable	spp, dt_top, dt_s, dt_e;
  
  dt_top = dt_e = (MsgTable)malloc(SZ_MSGTBL * hp->count);
  if(dt_s == (MsgTable)0) {
    perror("ApgwRemoveMtHash: malloc");
    return;
  }
  for (spp=((MsgTable)hp->tp+MtHash(mid, hp->size));spp->mid!=0LL; ) {
    if(spp->mid != mid) {
      bcopy((char *)spp, (char *)dt_e, SZ_MSGTBL);
      dt_e++;
    }
    bzero((char *)spp, SZ_MSGTBL);
    hp->count--;
    if(++spp >= ((MsgTable)hp->tp + hp->size))
      spp	= (MsgTable)hp->tp;
  }

  for(dt_s=dt_top; dt_s<dt_e; dt_s++) {
    ApgwEnterMtHash(hp, dt_s->mid,dt_s->caller,dt_s->callee);
  }
  free((char *)dt_top);
  return;
}

int	
  init_message_table()
{
  return(ApgwInitMtHash(&msg_tbl));
}
