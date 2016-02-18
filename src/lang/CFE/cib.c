/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/file.h>

#include "oz++/class-type.h"
#include "lang/internal.h"
#include "cfe.h"
#include "cb.h"

static OZ_ClassInfo class_info = NULL;

void
  PrintRuntimeClassInfo()
{
  int i, j;
  char name[256], vid[17], class_name[256], *buf;
  OO_Symbol sym;
  OO_ClassType ct;

  printf("no parts = %d\n", class_info->number_of_parts);
  for (i = 0; i < class_info->number_of_parts; i++)
    {
      printf("Part %d:\n", i);

      sprintf(vid, "0x%08x%08x", 
	     (int)(class_info->parts[i]->cid >> 32),
	     (int)(class_info->parts[i]->cid & 0xffffffff));
      
      printf("\tcid = %s", vid);

      if (buf = GetVID (vid, -1))
	{
	  strcpy (class_name, buf);
	  printf (" (%s)", class_name);
	}
      
      printf ("\n");

      sprintf(vid, "0x%08x%08x", 
	     (int)(class_info->parts[i]->compiled_vid >> 32),
	     (int)(class_info->parts[i]->compiled_vid & 0xffffffff));
      
      printf("\tcompiled_vid = %s\n\n", vid);

      printf("\tprotected_data_size   = %d\n", 
	     class_info->parts[i]->info.data_size_protected);
      printf("\tprivate_data_size     = %d\n", 
	     class_info->parts[i]->info.data_size_private);
      printf("\tno_protected_pointers = %d\n", 
	     class_info->parts[i]->info.number_of_pointer_protected);
      printf("\tno_private_pointers   = %d\n", 
	     class_info->parts[i]->info.number_of_pointer_private);
      printf("\tprotected_zero   = %d\n", 
	     class_info->parts[i]->info.zero_protected);
      printf("\tprivate_zero     = %d\n\n", 
	     class_info->parts[i]->info.zero_private);

      printf("\tno entries = %d\n", 
	     class_info->parts[i]->number_of_entries);

      if (buf)
	ct = LoadClassInfo (class_name, 0);

      for (j = 0; j < class_info->parts[i]->number_of_entries; j++)
	{
	  if (buf)
	    {
	      sprintf (name, "#%d", j);
	      if (!(sym = SearchMember (ct, name)))
		FatalError ("`%s' not defined\n", name);
	    }

	  sprintf (vid, "0x%08x%08x", 
		   (int)(class_info->parts[i]->entry[j].class_part_id >> 32),
		   (int)(class_info->parts[i]->entry[j].class_part_id & 
			 0xffffffff));

	  if (buf && sym)
	    {
	      printf("\t\t slot = %d (%s)\n", j, sym->string);
	      printf("\t\t\tcid = %s", vid);
	    }
	  else
	    {
	      printf("\t\t slot = %d\n", j);
	      printf("\t\t\tcid = %s", vid);
	    }

	  if (class_info->parts[i]->entry[j].class_part_id != 
	      class_info->parts[i]->cid)
	    if (buf = GetVID2 (vid, -1))
	      printf (" (%s)", buf);

	  printf (" func no = %d\n\n",
		  class_info->parts[i]->entry[j].function_no);
	}
    }
}

int
  LoadRuntimeClassInfo(char *filename)
{
  int fd, i, n, offset;
  OZ_ClassPart part;

  if ((fd = open(filename, O_RDONLY, 0644)) < 0) 
    {
      if (ExecMode != TCL_MODE) 
	fprintf(stderr, "cannot open file: `%s'\n", filename);
      return 1;
    }

  if (class_info)
    free (class_info);

  read (fd, (char *)&n, sizeof(int));
  class_info = (OZ_ClassInfo) malloc (n);
  read (fd, (char *) class_info, n);
  close (fd);
  for (i = 0; i < class_info->number_of_parts; i++) 
    {
      offset = (int) class_info->parts[i];
      offset += (int) class_info;
      class_info->parts[i] = (OZ_ClassPart) offset;
    }

  return 0;
}

