/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "lang/internal.h"
#include "cfe.h"
#include "command.h"

#define NONE -1
#define PUBLIC 0
#define PROTECTED 1
#define IMPLEMENT 2
#define CONFIG 3
#define VIDALL 5
#define ALL 6
#define NAME 7
#define KIND 8
#define SETCCID 9
#define SETVID 10
#define REMOVE 11
#define REAL 12
#define MAX 12

static char *command;

static add_count = 0;

static void
  print_usage ()
{
  fprintf (stderr, "usage: %s [-h] command\n", command);
  fprintf (stderr, "\tcommand is ...\n");
  fprintf (stderr, "\t\t(none)\tprint 'School' contents\n");
  fprintf (stderr, "\t\tname\tprint three 'Version Ids'\n");
  fprintf (stderr, "\t\tname 0\tprint 'Public Part'\n");
  fprintf (stderr, "\t\tname 1\tprint 'Protected Part'\n");
  fprintf (stderr, "\t\tname 2\tprint 'Implementation Part'\n");
  fprintf (stderr, "\t\tname 3\tprint 'Configured ID'\n");
  fprintf (stderr, "\t\tname 5\tprint all 'Version IDs'\n");
  fprintf (stderr, "\t\tname 6\tprint all 'IDs'\n");
  fprintf (stderr, "\t\tname 7\tprint name\n");
  fprintf (stderr, "\t\tname 8\tprint kind\n");
}

static int 
  search_entry (char *str, int part, char **opt, int argc)
{
  School sc;
  long long id;
  char *class;
  int i, j;

  if (part < NONE  || part > MAX)
    {
      print_usage ();
      return 1;
    }

  class = CleanupName (str);

  if (part == REAL)
    {
      int no_reals, i;
      char **reals;

      no_reals = GetRealGenerics (class, &reals);

      for (i = 0; i < no_reals; i++)
	printf ("%s\n", reals[i]);

      return 0;
    }
  else if (!(sc = SearchEntry (class)) && part != SETVID)
    {
      fprintf (stderr, "not found\n");
      free (class);
      return 1;
    }

  if (part != SETVID)
    free (class);

  switch (part)
    {
    case NONE:
      printf ("%s\n", sc->vid[0]);
#if 1
      if (!sc->class_sc || sc->class_sc == SC_ABSTRACT) 
	{
	  printf ("%s\n", sc->vid[1]);
	  printf ("%s\n", sc->vid[2]);
	}
#else
      printf ("%s\n", sc->vid[1]);
      printf ("%s\n", sc->vid[2]);
#endif
      break;
    case PUBLIC:
      printf ("%s\n", sc->vid[0]);
      break;
    case PROTECTED:
#if 1
      if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
	printf ("%s\n", sc->vid[1]);
#else
      printf ("%s\n", sc->vid[1]);
#endif
      break;
    case IMPLEMENT:
#if 1
      if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
	printf ("%s\n", sc->vid[2]);
      else
	printf ("%s\n", sc->vid[0]);
#else
      printf ("%s\n", sc->vid[2]);
#endif
      break;
    case CONFIG:
      if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
	printf ("%s\n", sc->ccid);
      break;
    case VIDALL:
      printf ("%s\n", sc->root);
      printf ("%s\n", sc->vid[0]);
#if 1
      if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
	{
	  printf ("%s\n", sc->vid[1]);
	  printf ("%s\n", sc->vid[2]);
	}
#else
      printf ("%s\n", sc->vid[1]);
      printf ("%s\n", sc->vid[2]);
#endif
      break;
    case ALL:
#if 1
      if (sc->class_sc != SC_RECORD && sc->class_sc != SC_SHARED)
	printf ("%s\n", sc->ccid);
#else
      printf ("%s\n", sc->ccid);
#endif
      printf ("%s\n", sc->root);
      printf ("%s\n", sc->vid[0]);
#if 1
      if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
	{
	  printf ("%s\n", sc->vid[1]);
	  printf ("%s\n", sc->vid[2]);
	}
#else
      printf ("%s\n", sc->vid[1]);
      printf ("%s\n", sc->vid[2]);
#endif
      break;
    case NAME:
      printf ("%s\n", sc->name);
      break;
    case KIND:
#if 0
      printf ("%s\n", class_kind_str[sc->class_sc]);
#else
      printf ("%d\n", sc->class_sc);
#endif
      break;
    case SETCCID:
      strcpy (sc->ccid, opt[0]);
      break;
    case SETVID:
      i = 0;

      if (!sc)
	sc = AddSchool (class, 0, atoi (opt[i++]), 0, 0);

      else
	sc->class_sc = atoi (opt[i++]);

      if (!sc->class_sc || sc->class_sc == SC_ABSTRACT) 
	{
	  if (argc > 5) 
	    strcpy (sc->root, opt[i++]);
	}
      else
	{
	  if (argc > 2)
	    strcpy (sc->root, opt[i++]);
	}

      switch (argc - i)
	{
	case 1:
	  if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
	    strcpy (sc->vid[2], opt[i++]);
	  else
	    strcpy (sc->vid[0], opt[i++]);
	  break;
	case 2:
	  strcpy (sc->vid[1], opt[i++]);
	  strcpy (sc->vid[2], opt[i++]);
	  break;
	default:
	  strcpy (sc->vid[0], opt[i++]);
	  strcpy (sc->vid[1], opt[i++]);
	  strcpy (sc->vid[2], opt[i++]);
	}
      
      if (i < argc)
	strcpy (sc->ccid, opt[i]);

      if (!strcmp (sc->root, "0")) 
	{
	  int l, h;
	  
	  sscanf (sc->vid[0], "%08x%08x", &l, &h);
	  sprintf (sc->root, "%08x%08x", l, h - 1);
	}

      free (class);

#if 0
      if (++add_count % 100 > 20)
	Save (0, NULL);
#endif

      break;
    case REMOVE:
      RemoveSchool (class);
      break;
    }

  return 0;
}

int
  SchoolBrowse (int argc, char **argv)
{
  int i, status, part;
  int kind = -1, generic = 0;

  command = argv[0];

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'k':
	      kind = atoi (argv[++i]);
	      argc = 1;
	      generic = kind / 100;
	      kind = kind % 100;
	      if (kind == 0 || (kind > 4 && kind < 9))
		break;
	    case 'h':
	    default:
	      print_usage ();
	      return 0;
	    }
	}
    }

  switch (argc)
    {
    case 1:
      PrintSchool (kind, generic);
      return 0;
    case 2:
      if (isdigit(*argv[1]))
	{
	  char *vid;

	  if (!strncmp (argv[1], "0x", 2) || 
	      !strncmp (argv[1], "0X", 2))
	    vid = &argv[1][2];
	  else 
	    vid = argv[1];

	  if (strlen (vid) < 16)
	    {
	      fprintf (stderr, "illegal ID: `%s'\n", argv[1]);
	      return 1;
	    }

	  if (!strncmp (&vid[16], "LL", 2) ||
	      !strncmp (&vid[16], "ll", 2))
	    vid[16] = 0;

	  return search_entry (vid, NAME, NULL, 0);
	}
      else
	return search_entry (argv[i], NONE, NULL, 0);
    case 3:
      if (isdigit (*argv[i + 1])) 
	return search_entry (argv[i], atoi (argv[i + 1]), NULL, 0);
      else
	print_usage ();
      break;
    default:
      part = atoi (argv[i + 1]);

      if (part <= MAX)
	return search_entry (argv[i], part, &argv [i + 2], argc - (i + 2));

      print_usage ();
      break;
    }
}

