/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "object.h"

extern FILE *yyin;
char *class_path, *oz_root = NULL;

int error = 0;

static
print_usage ()
{
  fprintf(stderr, "usage: oic [-d] [-c oid_counter] file1 ...\n");
}

main(int argc, char **argv)
{
  int debug = 0, opt = 0, i = argc < 4 ? argc - 1 : 3;

  if (argc < 2)
    {
      print_usage ();
      exit(1);
    }

  while (i > 0)
    {
      if (!strcmp(argv[i], "-d"))
	{
	  debug = 1;
	  opt++;
	  i--;
	}
      else if (isdigit(*argv[i]))
	{
	  if (strcmp (argv[--i], "-c"))
	    {
	      print_usage ();
	      exit (1);
	    }
	  
	  InitCounter(argv[i + 1]);
	  opt += 2;
	  i--;
	}
      else
	i--;
    }
  if (argc <= 3)
    InitCounter (NULL);

  if (!(oz_root = getenv ("OZROOT")))
    {
      fprintf (stderr, "You must set OZROOT\n");
      exit (1);
    }

#if 0
  if (!(class_path = getenv("OZCLASSPATH")))
    {
      fprintf(stderr, "OZCLASSPATH not defined\n");
      exit(0);
    }
#else
  class_path = (char *) malloc (strlen (oz_root) + 15 + 1);
  sprintf (class_path, "%s/lib/boot-class", oz_root);
#endif

  malloc_debug (2);

  for (i = opt + 1; i < argc; i++)
    {
      if (!(yyin = fopen(argv[i], "r")))
	{
	  fprintf(stderr, "cannot open file:%s\n", argv[i]);
	  exit(1);
	}
  
      yyparse();
      
      CheckRef();
      
      if (debug)
	{
	  PrintObjects();
	}
    }
      
  if (!error)
    EmitFile();

  return 0;
}
