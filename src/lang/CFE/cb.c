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
  print_usage (char *command)
{
  fprintf (stderr, 
	   "usage: %s [-h] class_name part [command | member ... ]\n", 
	   command);
  fprintf (stderr, "\tpart = public | protected | private\n");
  fprintf (stderr, "\tcommand are ...\n");
  fprintf (stderr, "\t\t 0 : only public\n");
  fprintf (stderr, "\t\t 1 : only constructor\n");
  fprintf (stderr, "\t\t 2 : only public and constructor\n");
  fprintf (stderr, "\t\t 3 : only protected\n");
  fprintf (stderr, "\t\t 4 : only protected methods\n");
  fprintf (stderr, "\t\t 5 : only protected variables\n");
  fprintf (stderr, "\tmember = member_name | #`slot_no2'\n");
}

int
 ClassBrowse (int argc, char **argv)
{
  int i, public;
  char *name, *access, filename[256], *orig_name;

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'c':
	      free (ClassPath);
	      ClassPath = malloc (strlen (argv[++i]) + 1);
	      strcpy (ClassPath, argv[i]);
	      fprintf (stderr, "%s\n", ClassPath);
	      break;
	    case 'h':
	    default:
	      print_usage (argv[0]);
	      return 0;
	    }
	}
    }

  name = CleanupName (argv[i++]);
  access = argv[i++];

  if (!strcmp (access, "public"))
    public = 1;
  else if (!strcmp (access, "protected"))
    public = 0;
  else if (!strcmp (access, "private"))
    public = -1;
  else
    {
      print_usage (argv[0]);
      return 1;
    }

  orig_name = name;

  if (!strncmp (orig_name, "0x", 2))
    {
      sprintf (filename, "%s/%s/%s.t", ClassPath, &orig_name[2], access);
      LoadSchool (filename);
      name = GetVID (orig_name, -1);
    }

  if (public >= 0)
    {
      OO_ClassType cl;

      if (!(cl = LoadClassInfo (name, public)))
	{
	  free (orig_name);
	  return 1;
	}

      if (i != argc)
	{
	  if (isdigit (*argv[i]))
	    PrintClass (cl, atoi (argv[i]) + 1, public);

	  else
	    {
	      OO_Symbol sym;
	      char *member_name;
	      
	      while (i < argc)
		{
		  member_name = argv[i++];
		  
		  if (!(sym = SearchMember (cl, member_name)))
		    FatalError ("`%s' not defined in class `%s'\n", 
				member_name, name);
		  else
		    PrintMember (sym, 0, *member_name == '#' ? 1 : 0);
		}
	    }
	}
      else
	PrintClass (cl, 0, public);
    }
  else 
    {
      if (!strncmp (orig_name, "0x", 2))
	sprintf(filename, "%s/%s/private.r", ClassPath, &orig_name[2]);

      else
	{
	  School sc;

	  sc = SearchEntry (name);
	  sprintf(filename, "%s/%s/private.r", ClassPath, sc->ccid);
	}
      
      if (!LoadRuntimeClassInfo(filename))
	PrintRuntimeClassInfo();
      else
	{
	  free (orig_name);
	  return 1;
	}
    }

  free (orig_name);

  return 0;
}
