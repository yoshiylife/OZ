/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "oz++/ozlibc.h"
#include "switch.h"
#include "p-table.h"

PointerTable
createPointerTable()
{
  PointerTable pt;
  pt=(PointerTable)OzMalloc(sizeof(PointerTableRec));
  pt->size=0;
  pt->next=(PointerTable)0;
  return(pt);
}

void
*readPointerTable(PointerTable pt, int index)
{
  PointerTable p;
  for(p=pt;index>=POINTER_TABLE_SIZE;index-=POINTER_TABLE_SIZE,p=p->next)
    ;
  return(p->table[index]);
}

int
putPointerTable(PointerTable pt,void *entry)
{
  PointerTable p;
  int i;

  for(p=pt,i=0;p->size==POINTER_TABLE_SIZE;i+=POINTER_TABLE_SIZE,p=p->next)
    ;
  p->table[p->size]=entry;
  i+=p->size;
  p->size++;
  if(p->size==POINTER_TABLE_SIZE)
    { /* if table full, prepare next one */
#if 0
      p->next=(PointerTable)OzMalloc(sizeof(PointerTableRec));
#else
    p->next = createPointerTable();
#endif
}
  return(i);
}

void
freePointerTable(PointerTable pt)
{
  PointerTable p,pnext;
  for(p=pt;p!=(PointerTable)0;)
    {
      pnext=p->next;
      OzFree(p);
      p=pnext;
    }
}

