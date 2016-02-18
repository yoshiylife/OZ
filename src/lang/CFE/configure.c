/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/file.h>

#include "oz++/class-type.h"
#include "lang/internal.h"
#include "lang/school.h"

#include "cfe.h"
#include "cb.h"
#include "command.h"

static OZ_ClassInfo cl;
static OZ_ClassPart *clp;
static int all_size, h_size;
static int slot1;
static char **parents;
static int all_no_parents;

static void
  print_usage_config ()
{
  fprintf(stderr, 
	  "usage: config [-dh]"
	  "<config ID> <version ID 1> <version ID 2> ...\n");
}

static void
  print_usage ()
{
  fprintf(stderr, "usage: config [-dhv] class_name [again]\n");
}

/* for debug */
static int
  print_class_info()
{
  int i, j;

  printf("no parts = %d\n", cl->number_of_parts);
  for (i = 0; i < cl->number_of_parts; i++)
    {
      printf("Part %d:\n", i);
      printf("\tcid = %08x%08x\n", 
             (int)(cl->parts[i]->cid >> 32),
             (int)(cl->parts[i]->cid & 0xffffffff));
      printf("\tcompiled_vid = %08x%08x\n\n", 
             (int)(cl->parts[i]->compiled_vid >> 32),
             (int)(cl->parts[i]->compiled_vid & 0xffffffff));

      printf("\tprotected_data_size   = %d\n", 
             cl->parts[i]->info.data_size_protected);
      printf("\tprivate_data_size     = %d\n", 
             cl->parts[i]->info.data_size_private);
      printf("\tno_protected_pointers = %d\n", 
             cl->parts[i]->info.number_of_pointer_protected);
      printf("\tno_private_pointers   = %d\n\n", 
             cl->parts[i]->info.number_of_pointer_private);
      printf("\tprotected_zero   = %d\n", 
             cl->parts[i]->info.zero_protected);
      printf("\tprivate_zero     = %d\n", 
             cl->parts[i]->info.zero_private);

      printf("\tno entries = %d\n", 
             cl->parts[i]->number_of_entries);
      for (j = 0; j < cl->parts[i]->number_of_entries; j++)
        {
          printf("\t\t slot = %d: cid = %08x%08x, func no = %d\n",
                 j, (int)(cl->parts[i]->entry[j].class_part_id >> 32),
                 (int)(cl->parts[i]->entry[j].class_part_id & 0xffffffff),
                 cl->parts[i]->entry[j].function_no);
        }
    }
}

/* for debug */
static int
  load_class_info (char *vid)
{
  int fd, i, n, offset;
  OZ_ClassPart part;
  char filename[256];
  
  sprintf(filename, "%s/%s/private.r", ClassPath, vid);

  if ((fd = open (filename, O_RDONLY, 0644)) < 0) 
    {
      fprintf(stderr, "CT: cannot read-open the file[%s]\n", filename);
      return 1;
    }
  read (fd, (char *) &n, sizeof (int));
  cl = (OZ_ClassInfo) malloc(n);
  read (fd, (char *) cl, n);
  close (fd);
  for (i = 0; i < cl->number_of_parts; i++) 
    {
      offset = (int) cl->parts[i];
      offset += (int) cl;
      cl->parts[i] = (OZ_ClassPart) offset;
    }

  return 0;
}

static char *
  get_implementation_vid (char *vid)
{
  int i;

  for (i = 0; i < all_no_parents; i += 2)
    if (!strcmp (parents [i], vid))
      return parents[i + 1];
}

static int
  create_class_part(FILE *fp, OID cid, OID cvid,
		    int no_parts, int no_parents, 
		    int no_methods, int no_redefined_methods, 
		    int no_alias_methods)
{
  char filename[256], vid[17], *imp_vid;
  int i, npt, npa, nm, nrm, nam;
  FILE *newfp;
  int slot_no1, slot_no2, func_no, ll, lh, ll2, lh2, size;
  unsigned short protected_data_size, private_data_size;
  unsigned short no_protected_pointers, no_private_pointers;
  unsigned short protected_zero, private_zero;

  if (fscanf(fp, "%hd %hd %hd %hd %hd %hd", 
             &protected_data_size, &private_data_size,
             &no_protected_pointers, &no_private_pointers,
             &protected_zero, &private_zero) != 6)
    {
      fprintf(stderr, "illegal format file\n");
      fclose (fp);
      return 1;
    }

  for (i = 0; i < no_parents; i++)
    {
      if (fscanf(fp, "%s", vid) != 1)
        {
          fprintf(stderr, "illegal format file\n");
	  fclose (fp);
	  return 1;
        }

      imp_vid = get_implementation_vid (vid);

      sprintf(filename, "%s/%s/private.i", ClassPath, imp_vid);

      if (!(newfp = fopen(filename, "r")))
        {
	  fprintf(stderr, "%s not found\n", filename);
	  fclose (fp);
	  return 1;
        }
      
      if (fscanf(newfp, "%08x%08x %08x%08x %d %d %d %d %d", 
                 &ll, &lh, &ll2, &lh2, &npt, &npa, 
                 &nm, &nrm, &nam) != 9)
        {
          fprintf(stderr, "illegal format file\n");
	  fclose (newfp);
	  fclose (fp);
	  return 1;
        }
      
      if (create_class_part(newfp, 
			    (long long) ((long long)ll << 32) + 
			    (long long) (lh & 0xffffffff),
			    (long long)((long long)ll2 << 32) + 
			    (long long) (lh2 & 0xffffffff),
			    npt, npa, nm, nrm, nam))
	return 1;
    }

  for (i = 0; i < no_alias_methods; i++)
    {
      int s1, s2;
      int diff1, diff2;

      if (fscanf(fp, "%d %d %d %d", 
                 &slot_no1, &slot_no2, &s1, &s2) != 4)
        {
          fprintf(stderr, "illegal format file\n");
	  fclose (fp);
	  return 1;
        }
      
      diff1 = slot_no1 < 0 ? slot1 : no_parts - slot_no1 - 1; 
      diff2 = s1 < 0 ? slot1 : no_parts - s1 - 1; 
      clp[slot1 - diff1]->entry[slot_no2].function_no 
	= clp[slot1 - diff2]->entry[s2].function_no;
      clp[slot1 - diff1]->entry[slot_no2].class_part_id
	= clp[slot1 - diff2]->entry[s2].class_part_id;
      clp[slot1 - diff1]->number_of_entries++;
    }

  for (i = 0; i < no_redefined_methods; i++)
    {
      int diff;

      if (fscanf(fp, "%d %d %08x%08x %d", 
                 &slot_no1, &slot_no2, &ll, &lh, &func_no) != 5)
        {
          fprintf(stderr, "illegal format file\n");
	  fclose (fp);
	  return 1;
        }
      
      diff = slot_no1 < 0 ? slot1 : no_parts - slot_no1 - 1; 
      clp[slot1 - diff]->entry[slot_no2].function_no = func_no;
      clp[slot1 - diff]->entry[slot_no2].class_part_id = 
        (long long)((long long)ll << 32) + (lh & 0xffffffff);
    }

  if (!no_methods)
    {
      clp[slot1] = 
        (OZ_ClassPart) malloc((size = sizeof(OZ_ClassPartRec)));
    }
  else
    {
      clp[slot1] = 
        (OZ_ClassPart) malloc((size = sizeof(OZ_ClassPartRec) +
                               sizeof(OZ_FunctionEntryRec) * 
			       (no_methods * 2 - 1)));
    }

  clp[slot1]->number_of_entries = no_methods;
  clp[slot1]->cid = cid;
  clp[slot1]->compiled_vid = cvid;

/* optimized version ! */
#ifdef OPTIMIZED
  clp[slot1]->impl_function_no = slot1;
#endif

  /* allocation info. */
  clp[slot1]->info.data_size_protected = protected_data_size;
  clp[slot1]->info.data_size_private = private_data_size;
  clp[slot1]->info.number_of_pointer_protected = no_protected_pointers;
  clp[slot1]->info.number_of_pointer_private = no_private_pointers;
  clp[slot1]->info.zero_protected = protected_zero;
  clp[slot1]->info.zero_private = private_zero;

  for (i = 0; i < no_methods; i++)
    {
      if (fscanf(fp, "%d %d %08x%08x %d", 
                 &slot_no1, &slot_no2, &ll, &lh, &func_no) != 5)
        {
          fprintf(stderr, "illegal format file\n");
	  fclose (fp);
	  return 1;
        }
      clp[slot1]->entry[slot_no2].function_no = func_no;
      clp[slot1]->entry[slot_no2].class_part_id = 
        (long long)((long long)ll << 32) + (lh & 0xffffffff);
    }
  
  fclose(fp);
  slot1++;

  return 0;
}

static 
  load_object_class_info (char *dir)
{
  int ll, lh, ll2, lh2;
  char filename[256];
  FILE *fp;
  int no_parts, no_parents, no_methods, no_redefined_methods, no_alias_methods;

  sprintf(filename, "%s/%s/private.i", ClassPath, dir);

  if (!(fp = fopen(filename, "r")))
    {
      fprintf(stderr, "%s not found\n", filename);
      return 1;
    }

  if (fscanf(fp, "%08x%08x %08x%08x %d %d %d %d %d", 
             &ll, &lh, &ll2, &lh2, &no_parts, &no_parents, 
             &no_methods, &no_redefined_methods, &no_alias_methods) != 9)
    {
      fprintf(stderr, "illegal format file\n");
      fclose (fp);
      return 1;
    }

  return create_class_part(fp, 
			   (long long) ((long long)ll << 32) + 
			   (long long) (lh & 0xffffffff),
			   (long long) ((long long)ll2 << 32) + 
			   (long long) (lh2 & 0xffffffff),
			   no_parts, no_parents, 
			   no_methods, no_redefined_methods, no_alias_methods);
}

static int
  write_class_info (char *cid)
{
  char filename[256];
  int fd;
  int i;
  int pad = 0, size = 0;

  sprintf(filename, "%s/%s/private.r", ClassPath, cid);

  if ((fd = open(filename, O_CREAT | O_WRONLY, 0644)) < 0)
    {
      fprintf(stderr, "cannot open file:%s\n", filename);
      return 1;
    }

  for (i = 0; i < cl->number_of_parts; i++)
    {
      (int)cl->parts[i] = all_size;
      all_size += sizeof (OZ_ClassPartRec) + sizeof (OZ_FunctionEntryRec) *
	(clp[i]->number_of_entries - 1);
    }

  if (write (fd, (char *)&all_size, sizeof(int)) < 0)
    {
      close (fd);
      unlink(filename);

      fprintf(stderr, "cannot write\n");
      return 1;
    }

  if (write(fd, (char *)cl, h_size) < 0) 
    {
      close (fd);
      unlink(filename);

      fprintf(stderr, "cannot write\n");
      return 1;
    }

  for (i = 0; i < cl->number_of_parts; i++)
    {
      if (write(fd, (char *)clp[i], 
                sizeof (OZ_ClassPartRec) + sizeof (OZ_FunctionEntryRec) *
		(clp[i]->number_of_entries - 1)) < 0)
        {
	  close (fd);
	  unlink(filename);

          fprintf(stderr, "cannot write\n");
	  return 1;
        }
    }

  close(fd);

  return 0;
}

static int
  write_all_parts (char *cid)
{
  char filename[256];
  FILE *fp;
  int i;

  sprintf(filename, "%s/%s/private.s", ClassPath, cid);

  if (!(fp = fopen (filename, "w")))
    {
      fprintf(stderr, "cannot open file:%s\n", filename);
      return 1;
    }

  for (i = 0; i < cl->number_of_parts; i++)
    fprintf (fp, "0x%08x%08xLL\n", 
	     (int)(clp[i]->cid >> 32),
	     (int)(clp[i]->cid & 0xffffffff));

  fclose(fp);

  return 0;
}

static int 
  config (int argc, char **argv)
{
  int ll, lh;
  int ll2, lh2;
  char filename[256];
  FILE *fp;
  int no_parts, no_parents, no_methods, no_redefined_methods, no_alias_methods;
  int debug = 0, object = 0, i, j;
  char *ccid;

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
	    case 'h':
	    default:
	      print_usage_config ();
	      return 0;
	    }
	}
    }

  if (argc - i < 2)
    {
      print_usage_config ();
      return 1;
    }

  if (argc - i == 2)
    object = 1;

  parents = (char **) malloc (sizeof (char *) * (argc - i - 3));
  for (j = 0; j < argc - i - 3; j++)
    parents[j] = argv[j + i + 3];

  all_no_parents = j;
  ccid = argv[i];
  slot1 = 0;

  sprintf(filename, "%s/%s/private.i", ClassPath, argv[i + 1]);

  if (!(fp = fopen(filename, "r")))
    {
      fprintf(stderr, "%s not found\n", filename);
      return 1;
    }

  if (fscanf(fp, "%08x%08x %08x%08x %d %d %d %d %d", 
             &ll, &lh, &ll2, &lh2, &no_parts, &no_parents, 
             &no_methods, &no_redefined_methods, &no_alias_methods) != 9)
    {
      fprintf(stderr, "illegal format file\n");
      fclose (fp);
      return 1;
     }

  if (!object)
    no_parts++;

  /* adjusting alignment for 8 bytse boundary */
  if (!(no_parts % 2))
    cl = (OZ_ClassInfo) malloc((h_size = all_size = sizeof(OZ_ClassInfoRec) +
                                sizeof(OZ_ClassPart) * no_parts));
  else
    cl = (OZ_ClassInfo) malloc((h_size = all_size = sizeof(OZ_ClassInfoRec) +
                                sizeof(OZ_ClassPart) * (no_parts - 1)));

  cl->number_of_parts = no_parts;
  clp = (OZ_ClassPart *) malloc(sizeof(OZ_ClassPart *) * (no_parts));

  if (!object)
    {
      if (load_object_class_info (argv [i + 2]))
	{
	  fclose (fp);
	  return 1;
	}
      no_parts--;
    }

  if (create_class_part(fp, 
			(long long) ((long long)ll << 32) + 
			(long long) (lh & 0xffffffff),
			(long long) ((long long)ll2 << 32) + 
			(long long) (lh2 & 0xffffffff),
			no_parts, no_parents, no_methods, no_redefined_methods,
			no_alias_methods))
    return 1;

#if 0
  for (i = 0; i < cl->number_of_parts; i++)
    cl->parts[i] = clp[i];
  print_class_info();
#endif

  if (write_class_info (ccid))
    return 1;

  if (write_all_parts (ccid))
    return 1;

  for (i = 0; i < cl->number_of_parts; i++)
    free (clp[i]);

  free (clp);
  free (cl);
  free (parents);

  if (debug)
    {
      if (load_class_info(ccid))
	return 1;

      print_class_info();

      free (cl);
    }

  return 0;
}

int 
  Config (int argc, char **argv)
{
  int debug = 0, verbose = 0, i, j = 0;
  School sc;
  int conf_argc;
  char **conf_argv;
  char buf[256];
  int status;
  FILE *fp;
  int again = 0;
  OO_ClassType cl;

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
  
  if (i + 1 < argc)
    {
      if (!strcmp (argv[i + 1], "again"))
	again = 1;
      else
	{
	  print_usage ();
	  return 1;
	}
    }

  sc = SearchEntry (argv[i]);

  if (!sc || sc->class_sc == SC_SHARED || sc->class_sc == SC_RECORD)
    return 1;

  sprintf (buf, "%s/%s/private.r", ClassPath, sc->ccid);
  if (!access (buf, F_OK))
    {
      if (!again)
	{
	  if (ExecMode != TCL_MODE)
	    fprintf (stderr, "already configured : %s\n", argv[i]);
	  return 2;
	}
      else
	unlink (buf);
    }

  if ((!sc->class_sc || sc->class_sc == SC_ABSTRACT) && 
	   strcmp (argv[i], OBJECT_NAME))
    {
      if (!(cl = LoadClassInfo (argv[i], 1)))
	return 1;
      
      conf_argc = 4 + cl->no_parents * 2 + debug;
    }
  else
    conf_argc = 3 + debug;

  conf_argv = (char **) malloc (conf_argc * sizeof (char *));

  conf_argv[j++] = "config";
  if (debug)
    conf_argv[j++] = "-d";
  
  conf_argv[j++] = sc->ccid;

  if (sc->class_sc == SC_STATIC)
    conf_argv[j++] = sc->vid[0];
  else
    conf_argv[j++] = sc->vid[2];
    

  if (conf_argc > 3 + debug)
    {
      OO_List list;
      long long vid;

      conf_argv[j++] = OBJECT_PRIVATE;

      if (list = cl->class_part_list)
	list = &list->cdr->list_rec;

      for (; j < conf_argc; j += 2, list = &list->cdr->list_rec)
	{
	  vid = list->car->class_type_rec.class_id_protected;

	  conf_argv[j] = malloc (17);
	  sprintf (conf_argv[j], "%08x%08x",
		   (int) (vid >> 32), (int) (vid & 0xffffffff));

	  conf_argv[j + 1] = malloc (17);
	  strcpy (conf_argv[j + 1], GetVID (conf_argv[j], 2));
	}
    }

  if (verbose)
    {
      for (j = 0; j < conf_argc; j++)
	printf ("%s ", conf_argv[j]);

      printf ("\n");
    }

  if (status = config (conf_argc, conf_argv))
    fsync ();

  if (conf_argc > 5)
    {
      for (j = 4 + debug; j < conf_argc; j++)
	free (conf_argv[j]);
    }

  free (conf_argv);
  
  return status;
}

