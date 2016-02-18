/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdlib.h>
#include <sys/file.h>

#include <oz++/object-image.h>
#include <lang/types.h>

static char ids[256];
static OZ_Object global_obj;

static int count = 0;
static ObjectList obj_list, obj_list_tail;
static PtrList ptr_list, ptr_list_tail;
static int arch_type;
static char *class_path;

static char monitor[8];

/*
 * private funcitons
 */


static int 
  get_offset(char *label)
{
  ObjectList obj = obj_list;

  while (obj)
    {
      if ((int) obj->obj == (int) global_obj)
	return count;

      if (!strcmp(obj->label, label))
	return obj->offset + count;
      obj = obj->next;
    }
  return -1;
}

static int
  object_size(OZ_Header obj)
{
  int size, i;
  OZ_ObjectAll all;
  OZ_StaticObject s_obj;

  if (obj->h > 0)
    {
      size = obj->e;
    }
  else
    {
      if (obj->h == -1)
	{
	  size = obj->e;
	}
      else
	{
	  (int)all = (int)obj - (obj->e + 1) * sizeof(OZ_HeaderRec);
	  size = sizeof(OZ_ObjectAllRec) 
	    + all->head[0].h * sizeof(OZ_HeaderRec);
	  for (i = 0; i < all->head[0].h; i++)
	    size += - all->head[i + 1].h;
	  size += sizeof (monitor);
	}
    }

  return size;
}

static int 
  this_write(int fd, char *ptr, int size)
{
  int res;

  if ((res = write(fd, ptr, size)) < 0)
    {
      fprintf(stderr, "cannot write\n");
      exit(1);
    }

  return res;
}

static void
  write_header(int fd, OZ_Object obj)
{
  OZ_ObjectAll all;

  (int)all = (int)obj - (obj->head.e + 1) * sizeof(OZ_HeaderRec);

  this_write(fd, (char *)&arch_type, sizeof(int));
  this_write(fd, (char *)&all->head[0].h, sizeof(int));
}


static int
  write_object_all(int fd, OZ_Object obj, int global)
{ 
  int size, i, offset;
  OZ_ObjectAll all, buf;
  int *s;
  
  (int)all = (int)obj - (obj->head.e + 1) * sizeof(OZ_HeaderRec);

  offset = size  
    = sizeof(OZ_ObjectAllRec) + all->head[0].h * sizeof(OZ_ObjectRec);

  s = (int *)malloc(sizeof(int) * all->head[0].h);

  buf = (OZ_ObjectAll)malloc(size);
  bcopy((char *)all, (char *)buf, size);

  for (i =0; i < all->head[0].h; i++)
    {
      (int)all->head[i + 1].d = offset;
      s[i] = - all->head[i + 1].h;
      all->head[i + 1].h = -2;
      offset += s[i];
    }

  (int)all->head[0].d = OZ_LOCAL_OBJECT;
#ifdef 0
  (int)all->head[0].d = 10;
#endif

  /* allocate `monitor' area */
  all->head[0].t = offset;
  offset += sizeof (monitor);

  (int)all->head[0].e = offset;

  size = this_write(fd, (char *)all, size);

  for (i = 0; i < all->head[0].h; i++)
    {
      size += this_write(fd, (char *)buf->head[i + 1].d, s[i]);
    }
  
  /* allocate `monitor' area */
  size += this_write (fd, monitor, sizeof (monitor));

  return size;
}

static int
  write_object_static(int fd, OZ_StaticObject obj)
{ 
  int size;

  (int) obj->head.d = OZ_STATIC_OBJECT;
  size = this_write(fd, (char *)obj, obj->head.e);
  return size;
}

static int
  write_object_array(int fd, OZ_Array obj)
{ 
  int size;

  size = this_write(fd, (char *)obj, obj->head.e);
  return size;
}

static int
  write_object(int fd, OZ_Header h, int global)
{
  if (h->h > 0)
    {
      return write_object_array(fd, (OZ_Array) h);
    }
  else
    {
      if (h->h == -1)
	{
	  return write_object_static(fd, (OZ_StaticObject) h);
	}
      else
	{
	  return write_object_all(fd, (OZ_Object) h, global);
	}
    }
} 

/* 
 * global functions
 */

OZ_ClassInfo
  LoadClass(char *oid)
{

  int fd, i, n, offset;
  OZ_ClassInfo class;
  OZ_ClassPart part;
  char filename[256];

  sprintf(filename, "%s/%s/private.r", class_path, oid);

  if ((fd = open(filename, O_RDONLY, 0644)) < 0) 
    {
      fprintf(stderr, "CT: cannot read-open the file[%s]\n", filename);
      exit(1);
    }
  read(fd, (char *)&n, sizeof(int));
  class = (OZ_ClassInfo) malloc(n);
  read(fd, (char *)class, n);
  close(fd);
  for (i = 0; i < class->number_of_parts; i++) 
    {
      offset = (int)class->parts[i];
      offset += (int)class;
      class->parts[i] = (OZ_ClassPart)offset;
    }

  return class;
}

void
WriteObjects(char *oid)
{
  ObjectList obj = obj_list;
  int i, fd;
  char filename[256];

  sprintf(filename, "%s", oid);

  unlink(filename);

  if ((fd = open(filename, O_CREAT | O_WRONLY, 0644)) < 0)
    {
      fprintf(stderr, "cannot open file:%s\n", filename);
      exit(1);
    }

  bzero (monitor, sizeof (monitor));

  /* header info. */
  write_header(fd, global_obj);

  write_object(fd, (OZ_Header)global_obj, 1);

  while (obj && obj->next)
    {
      write_object(fd, (OZ_Header)obj->obj, 0);
      obj = obj->next;
    }

  close(fd);
}

void
  AppendList(OZ_Header obj, char *label)
{
  ObjectList buf;

  buf = (ObjectList) malloc(sizeof(ObjectListRec));
  buf->obj = obj;
  buf->label = (char *)malloc(strlen(label) + 1);
  strcpy(buf->label, label);
  if (obj->h == -1)
    count++;
  else if (obj->h < -1)
    count += (obj->e + 1);
  buf->offset = ++count;
  buf->next = NULL;

  if (!obj_list)
    obj_list = buf;
  else
    obj_list_tail->next = buf;

  obj_list_tail = buf;
}

void
  SetAllocInfo(OZ_AllocateInfo info, OZ_ClassInfo class, int part_no)
{
  info->data_size_protected = class->parts[part_no]->info.data_size_protected;
  info->data_size_private = class->parts[part_no]->info.data_size_private;
  info->number_of_pointer_protected
    = class->parts[part_no]->info.number_of_pointer_protected;
  info->number_of_pointer_private
    = class->parts[part_no]->info.number_of_pointer_private;
  info->zero_protected = class->parts[part_no]->info.zero_protected;
  info->zero_private = class->parts[part_no]->info.zero_private;
}

void
AppendPtrList(int *addr, char *label)
{
  PtrList buf = ptr_list;

  buf = (PtrList) malloc(sizeof(PtrListRec));
  buf->addr = addr;
  buf->label = (char *)malloc(strlen(label) + 1);
  strcpy(buf->label, label);
  buf->next = NULL;

  if (!ptr_list)
    {
      ptr_list = buf;
    }
  else
    {
      ptr_list_tail->next = buf;
    }
  ptr_list_tail = buf;
}

void
  SetPtrs()
{
  PtrList ptr = ptr_list;

  while (ptr)
    {
      if ((*ptr->addr = get_offset(ptr->label)) < 0)
	{
	  fprintf(stderr, "illegal offset value\n");
	  exit(1);
	}
      ptr = ptr->next;
    }
}

OID
  ConvertClassID(char *str)
{
  int l, h;

  sscanf(str, "%08x%08x", &l, &h);
  return (long long)((long long)l << 32) + (h & 0xffffffff);
}

OZ_Array
  CreateArray(int type_size, int size, char *label)
{
  OZ_Array obj;
  int t_size = sizeof (OZ_HeaderRec) + type_size * size;

  if (t_size % 8)
    t_size += 8 - (t_size % 8);

  obj = (OZ_Array)malloc(t_size);
  bzero(obj, t_size);
  obj->head.e = t_size;
  (int) obj->head.d = OZ_ARRAY;
#ifdef 0
  (int) obj->head.d = 8;
#endif
  obj->head.h = size;

  return obj;
}
  
void
  Init()
{
  char *oz_root;

  obj_list = NULL;
  ptr_list = NULL;

  if (!(oz_root = getenv ("OZROOT")))
    {
      fprintf (stderr, "You must set OZROOT\n");
      exit (1);
    }

#if 0
  if (!(class_path = getenv("OZCLASSPATH")))
    {
      fprintf(stderr, "OZCLASSPATH not defined\n");
      exit(0);
    }
#else
  class_path = (char *) malloc (strlen (oz_root) + 15 + 1);
  sprintf (class_path, "%s/lib/boot-class", oz_root);
#endif
}

OID
  Str2OID(char *str)
{
  int l, h;

  sscanf(str, "%08x%08x", &l, &h);
  return (long long)((long long)l << 32) + (h & 0xffffffff);
}

OID
  Str2OIDwith(char *str)
{
  int l, h;
  char id[256];

  sprintf(id, "%s%s", ids, str);
  sscanf(id, "%08x%08x", &l, &h);
  return (long long)((long long)l << 32) + (h & 0xffffffff);
}

void
  CreateIDs(int argc, char **argv)
{
  if (argc < 4 || strlen(argv[1]) != 4 || strlen(argv[2]) != 4 
      || strlen (argv[3]) != 6)
    {
      fprintf(stderr, "usage: build [arch_ID:4] [cite_ID: 4] [exec_ID:6]\n");
      exit(1);
    }

  sscanf(argv[1], "%d", &arch_type);

  sprintf(ids, "%s%s", argv[2], argv[3]);
}

void
  CreateGlobal()
{
}

void
  CalcGlobalSize(OZ_Object obj)
{
  count = obj->head.e + 1;
  global_obj = obj;
}
