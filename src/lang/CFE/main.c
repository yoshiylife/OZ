/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pwd.h>
#include <varargs.h>
#include <signal.h>

#include "cfe.h"
#include "command.h"

#define COMMAND_NAME "cfed"

char *ClassPath = NULL, *OzRoot = NULL, *User = NULL;
enum EXEC_MODE ExecMode = NORMAL_MODE;
int Boot = 1;
char *cfedrc = NULL;

static void
  print_usage ()
{
  fprintf (stderr, COMMAND_NAME 
	   " [-ahpt] [-c class_path] [-s school]\n");
}

static CommandProc
  *is_command (char *str)
{
  int l, h, m, ret;
  char *buf;

  for (l = 0, h = COMMAND_SIZE; l < h; ) 
    {
      m = (l + h) >> 1;
      if ((ret = strcmp (commands[m].name, str)) < 0)
	l = m + 1;
      else if (ret > 0)
	h = m;
      else
	return commands[m].proc;
    }
  return NULL;
}

static int 
  parse_command (char *buf, char *argv[])
{
  int i = 0, j;
  char b[256];
  unsigned char quote = 0;

  while (*buf)
    {
      while (*buf == ' ' || *buf == '\n')
	*buf++;

      for (j = 0; *buf && ((*buf != ' ' && *buf != '\n') || quote);)
	{
	  if (*buf == '{' || *buf == '}')
	    {
	      buf++;
	      continue;
	    }

	  if (*buf == '"' || *buf == '\'')
	    {
	      quote ^= 0x1;
	      buf++;
	      continue;
	    }

	  b[j++] = *buf++;
	}

      if (j)
	{
	  b[j] = 0;
	  strcpy (argv[i], b);
	  i++;
	}
    }

  return i;
}

static int 
  killed ()
{
  Quit (0, NULL);
}

char *
  Start (int prompt, int once)
{

#define BUF_SIZE 4096

  char *argv[256];
  static char buf[BUF_SIZE];
  int argc, i, status;
  CommandProc *proc;

  for (i = 0; i < 256; i++)
    argv[i] = malloc (256);

  setbuf (stdout, NULL);

  for (;;)
    {
      if (prompt)
	printf ("CFE> ");
      
      bzero (buf, BUF_SIZE);
      if (gets (buf))
	{
#if 0
	  fprintf (stderr, COMMAND_NAME ": %s\n", buf);
#endif
	  
	  argc = parse_command (buf, argv);
	  
	  if (!(proc = is_command (argv[0])))
	    {
	      if (once)
		return buf;

	      fprintf (stderr, "illegal command: `%s'\n", argv[0]);
	      continue;
	    }
	      
#if 0
	  for (i = 0; i < argc; i++) printf ("%s\n", argv[i]);
#endif
	  
	  status = proc (argc, argv);

#if 0
	  if (ExecMode == TCL_MODE && !once)
#endif
	  if (ExecMode == TCL_MODE)
	    printf ("TCL:Success:%d\n", status);

	  fflush (stdout);
	}
    }
}

int
  Chdir (int argc, char **argv)
{
 if (argc < 2)
    return 1;

  return chdir (argv[1]);
}

int 
  Quit (int argc, char **argv)
{
  FILE *fp;

  Save (0, NULL);
  
  if (!(fp = fopen (cfedrc, "w")))
    {
      fprintf (stderr, "cannot open file: %s\n", cfedrc);
      exit (1);
    }

#if 1
  PrintWanteds (fp);
#endif

  fclose (fp);

  exit (0);
}

main (int argc, char **argv)
{
  char *school = NULL, *buf, *cpath = NULL, *spath = NULL;
  int i, noauth = 1, prompt = 0, daemon = 0;
#if 1
  int mem_debug = 0;
#endif

  while (buf = strchr (argv[0], '/'))
    argv[0] = ++buf;

  if (strstr (argv[0], COMMAND_NAME))
    {
      daemon = 1;
      for (i = 1; i < argc && *argv[i] == '-'; i++)
	{
	  char *p;
	  
	  for (p = &argv[i][1]; *p; p++)
	    {
	      switch (*p)
		{
		case 'a':
		  noauth = 1;
		  Boot = 0;
		  break;
		case 'b':
		  noauth = 0;
		  break;
		case 'c':
		  cpath = argv[++i];
		  break;
		case 'p':
		  prompt = 1;
		  break;
		case 's':
		  spath = argv[++i];
		  break;
		case 't':
		  ExecMode = TCL_MODE;
		  break;
		case 'm':
		  mem_debug = atoi (argv[++i]);
		  break;
		case 'h':
		default:
		  print_usage ();
		  exit (1);
		}
	    }
	}
    }

#if 1
  malloc_debug (mem_debug);
#endif

  if (!(User = (char *) getlogin ()) && !(User = (char *) cuserid (NULL)) && 
      !(User = getpwuid (getuid ())->pw_name))
    {
      fprintf (stderr, "cannot get your name\n");
      exit (1);
    }

  if (!(OzRoot = getenv ("OZROOT")))
    {
      fprintf (stderr, "You must set OZROOT\n");
      exit (1);
    }

  if (!noauth)
    Auth ();

  if (Boot || !cpath)
    cpath = "lib/boot-class";

  ClassPath = (char *) malloc (strlen (OzRoot) + strlen (cpath) + 2);
  sprintf (ClassPath, "%s/%s", OzRoot, cpath);

  if (Boot || !spath)
    {
      char *home = getenv ("HOME");

      spath = "etc/boot-school";
      cfedrc = (char *) malloc (strlen (home) + 9);
      sprintf (cfedrc, "%s/.cfedrc", home);
    }
  else
    {
      cfedrc = (char *) malloc (strlen (OzRoot) + strlen (spath) + 9);
      sprintf (cfedrc, "%s/%s-cfedrc", OzRoot, spath);
    }

  school = (char *) malloc (strlen (OzRoot) + strlen (spath) + 2);
  sprintf (school, "%s/%s", OzRoot, spath);

#if 0
  Compiler = malloc (strlen (OZCOMPILER) + 4 + strlen (cpath) + 1);
  sprintf (Compiler, "%s -c %s", OZCOMPILER, cpath);
#endif

  if (LoadInitialSchool (school))
    return 1;

  LoadPrevWanteds (cfedrc);

  signal (SIGPIPE, killed);
  signal (SIGTERM, killed);
  signal (SIGINT, killed);

  if (ExecMode == TCL_MODE)
    dup2 (1, 2);

  if (daemon)
    Start (prompt, 0);
  else
    {
      CommandProc *proc;

      if (!(proc = is_command (argv[0])))
	{
	  fprintf (stderr, "illegal command: `%s'\n", argv[0]);
	  exit (1);
	}

      return proc (argc, argv);
    }

  return 0;
}

void
WriteToTcl (char *format, ...)
{
  va_list pvar;

  va_start (pvar);
  Emit2 (stdout, format, pvar);
  va_end (pvar);

  fflush (stdout);
}
