/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dirent.h>

#include "lang/internal.h"
#include "lang/school.h"
#include "cfe.h"
#include "command.h"

static int count = 0, verbose = 0, nolink = 0;
static char *newfile[100], *newname[100];
static int newsc[100];
static int dir_count = 0, dir_base = 0;
static char dir[256];

static void
  print_usage ()
{
  fprintf (stderr, "usage: generate [-hvz] [-d dir] class_name [again]\n");
}

static void
  print_usage_regenerate ()
{
  fprintf (stderr, "usage: regenerate [-hvz] [-d dir] class_name\n");
}

static char *
  create_new_file ()
{
  char *buf = newfile [count] = malloc (256);

  sprintf (buf, "%s/.generate_%d.oz", dir, count++);

  return buf;
}

static void
  remove_files ()
{
#if 0
  system ("rm -f generated_[0-9]*.oz");
#endif
#if 0
  chdir (OzRoot);
#endif
  rmdir (dir);
}

static int 
  assign_id (char *to, char *name, int class_sc, int again)
{
  char *args[3];

  if (ExecMode == TCL_MODE) 
    {
      char *buf;

      WriteToTcl ("checkversion %d %d %s\n", again, class_sc, name);

      buf = Start (0, 1);

#if 0
      fprintf (stderr, "%s\n", buf);
#endif

      if (strcmp (buf, "continue1") && strcmp (buf, "continue2"))
	return strcmp (buf, "continue0");
    }

  args[0] = "generate";
  args[1] = to;
  args[2] = "id";
  
  return Compile (3, args);
}

static int
  generate_file (char *class, char *to, int again)
{
  char *orig, buf[256], *p;
  FILE *fp;
  int part;
  School sc;
  char *args[3];

  if (!(orig = GetOriginalName (class, 0)))
    return 1;

  if (!(sc = SearchEntry (orig)))
    return 1;
      
  if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
    part = 2;
  else 
    part = 0;

  sprintf (buf, "%s/%s/private.oz", ClassPath, sc->vid[part]);

  if (access (buf, F_OK) < 0)
    return 1;

  free (orig);
  orig = GetClassName (buf, NULL, 1);

  p = class;
  while (*p)
    {
      if (*p == '*')
	*p = 'T';
      p++;
    }

  if (verbose)
    printf ("%s (%s)\n", orig, sc->vid[part]);

  if (GenerateNew (orig, class, buf, to))
    return 1;

  if (!Boot || !again)
    if (assign_id (to, class, sc->class_sc, again))
      return 1;

  if (verbose)
    printf ("generate: %s %s\n", class, to);

  return 0;
}

static char **
  check_dependency (char *name, char *file, int private)
{
  School sc = SearchEntry (name);
  char **classes = NULL;
  int i;

  if (!private)
    classes = GetAllClasses (file, "protected");

  else 
    {
      if (sc->class_sc && sc->class_sc != SC_ABSTRACT)
	return NULL;

      classes = GetAllClasses (file, "private");
    }

  if (!classes)
    return NULL;


  for (i = 0; classes[i]; i++)
    {
      if (SearchEntry (classes[i]))
	{
	  free (classes[i]);
	  classes[i] = "";
	}
    }

  return classes;
}


static int
  generate_other_files (char *name, char *file, int private)
{
  char **classes;
  char *new;
  int start = count, last, status;
  int i;

  if (classes = check_dependency (name, file, private))
    {
      for (i = 0; classes[i]; i++)
	{
	  if (!*classes[i])
	    continue;

	  new = create_new_file ();

	  status = generate_file (classes[i], new, 0);
	  free (classes[i]);

	  if (status)
	    {
	      fprintf (stderr, "cannot generate: `%s'\n", classes[i]);
	      return 1;
	    }
	}

      last = count;
      for (i = start; i < last; i++)
	{
	  if (!newname[i])
	    newname[i] = GetClassName (newfile[i], &newsc[i], 0);
	  
	  generate_other_files (newname[i], newfile[i], 0);
	}
    }

  return 0;
}

static int 
  compile_all_if (int start, int again)
{
  int argc = 0;
  char *argv[4], *results;
  int success = 1, error = 1;
  int i, j, k, status;

  argv[argc++] = "generate";
  if (verbose)
    argv[argc++] = "-v";
  j = argc++;
  if (again < 2)
    argv[argc++] = "if";
  else
    argv[argc++] = "protected";
  if (again)
    argv[argc++] = "again";

  InternalCompileStart (0);

  results = malloc (count - start + 1);
  bzero (results, count - start + 1);

  while (success && error)
    {
      success = error = 0;
      for (i = start; i < count; i++)
	{
	  if (!results[i - start])
	    {
	      argv[j] = newfile[i];
	      
	      if (verbose)
		{
#if 0
		  for (k = 0; k < argc; k++)
		    printf ("%s ", argv[k]);
		  printf ("\n");
#else
		  printf ("%s\n", newfile[i]);
#endif
		}

	      status = Compile (argc, argv);
		  
	      switch (status)
		{
		case 0:
		  results[i - start] = 1;
		  success++;

		  if (newsc[i] == SC_RECORD || newsc[i] == SC_SHARED)
		    unlink (newfile[i]);

		  break;
		case 1:
		  error++;
		  break;
		case 2:
		  results[i - start] = -1;
		  if (verbose)
		    printf ("   later\n");
		  break;
		}
	    }
	}
    }
  
  free (results);

  InternalCompileEnd ();
}

static int 
  compile_all_private (int again)
{
  char *argv[5];
  int i = 0, j, k, argc;

  argv[i++] = "generate";
  if (nolink)
    argv[i++] = "-z";
  if (verbose)
    argv[i++] = "-v";
  argv[i + 1] = "private";
  if (again)
    {
      argv[i + 2] = "again";
      argc = i + 3;
    }
  else
    argc = i + 2;

  InternalCompileStart (0);

  for (j = 0; j < count; j++)
    {
      if (newsc[j] && newsc[j] != SC_ABSTRACT)
	continue;

      argv[i] = newfile[j];

      if (verbose)
	{
#if 0
	  for (k = 0; k < argc; k++)
	    printf ("%s ", argv[k]);
	  printf ("\n");
#else
	  printf ("%s\n", newfile[j]);
#endif
	}

      Compile (argc, argv);
    }

  InternalCompileEnd ();
}


static int 
  config_all (int again)
{
  char *argv[4];
  int i = 0, j, k, argc, status = 0;

  argv[i++] = "generate";
  if (verbose)
    argv[i++] = "-v";
  if (again)
    {
      argv[i + 1] = "again";
      argc = i + 2;
    }
  else
    argc = i + 1;

  for (j = 0; j < count; j++)
    {
      if (newsc[j] == SC_RECORD || newsc[j] == SC_SHARED)
	continue;
      
      argv[i] = newname[j];
      
      if (verbose)
	{
#if 0
	  for (k = 0; k < argc; k++)
	    printf ("%s ", argv[k]);
	  printf ("\n");
#else
	  printf ("%s\n", newname[j]);
	}
#endif
      
      if (!Config (argc, argv))
	unlink (newfile[j]);

      else
	status = 1;
    }

  return status;
}

int 
  Generate (int argc, char **argv)
{
  int i, start, again = 0, status = 0;
  char *name, *buf, *target = ".";
  School sc;
  char command[256];

  verbose = nolink = 0;

  if (!dir_base)
    dir_base = getpid ();

  for (i = 0; i < count; i++)
    {
      free (newfile[i]);
      free (newname[i]);
    }

  bzero (newname, count * sizeof (char *));
  bzero (newsc, count * sizeof (int));

  start = count = 0;

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'd':
	      target = argv[++i];
	      break;
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

  name = CleanupName (argv[i++]);

  if (i < argc)
    {
      if (!strcmp (argv[i++], "again"))
	{
	  if (i < argc)
	    again = atoi (argv[i++]);
	  else
	    again = 1;
	}
      else
	{
	  print_usage ();
	  return 1;
	}
    }

  if (!again && SearchEntry (name))
    {
      fprintf (stderr, "%s: already generated\n", name);
      free (name);
      return 0;
    }

  sprintf (dir, "%s/tmp/%d-%d", OzRoot, dir_base, dir_count);
  mkdir (dir, 0755);
#if 0
  chdir (dir);
#endif

  buf = create_new_file ();

  if (generate_file (name, buf, again))
    {
      fprintf (stderr, "cannot generate\n");
      remove_files ();
      free (name);
      return 1;
    }

  if (generate_other_files (name, buf, 0))
    {
      fprintf (stderr, "cannot generate\n");
      remove_files ();
      free (name);
      return 1;
    }

  free (name);

  do 
    {
      int i = start, last = count;
      
      if (again < 3)
	{
	  if (verbose)
	    printf ("compile public & protected\n");
	  
	  compile_all_if (start, again);
	}
	  
      start = count;
	  
      for (; i < last; i++)
	{
	  if (!newname[i])
	    newname[i] = GetClassName (newfile[i], &newsc[i], 0);
	      
	  if (newsc[i] && newsc[i] != SC_ABSTRACT)
	    continue;
	      
	  if (again < 3 && generate_other_files (newname[i], newfile[i], 1))
	    {
	      fprintf (stderr, "cannot generate\n");
	      remove_files ();
	      return 1;
	    }
	}
    }
  while (start != count);

  if (verbose)
    printf ("compile private\n");

  if (compile_all_private (again) && verbose)
    printf ("configure\n");

  if (config_all (again))
    {
#if 0
      sprintf (dir, "%s/%d-%d", target, dir_base, dir_count++);
      mkdir (dir, 0755);

      sprintf (command, "mv generated_[0-9]*.oz %s", dir);
      system (command);

      printf ("%s: copied generated files to `%s/'\n", newname[0], dir);
#else
      if (ExecMode == NORMAL_MODE)
	printf ("%s: copied generated files to `%s/'\n", newname[0], dir);

      else
	{
	  WriteToTcl ("dir: %s\n", dir);
	  AddWantedDir (dir);
	}

      status = 2;

      fsync ();
#endif
    }
  else if (ExecMode == NORMAL_MODE)
    printf ("complete generating all files\n");

  Save (0, NULL);

  dir_count++;

  return status;
}

int
  ReGenerate (int argc, char **argv)
{
  char **reals, *target = NULL;
  int no_reals;
  int i, j = 0, p, status = 1;
  char *arg[8];
  int verbose = 0, nolink = 0;
  
  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'd':
	      target = argv[++i];
	      break;
	    case 'v':
	      verbose = 1;
	      break;
	    case 'z':
	      nolink = 1;
	      break;
	    case 'h':
	    default:
	      print_usage_regenerate ();
	      return 0;
	    }
	}
    }

  if (i == argc)
    {
      print_usage_regenerate ();
      return 1;
    }

  no_reals = GetRealGenerics (argv[i++], &reals);

  arg[j++] = "regenerate";
  if (verbose)
    arg[j++] = "-v";
  if (nolink)
    arg[j++] = "-z";
  if (target)
    {
      arg[j++] = "-d";
      arg[j++] = target;
    }
  p = j++;
  arg[j++] = "again";
  if (i < argc)
    arg[j++] = argv[i++];

  for (i = 0; i < no_reals; i++)
    {
      arg[p] = reals[i];
      if (!Generate (j, arg))
	status = 0;
    }

  free (reals);

  return status;
}
     
