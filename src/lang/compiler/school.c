/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "lang/school.h"
#include "emit-header.h"
#include "ozc.h"

static School school = NULL;

static School
  get_school (char *name)
{
  School sc = school;
  
  if (!strncmp (name, "0x", 2) || !strncmp (name, "0X", 2))
    name = &name[2];

  if ((strlen (name) == 16 && isxdigit (*name)) || 
      (strlen (name) == 18 && !strncmp (name, "__", 2)))
    {
      int i, len = strlen (name);
      
      for (i = len == 18 ? 2 : 0; i < len; i++)
	if (!isxdigit (name[i]))
	  break;

      if (i == len)
	{
	  while (sc)
	    {
	      int i;
	      
	      for (i = 0; i < 3; i++)
		{
		  if (!strcmp (sc->vid[i], &name[len-16]))
		    return sc;
		}
	      sc = sc->next;
	    }
	  return NULL;
	}
    }
  
  while (sc)
    {
      if (!strcmp (sc->name, name))
	return sc;
      
      sc = sc->next;
    }

  return NULL;
}

School
AddSchool (char *name, char (*vid)[17], int class_sc , char *ccid, char *root)
{
  School sc, before, sc2 = school;
  int i;
  char *c = name;

  while (sc2)
    {
      if (!strcmp (sc2->name, name))
	return sc2;

      before = sc2;
      sc2 = sc2->next;
    }

  sc = (School) malloc (sizeof (SchoolRec) + strlen (name));
  strcpy (sc->name, name);

  if (ccid)
    strcpy (sc->ccid, ccid);
  else
    *sc->ccid = 0;

  if (root)
    strcpy (sc->root, root);
  else
    *sc->root = 0;

  for (i = 0; i < 3; i++)
    if (vid && *vid[i])
      strcpy(sc->vid[i], vid[i]);
    else
      *sc->vid[i] = 0;

#ifdef CFE
  while (*c != 0 && *c != '<')
    c++;

  if (*c) 
    {
      if (*(c + 1) == '*')
	sc->generic = 1;
      else
	sc->generic = 2;
    }
  else
    sc->generic = 0;
#else
  sc->generic = 0;
#endif

  sc->class_sc = class_sc;

  sc->next = NULL;

  if (school)
    {
      before->next = sc;
    }
  else
    {
      school = sc;
    }

  return sc;
}

void
PrintSchool (int class_sc, int generic)
{
  School sc = school;
  int i = 0;

  while (sc)
    {
#ifndef CFE
      printf ("%s (%d)\n", sc->name, sc->class_sc);
      printf ("            public = %s\n", sc->vid[0]);
      printf ("         protected = %s\n", sc->vid[1]);
      printf ("    implementation = %s\n\n", sc->vid[2]);
#else
      if (class_sc < 0 || (sc->class_sc == class_sc && sc->generic == generic))
	{
	  printf ("%s\n", sc->name);
	  i++;
	}
#endif
      sc = sc->next;
    }
  printf ("Number of entries of this school = %d\n", i);
}

#if 0
void
EmitUsedHeaderInRecord (FILE *fp)
{
  School sc = school;

  while (sc)
    {
      if (strcmp (sc->name, ThisClass->symbol->string))
	{
	  if (sc->class_sc != SC_RECORD)
	    Emit (fp, "#include \"%s/public.h\"\n", 
		  sc->vid[0], 0);
	}

      sc = sc->next;
    }

  Emit (fp, "\n");
}
#endif

int
LoadSchool (char *filename)
{
  FILE *fp;
  char vid[3][17], name[256], buf[256];
#ifdef CFE
  char ccid[17], root[17];
  int l, h;
#endif
  int class_sc = 0, n;

  if (!(fp = fopen (filename, "r"))) {
#ifndef CFE
    fprintf(stderr, "cannot open file: %s\n", filename);
    exit(1);
#else
    return 1;
#endif
  }

#ifndef CFE
  strcpy (vid[0], OBJECT_PUBLIC);
  strcpy (vid[1], OBJECT_PROTECTED);
  strcpy (vid[2], OBJECT_PRIVATE);
  AddSchool (OBJECT_NAME, vid, 0, NULL, NULL);
  if (!fp)
    return 0;
#endif

  while (!feof(fp))
    {
      char c;
      int i = 0;

      do 
	{
	  c = fgetc (fp);
	}
      while (c != EOF && (c == ' ' || c == '\n'));

      if (c == EOF)
	break;

      ungetc (c, fp);

#if 1
      fscanf (fp, "%d", &class_sc);

      fgetc (fp);		/* skip space */
#endif
      
      while ((c = fgetc (fp)) != '\n')
	name[i++] = c;
      name[i] = 0;

      fgets (buf, 256, fp);

#if 1
      n = sscanf (buf, "%s %s %s", vid[0], vid[1], vid[2]);

      for (i = 0; i < n; i++)
	if (!strcmp (vid[i], "0000000000000000"))
	  vid[i][0] = 0;

      for (i = n; i < 3; i++)
	vid[i][0] = 0;
      
#else
      fscanf (fp, "%s %s", vid[1], vid[2]);
#endif

#ifndef CFE
      AddSchool (name, vid, class_sc, NULL, NULL);
#else
      if (Boot)
	{
	  sscanf (vid[0], "%08x%08x", &l, &h);
	  sprintf (ccid, "%08x%08x", l, h - 2);
	  sprintf (root, "%08x%08x", l, h - 1);
	  AddSchool (name, vid, class_sc, ccid, root);
	}
      else
	AddSchool (name, vid, class_sc, NULL, NULL);
#endif
    }

  fclose (fp);

  return 0;
}

char *
  GetVID (char *name, int part)
{
  School sc = get_school (name);

  if (sc)
    {
      if (part == -1)
	return sc->name;
      else
	return sc->vid[part];
    }
  else
    {
      if (part == -1)
	return name;

      return NULL;
    }
}

long long
GetVIDValue (long long vid, int part)
{
  int l, h, i;
  long long id[3];
  School sc = school;

  while (sc)
    {
      for (i = 0; i < 3; i++)
	{
	  sscanf (sc->vid[i], "%08x%08x", &l, &h);
	  id[i] = (long long)((long long)l << 32) + (h & 0xffffffff);
	  if (id[i] == vid)
	    {
	      if (i <= part)
		return id[part];
	      else
		{
		  sscanf (sc->vid[part], "%08x%08x", &l, &h);
		  return (long long)((long long)l << 32) + (h & 0xffffffff);
		}
	    }
	}
      sc = sc->next;
    }
  return 0LL;
}

int 
GetClassSC (char *name)
{
  School sc = get_school (name);

  if (sc)
    return sc->class_sc;
  else
    return 0;
}
