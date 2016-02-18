/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>

#include "generic.h"

static TypeParameterList tp_list = NULL, tail = NULL;

SetTypeParameter (char *str)
{
  TypeParameterList buf;
  
  buf = (TypeParameterList) malloc (sizeof (TypeParameterList_Rec) 
				    + strlen (str));
  
  strcpy (buf->param, str);
  buf->next = NULL;
  
  if (tail)
    tail->next = buf;
  else
    tp_list = buf;
  tail = buf;
}

SearchTypeParameter (char *str)
{
  TypeParameterList list = tp_list;

  while (list)
    {
      if (!strcmp (list->param, str))
	return 1;
      list = list->next;
    }
  return 0;
}

PrintTypeParameters ()
{
  TypeParameterList list = tp_list;

  while (list)
    {
      printf ("%s\n", list->param);
      list = list->next;
    }
}


