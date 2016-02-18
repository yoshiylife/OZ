/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <varargs.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/param.h>
#include <search.h>
#include <sys/dir.h>

#include "lang/internal.h"
#include "cfe.h"
#include "command.h"

static int class_sc = 0;
static char class_name[256], oz_class[256], school_file[256];
static char *object, *generic[256], *goption = "-g";
static int debug = 0, verbose = 0, nolink = 0, again = 0;
static int generic_count = 0;

static int no_wanted = 0, no_one_wanted = 0;
static char *wanted[256], *one_wanted[256];

static int no_wanted_dir = 0;
static char *wanted_dir[256];

static int internal = 0;
static int pid;

School *classes[2];
int classes_len[2] = {0, 0}, classes_num[2];

static create_class_list_file_entry (School, int);

static struct {
  char str[20];
} part_str[] = {
  "public",
  "protected",
  "private",
};

static void
  print_one_wanteds ()
{
  int i;

  if (no_one_wanted < 1)
    return;

  printf ("you need to generate some generic classes\n");
  
  for (i = no_one_wanted - 1; i >= 0; i--)
    if (one_wanted[i])
      printf ("%s\n", one_wanted[i]);

  fflush (stdout);
}
static void
  remove_wanted_dir (char *dir)
{
  int i;

  for (i = 0; i < no_wanted_dir; i++)
    if (wanted_dir[i] && !strcmp (dir, wanted_dir[i]))
      {
	free (wanted_dir[i]);
	wanted_dir[i] = 0;
      }
}

static void
  print_usage (char *command)
{
  if (!strcmp (command, "link"))
    fprintf (stderr, 
	     "usage: link [-dhv] source_file [again]\n");

  else if (!strcmp (command, "clean"))
    {
      fprintf (stderr, 
	       "usage: clean [-dhv] [part]\n");
      fprintf (stderr, "\tpart = public | protected | private\n");
    }

  else
    {
      fprintf (stderr, 
	       "usage: %s [-dhvz] source_file part [again]\n", command);
      fprintf (stderr, "\tpart = public | protected | private | all\n");
      fprintf (stderr, 
	       "usage: %s [-dhvz] source_file command\n", command);
      fprintf (stderr, 
	       "\tcomand = id | name | gcheck\n");
    }
}

static void
  warning (char *format, ...)
{
  va_list pvar;

  va_start (pvar);
  if (!internal)
    Emit2 (stderr, format, pvar);
  va_end (pvar);
}

static int
  school_compare (School *s1, School *s2)
{
  return strcmp ((*s1)->name, (*s2)->name);
}

static int
  exec_command (char *command)
{
  int i, status;
  char *argv[256], *p, buf[256];

  i = 0;
  p = command;
  
  while (*p)
    {
      char *q = buf;
      
      while (*p && *p != ' ')
	*q++ = *p++;
      *q = 0;

      if (*p)
	p++;
      
      argv[i] = malloc (strlen (buf) + 1);
      strcpy (argv[i++], buf);
      
#if 0
      printf ("%s\n", argv[i - 1]);
#endif
    }
  
  argv[i] = 0;

  switch (pid = fork ())
    {
    case -1:
      perror ("fork");
      return 1;
    case 0:
      execvp (argv[0], argv);
      exit (1);
    default:
      while (wait (&status) != pid);

#if 0
      printf ("%d\n", (status >> 8) & 0xff);
#endif
      
      if (!(status & 0xff))
	return (status >> 8) & 0xff;
      else
	return status & 0x7f;
    }
}

static void
  add_wanted (char *name)
{
  int i;

  if (!internal)
    {
      for (i = 0; i < no_one_wanted; i++)
	if (!strcmp (one_wanted[i], name))
	  return;

      if (i == no_one_wanted)
	{
	  one_wanted[no_one_wanted] = malloc (strlen (name) + 1);
	  strcpy (one_wanted[no_one_wanted++], name);
	}
    }

  for (i = 0; i < no_wanted; i++)
    if (!strcmp (wanted[i], name))
      return;

  wanted[no_wanted] = malloc (strlen (name) + 1);
  strcpy (wanted[no_wanted++], name);
}

static
check_generic (char *file)
{
  int i = 0, j = 0;
  char c, buf[256];
  FILE *fp;
  int status;

  if (generic_count)
    {
      int i;

      for (i = 0; i < generic_count; i++)
	free (generic[i]);
      generic_count = 0;
    }

  if (verbose && !internal)
    PrintOzcCommands ("-pg %s", file);

  if (!(fp = ExecOzc ("-pg", file, 0)))
    {
      fprintf (stderr, "cannot execute\n");
      return 1;
    }

  while ((c = fgetc (fp)) != EOF)
    {
      while (c != '\n')
	{
	  buf[i++] = c;
	  c = fgetc (fp);
	}
      buf[i] = 0;
      
      if (i && !GetVID (buf, 0))
	{
	  generic[generic_count] = malloc (strlen (buf) + 1);
	  strcpy (generic[generic_count++], buf);
	}

      i = 0;
    }

  return CloseOzc (fp);
}

static
  set_class_name (char *file, int noconvert, int print)
{
  int i = 0, status;
  char c;
  FILE *fp;

  if (!noconvert)
    {
      if (check_generic (file))
	return 1;
    }
  else
    {
      if (generic_count)
	{
	  int i;

	  for (i = 0; i < generic_count; i++)
	    free (generic[i]);
	  generic_count = 0;
	}
    }

  if (print == 1)
    {
      if (generic_count)
	{
	  printf ("-g %d", generic_count);
	  for (i = 0; i < generic_count; i++)
	    printf (" %s", generic[i]);
	}
      printf ("\n");
      return 0;
    }

  if (verbose && !internal)
    PrintOzcCommands ("-p0 %s", file);

 if (!(fp = ExecOzc ("-p0", file, 0)))
    {
      fprintf (stderr, "cannot execute\n");
      return 1;
    }

  class_sc = fgetc (fp) - '0';

  while ((c = fgetc (fp)) == ' ');

  while (c != EOF && c != '\n')
    {
      class_name[i++] = c;
      c = fgetc (fp);
    }
  class_name[i] = 0;

  CloseOzc (fp);

  if (*class_name == 0)
    {
      fprintf (stderr, "cannot get class name\n");
      return 1;
    }

  if (print)
    printf ("%d %s\n", class_sc, class_name);
  else if (!strcmp (class_name, "Object"))
    object = "-object";
  else
    object = NULL;

  return 0;
}


static
check_start_compile (char *file, School sc, int part)
{
  char buf[256];
  int ng = 0, ac;
  FILE *sfp, *fp;
  int i, j, count;

  if (part > 0)
    {
      sprintf (school_file, "%s/%s/%s.t", 
	       ClassPath, sc->vid[part - 1],
	       part_str[part - 1].str);
	
      if (access (school_file, F_OK) < 0)
	{
	  warning ("you must compile first with `%s' option\n", 
		   part_str[part - 1].str);
	  return 1;
	}
    }

  sprintf (school_file, "%s/%s/%s.t", 
	   ClassPath, sc->vid[part], part_str[part].str);
  
  if (!(ac = access (school_file, F_OK)))
    {
      if (part == 2 && !nolink)
	{
	  sprintf (school_file, "%s/%s/%s.o", 
		   ClassPath, sc->vid[part], part_str[part].str);
	  
	  ac = access (school_file, F_OK);
	}
      if (!ac)
	{
	  warning ("you have compiled already with `%s' option\n", 
		   part_str[part].str);
	  return 3;
	}
      else
	return -1;
    }

  if (!(sfp = fopen (school_file, "w")))
    {
      fprintf (stderr, "cannot open file: %s\n", school_file);
      return 1;
    }

  count = !class_sc || class_sc == SC_ABSTRACT ? 2 : 1;

  if (no_one_wanted)
    {
      int i;

      for (i = 0; i < no_one_wanted; i++)
	free (one_wanted[i]);

      no_one_wanted = 0;
    }

  for (j = 0; j < count && !ng; j++)
    {
      if (class_sc == SC_SHARED)
	{
	  if (verbose && !internal)
	    PrintOzcCommands ("-p3 0 %s", file);
	  fp = ExecOzc ("-p3", "0", file, 0);
	}
      else if (class_sc == SC_RECORD || class_sc == SC_STATIC)
	{
	  if (verbose && !internal)
	    PrintOzcCommands ("-p3 2 %s", file);
	  fp = ExecOzc ("-p3", "2", file, 0);
	}
      else if (!j)
	{
	  if (verbose && !internal)
	    PrintOzcCommands ("-p2 %s", file);
	  fp = ExecOzc ("-p2", file, 0);
	}
      else if (part < 2)
	{
	  char p[2];
	  
	  p[0] = part + '0';
	  p[1] = 0;
	  if (verbose && !internal)
	    PrintOzcCommands ("-p3 %s %s", p, file);
	  fp = ExecOzc ("-p3", p, file, 0);
	}
      else
	{
	  char buf[256];
	  
	  sprintf (buf, "%s/%s/protected.t", ClassPath, sc->vid[1]);
	  
	  if (verbose && !internal)
	    PrintOzcCommands ("-p3 %s %s", file, buf);
	  fp = ExecOzc ("-p3", file, buf, 0);
	}
      
      if (!fp)
	{
	  fprintf (stderr, "cannot execute\n");
	  fclose (sfp);
	  return 1;
	}

      if (!classes_len[j])
	{
	  classes_len[j] = 256;
	  classes[j] = (School *) malloc (sizeof (School) * classes_len[j]);
	}

      classes_num[j] = 0;
      
      while (!feof (fp))
	{
	  School sc;
	  char c;
	  int i = 0, num;
	  
	  do 
	    {
	      c = fgetc (fp);
	    }
	  while (c != EOF && (c == ' ' || c == '\n'));
	  
	  if (c == EOF)
	    break;
	  
	  ungetc (c, fp);
 	  while ((c = fgetc (fp)) != '\n' && !feof (fp))
	    buf[i++] = c;
	  buf[i] = 0;
	  
	  if (feof (fp))
	    break;
	  
	  if (strchr (buf, ':'))
	    {
	      ng = 1;
	      fprintf (stderr, "%s\n", buf);
	    }
	  else if (!(sc = SearchEntry (buf)))
	    {
	      if (strchr (buf, '<') || strchr (buf, '*'))
		{
		  add_wanted (buf);
		  if (!ng)
		    ng = 1;
		}
	      
	      else
		{
		  fprintf (stderr, "you must compile first:\n");
		  fprintf (stderr, "\t%s\n", buf);
		  ng = 1;
		}
	    }
	  else if (!ng)
	    {
	      if (classes_num[j] == classes_len[j])
		classes[j] = realloc (classes[j], (classes_len[j] += 256));

	      lsearch ((char *)&sc, (char *)(classes[j]), 
		       &(classes_num[j]), 4, school_compare);
	    }
	}
      
      ng = CloseOzc (fp) || ng ? 1 : 0;
    }

  if (ng)
    {
      fclose (sfp);

      unlink (school_file);
      return ng;
    }
  else
    {
      int i, j, k, num;
      School sc;
      
      for (j = 0; j < count; j++)
	{
#if 0
	  printf ("%d %d\n", j, classes_num[j]);
#endif
	  for (k = 0; k < classes_num[j]; k++)
	    {
	      sc = classes[j][k];

#if 0	      
	      printf ("%d %s\n", k, sc->name);
#endif
	      
	      fprintf (sfp, "%d %s\n", sc->class_sc, sc->name);
	      
	      num = (!sc->class_sc || sc->class_sc == SC_ABSTRACT) ? 3 : 1;
	      
	      for (i = 0; i < num; i++)
		fprintf (sfp, "\t%s", sc->vid[i]);
	      fprintf (sfp, "\n");
	    }
	}
    }

  fclose (sfp);

  return 0;
}

static 
  remove_files (char *vid)
{
  DIR *dirp;
  struct direct *d;
  char dir[256], buf[256];

  sprintf (dir, "%s/%s", ClassPath, vid);

  if (verbose && !internal)
    printf ("rm -f %s/*\n", dir);

  if (!(dirp = opendir (dir)))
    {
      fprintf (stderr, "cannot open directroy: `%s'\n", dir);
      return 0;
    }
  
  while (d = readdir (dirp)) 
    {
      if (!d->d_ino ||
	  !strcmp (d->d_name, ".") ||
	  !strcmp (d->d_name, ".."))
	continue;

      sprintf (buf, "%s/%s", dir, d->d_name);
      unlink (buf);
    }

  closedir (dirp);

  fsync ();
}

static
  check_files (int status, School sc, int part)
{
  char command[256];
  int p;

  if (!class_sc || class_sc == SC_ABSTRACT)
    p = part > 2 ? 2 : part;
  else
    p = 0;

  if (ExecMode != TCL_MODE && (debug || status))
    {
      sprintf (command, "cp %s/%s/* .", ClassPath, sc->vid[p]);

      if (verbose && !internal)
	printf ("%s\n", command);

      system (command);
    }

  if (status)
    remove_files (sc->vid[p]);

#if 0
  if (generic_count && part == 3)
    {
      p =  (!class_sc || class_sc == SC_ABSTRACT) ? 2 : 0;
      sprintf (command, "%s/%s/private.o", ClassPath, sc->vid[p]);

      creat (command, 0755);
    }
#endif
}

static
start_compile (char *file, School sc, int part)
{
  char command[256], buf[1024], *result;
  int status;
  FILE *fp;

  if (class_sc == SC_SHARED || class_sc == SC_RECORD || class_sc == SC_STATIC)
    {
      if (verbose && !internal)
	PrintOzcCommands ("0 \"%s\" %s %s", class_name, file, school_file);
      fp = ExecOzc ("0", class_name, file, school_file, 0);
    }
  else
    {
      char p[2];

      p[0] = part + '0';
      p[1] = 0;

      if (!object)
	{
	  if (verbose && !internal)
	    PrintOzcCommands ("%s \"%s\" %s %s", 
				p, class_name, file, school_file);
	  fp = ExecOzc (p, class_name, file, school_file, 0);
	}
      else
	{
	  if (verbose && !internal)
	    PrintOzcCommands ("%s %s \"%s\" %s %s", 
				object, p, class_name, file, school_file);
	  fp = ExecOzc (object, p, class_name, file, school_file, 0);
	}
    }

  if (!fp)
    {
      fprintf (stderr, "cannot execute\n");
      return 1;
    }
      
  while (fgets (buf, 1024, fp))
    {
      if (internal && part < 2 && strstr (buf, "cannot load interfaces"))
	continue;
      
      if (ExecMode == TCL_MODE && strstr (buf, "searchclass "))
	{
	  WriteToTcl (buf);
	  Start (0, 1);

	  continue;
	}
      
      printf ("%s", buf);
      fflush (stdout);
    }
  status = CloseOzc (fp);

  if (!status && class_sc == SC_SHARED)
    {
      if (class_sc == SC_SHARED)
	{
	  if (create_class_list_file_entry (sc, 0))
	    return 1;
	  
	  sprintf (command, "cp %s %s/%s/private.oz", 
		   file, ClassPath, sc->vid[0]);

	  if (verbose && !internal)
	    printf ("%s\n", command);

	  exec_command (command);
	}
    }
  fflush (stdout);

  check_files (status, sc, part);

  return status ? 1 : 0;
}

static
start_link (char *file, School sc)
{
  FILE *fp;
  int status;
#ifdef NONISHIOKA
  char *option = generic_count ? "-w" : "-fPIC -ffixed-i0 -O";
#else
  char *option = generic_count ? "-w" : "-fPIC -ffixed-i0 -O -frerun-cse-after-loop";
#endif
  char command[256];
  char *vid;

  vid = (!sc->class_sc || sc->class_sc == SC_ABSTRACT) ? 
    sc->vid[2] : sc->vid[0];

  sprintf (command, "%s %s %s -I%s/include -I%s %s/%s/private.c", 
	   OZCC, option, goption, OzRoot, ClassPath, ClassPath, vid);
  
  if (verbose && !internal)
    printf ("%s\n", command);
  fflush (stdout);

  status = exec_command (command);
  fflush (stderr);

  check_files (status, sc, 2);

  if (status)
    return status;

  if (!generic_count)
    {
      sprintf (command, "%s -o %s/%s/private.o private.o", 
	       "ld", ClassPath, vid);

      if (verbose && !internal)
	printf ("%s\n", command);

      status = exec_command (command);
      fflush (stderr);
    }
  else
    {
      sprintf (command, "%s/%s/private.o", ClassPath, vid);
      close (creat (command, 0755));
    }

  if (!status)
    {
      if (class_sc != SC_SHARED)
	{
	  if (create_class_list_file_entry (sc, 0))
	    return 1;
	}
    }

  check_files (status, sc, 3);

  unlink ("private.o");

  if (!status)
    {
      sprintf (command, "cp %s %s/%s/private.oz", 
	       file, ClassPath, vid);

      if (verbose && !internal)
	printf ("%s\n", command);

      exec_command (command);
    }

  return status;
}

static void
  make_class_list_file_entry (School sc, FILE *fp)
{
#if 0
  int i, num;

  num = (!sc->class_sc || sc->class_sc == SC_ABSTRACT) ? 3 : 1;

  fprintf (fp, "{\n");

  fprintf (fp, "# versionIDs\n");
  fprintf (fp, "0x%sLL\n", sc->root);
  for (i = 0; i < num; i++)
    fprintf (fp, "0x%sLL\n", sc->vid[i]);

  for (; i < 3; i++)
    fprintf (fp, "0x%sLL\n", sc->root);

  fprintf (fp, "# ccID\n");
  if (sc->class_sc == SC_SHARED || sc->class_sc == SC_RECORD)
    fprintf (fp, "0x%sLL\n", sc->root);
  else
    fprintf (fp, "0x%sLL\n", sc->ccid);

#if 0
  fprintf (fp, "# execFileName\n");
  fprintf (fp, "\"%s/%s/private.o\"\n", ClassPath, sc->vid[num - 1]);
  fprintf (fp, "# layoutFileName\n");
  fprintf (fp, "\"%s/%s/private.l\"\n", ClassPath, sc->vid[num - 1]);
  fprintf (fp, "# compileClassInfo\n");
  fprintf (fp, "\"%s\"\n", ClassPath);
  fprintf (fp, "# runtimeClassInfo\n");
  if (sc->class_sc == SC_SHARED || sc->class_sc == SC_RECORD)
    fprintf (fp, "\"%s/%s/private.r\"\n", ClassPath, sc->root);
  else
    fprintf (fp, "\"%s/%s/private.r\"\n", ClassPath, sc->ccid);
#else
  fprintf (fp, "\"\"\n");
  fprintf (fp, "\"\"\n");
  fprintf (fp, "\"\"\n");
  fprintf (fp, "\"\"\n");
#endif

  fprintf (fp, "}\n");
#else
  fprintf (fp, "%d 0x%sLL\n", sc->class_sc == SC_ABSTRACT ? 0 : sc->class_sc,
	   sc->root);
#endif

  fclose (fp);
}

static
create_class_list_file_entry (School sc, int merge)
{
  char filename[256], buf[256];
  int l, h, i;
  FILE *fp;

  if (class_sc == SC_SHARED || class_sc == SC_RECORD || class_sc == SC_STATIC)
    sprintf (filename, "%s/%s/private.cl", ClassPath, sc->vid[0]);
  else
    sprintf (filename, "%s/%s/private.cl", ClassPath, sc->vid[2]);

  if (!(fp = fopen (filename, "w")))
    {
      fprintf (stderr, "cannot open file: %s\n", filename);
      return 1;
    }

  make_class_list_file_entry (sc, fp);

  if (merge)
    {
      if (class_sc != SC_RECORD && class_sc != SC_SHARED)
	{
	  sprintf (buf, "%s/%s", ClassPath, sc->ccid);
	  mkdir (buf, 0755);
	}

      sprintf (buf, "%s/%s", ClassPath, sc->root);
      mkdir (buf, 0755);

      if ((fp = fopen (oz_class, "a")))
	{
	  make_class_list_file_entry (sc, fp);
	}

    }

  return 0;
}

static
  create_protected_all_h (char *file, char *vid)
{
  FILE *pfp, *pfp2;
  char line_buf[256 + 1], filename[256];
  int i;

  sprintf (filename, "%s/%s/protected-all.h", ClassPath, vid);
  if (!(pfp = fopen (filename, "w")))
    {
      fprintf (stderr, "cannot open file: %s\n", filename);
      return 1;
    }
  
  fprintf (pfp, "#ifndef _PROTECTED_ALL_%s_H\n", vid);
  fprintf (pfp, "#define _PROTECTED_ALL_%s_H\n\n", vid);

  for (i = 0; i < classes_num[0]; i++)
    {
      School sc = classes[0][i];

      sprintf (filename, "%s/%s/protected-all.h", ClassPath, sc->vid[1]);
      if (!(pfp2 = fopen (filename, "r")))
	{
	  fprintf (stderr, "cannot open file: %s\n", filename);
	  fclose (pfp);
	  return 1;
	}
      
      while (!feof (pfp2))
	{
	  bzero (line_buf, 257);
	  if (!fread (line_buf, 256, 1, pfp2))
	    break;
	  fwrite (line_buf, strlen (line_buf), 1, pfp);
	}
      fwrite (line_buf, strlen (line_buf), 1, pfp);
      
      fclose (pfp2);
    }

  sprintf (filename, "%s/%s/protected.h", ClassPath, vid);
  if (!(pfp2 = fopen (filename, "r")))
    {
      fprintf (stderr, "cannot open file: %s\n", filename);

      fclose (pfp);
      return 1;
    }
      
  while (!feof (pfp2))
    {
      bzero (line_buf, 257);
      if (!fread (line_buf, 256, 1, pfp2))
	break;
      fwrite (line_buf, strlen (line_buf), 1, pfp);
    }
  fwrite (line_buf, strlen (line_buf), 1, pfp);
  
  fclose (pfp2);

  fprintf (pfp, "\n\n#endif _PROTECTED_ALL_%s_H\n", vid);
  fclose (pfp);

  return 0;
}

static
exec_compile (char *file, School sc, int c_part)
{
  int status;
  char command[256];

  status = check_start_compile (file, sc, c_part);

  if (status > 0)
    {
      print_one_wanteds ();

      return status;
    }

  else if (status < 0)
    return start_link (file, sc);

  status = start_compile (file, sc, c_part);

  if ((c_part < 1 && class_sc != SC_STATIC && class_sc != SC_RECORD) || status)
    return status;

  if (c_part == 1)
    return create_protected_all_h (file, sc->vid[1]) || status ? 1 : 0;

  if (nolink)
    {
      if (!status)
	{
	  sprintf (command, "cp %s %s/%s/private.oz", 
		   file, ClassPath, sc->vid[class_sc == SC_RECORD || 
					     class_sc == SC_STATIC ? 0 : 2]);
	  if (verbose && !internal)
	    printf ("%s\n", command);

	  exec_command (command);
	}
      return status;
    }
  else
    return start_link (file, sc);
}

static int
  exec_configure (char *command)
{
  int argc = 0;
  char *argv[3];
  
  argv[argc++] = command;
  if (verbose)
    argv[argc++] = "-v";
  argv[argc++] = class_name;
  if (again)
    argv[argc++] = "again";
		
  return Config (argc, argv);
}

int
  Compile (int argc, char **argv)
{
  char filename[256];
  int i, c_part, status;
  char *file, *part;
  School sc = NULL;

  goption = "-g";
  debug = verbose = nolink = again = 0;

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'd':
	      debug = 1;
	      break;

	    case 'v':
	      verbose = 1;
	      break;

	    case 'g':
	      goption = "";
	      break;

	    case 'z':
	      nolink = 1;
	      break;

	    case 'h':
	    default:
	      print_usage (argv[0]);
	      return 0;
	    }
	}
    }

  file = argv[i++];

  if (!strcmp (argv[0], "link"))
    c_part = 4;

  else if (!strcmp (argv[0], "clean"))
    c_part = -3;

  else if (i < argc)
    {
      part = argv[i++];

      if (!strcmp (part, "public"))
	c_part = 0;
      else if (!strcmp (part, "protected"))
	c_part = 1;
      else if (!strcmp (part, "private"))
	c_part = 2;
      else if (!strcmp (part, "all"))
	c_part = 3;
      else if (!strcmp (part, "if"))
	c_part = 5;
      else if (!strcmp (part, "id"))
	{
#if 0
	  if (ExecMode == TCL_MODE)
	    return 1;
#endif
	  c_part = -1;
	}
      else if (!strcmp (part, "name"))
	c_part = -4;
      else if (!strcmp (part, "gcheck"))
	c_part = -5;
      
#if 1
      else if (!strcmp (part, "clean"))
	c_part = -3;
      else if (!strcmp (part, "link"))
	c_part = 4;
#endif

    }

  else
    {
      print_usage (argv[0]);
      return 1;
    }

  if (i < argc)
    {
      if (c_part < 0 || strcmp (argv[i++], "again"))
	{
	  print_usage (argv[0]);
	  return 1;
	}
      else
	again = 1;
    }
  
  if (set_class_name (file, 0, c_part > -4 ? 0 : c_part + 6))
    return 1;
  
  if ((class_sc == SC_SHARED && c_part > 0 && c_part != 3 && c_part != 5) || 
      ((class_sc == SC_RECORD || class_sc == SC_STATIC) && 
       c_part > 0 && c_part < 3))
    return 4;
  
  if (c_part == -3 || again)
    {
      int quit = c_part == -3 ? 1 : 0;
      
      if (i < argc)
	{
	  part = argv[i];
	  if (!strcmp (part, "public"))
	    {
	      if (!class_sc || class_sc == SC_ABSTRACT)
		c_part = 0;
	    }
	  
	  else if (class_sc && class_sc != SC_ABSTRACT)
	    return 1;
	  
	  else if (!strcmp (part, "protected"))
	    c_part = 1;
	  
	  else if (!strcmp (part, "private"))
	    c_part = 2;
	}
      
      if (sc = SearchEntry (class_name))
	{
	  if (c_part < 0 || c_part == 3)
	    {
	      sprintf (filename, "%s/%s/private.r", ClassPath, sc->ccid);
	      unlink (filename);
	    }
	  if (c_part <= 0 || c_part == 3 || c_part == 5)
	    {
	      remove_files (sc->vid[0]);
	    }
	  if ((!sc->class_sc || sc->class_sc & SC_ABSTRACT) &&
	      (c_part < 0 || c_part == 1 || c_part == 3 || c_part == 5))
	    {
	      remove_files (sc->vid[1]);
	    }
	  if ((!sc->class_sc || sc->class_sc & SC_ABSTRACT) &&
	      (c_part < 0 || c_part == 2 || c_part == 3))
	    {
	      remove_files (sc->vid[2]);
	    }
	  if (c_part == 4)
	    {
	      sprintf (filename, "%s/%s/private.o", ClassPath, sc->vid[2]);
	      unlink (filename);
	    }
	}
      
      if (quit)
	return 0;
    }
  else
    sc = SearchEntry (class_name);
  
  if (!sc)
    {
      if ((c_part > 0 && c_part < 3) || c_part == -2)
	{
	  fprintf (stderr, "you must compile first with `public' option\n");
	  return 1;
	}
      
      if (c_part == 0 || c_part == -1 || c_part == 3 || c_part == 5)
	{
	  int i, status;
	  char path[256], lock_file[256];

	  if (!(sc = CreateEntry (class_name, class_sc)))
	    return 1;

	  for (i = 0; i < 3 && sc->vid[i][0]; i++)
	    {
	      sprintf (path, "%s/%s", ClassPath, sc->vid[i]);
	      mkdir (path, 0755);
	    }

	  sprintf (oz_class, "%s/etc/boot-classes", OzRoot);
	  sprintf (lock_file, "%s/%s", ClassPath, OZLOCK);

	  while (Lock (lock_file) < 0)
	    sleep (1);
	  status = create_class_list_file_entry (sc, 1); 
	  UnLock (lock_file);

	  if (status)
	    return 1;
	}
    }
  
  if (c_part < 0)
    return 0;
  
  if (c_part < 3)
    {
      if (!(status = exec_compile (file, sc, c_part)))
	{
#if 0
	  switch (c_part)
	    {
	    case 0:
	      if (class_sc == SC_STATIC)
		exec_configure (argv[0]);
	      break;
	    case 1:
	      break;
	    case 2:
	      exec_configure (argv[0]);
	      break;
	    }
#endif
	}
    }

  else if (c_part == 3 || c_part == 5)
    {
      int i, s;
      int count = c_part == 3 ? 3 : 2;

      for (i = 0; i < count; i++)
	{
	  status = exec_compile (file, sc, i);
	  if ((status && status != 3) || 
	      class_sc == SC_SHARED || class_sc == SC_RECORD)
	    break;

	  if (class_sc == SC_STATIC || i == 2)
	    {
#if 0
	      status = exec_configure (argv[0]);
#endif
	      break;
	    }
	}
    }

  else
    {
      FILE *fp;
      int p = (!class_sc || class_sc == SC_ABSTRACT) ? 2 : 0;

      sprintf (filename, "%s/%s/private.c", ClassPath, sc->vid[p]);
      if (access (filename, F_OK) < 0)
	{
	  fprintf (stderr, "not exist `private.c'\n");
	  return 1;
	}
      sprintf (filename, "%s/%s/private.o", ClassPath, sc->vid[p]);
      if (!access (filename, F_OK))
	{
	  warning ("you have already linked\n");
	  return 3;
	}

      if (!(status = start_link (file, sc)))
	{
#if 0
	  if (class_sc != SC_RECORD)
	    status = exec_configure (argv[0]);
#endif
	}
    }

  return status;
}

char *
  GetGenericParams (char *file)
{
  char *buf = NULL;

  if (check_generic (file))
    return NULL;
  
  if (generic_count)
    {
      int len = 0, i;

      for (i = 0; i < generic_count; i++)
	len += strlen (generic[i]) + 1;

      buf = malloc (len);
      *buf = 0;

      for (i = 0; i < generic_count; i++)
	strcat (buf, generic[i]);
    }

  return buf;
}

char *
  GetClassName (char *file, int *sc, int noconvert)
{
  char *buf;

  verbose = 0;

  if (set_class_name (file, noconvert, 0))
    return NULL;

  if (sc)
    *sc = class_sc;

  buf = malloc (strlen (class_name) + 1);
  strcpy (buf, class_name);

  return buf;
}

void
InternalCompileStart (int clean)
{
  int i;

  internal = 1;

  if (clean)
    {
      for (i = 0; i < no_wanted; i++)
	if (wanted[i]) 
	  {
	    free (wanted[i]);
	    wanted[i] = NULL;
	  }
      
      no_wanted = 0;
    }
}

int
  InternalCompileEnd ()
{
  internal = 0;
  return no_wanted;
}

char **
  GetWanted (int *n)
{
  *n = no_wanted;

  return wanted;
}

void
  PrintWanteds (FILE *fp)
{
  int i;

  if (no_wanted < 1 && no_wanted_dir < 1)
    return;

  if (no_wanted > 0)
    {
      if (fp == stdout)
	fprintf (fp, "you need to generate some generic classes\n");
  
      for (i = no_wanted - 1; i >= 0; i--)
	if (wanted[i])
	  fprintf (fp, "%s\n", wanted[i]);
    }

  if (no_wanted_dir > 0 && fp != stdout)
    {
      fprintf (fp, "directories:\n");
  
      for (i = no_wanted_dir - 1; i >= 0; i--)
	if (wanted_dir[i])
	  fprintf (fp, "%s\n", wanted_dir[i]);
    }

  if (fp == stdout)
    fprintf (fp, "\n");
  fflush (fp);
}

void
  CleanupWanteds ()
{
  int i, count = 0, j;
  char *buf[256];
  
  for (i = 0; i < no_wanted; i++)
    {
      if (wanted[i])
	{
	  buf[j] = malloc (strlen (wanted[i]) + 1);
	  strcpy (buf[j++], wanted[i]);
	  free (wanted[i]);
	  continue;
	}

      count++;
    }

  no_wanted -= count;

  for (i = 0; i < no_wanted; i++)
    wanted[i] = buf[i];
}

void
  LoadPrevWanteds (char *cfedrc)
{
  char buf[256], *c;
  FILE *fp;
  int i = 0, len;

  if (!(fp = fopen (cfedrc, "r")))
    return;

  while (fgets (buf, 256, fp))
    {
      if (strstr (buf, "directories:"))
	break;

      if (c = strchr (buf, '\n'))
	*c = 0;

      if (!(len = strlen (buf)))
	continue;

      wanted[i] = malloc (strlen (buf) + 1);
      strcpy (wanted[i++], buf);
    }

  no_wanted = i;

  i = 0;
  while (fgets (buf, 256, fp))
    {
      if (c = strchr (buf, '\n'))
	*c = 0;

      if (!(len = strlen (buf)))
	continue;

      wanted_dir[i] = malloc (strlen (buf) + 1);
      strcpy (wanted_dir[i++], buf);
    }

  no_wanted_dir = i;

  fclose (fp);
}

int 
  Wanted (int argc, char **argv)
{
  int i;
	  
  switch (argc)
    {
    case 1:
      if (no_wanted)
	PrintWanteds (stdout);
      break;
    case 2:
      if (!strcmp (argv[1], "dir"))
	{
	  for (i = 0; i < no_wanted_dir; i++)
	    if (wanted_dir[i])
	      printf ("%s\n", wanted_dir[i]);

	  fflush (stdout);
	}
	
      break;
    case 3:
      if (!strcmp (argv[1], "remove"))
	remove_wanted_dir (argv[2]);

      else if (!strcmp (argv[1], "discard"))
	{
	  if (!strcmp (argv[2], "class"))
	    {
	      for (i = 0; i < no_wanted; i++)
		if (wanted[i])
		  free (wanted[i]);
	      no_wanted = 0;
	    }
	  else if (!strcmp (argv[2], "file"))
	    {
	      for (i = 0; i < no_wanted_dir; i++)
		if (wanted_dir[i])
		  free (wanted_dir[i]);
	      
	      no_wanted_dir = 0;
	    }
	}
      

      break;
    }

  return 0;
}

FILE *
  ExecOzc (char *arg, ...)
{
  FILE *fp;
  int fds[2];
  int i, j;
  va_list pvar;
  char *argv[256], gnum[4];;

  if (socketpair (AF_UNIX, SOCK_STREAM, 0, fds) < 0)
    {
      perror ("scoketpair");
      return NULL;
    }

  i = 0;
  argv[i++] = "ozc";
  argv[i++] = "-c";
  argv[i++] = ClassPath;
  if (generic_count)
    {
      argv[i++] = "-g";
      sprintf (gnum, "%d", generic_count);
      argv[i++] = gnum;
      for (j = 0; j < generic_count; j++)
	argv[i++] = generic[j];
    }
  
  argv[i++] = arg;

  va_start (pvar);

  while ((argv[i++] = va_arg (pvar, char *)));

  va_end (pvar);

  switch (pid = fork ())
    {
    case -1:
      perror ("fork");
      return NULL;
    case 0:
      dup2 (fds[1], 0);
      dup2 (fds[1], 1);
      dup2 (fds[1], 2);

      for (i = 3; i < NOFILE; i++)
	close (i);

      execvp (argv[0], argv);
      exit (1);
    default:
      close (fds[1]);
#if 0
      printf ("%d\n", fds[0]);
#endif
      fp = fdopen (fds[0], "w+");
      setbuf (fp, NULL);
      return fp;
    }
}

int 
  CloseOzc (FILE *fp)
{
  int status;

  fclose (fp);

  while (wait (&status) != pid);

  if (!(status & 0xff))
    {
#if 0
      fprintf (stderr, "%d\n", (status >> 8) & 0xff);
#endif
      return (status >> 8) & 0xff;
    }
  else
    {
      fprintf (stderr, "core dumped\n");
      return status & 0x7f;
    }
}

void
  PrintOzcCommands (char *format, ...)
{
  va_list pvar;
  char *argv[256];
  int i, j;

  printf ("ozc -c %s", ClassPath);

  if (generic_count)
    {
      printf (" -g %d", generic_count);
      for (j = 0; j < generic_count; j++)
	printf (" %s", generic[j]);
    }

  printf (" ");

  va_start (pvar);
  Emit2 (stdout, format, pvar);
  va_end (pvar);

  printf ("\n");
}

void 
  AddWantedDir (char *dir)
{
  int i;

  for (i = 0; i < no_wanted_dir; i++)
    if (!strcmp (wanted_dir[i], dir))
      return;

  wanted_dir[no_wanted_dir] = malloc (strlen (dir) + 1);
  strcpy (wanted_dir[no_wanted_dir++], dir);
}

