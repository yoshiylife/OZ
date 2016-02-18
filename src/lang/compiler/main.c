/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "ozc.h"

#include "emit-class.h"
#include "class.h"
#include "lang/school.h"

int Debug = 0, Generic = 0;

FILE *PrivateOutputFileH;
FILE *PrivateOutputFileL;
FILE *PrivateOutputFileI;
FILE *PrivateOutputFileC;
FILE *PrivateOutputFileD;

FILE *ProtectedOutputFileH;
FILE *ProtectedOutputFileZ;

FILE *PublicOutputFileZ;
FILE *PublicOutputFileH;

int Part, Mode;
int Object = 0;
char *ClassPath = NULL;

static char escaped_file[256];

FILE *
  file_open (char *filename)
{
  FILE *fp;

  if (!(fp = fopen(filename, "w")))
    {
      fprintf(stderr, "cannot open file: %s\n", filename);
      exit(1);
    }
  
  return fp;
}

/*
 * -p0: print this class
 * -p1: print use classes (not included parent classes)
 * -p2: print parnt clases
 * -p3: use option '-p0' , '-p1' and '-p2' 
 */

static 
print_usage ()
{
  fprintf(stderr, 
	  "usage: ozc [-n] [-d2] [-g params] [-object] "
	  "part name file school\n");
#if 0
  fprintf(stderr, 
	  "       ozc [-d2] [-g params] -s name file school\n");
#endif
  fprintf(stderr, 
	  "       ozc [-d2] [-g params] -p0|p2 file\n");
  fprintf(stderr, 
	  "       ozc [-d2] [-g params] -p1|p3 0|1|2 file\n");
  fprintf(stderr, 
	  "       ozc [-d2] [-g params] -p1|p3 file school\n");
#if 0
  fprintf(stderr, 
	  "       ozc [-d2] [-g params] -s -p1|p3 file\n");
#endif
  fprintf(stderr, 
	  "options:\n");
  fprintf(stderr, 
	  "       -n: not emit\n");
  fprintf(stderr, 
	  "       -object: compile for `Object' class\n");
  fprintf(stderr, 
	  "       -p0: print this class\n");
  fprintf(stderr, 
	  "       -p1: print use classes (not included parent classes)\n");
  fprintf(stderr, 
	  "       -p2: print parent clases\n");
  fprintf(stderr, 
	  "       -p3: use option '-p0' , '-p1' and '-p2' \n");
  fprintf(stderr, 
	  "       -pg: print generic parameters\n");
}

/* called by exit */
static void
delete_octal_escaped_source (int status, caddr_t arg) {
#if 1
  unlink (escaped_file);
#endif
}

FILE *
EucToOctalEscape (FILE *in, char *oz_root) {
  int c;
  FILE *out;

  sprintf (escaped_file, "%s/tmp/ozc%d.oz", oz_root, getpid ());

  if ((out = fopen (escaped_file, "w+")) == NULL) {
    fprintf(stderr, "cannot open file: %s\n", escaped_file);
    exit(1);
  }

  on_exit (&delete_octal_escaped_source, NULL);

  while ((c = fgetc (in)) != EOF) {

    if (c > 0x7f) {
      fprintf (out, "\\%o\\%o", c, fgetc (in));
    } else {
      fputc (c, out);
    }
  }

  fclose (in);

  rewind (out);
  return out;
}

main(int argc, char **argv)
{
  int i = 1, not_emit = 0, mem_debug = 0;
  char *vid, filename[256], *name, *oz_root, class_sc, *cpath = NULL;
#if 0
  int shared = 0;
#endif

  Mode = NORMAL;

  while (i < argc && *argv[i] == '-')
    {
      if (!strcmp(argv[i], "-d")) 
	{
	  Debug = 1;
	}
      else if (!strcmp(argv[i], "-d2")) 
	{
	  Debug = 2;
	}
      else if (!strcmp (argv[i], "-n"))
	{
	  not_emit = 1;
	}
      else if (!strcmp (argv[i], "-g"))
	{
	  int j, num = atoi(argv[++i]);

	  for (j = 0; j < num; j++)
	    SetTypeParameter (argv[++i]);

	  Generic = 1;
	}
#if 0
      else if (!strcmp (argv[i], "-s"))
	{
	  shared = 1;
	}
#endif
      else if (!strcmp (argv[i], "-c"))
	{
	  ClassPath = argv[++i];
	}
      else if (!strcmp (argv[i], "-p0"))
	{
	  Mode = THIS_CLASS;
	}
      else if (!strcmp (argv[i], "-p1"))
	{
	  Mode = USED_CLASSES;
	}
      else if (!strcmp (argv[i], "-p2"))
	{
	  Mode = INHERITED_CLASSES;
	}
      else if (!strcmp (argv[i], "-p3"))
	{
	  Mode = ALL_CLASSES;
	}
      else if (!strcmp (argv[i], "-pg"))
	{
	  Generic = 1;
	  Mode = GENERIC_PARAMS;
	}
      else if (!strcmp (argv[i], "-object"))
	{
	  Object = 1;
	}
#ifdef NONISHIOKA
      else if (!strcmp (argv[i], "-md"))
	{
	  mem_debug = atoi (argv[++i]);
	}
#else
#ifdef MALLOC_DEBUG
      else if (!strcmp (argv[i], "-md"))
	{
	  mem_debug = atoi (argv[++i]);
	}
#endif
#endif
      i++;
    }

#ifdef NONISHIOKA
  malloc_debug (mem_debug);
#else
#ifdef MALLOC_DEBUG
  malloc_debug (mem_debug);
#endif
#endif

  if (!(oz_root = getenv ("OZROOT")))
    {
      fprintf (stderr, "You must set OZROOT\n");
      exit (1);
    }
  if (!ClassPath)
    {
      cpath = "lib/boot-class";
      ClassPath = (char *) malloc (strlen (oz_root) + strlen (cpath) + 1);
      sprintf (ClassPath, "%s/%s", oz_root, cpath);
    }

  Pass = 0;
  Part = NOT_PART;

  if (Mode != NORMAL)
    {
#if 0
      if (shared)
	{
	  if (Mode == INHERITED_CLASSES)
	    {
	      print_usage ();
	      exit (1);
	    }
	  
	  yyfile = argv[i];
	  Part = PUBLIC_PART;
	}
      else if (Mode == GENERIC_PARAMS)
#endif
      if (Mode == GENERIC_PARAMS)
	{
	  yyfile = argv[i];
	}
      else if (Mode == USED_CLASSES || Mode == ALL_CLASSES)
	{
	  if (i + 1 == argc)
	    {
	      print_usage ();
	      exit (1);
	    }
	  
	  if (!strchr (argv[i], '.'))
	    {
	      Part = atoi (argv[i++]);
	      yyfile = argv[i];
	    }
	  else
	    {
	      yyfile = argv[i++];
	      LoadSchool (argv[i++]);
	      Part = PRIVATE_PART;
	    }
	}
      else
	yyfile = argv[i];

      if (!(yyin = fopen (yyfile, "r")))
	{
	  fprintf(stderr, "cannot open file: %s\n", argv[i]);
	  exit(1);
	}

      /* octal escaping */
      yyin = EucToOctalEscape (yyin, oz_root);

      yyparse ();

      if (Part == PRIVATE_PART)
	{
	  Pass = 1;
	  yylineno = 1;
	  rewind (yyin);
	  yyparse ();
	}

      fclose (yyin);

      return Error;
    }

#if 0
  if ((shared && i + 2 >= argc) || (!shared && i + 3 >= argc))
#endif
  if (i + 3 >= argc)
    {
      print_usage ();
      exit(1);
    }
  
#if 0
  if (shared)
    {
      Part = PUBLIC_PART;
      name = argv[i++];
    }
  else
    {
#endif
      Part = atoi (argv [i++]);
      name = argv[i++];
  
      if (Object && strcmp (name, "Object"))
	{
	  fprintf (stderr, "this class not `Object'\n");
	  exit (1);
	}
#if 0
    }
#endif

  yyfile = argv[i++];
  LoadSchool (argv[i]);

  vid = GetVID (name, Part);

  if (Debug)
    PrintSchool (-1, 0);

  if (!not_emit)
    switch (Part) 
      {
      case PUBLIC_PART:
	sprintf (filename, "%s/%s/public.z", ClassPath, vid);
	PublicOutputFileZ = file_open (filename);
	
	sprintf (filename, "%s/%s/public.h", ClassPath, vid);
	PublicOutputFileH = file_open (filename);

	class_sc = GetClassSC (name);

	if (class_sc == SC_RECORD || class_sc == SC_STATIC) 
	  {
	    if (class_sc == SC_STATIC)
	      {
		sprintf (filename, "%s/%s/private.i", ClassPath, vid);
		PrivateOutputFileI = file_open (filename);
	      }

	    sprintf (filename, "%s/%s/private.l", ClassPath, vid);
	    PrivateOutputFileL = file_open (filename);
#if 0
	    vid = GetVID (name, 2);
#endif
	    sprintf (filename, "%s/%s/private.c", ClassPath, vid);
	    PrivateOutputFileC = file_open (filename);
	  }

	if (class_sc && class_sc != SC_ABSTRACT)
	  {
	    sprintf (filename, "%s/%s/private.d", ClassPath, vid);
	    PrivateOutputFileD = file_open (filename);
	  }

	break;

      case PROTECTED_PART:
	sprintf (filename, "%s/%s/protected.z", ClassPath, vid);
	ProtectedOutputFileZ = file_open (filename);
	
	sprintf (filename, "%s/%s/protected.h", ClassPath, vid);
	ProtectedOutputFileH = file_open (filename);
	break;

    case PRIVATE_PART:
	sprintf (filename, "%s/%s/private.l", ClassPath, vid);
	PrivateOutputFileL = file_open (filename);
	
	sprintf (filename, "%s/%s/private.i", ClassPath, vid);
	PrivateOutputFileI = file_open (filename);
	      
	sprintf (filename, "%s/%s/private.d", ClassPath, vid);
	PrivateOutputFileD = file_open (filename);
	  
	sprintf (filename, "%s/%s/private.h", ClassPath, vid);
	PrivateOutputFileH = file_open (filename);
	      
	sprintf (filename, "%s/%s/private.c", ClassPath, vid);
	PrivateOutputFileC = file_open (filename);
	break;
      }

  CreateObjectClass ();
  LoadClass (yyfile, name, oz_root);

  if (!not_emit)
    switch (Part)
      {
      case PUBLIC_PART:
	if (!Error)
	  {
	    EmitClassFileZ (ThisClass, Part);
	    EmitHeader (ThisClass);
	    if (ThisClass->cl == TC_StaticObject)
	      {
		EmitClassFileI (ThisClass);
		fclose (PrivateOutputFileI);
	      }
	  }

	if (ThisClass->cl == TC_Record || ThisClass->cl == TC_StaticObject)
	  {
	    fclose (PrivateOutputFileL);
	    fclose (PrivateOutputFileC);
	  }

	if (ThisClass->cl != TC_Object)
	  fclose (PrivateOutputFileD);

	fclose (PublicOutputFileZ);
	fclose (PublicOutputFileH);
	break;
      case PROTECTED_PART:
	if (!Error)
	  {
	    EmitClassFileZ (ThisClass, Part);
	    EmitHeader (ThisClass);
	  }
	fclose (ProtectedOutputFileZ);
	fclose (ProtectedOutputFileH);
	break;
      case PRIVATE_PART:
	if (!Error)
	  {
	    EmitClassFileI (ThisClass);
	    EmitHeader (ThisClass);
	  }
	fclose (PrivateOutputFileL);
	fclose (PrivateOutputFileI);
	fclose (PrivateOutputFileD);
	fclose (PrivateOutputFileH);
	fclose (PrivateOutputFileC);
	break;
      }

  return Error;
}


