/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <varargs.h>
#include <dirent.h>

#include "lang/internal.h"
#include "cfe.h"
#include "command.h"

static void
  print_usage ()
{
  fprintf(stderr, "usage: info [-hv] `this' file\n");
  fprintf(stderr, "       info [-hv] `generic' file\n");
  fprintf(stderr, "       info [-hv] `parents' "
	  "file | class_name\n");
  fprintf(stderr, "       info [-hv] `used' "
	  "part file | class_name\n");
  fprintf(stderr, "       info [-hv] `all' "
	  "part file | class_name\n");
  fprintf(stderr, "part = public | protected | private\n");
  fprintf(stderr, "   this: print this class\n");
  fprintf(stderr, "generic: print generic parameters\n");
  fprintf(stderr, "parents: print parent clases\n");
  fprintf(stderr, "   used: print use classes "
	  "(not included parent classes)\n");
  fprintf(stderr, "    all: use option 'this', 'parents' and 'used \n");
}

static char **
  exec_ozc_info (int verbose, ...)
{
  char *mode, *file, *gp, *opt, buf[256];
  va_list pvar;
  int part = -1;
  char command[256];
  char **result;
  FILE *fp;
  int no_result = 256, i = 0;

  va_start (pvar);
  mode = va_arg (pvar, char *);
  file = va_arg (pvar, char *);
  opt = va_arg (pvar, char *);
  va_end (pvar);

  if (!strstr (file, ".oz"))
    {
      School sc;
      char *name = CleanupName (file);

      if (!(sc = SearchEntry (name)))
	return NULL;

      if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
	sprintf (buf, "%s/%s/private.oz", ClassPath, sc->vid[2]);

      else
	sprintf (buf, "%s/%s/public.oz", ClassPath, sc->vid[0]);
      file = buf;

      free (name);
    }

  if (gp = GetGenericParams (file))
    free (gp);

  if (opt)
    {
      if (!strcmp (opt, "public"))
	part = 0;
      else if (!strcmp (opt, "protected"))
	part = 1;
      else if (!strcmp (opt, "private"))
	part = 2;
    }

  if (part < 0)
    {
      if (verbose)
	PrintOzcCommands ("%s %s", mode, file);
      fp = ExecOzc (mode, file, 0);
    }

  else if (part < 2)
    {
      char p[2];

      p[0] = part + '0';
      p[1] = 0;

      if (verbose)
	PrintOzcCommands ("%s %s %s", mode, p, file);
      fp = ExecOzc (mode, p, file, 0);
    }

  else
    {
      char *name;
      char buf[256];

      if (!(name = GetClassName (file, NULL, 0)))
	return NULL;

      sprintf (buf, "%s/%s/protected.t", ClassPath, GetVID (name, 1));

      if (verbose)
	PrintOzcCommands ("%s %s %s", mode, file, buf);
      fp = ExecOzc (mode, file, buf, 0);

      free (name);
    }

  result = (char **) malloc (sizeof (char *) * no_result);

  if (!fp)
    {
      fprintf (stderr, "cannot execute\n");
      return NULL;
    }

  while (!feof (fp))
    {
      char c, *p;

      p = buf;

      do 
	{
	  c = fgetc (fp);
	}
      while (c != EOF && (c == ' ' || c == '\n'));

      if (c == EOF)
	break;

      ungetc (c, fp);
      while ((c = fgetc (fp)) != '\n')
	*p++ = c;
      *p = 0;

      if (feof (fp))
	break;

      result[i] = malloc (strlen (buf) + 1);
      strcpy (result[i++], buf);

      if (i == no_result)
	{
	  no_result += 256;
	  result = (char **) realloc (result, sizeof (char *) * no_result);
	}
    }

  CloseOzc (fp);
  result[i] = 0;

  return result;
}

int 
  Info (int argc, char **argv)
{
  int i;
  char **result, *arg[10];
  int verbose = 0;

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'v':
	      verbose = 1;
	      break;
	    case 'h':
	    default:
	      print_usage ();
	      return 0;
	    }
	}
    }

  if (argc - i < 2)
    {
      print_usage ();
      return 1;
    }

  if (!strcmp (argv[i], "this"))
    {
      int j = 0;
      arg[j++] = argv[i];
      if (verbose)
	arg[j++] = "-v";
      arg[j++] = argv[i + 1];
      arg[j++] = "name";

      return Compile (j, arg);
    }

  else if (!strcmp (argv[i], "generic"))
    {
      char *buf, *bufp;

      if (bufp = buf = GetGenericParams (argv[i + 1]))
	{
	  while (!isspace (*buf)) buf++;
	  while (isspace (*buf)) buf++;
	  while (!isspace (*buf)) buf++;
	  while (isspace (*buf)) buf++;

	  printf ("%s\n", buf);

	  free (bufp);
	}

      return 0;
    }
  
  else if (!strcmp (argv[i], "parents"))
    result = exec_ozc_info (verbose, "-p2", argv[i + 1], NULL);
  
  else if (!strcmp (argv[i], "used"))
    result = exec_ozc_info (verbose, "-p1", argv[i + 2], argv[i + 1], NULL);
  
  else if (!strcmp (argv[i], "all"))
    result = exec_ozc_info (verbose, "-p3", argv[i + 2], argv[i + 1], NULL);

  else 
    {
      print_usage ();
      return 1;
    }

  for (; *result; result++)
    printf ("%s\n", *result);

  return 0;
}

char **
  GetAllClasses (char *file, char *part)
{
  return exec_ozc_info (0, "-p3", file, part, NULL);
}
