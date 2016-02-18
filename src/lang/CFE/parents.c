/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "cfe.h"
#include "cb.h"
#include "command.h"

static void
  print_usage_parents ()
{
  fprintf (stderr, "usage: parents version_id\n");
}

int 
  Parents (int argc, char **argv)
{
  OO_ClassType cl;
  int l, h;
  OO_List list;
  long long vid;

  if (argc < 2)
    print_usage_parents ();
  
  if (!(cl= LoadClassFromZ (GetVID (argv[1], -1), 1)))
    return 1;

  if (list = cl->class_part_list)
    list = &list->cdr->list_rec;

  for (; list ; list = &list->cdr->list_rec)
    {
      vid = list->car->class_type_rec.class_id_protected;

      printf ("%08x%08x ",
	      (int) (vid >> 32), (int) (vid & 0xffffffff));
    }

  if (cl->no_parents)
    printf ("\n");
}

