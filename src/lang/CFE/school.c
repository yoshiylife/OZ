/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "lang/internal.h"
#include "cb.h"
#include "cfe.h"

#define PREFIX "0001000002"

static int start_count;
static School sub_school = NULL;
static char *school_file = NULL;

static created_count = 0;

#define CFE
#include "../compiler/school.c"

static void
  print_usage_children ()
{
  fprintf (stderr, "usage: children name\n");
}

static void
  print_usage_instantiate ()
{
  fprintf (stderr, "usage: insatnciate name\n");
}

static void
  print_usage_invoke ()
{
  fprintf (stderr, "usage: invoke name\n");
}

static FILE *
  open_file (char *filename, char *mode, int msgon)
{
  FILE *fp;

  if (!(fp = fopen (filename, mode)))
    {
      if (msgon)
	fprintf (stderr, "cannot open file: %s\n", filename);
      return NULL;
    }

  return fp;
}

static void
  free_school (School sc)
{
  School buf;

  while (sc)
    {
      buf = sc->next;
      free (sc);
      sc = buf;
    }
}

void
  RemoveSchool (char *name)
{
  School sc = school, prev = NULL;

  while (sc)
    {
      if (!strcmp (name, sc->name))
	{
	  if (prev)
	    prev->next = sc->next;
	  else
	    school = sc->next;

	  free (sc);
	  return;
	}

      prev = sc;
      sc = sc->next;
    }
}

School
  SearchEntry (char *name)
{
  School sc = school;

  while (sc)
    {
      if (!strcmp (name, sc->name) || 
	  !strncmp (name, sc->vid[0], 16) ||
	  !strncmp (name, sc->vid[1], 16) || !strncmp (name, sc->vid[2], 16))
	return sc;

      sc = sc->next;
    }

  return NULL;
}

School
  CreateEntry (char *class, int class_sc)
{
  FILE *fp;
  char buf[256], vid[3][17], ccid[17], root[17];
  int l, h, i, not_object, num;
#if 0
  long long id;
#endif

  num = (!class_sc || class_sc == SC_ABSTRACT) ? 3 : 1;

  if ((not_object = strcmp (class, OBJECT_NAME))) 
    {
      sprintf (buf, "%s/.%s", ClassPath, User);
      
      if (!(fp = open_file (buf, "r+", 0)))
	{
	  if (!(fp = open_file (buf, "w", 1)))
	    return NULL;
	  sprintf (buf, "%s%06x", PREFIX, start_count);
	  sscanf (buf, "%08x%08x", &l, &h);
	}
      else 
	{
	  fscanf (fp, "%08x%08x", &l, &h);
	  fseek (fp, 0L, 0);
	}

#if 0      
      id = (long long)((long long)l << 32) + (h & 0xffffffff) + 1;
      fprintf (fp, "%08x%08x\n", 
	       (int)((id + 4) >> 32), (int)((id + 4) & 0xffffffff));
#else
      if (class_sc != SC_SHARED && class_sc != SC_RECORD)
	h++;
      fprintf (fp, "%08x%08x\n", l, h + num + 1);
#endif
      fclose (fp);
    }
  else
    {
      sscanf (OBJECT_CID, "%08x%08x", &l, &h);
#if 0
      id = (long long)((long long)l << 32) + (h & 0xffffffff);
#endif
    }

#if 0
  sprintf (ccid, "%08x%08x", 
	   (int)(id >> 32), (int)(id & 0xffffffff));
  id++;
  sprintf (root, "%08x%08x", 
	   (int)(id >> 32), (int)(id & 0xffffffff));
#else
  if (class_sc != SC_SHARED && class_sc != SC_RECORD)
    sprintf (ccid, "%08x%08x", l, h++);
  else
    h++;
  sprintf (root, "%08x%08x", l, h++);
#endif

  for (i = 0; i < num; i++)
    {
#if 0
      id++;
      sprintf (vid[i], "%08x%08x", 
	       (int)(id >> 32), (int)(id & 0xffffffff));
#else
      sprintf (vid[i], "%08x%08x", l, h++);
#endif
    }

  for (; i < 3; i++)
    *vid[i] = 0;

#if 0
  if (++created_count % 100 > 20)
    Save (0, NULL);
#endif

  return AddSchool (class, vid, class_sc, ccid, root);
}

int
  LoadSubSchool (char *filename)
{
  School tmp = school;

  school = NULL;
  if (sub_school)
    {
      free_school (sub_school);
      sub_school = NULL;
    }

  if (LoadSchool (filename))
    {
      fprintf(stderr, "cannot open file: %s\n", filename);
      school = tmp;
      return 1;
    }

  sub_school = school;
  school = tmp;

  return 0;
}

char *
  GetVID2 (char *name, int part)
{
  School tmp = school;
  char *result = NULL;
  int i;

  school = sub_school;

  for (i = 0; i < 2 && !result; i++)
    {
      result = GetVID (name, part);

      if (part < 0 && !strcmp (name, result))
	result = NULL;

      school = tmp;
    }

  return result;
}

void
Auth ()
{
#ifdef AUTH
  char filename[256], name[256];
  FILE *fp;
  int i = 0;

  sprintf (filename, "%s/etc/ozusers", OzRoot);
  
  if (!(fp = fopen (filename, "r")))
    {
      fprintf (stderr, "cannot open `%s'\n", filename);
      exit (1);
    }
  
  for ( ; ; )
    {
      if (!fscanf (fp, "%s", name))
	break;

      if (!strcmp (User, name))
	{
	  start_count = i * 0x10000;
	  fclose (fp);
	  return;
	}

      i++;
    }

  fclose (fp);

  fprintf (stderr, "You cannot use this oz++ system\n");
  fprintf (stderr, "Please contact your system administrator\n");
  exit (1);
#else
  if (!strcmp (User, "oz++admin"))
    start_count = 0;
  else
    {
      fprintf (stderr, "you must be oz++admin to use\n");
      exit (1);
    }
#endif
}

int 
  Save (int argc, char **argv)
{
  School sc = school;
  int i;
  FILE *fp;
  char *file;

  if (argc < 2)
    file = school_file;
  else
    file = argv[1];

  if (!(fp = open_file (file, "w", 1)))
    return 1;

  while (sc)
    {
      fprintf (fp, "%d %s\n", sc->class_sc, sc->name);
      for (i = 0; i < 3 && *sc->vid[i]; i++)
	fprintf (fp, "\t%s", sc->vid[i]);
      fprintf (fp, "\n");
      sc = sc->next;
    }

  fclose (fp);

  return 0;
}

int 
  Load (int argc, char **argv)
{
  if (argc < 2)
    {
      fprintf (stderr, "usage: load file_name\n");
      return 1;
    }

  if (school)
    {
      free_school (school);
      school = NULL;
    }

  if (LoadSchool (argv[1]))
    {
      fprintf(stderr, "cannot open file: %s\n", argv[1]);
      return 1;
    }

  if (school_file)
    free (school_file);

  school_file = malloc (strlen (argv[1]) + 1);
  strcpy (school_file, argv[1]);

  return 0;
}

int 
  LoadInitialSchool (char *filename)
{
#if 0
  School sc;
  OO_ClassType cl;
  OO_List part;
#endif

  school_file = malloc (strlen (filename) + 1);
  strcpy (school_file, filename);
  if (LoadSchool (filename))
    {
      int fd;
    
      if ((fd = creat (filename, 0644)) < 0)
	{
	  fprintf(stderr, "cannot create file: %s\n", filename);
	  return 1;
	}

      close (fd);
    }

#if 0
  for (sc = school; sc; sc = sc->next)
    {
      if (!sc->class_sc && !sc->generic)
	if (cl = LoadClassInfo (sc->name, 1))
	  for (part = cl->class_part_list; part; part = &part->cdr->list_rec)
	    {
	      if (part->car->class_type_rec.class_id_protected == 0x0001000002000190LL)
		printf ("%s\n", sc->name);
	    }
    }
#endif

  return 0;
}

char *
  CleanupName (char *name)
{
  char buf[256];
  char *p = buf, prev = ',';

  if (*name == '"' || *name == '\'')
    name++;

  for (;*name && *name != '"' && *name != '\'';)
    {
      if (!isspace (*name))
	{
	  prev = *p++ = *name;
	  name++;
	}

      else
	{
	  while (isspace (*name))
	    name++;

	  if ((*name != ',' && *name != '<' && *name != '>') &&
	      (prev != ',' && prev != '<' && prev != '>'))
	    *p++ = ' ';
	}
    }

  *p = 0;

  p = malloc (strlen (buf) + 1);
  strcpy (p, buf);

  return p;
}

int 
  GetRealGenerics (char *name, char ***reals)
{
  School sc = school;
  int len = 0;
  char *p = name;
  int no_reals = 256, i = 0;

  *reals = (char **) malloc (sizeof (char *) * no_reals);

  while (*p)
    {
      p++;
      len++;
    }

  while (sc)
    {
      if (!strncmp (sc->name, name, len) && sc->name[len] == '<' && 
	  !strchr (sc->name, '*'))
	{
	  if (i == no_reals)
	    {
	      no_reals += 256;
	      *reals = (char **) realloc (reals, no_reals * sizeof (char *));
	    }
	  (*reals)[i++] = sc->name;
	}

      sc = sc->next;
    }

  return i;
}

int 
  Children (int argc, char **argv)
{
#if 0
  OO_ClassType cl;
  int l, h;
  OO_List list;
  long long vid;
  School sc;
#else
  char *vid, buf[256], filename[256];
  School sc;
  FILE *fp;
#endif

  if (argc < 2)
    print_usage_children ();

#if 0
  sscanf (GetVID (argv[1], 1), "%08x%08x", &l ,&h);
  vid = (long long)((long long)l << 32) + (h & 0xffffffff);
  
  for (sc = school; sc ; sc = sc->next)
    {
      if (sc->class_sc || !(cl= LoadClassFromZ (sc->name, 1)))
	continue;
      
      if (list = cl->class_part_list)
	list = &list->cdr->list_rec;
      
      for (; list ; list = &list->cdr->list_rec)
	{
	  if (list->car->class_type_rec.class_id_protected == vid)
	    printf ("%s\n", sc->name);
	}
    }

#else  
  if (!(vid = GetVID (argv[1], 1)))
    return 1;

  for (sc = school; sc ; sc = sc->next)
    {
      if (sc->class_sc)
	continue;

      sprintf (filename, "%s/%s/public.h", ClassPath, sc->vid[0]);

      if (!(fp = fopen (filename, "r")))
	continue;

      fgets (buf, 256, fp);

      for (;;) 
	{
	  fgets (buf, 256, fp);
	  
	  if (*buf == '*')
	    break;

	  if (!strncmp (buf, vid, 16))
	    {
	      printf ("%s\n", sc->name);
	      break;
	    }
	}

      fclose (fp);
    }
#endif
  return 0;
}

int 
  Instantiate (int argc, char **argv)
{
  School sc;
  FILE *fp;
  char filename[256], buf[256];

  if (argc < 2)
    print_usage_instantiate ();

  if (!(sc = SearchEntry (argv[1])))
    return 1;

  if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
    sprintf (filename, "%s/%s/private.h", ClassPath, sc->vid[2]);
  else
    sprintf (filename, "%s/%s/public.h", ClassPath, sc->vid[0]);

  if (!(fp = fopen (filename, "r")))
    {
      fprintf (stderr, "cannot open file: %s\n", filename);
      return 1;
    }

  fgets (buf, 256, fp);

  for (;;) 
    {
      fgets (buf, 256, fp);
      
      if (*buf == '*')
	break;

      printf ("%s", buf);
    }

  fclose (fp);

  return 0;
}

int 
  Invoke (int argc, char **argv)
{
  School sc;
  FILE *fp;
  char filename[256], buf[256];

  if (argc < 2)
    print_usage_invoke ();

  if (!(sc = SearchEntry (argv[1])))
    return 1;

  if (!sc->class_sc || sc->class_sc == SC_ABSTRACT)
    sprintf (filename, "%s/%s/private.h", ClassPath, sc->vid[2]);
  else
    sprintf (filename, "%s/%s/public.h", ClassPath, sc->vid[0]);

  if (!(fp = fopen (filename, "r")))
    {
      fprintf (stderr, "cannot open file: %s\n", filename);
      return 1;
    }

  fgets (buf, 256, fp);

  for (;;) 
    {
      fgets (buf, 256, fp);
      
      if (*buf == '*')
	break;
    }

  for (;;)
    {
      fgets (buf, 256, fp);
      if (*buf == '/')
	break;
    }

  for (;;) 
    {
      fgets (buf, 256, fp);
      
      if (*buf == '*')
	break;

      printf ("%s", buf);
    }

  fclose (fp);

  return 0;
}
