/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OH_IMPL_H_
#define _OH_IMPL_H_

typedef	enum	{
  OH_LONGLONG,
  OH_STRING
} KeyType;

typedef struct ExecHashTableRec {
  int size;
  KeyType key_type;
  HashHeader table[1];
} ExecHashTableRec, *ExecHashTable;

#define SHOW_KEY   0
#define SHOW_COUNT 1

#include "oz++/ozlibc.h"

inline extern ExecHashTable 
OhCreateHashTable(int size, KeyType key_type)
{
  int i;
  ExecHashTable table;

  table = (ExecHashTable)OzMalloc(sizeof(ExecHashTableRec)
			      + (sizeof(HashHeader) * (size - 1)));
  table->size = size;
  table->key_type = key_type;
  for (i = 0; i < size; i++)
    table->table[i] = (HashHeader)0;
  return(table);
}

#define MAXSUMLEN     15
inline static int code_sum(char *key)
{
  char *c;
  int i, sum = 0;

  for (i = 0, c = key; i < MAXSUMLEN && *c != '\0'; i++, c++)
    sum = sum + (int)(*c);
  return(sum);
}

inline static int
calc_index(void *key, KeyType key_type, int size)
{
  switch(key_type) {
  case OH_LONGLONG:
    return(*(long long *)key & (size - 1));
              /* i.e. int index = element->id % table->size; */
  case OH_STRING:
    return(code_sum((char *)key) & (size - 1));
  default:
    return(0);
  }
}

inline extern void 
OhInsertIntoHashTable(HashHeader element, void *key, ExecHashTable table)
{
  HashHeader head;
  int index = 0;

  element->key = key;
  index = calc_index(key, table->key_type, table->size);
#if 1
  if (index >= table->size) {
    OzError("Hash insert: index out of range (%d).", index);
    OzShutdownExecutor() ;
  }
#endif
  if ((head = table->table[index]) == 0) {
    table->table[index] = element;
    element->next = element;
    element->prev = element;
  } else {
    head->prev->next = element;
    element->prev = head->prev;
    element->next = head;
    head->prev = element;
  }
  element->entry = &table->table[index];
}

inline static int
str_cmp( unsigned char *s1, unsigned char *s2 )
{
	unsigned char c1 ;
	unsigned char c2 ;
	do {
		c1 = *s1 ++ ;
		c2 = *s2 ++ ;
	} while( c1 && c1 == c2 ) ;
	return( c1 - c2 ) ;
}

inline static int
key_eq(void *key1, void *key2, KeyType key_type)
{
  switch(key_type) {
  case OH_LONGLONG:
    return(*(long long *)key1 == *(long long *)key2);
  case OH_STRING:
    return( ! str_cmp(key1,key2) );
  }
  return 0;
}

inline extern HashHeader 
OhKeySearchHashTable(void *key, ExecHashTable table)
{
  HashHeader element, first;

  int index = calc_index(key, table->key_type, table->size);
#if 1
  if (index >= table->size) {
    OzError("Hash search: index out of range.");
    OzShutdownExecutor() ;
  }
#endif
  if (!table->table[index])
    return((HashHeader)0);
  first = (HashHeader)0;
  for (element = table->table[index];
       element != first;
       element = element->next) {
    if (!first)
      first = element;
    if (key_eq(key, element->key, table->key_type)) {
      return(element);
    }
  }
#if 0
  OzDebugf("Hash search: key not found.\n");
#endif
  return((HashHeader)0);
}

inline extern void 
OhRemoveFromHashTable(HashHeader element, ExecHashTable table)
{
  if (element->next == element) {
    *element->entry = (HashHeader)0;
    /* goto end; */
    return;
  }
  if (element == *element->entry)
    *element->entry = element->next;
  element->prev->next = element->next;
  element->next->prev = element->prev;
  /*
 end:
  free(element);
  */
}

inline static void
show_key(void *key, KeyType key_type)
{
  long long val;

  switch(key_type) {
  case OH_LONGLONG:
    val = *(long long *)key;
    OzDebugf("  %08x%08x", (int)(val >> 32), (int)(val & 0xffffffff));
    break;
  case OH_STRING:
    OzDebugf("  %s", (char *)key);
    break;
  }
}

inline extern void 
OhListHashTable(ExecHashTable table, int flag)
{
  int i, count;
  HashHeader element, first;

  for (i = 0; i < table->size; i++) {
    OzDebugf("\n%x: ", i);
    if (!table->table[i])
      continue;
    first = (HashHeader)0;
    count = 0;
    for (element = table->table[i];
	 element != first;
	 element = element->next) {
      count++;
      if (!first)
	first = element;
      if (flag == SHOW_KEY)
	show_key(element->key, table->key_type);
    }
    if (flag == SHOW_COUNT)
      OzDebugf(" %x", count);
  }
  OzDebugf("\n");
}

inline extern int 
OhMapHashTable(ExecHashTable table, int (func)(), void *args )
{
  HashHeader element, last, next;
  int i, flg;
  int count = 0;

  for (i = 0; i < table->size; i++) {
    if (!(element = table->table[i])) continue;
    flg = 1;
    for (last = (table->table[i])->prev; flg; element = next) {
      if (element == last)
	flg--;
      next = (element->next && element->next != element) ? element->next : 0;
      if ( func(element,args) == 0 ) count ++ ;
    }
  }
  return( count ) ;
}

inline extern int 
OhMapHashTable2
  (ExecHashTable table, int (fetch_func)(), int (proc_func)(), void *args )
{
  HashHeader element, first;
  int i;
  int count = 0;
  int data;

  for (i = 0; i < table->size; i++) {
    if (!table->table[i]) continue;
    first = (HashHeader)0;
    for (element = table->table[i];
	 element != first;
	 element = element->next) {
      if (!first)
	first = element;
      if ((data = fetch_func(element)) == 0)
	continue;
      /* if (proc_func(data, args)) count++; *//* Modify by yoshi */
      if (proc_func(data, args) == 0) count++;
    }
  }
  return( count ) ;
}

#endif _OH_IMPL_H_
