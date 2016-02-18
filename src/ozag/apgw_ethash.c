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
#include "apgw_ethash.h"
  
  HashTableRec	ex_tbl;

ExecTable	ApgwEnterEtHash(HashTable hp, long long eid, 
				struct sockaddr_in *addr, 
				executor_location loc);

static int	EtHash(long long eid, int hsize)
{
  unsigned int	sid, exid;
  
  sid	= (int)((eid>>48) & 0xffffLL);
  exid	= (int)((eid>>24) & ET_HASH_MASK);
  return((int)((sid * exid) % hsize));
}

int	
  ApgwInitEtHash(HashTable hp)
{
  hp->size	= INIT_EXEC_TABLE_SIZE;
  hp->count = 0;
  hp->tp = (void *)malloc(SZ_EXTBL * INIT_EXEC_TABLE_SIZE);
  if(hp->tp == (void *)0) {
    perror("ApgwInitEtHash: malloc");
    return(1);
  }
  bzero((char *)hp->tp, SZ_EXTBL * INIT_EXEC_TABLE_SIZE);
  return(0);
}

static int	ApgwXpndEtHash(HashTable hp)
{
  HashTableRec	hh;
  ExecTable	sp, ep;
  
  hh.size		= hp->size * 2;
  
  hh.tp = (void *)malloc(SZ_EXTBL * hh.size);
  if(hh.tp == (void *)0) {
    perror("ApgwXpndEtHash: malloc");
    return(1);
  }
  
  bzero((char *)hh.tp, SZ_EXTBL * hh.size);
  
  hh.count	= 0;
  ep	= (ExecTable)hh.tp + hh.size;
  for(sp=(ExecTable)hh.tp; sp<ep; sp++) {
    if(sp->eid == 0LL) continue;
    ApgwEnterEtHash(&hh, sp->eid, &(sp->addr), sp->loc);
  }
  
  free((char *)hp->tp);
  hp->size	= hh.size;
  hp->tp		= hh.tp;
  return(0);
}

ExecTable	
  ApgwEnterEtHash(HashTable hp, long long eid, struct sockaddr_in *addr, 
		  executor_location  loc)
{
  int		sw;
  ExecTable	sp;
  
  if((eid & 0x0000ffffffffffffLL)==0LL)
    return((ExecTable)1); /* dummy exid, ignored */

  if(hp->size < (hp->count * 2)) {
    if(ApgwXpndEtHash(hp))
      return((ExecTable)0);
  }
  
  sw	= 0;
  for (sp=((ExecTable)hp->tp+EtHash(eid, hp->size));sp->eid!=0LL; ) {
    if(sp->eid == (eid & EXID_MASK)) {
      sw	= 1;
      break;
    }
    if(++sp >= ((ExecTable)hp->tp + hp->size))
      sp	= (ExecTable)hp->tp;
  }
  
  sp->eid	= (eid & EXID_MASK);
  bcopy((char *)addr, (char *)&(sp->addr), sizeof(sp->addr));
  sp->loc	= loc;

  if(!sw)
    hp->count++;
#ifdef  DEBUG
  printf("ApgwEnterEtHash: entered ID(0x%08x%08x) on Executor Table, Count(%d)\n",
	 (int)((eid>>32)&INTEGER_MASK), (int)(eid&INTEGER_MASK), hp->count);
#endif
  return(sp);
}
  
ExecTable	ApgwSearchEtHash(HashTable hp, long long eid)
{
  ExecTable	sp;
  
  for (sp=((ExecTable)hp->tp+EtHash(eid, hp->size));sp->eid!=0LL; ) {
    if(sp->eid == (eid & EXID_MASK))
      return(sp);
    if(++sp >= ((ExecTable)hp->tp + hp->size))
      sp	= (ExecTable)hp->tp;
  }
  return((ExecTable)0);
}
  
void	ApgwRemoveEtHash(HashTable hp, long long eid)
{
  ExecTable	spp, dt_top, dt_s, dt_e;
  
  dt_top = dt_e = (ExecTable)malloc(SZ_EXTBL * hp->count);
  if(dt_s == (ExecTable)0) {
    perror("ApgwRemoveEtHash: malloc");
    return;
  }
  for (spp=((ExecTable)hp->tp+EtHash(eid, hp->size));spp->eid!=0LL; ) {
    if(spp->eid != (eid & EXID_MASK)) {
      bcopy((char *)spp, (char *)dt_e, SZ_EXTBL);
      dt_e++;
    }
    bzero((char *)spp, SZ_EXTBL);
    hp->count--;
    if(++spp >= ((ExecTable)hp->tp + hp->size))
      spp	= (ExecTable)hp->tp;
  }
  for(dt_s=dt_top; dt_s<dt_e; dt_s++) {
    ApgwEnterEtHash(hp, dt_s->eid, &(dt_s->addr), dt_s->loc);
  }
  free((char *)dt_top);
  return;
}

int	init_executor_table()
{
  return(ApgwInitEtHash(&ex_tbl));
}

