/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/dir.h>
#include <sys/stat.h>

#include "lang/internal.h"
#include "cfe.h"
#include "command.h"

enum ALL_PART {
  ID_ALL,
  PUBLIC_ALL,
  PROTECTED_ALL,
  IF_ALL,
  PRIVATE_ALL,
  CONFIG_ALL,
  ALL_ALL,
  LINK_ALL,
  MAX_ALL,
};


struct src_rec {
  char name [256];
  int ino;
  char result[MAX_ALL];
};

static int no_files = 0;
static struct src_rec files[1024];

static void
  print_usage ()
{
  fprintf (stderr, "usage: all [-hvz] part [again]\n");
  fprintf (stderr, "\tpart = id | public | protected | private | if | all\n");
  fprintf (stderr, "\t\t | link\n");
}

static void
  print_usage_add_files ()
{
  fprintf (stderr, "usage: add [-ch] [dir | files ...]\n");
}

static void
  print_usage_remove_files ()
{
  fprintf (stderr, "usage: remove [-h] [dir | files ...]\n");
}

static void
  print_usage_configall ()
{
  fprintf (stderr, "usage: configall [-dhv] [again]\n");
}

static void
  print_usage_generateall ()
{
  fprintf (stderr, "usage: generateall [-hvz] [-d dir]\n");
}

static void
  print_usage_ls ()
{
  fprintf (stderr, "usage: ls\n");
}

static int
  comp_file (struct src_rec *one, struct src_rec *two)
{
  return strcmp ((*one).name, (*two).name);
}

static void
  sort_files ()
{
  qsort (files, no_files, sizeof (struct src_rec), (int (*)()) comp_file);
}

static void
  add_file (char *file, int ino, char *dir)
{
  int i;
  char *buf;

  if (dir)
    {
      buf = malloc (strlen (dir) + strlen (file) + 2);
      sprintf (buf, "%s/%s", dir, file);
    }
  else
    {
      buf = malloc (strlen (file) + 1);
      strcpy (buf, file);
    }

  if (!ino)
    {
      struct stat sbuf;

      stat (buf, &sbuf);
      ino = sbuf.st_ino;
    }

  for (i = 0; i < no_files; i++)
    {
      if (files[i].ino == ino)
	{
	  fprintf (stderr, "already registered: %s\n", files[i].name);
	  return;
	}
    }

  files[no_files].ino = ino;
  bzero (files[no_files].result, MAX_ALL);
  strcpy (files[no_files++].name, buf);
}

static void
  remove_file (char *file, char *dir)
{
  int i;
  char buf[256], *p;

  if (dir)
    {
      while (dir[strlen (dir) - 1] == '/')
	dir[strlen (dir) - 1] = 0;
      sprintf (buf, "%s/", dir);
    }

  for (i = 0; i < no_files; i++)
    if ((file && !strcmp (files[i].name, file)) ||
	(dir && (p = strstr (files[i].name, buf)) && 
	 (p == files[i].name || *(p - 1) == '/')))
      {
	files[i].name[0] = 0;
	files[i].ino = 0;

	if (!dir)
	  return;
      }
}

static int 
  get_files (char *dir)
{
  DIR *dirp;
  struct direct *d;
  char buf[256], *p;
  struct stat sbuf;

  while (dir[strlen (dir) - 1] == '/')
    dir[strlen (dir) - 1] = 0;

  if (!(dirp = opendir (dir)))
    {
      fprintf (stderr, "cannot open directroy: `%s'\n", dir);
      return 0;
    }
  
  while (d = readdir (dirp)) 
    {
      if (!d->d_ino ||
	  !strcmp (d->d_name, ".") ||
	  !strcmp (d->d_name, "..") ||
	  !strcmp (d->d_name, "public.oz") ||
	  !strcmp (d->d_name, "protected.oz") ||
	  !strcmp (d->d_name, "private.oz"))
	continue;

      if (!(p = strstr (d->d_name, ".oz")))
	{
	  sprintf (buf, "%s/%s", dir, d->d_name);
	  stat (buf, &sbuf);
	  
	  if (S_ISDIR (sbuf.st_mode))
	    get_files (buf);

	  continue;
	}
      else if (strlen (p) > 3)
	continue;
	  
      add_file (d->d_name, d->d_ino, dir);
    }

  closedir (dirp);

  return no_files;
}

static int
  part_no (char *part)
{
  int n = 0;

  for (;;)
    {
      if (!strcmp (part, "id"))
	break;

      n++;
      if (!strcmp (part, "public"))
	break;

      n++;
      if (!strcmp (part, "protected"))
	break;

      n++;
      if (!strcmp (part, "if"))
	break;

      n++;
      if (!strcmp (part, "private"))
	break;

#if 1
      if (!strcmp (part, "link"))
	{
	  n = LINK_ALL;
	  break;
	}
#endif

      if (!strcmp (part, "all"))
	break;

      return -1;
    }
  
  return n;
}

static int
  exec_compile_all (char *part, 
		    int verbose, int again, int nolink)
{
  int i, j, k;
  char *argv[7], buf[16];
  int argc = 0, status;
  int n = 0;

  argv[argc++] = "all";
  if (nolink)
    argv[argc++] = "-z";
  if (verbose)
    argv[argc++] = "-v";
  j = argc++;
  argv[argc++] = part;
  if (again)
    argv[argc++] = "again";

  if ((n = part_no (part)) < 0) 
    {
      print_usage ();
      return 1;
    }

  if (!strcmp (part, "if"))
    {
      int success = 1, error = 1;

#if 1
      InternalCompileStart (1);
#else
      InternalCompileStart (0);
#endif

      while (success && error)
	{
	  success = error = 0;
	  for (i = 0; i < no_files; i++)
	    {
	      if (*files[i].name && !files[i].result[n])
		{
		  argv[j] = files[i].name;
		  if (verbose)
		    {
#if 0
		      for (k = 0; k < argc; k++)
			printf ("%s ", argv[k]);
		      printf ("\n");
#else
		      printf ("%s\n", files[i].name);
#endif
		    }

		  if (ExecMode == TCL_MODE)
		    WriteToTcl ("%s\n", files[i].name);

		  status = Compile (argc, argv);
		  
		  switch (status)
		    {
		    case 0:
		      success++;
		    case 3:
		    case 4:
		      files[i].result[n] = 1;
		      break;
		    case 1:
		      error++;
		      break;
		    case 2:
		      files[i].result[n] = -1;
		      if (verbose)
			printf ("   later\n");
		      break;
		    }
		  
		  if (ExecMode == TCL_MODE)
		    WriteToTcl ("done %d %s\n", status, files[i].name);
#if 0
/* for synchronize */
		  gets (buf);
#endif		  
		}
	    }
#if 1
	  if (verbose)
	    printf ("success = %d, error = %d\n", success, error);
#endif
	}

      for (i = 0; i < no_files; i++)
	if (files[i].result[n] < 0)
	  files[i].result[n] = 0;
    }
  else 
    {
      InternalCompileStart (0);

      for (i = 0; i < no_files; i++)
	{
	  if (*files[i].name && !files[i].result[n])
	    {
	      argv[j] = files[i].name;
	      if (verbose)
		{
#if 0
		  for (k = 0; k < argc; k++)
		    printf ("%s ", argv[k]);
		  printf ("\n");
#else
		  printf ("%s\n", files[i].name);
#endif
		}
	      
	      if (ExecMode == TCL_MODE)
		WriteToTcl ("%s\n", files[i].name);

	      status = Compile (argc, argv);

	      switch (status)
		{
		case 0:
		case 3:
		case 4:
		  files[i].result[n] = 1;
		  break;
		case 1:
		  break;
		case 2:
		  if (verbose)
		    printf ("   later\n");
		  break;
		}
	      
	      if (ExecMode == TCL_MODE)
		WriteToTcl ("done %d %s\n", status, files[i].name);
#if 0
/* for synchronize */
	      gets (buf);
#endif		  
	    }
	}

      if (n == ID_ALL)
	Save (0, NULL);
    }

  return InternalCompileEnd ();
}

int 
  CompileAll (int argc, char **argv)
{
  int i;
  char *part;
  int verbose = 0, again = 0, nolink = 0;
  
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
	    case 'z':
	      nolink = 1;
	      break;
	    case 'h':
	    default:
	      print_usage ();
	      return 0;
	    }
	}
    }

  if (i == argc)
    {
      print_usage ();
      return 1;
    }

  part = argv[i];

  i++;
  if (i < argc)
    {
      if (!strcmp (argv[i], "again"))
	again = 1;

      else if (i + 1 < argc)
	{
	  print_usage ();
	  return 1;
	}
    }

#if 0
  if (!strcmp (part, "all"))
    {
      if (exec_compile_all ("if", verbose, again, nolink))
	{
	  PrintWanteds (stdout);
	  return 0;
	}

      part = "private";
    }
#endif

  if (exec_compile_all (part, verbose, again, nolink))
    PrintWanteds (stdout);

  return 0;
}

int
  AddFiles (int argc, char **argv)
{
  int i, current;
  char *part;

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'c':
	      no_files = 0;
	      break;
	    case 'h':
	    default:
	      print_usage_add_files ();
	      return 0;
	    }
	}
    }

  current = no_files;

  if (i == argc)
    {
      if (!(no_files = get_files (".")))
	return 1;
    }

  else if (strstr(argv[i], ".oz"))
    {
      for (; i < argc; i++)
	{
	  if (!strstr (argv[i], ".oz"))
	    continue;

	  add_file (argv[i], 0, NULL);
	}
    }
  
  else if (i + 1 < argc)
    {
      print_usage_add_files ();
      return 1;
    }
  
  else if (!(no_files = get_files (argv[i])))
    return 1;

  sort_files ();

#if 0  
  for (i = current; i < no_files; i++)
    bzero (files[i].result, MAX_ALL);
#endif

  return 0;
}

  
int 
  RemoveFiles (int argc, char **argv)
{
  int i, current;
  char *part;

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'h':
	    default:
	      print_usage_remove_files ();
	      return 0;
	    }
	}
    }

  current = no_files;

  if (i == argc)
    remove_file (NULL, ".");

  else if (strstr(argv[i], ".oz"))
    {
      for (; i < argc; i++)
	{
	  if (!strstr (argv[i], ".oz"))
	    continue;

	  remove_file (argv[i], NULL);
	}
    }
  
  else if (i + 1 < argc)
    {
      print_usage_remove_files ();
      return 1;
    }
  
  else 
    remove_file (NULL, argv[i]);
  
  return 0;
}

int 
  ConfigAll (int argc, char **argv)
{
  int i, verbose = 0, debug = 0, j = 0, k, class_sc, again = 0, status;
  char *arg[4], buf[16];

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
	    case 'd':
	      debug = 1;
	      break;
	    case 'h':
	    default:
	      print_usage_configall ();
	      return 0;
	    }
	}
    }

  if (i < argc)
    {
      if (!strcmp (argv[i], "again"))
	again = 1;
      else
	{
	  print_usage_configall ();
	  return 1;
	}
    }

  arg[j++] = "configall";
  if (debug)
    arg[j++] = "-d";
  if (verbose)
    arg[j++] = "-v";
  j++;
  if (again)
    arg[j++] = "again";

  for (i = 0; i < no_files; i++)
    {
      if (*files[i].name && !files[i].result[CONFIG_ALL])
	{
	  arg[j - 1 - again] = GetClassName (files[i].name, &class_sc, 0);

	  if (class_sc == SC_SHARED || class_sc == SC_RECORD ||
	      strchr (arg[j - 1 - again], '*'))
	    {
	      free (arg[j - 1 - again]);
	      continue;
	    }

	  if (verbose)
	    {
#if 0
	      for (k = 0; k < j; k++)
		printf ("%s ", arg[k]);
	      printf ("\n");
#else
	      printf ("%s\n", arg[j - 1 - again]);
#endif
	    }

	  if (ExecMode == TCL_MODE)
	    WriteToTcl ("%s\n", files[i].name);

	  status = Config (j, arg);
	  files[i].result[CONFIG_ALL] = status == 1 ? 0 : 1;

	  if (ExecMode == TCL_MODE)
	    WriteToTcl ("done %d %s\n", status, files[i].name);

	  free (arg[j - 1 - again]);

#if 0
/* for synchronize */
	  gets (buf);
#endif		  

	}
    }

  return 0;
}

int
  List (int argc, char **argv)
{
  int len = 0, i, count = 0, l;

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'h':
	    default:
	      print_usage_ls ();
	      return 0;
	    }
	}
    }

  for (i = 0 ; i < no_files; i++)
    {
      if (!files[i].name || !*files[i].name)
	continue;

      if (len) 
	{
	  if ((len += (l = strlen (files[i].name)) + 2) > 80)
	    {
	      printf ("\n");
	      len = l;
	    }
	  else 
	    {
	      printf (" ");
	      len++;
	    }
	}
      else
	len = strlen (files[i].name);

      printf ("%s", files[i].name);
      count++;
    }

  if (count)
    printf ("\n");
  else
    no_files = 0;

#if 0
  printf ("%d files\n", count);
#endif

  return 0;
}

int 
  GenerateAll (int argc, char **argv)
{
  int no_gen;
  char **gen;
  int i, j, verbose = 0;

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
	    case 'z':
	      break;
	    case 'd':
	      i++;
	      break;
	    case 'h':
	    default:
	      print_usage_generateall ();
	      return 0;
	    }
	}
    }

  gen = GetWanted (&no_gen);

  j = i;

  for (i = 0; i < no_gen; i++)
    {
      if (*gen[i])
	{
	  argv[j] = gen[i];
	  if (verbose)
	    printf ("%s\n", gen[i]);
	  switch (Generate (j + 1, argv))
	    {
	    case 0:
	    case 2:
	      free (gen[i]);
	      gen[i] = NULL;
	      break;
	    }
	}
    }

  CleanupWanteds ();

  return 0;
}

int
  Reset (int argc, char **argv)
{
  int i;

  for (i = 0; i < no_files; i++)
    bzero (files[i].result, MAX_ALL);

  return 0;
}

