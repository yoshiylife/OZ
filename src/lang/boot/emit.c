/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <sys/file.h>
#include <string.h>

#include "object.h"

static FILE *file_main_c, *file_c, *file_h;
static Record r_list = NULL;

extern char *class_path;

#define emit_h(format, args...) \
  fprintf(file_h, format, ## args)

#define emit_main_c(format, args...) \
  fprintf(file_main_c, format, ## args)

#define emit_c(format, args...) \
  fprintf(file_c, format, ## args)

/*
 * private functions
 */

static TypePart read_type (Class c, int p_no);

static TypePart
load_record(char *name, Record before)
{
  Record r;
  int l, h;

  r = (Record)malloc(sizeof(RecordRec));

  r->name = (char *)malloc(strlen(name) + 1);
  strcpy(r->name, name);

#if 0
  sscanf (name, "%08x%08x", &l, &h);
  sprintf (name, "%08x%08x", l, h + 2);
#endif

  r->type = read_type((Class)name, -1);
  r->next = NULL;

  if (r_list)
    {
      before->next = r;
    }
  else
    {
      r_list = r;
    }

  return r->type;
}

static TypePart
search_record(char *type)
{
  Record r = r_list, before = NULL;
  char name[17], *index;

  index = strstr(type, RECORD_TYPE);

  strncpy(name, index - strlen(RECORD_TYPE) - 16 + 1, 16);
  name[16] = '\0';

  while (r)
    {
      if (!strcmp(r->name, name))
	return r->type;
      before = r;
      r = r->next;
    }

  return load_record(name, before);
}

static char *
search_type_members(char *type, char *member)
{
  TypePart t;
  TypeList list;
  char *name, *index, *r;

  t = search_record(type);

  name = (char *)malloc(strlen(member) + 1);
  strcpy(name, member);

  index = strchr(name, '.');
  if (index)
    {
      *index = '\0';
    }

  list = t->list;

  while (list)
    {
      if (!strcmp(list->name, &name[2]))
	{
	  if (index)
	    {
	      r = search_type_members(list->type, ++index);
	      free(name);
	      return r;
	    }
	  else
	    {
	      free(name);
	      return list->type;
	    }
	}
      list = list->next;
    }

  fprintf(stderr, "this class has not member:%s\n", name);
  exit(1);
}

static char *
search_type(Class c, char *name, char *member)
{
  Type t = c->type;
  int i;

  for (i = 0; i < c->info->number_of_parts; i++)
    {
      TypeList list = t->part[i]->list;

      while (list)
	{
	  if (!strcmp(list->name, name))
	    {
	      if (member)
		{
		  return search_type_members(list->type, member);
		}
	      else
		{
		  return list->type;
		}
	    }
	  list = list->next;
	}
    }

  fprintf(stderr, "this class has not member:%s\n", name);
  exit(1);
}

static int
search_part_no(Class c, char *name)
{
  Type t = c->type;
  int i;

  for (i = c->info->number_of_parts - 1; i >= 0; i--)
    {
      TypeList list = c->type->part[i]->list;

      while (list)
	{
	  if (!strcmp(list->name, name))
	    {
	      return i;
	    }
	  list = list->next;
	}
    }
  return -1;
}

static void
  emit_exp(Exp exp, Object o)
{
  char *pos;
  int p;
  Object array;
  
  if (!exp)
    return;

  switch (exp->op)
    {
    case OP_VALUE:
      emit_c("%s", (char *)exp->exp1);
      break;
    case OP_UMINUS:
      emit_c("-");
      emit_exp(exp->exp1, o);
      break;
    case OP_NOT:
      emit_c("~");
      emit_exp(exp->exp1, o);
      break;
    case OP_EXP:
      emit_c("(");
      emit_exp(exp->exp1, o);
      emit_c(")");
      break;
    case OP_PLUS:
      emit_exp(exp->exp1, o);
      emit_c(" + ");
      emit_exp(exp->exp2, o);
      break;
    case OP_MINUS:
      emit_exp(exp->exp1, o);
      emit_c(" - ");
      emit_exp(exp->exp2, o);
      break;
    case OP_MUL:
      emit_exp(exp->exp1, o);
      emit_c(" * ");
      emit_exp(exp->exp2, o);
      break;
    case OP_DIV:
      emit_exp(exp->exp1, o);
      emit_c(" / ");
      emit_exp(exp->exp2, o);
      break;
    case OP_MOD:
      emit_exp(exp->exp1, o);
      emit_c(" % ");
      emit_exp(exp->exp2, o);
      break;
    case OP_VAL:
      if ((pos = strstr ((char *)exp->exp1, ":")))
	{
	  p = atoi (pos + 1);
	  ((char *)exp->exp1)[strlen ((char *)exp->exp1) - strlen (pos)] 
	    = '\0';
	}
      else
	{
	  p = search_part_no(o->class, (char *)exp->exp1);
	}
      if (p < 0)
	fprintf (stderr, "`%s' not defined in `%s'\n", 
		 (char *)exp->exp1, o->name);
      emit_c("INSTANCE(obj_%d_p_%d, %s)", o->count, p, (char *)exp->exp1);
      if (exp->member)
	{
	  emit_c(".%s", exp->member);
	}
      break;
    case OP_ARRAY_VAL:
      array = (Object)exp->exp1;
      emit_c("ELEMENT(obj_%d, %s, %s)", 
	     array->count, array->oid, (char *)exp->exp2);
      if (exp->member)
	{
	  emit_c(".%s", exp->member);
	}
      break;
    case OP_BR:
      emit_c("{ ");
      emit_exp(exp->exp1, o);
      emit_c(" }");
      break;
    case OP_COM:
      emit_exp(exp->exp1, o);
      emit_c(", ");
      emit_exp(exp->exp2, o);
      break;
    case OP_OR:
      emit_exp(exp->exp1, o);
      emit_c(" | ");
      emit_exp(exp->exp2, o);
      break;
    case OP_EOR:
      emit_exp(exp->exp1, o);
      emit_c(" ^ ");
      emit_exp(exp->exp2, o);
      break;
    case OP_AND:
      emit_exp(exp->exp1, o);
      emit_c(" & ");
      emit_exp(exp->exp2, o);
      break;
    case OP_LSHIFT:
      emit_exp(exp->exp1, o);
      emit_c(" << ");
      emit_exp(exp->exp2, o);
      break;
    case OP_RSHIFT:
      emit_exp(exp->exp1, o);
      emit_c(" >> ");
      emit_exp(exp->exp2, o);
      break;
    }
}

static void
open_files()
{
  char filename[256];

  sprintf(filename, "objects_main.c");
  if (!(file_main_c = fopen(filename, "w")))
    {
      fprintf(stderr, "cannot open file:%s\n", filename);
      exit(1);
    }

  sprintf(filename, "objects.c");
  if (!(file_c = fopen(filename, "w")))
    {
      fprintf(stderr, "cannot open file:%s\n", filename);
      exit(1);
    }

  sprintf(filename, "objects.h");
  if (!(file_h = fopen(filename, "w")))
    {
      fprintf(stderr, "cannot open file:%s\n", filename);
      exit(1);
    }
}

static void
close_files()
{
  fclose(file_main_c);
  fclose(file_c);
  fclose(file_h);
}

static void
emit_classes()
{
  Class c = c_list;
  int i;

  while (c)
    {
      if (c->kind == T_RECORD)
	{
	  c = c->next;
	  continue;
	}

      else
	{
	  for (i = 0; i < c->info->number_of_parts; i++)
	    emit_h("#include \"%s/private.h\"\n", 
		   c->type->part[i]->cid);
	  c = c->next;
	}
    }

  emit_h("\n");
}

static void
emit_records ()
{
  Record r = r_list;

  while (r)
    {
      emit_h("#include \"%s/public.h\"\n", 
	     r->name);
      r = r->next;
    }

  emit_h("\n");
}

static void
emit_header_info()
{
  emit_h("#include <oz++/object-image.h>\n\n");
  emit_h("#ifndef  _OBJECT_IMAGE_COMPILE_\n");
  emit_h("#define  _OBJECT_IMAGE_COMPILE_\n");
  emit_h("#endif  _OBJECT_IMAGE_COMPILE_\n\n");
}

static void
emit_label(Object o)
{
  if (o->g == o)
    {
      emit_h("#define L_%s \"%s\"\n", o->name, o->oid);
      emit_h("#define L_%s_local_%s \"%s\"\n", o->name, o->name, o->oid);
    }
  else
    {
      if (o->class)
	{
	  emit_h("#define L_%s_local_%s \"%s_local_%s\"\n", 
		 o->g->name, o->name, o->g->name, o->name);
	}
      else
	{
	  emit_h("#define L_%s_array_%s \"%s_array_%s\"\n", 
		 o->g->name, o->name, o->g->name, o->name);
	}
    }
}

static void
emit_main_start()
{
  emit_main_c("#include \"objects.h\"\n\n");

  emit_main_c("main(int argc, char **argv)\n");
  emit_main_c("{\n");

  emit_main_c("\tCreateIDs(argc, argv);\n");
}

static void
emit_main_end()
{
  emit_main_c("\treturn 0;\n");
  emit_main_c("}\n");
}

static void
emit_class_declaration()
{
  Class c = c_list;

  while (c)
    {
/* 94.7.27
      emit_c("static OZ_ClassInfo class_%s = NULL;\n", 
	     c->type->part[c->info->number_of_parts - 1]->cid);
*/
      emit_c("static OZ_ClassInfo class_%s = NULL;\n", 
	     c->cid);
      c = c->next;
    }
  emit_c("\n");
}

OZ_ClassInfo
  load_class(char *oid)
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

static char *
set_type (char *type)
{
  char *buf;

  switch (*type)
    {
    case 'c':
    case 'C':
      buf = (char *) malloc (5);
      strcpy (buf, "char");
      break;
    case 's':
    case 'S':
      buf = (char *) malloc (6);
      strcpy (buf, "short");
      break;
    case 'i':
    case 'I':
      buf = (char *) malloc (4);
      strcpy (buf, "int");
      break;
    case 'l':
    case 'L':
      buf = (char *) malloc (10);
      strcpy (buf, "long long");
      break;
    case 'f':
      buf = (char *) malloc (10);
      strcpy (buf, "long long");
      break;
    case 'd':
      buf = (char *) malloc (10);
      strcpy (buf, "long long");
      break;
    case 'z':
      buf = (char *) malloc (13);
      strcpy (buf, "OZ_Condition");
      break;
    case '@':
      buf = (char *) malloc (13);
      strcpy (buf, "OZ_ProcessID");
      break;
    case 'G':
      buf = (char *) malloc (4);
      strcpy (buf, "OID");
      break;
    case 'R':
      buf = (char *) malloc (29);
      strcpy (buf, "OZ");
      strncat (buf, (char *) (type + 1), 16);
      strcat (buf, "Record_Rec");
      break;
    case 'o':
      buf = (char *) malloc (16);
      strcpy (buf, "OZ_StaticObject");
      break;
    case 'O':
      buf = (char *) malloc (10);
      strcpy (buf, "OZ_Object");
      break;
    case '*':
      buf = (char *) malloc (9);
      strcpy (buf, "OZ_Array");
      break;
    }

  return buf;
}

static TypePart
read_type(Class c, int p_no)
{
  FILE *fp;
  char filename[256], buf1[256], buf2[256];
  TypePart tp;
  TypeList list, before;
  OID cid;
  int l, h;
  int i, num, junk;

  if (p_no < 0)
    {
      sprintf(filename, "%s/%s/private.d", class_path, (char *)c);
    }
  else
    {
      cid = c->info->parts[p_no]->cid;
      sprintf(filename, "%s/%08x%08x/private.d", 
	      class_path, (int)(cid >> 32), (int)(cid & 0xffffffff));
    }

  if (!(fp = fopen(filename, "r")))
    {
      fprintf(stderr, "cannot open file:(%s)\n", filename);
      exit(1);
    }

  fscanf(fp, "%d %d %d", &num, &junk, &junk);

  tp = (TypePart)malloc(sizeof(TypePartRec));

  if (p_no >= 0)
    {
      tp->part_no = p_no;
      tp->cid = (char *)malloc(16 + 1);
      sprintf(tp->cid, "%08x%08x", (int)(cid >> 32), (int)(cid & 0xffffffff));
    }

  before = tp->list = NULL;

  for (i = 0; i < num; i++)
    {
      int len;
      char name[256], type[256];
      int s = 0;
      int ast = 0;

      fscanf(fp, "%s %d %d %s", name, &junk, &junk, type);

#if 0
      if (!strcmp(buf1, "struct"))
	{
	  s = T_STRUCT;
	  fscanf(fp, "%s ", buf1);
	}
      else 
	{
	  if (!strcmp(buf1, "union"))
	    {
	      s = T_UNION;
	      fscanf(fp, "%s ", buf1);
	    }
	  else
	    {
	      s = 0;
	    }
	}
#endif

      list = (TypeList)malloc(sizeof(TypeListRec));
      list->next = NULL;

#if 0
      switch (s)
	{
	case T_STRUCT:
	  list->type = (char *)malloc(strlen(buf1) 
				      + strlen("struct ") + 1 + ast);
	  sprintf(list->type, "struct %s", buf1);
	  break;
	case T_UNION:
	  list->type = (char *)malloc(strlen(buf1) 
				      + strlen("union ") + 1 + ast);
	  sprintf(list->type, "union %s", buf1);
	  break;
	default:
	  set_type (list->type, type);
	  break;
	}
#endif
      list->type = set_type (type);

#if 0
      while (ast)
	{
	  strcat(buf1, "*");
	  ast--;
	}
#endif

      list->name = (char *)malloc(strlen(name) + 1);
      strcpy(list->name, name);

      if (!before)
	{
	  tp->list = list;
	}
      else
	{
	  before->next = list;
	}
      before = list;
    }

  fclose(fp);

  return tp;
}

static void
load_class_info(Class c)
{
  int i;

  c->info = load_class(c->cid);

  c->type = (Type)malloc(sizeof(TypeRec) 
			 + sizeof(TypePart) 
			 * (c->info->number_of_parts - 1));

  for (i = 0; i < c->info->number_of_parts; i++)
    c->type->part[i] = read_type(c, i);
}

static void emit_declaration(Object);

static void 
emit_declaration_object(Object o)
{
  int i;

  emit_c("\tOZ%sAll obj_%d;\n", 
	 o->class->type->part[o->class->info->number_of_parts - 1]->cid, 
	 o->count);

  for (i = 0; i < o->class->info->number_of_parts; i++)
    {
      emit_c("\tOZ%sPart obj_%d_p_%d;\n", 
	     o->class->type->part[i]->cid, o->count, i);
    }

  emit_c("\n");
}

static void
emit_declaration_array(Object o)
{
  emit_c("\tOZ_Array obj_%d;\n\n", o->count);
}

static void
emit_declaration_static(Object o)
{
  emit_c("\tOZ%sStatic obj_%d_p_0;\n\n", o->class->cid, o->count);
}

static void
emit_declaration(Object o)
{
  Object l = o->locals;

  emit_declaration_object(o);

  while (l)
    {
      if (!l->class)
	{
	  emit_declaration_array(l);
	  l = l->next;
	  continue;
	}
      
      switch (l->class->kind)
	{
	case T_STATIC:
	  emit_declaration_static(l);
	  break;
	case T_RECORD:
	  break;
	default:
	  emit_declaration_object(l);
	  break;
	}
      l = l->next;
    }

  emit_c("\tInit();\n\n");
}

static void
emit_assign_array(Object o, InstanceVal inst)
{
  switch (inst->type)
    {
    case T_LOCAL:
      emit_c("\tAppendPtrList((int)&ELEMENT(obj_%d, %s, %d), L_%s_local_%s);\n", 
	     o->count, o->oid, inst->index, o->g->name, inst->val);
      break;
    case T_ARRAY:
      emit_c("\tAppendPtrList((int)&ELEMENT(obj_%d, %s, %d), L_%s_array_%s);\n", 
	     o->count, o->oid, inst->index, o->g->name, inst->val);
      break;
    case T_OID:
      emit_c("\tELEMENT(obj_%d, %s, %d) = Str2OID(\"%s\");\n", 
	     o->count, o->oid, inst->index, inst->val);
      break;
    case T_GLOBAL:
      emit_c("\tELEMENT(obj_%d, %s, %d) = Str2OIDwith(L_%s);\n", 
	     o->count, o->oid, inst->index, inst->val);
      break;
    case T_EXP:
      if (((Exp)inst->val)->op == OP_BR)
	{
	  emit_c("\t{\n");
	  if (inst->member)
	    {
	      emit_c("\t\t%s tmp = ", 
		     search_type_members(o->oid, inst->member));
	    }
	  else
	    {
	      emit_c("\t\t%s tmp = ", o->oid);
	    }
	  emit_exp((Exp)inst->val, o);
	  emit_c(";\n\t");
	}
      if (inst->member)
	{
	  emit_c("\tELEMENT(obj_%d, %s, %d).%s = ",
		 o->count, o->oid, inst->index, inst->member);
	}
      else
	{
	  emit_c("\tELEMENT(obj_%d, %s, %d) = ",o->count, o->oid, inst->index);
	}
      if (((Exp)inst->val)->op == OP_BR)
	{
	  emit_c("tmp;\n");
	  emit_c("\t}\n");
	}
      else
	{
	  emit_exp((Exp)inst->val, o);
	  emit_c(";\n");
	}
      break;
    case T_STR:
      emit_c("\tstrcpy(&ELEMENT(obj_%d, %s, 0), %s);\n", 
	     o->count, o->oid, inst->val);
      break;
    }
}

static void
emit_array(Object o)
{
  InstanceVal inst;

  if (o->type < (OID) 100)
    {
      emit_c("\tobj_%d = CREATE_ARRAY(obj_%d, %d, %d, L_%s_array_%s, \"%016x\");\n\n", 
	     o->count, o->count, 
	     oz_size_of_type[(int)o->type], (int)o->locals, 
	     o->g->name, o->name, (int)o->type);
    }
  else
    {
      emit_c("\tobj_%d = CREATE_ARRAY(obj_%d, sizeof(%s), %d, L_%s_array_%s, \"%08x%08x\");\n\n", 
	     o->count, o->count, o->oid, (int)o->locals, 
	     o->g->name, o->name, 
	     (int)(o->type >> 32), (int)(o->type & 0xffffffff));

    }

  inst = o->instance;
  while (inst)
    {
      emit_assign_array(o, inst);
      inst = inst->next;
    }

  emit_c("\n");
}

static void
emit_assign(Object o, int p_no, InstanceVal inst)
{
  int p;
  char *buf = strstr (inst->name, ":");
  
  if (buf)
    inst->name [strlen (inst->name) - strlen (buf)] = '\0';

  switch (inst->type)
    {
    case T_LOCAL:
      emit_c("\tAppendPtrList((int)&INSTANCE(obj_%d_p_%d, %s), L_%s_local_%s);\n", 
	     o->count, p_no, inst->name, o->g->name, inst->val);
      break;
    case T_ARRAY:
      emit_c("\tAppendPtrList((int)&INSTANCE(obj_%d_p_%d, %s), L_%s_array_%s);\n", 
	     o->count, p_no, inst->name, o->g->name, inst->val);
      break;
    case T_OID:
      emit_c("\tINSTANCE(obj_%d_p_%d, %s) = Str2OID(\"%s\");\n", 
	     o->count, p_no, inst->name, inst->val);
      break;
    case T_GLOBAL:
      emit_c("\tINSTANCE(obj_%d_p_%d, %s) = Str2OIDwith(L_%s);\n", 
	     o->count, p_no, inst->name, inst->val);
      break;
    case T_EXP:
      if (((Exp)inst->val)->op == OP_BR)
	{
	  emit_c("\t{\n");
	  emit_c("\t\t%s tmp = ", search_type(o->class, inst->name, inst->member));
	  emit_exp((Exp)inst->val, o);
	  emit_c(";\n\t");
	}
      if (inst->member)
	{
	  emit_c("\tINSTANCE(obj_%d_p_%d, %s).%s = ", 
		 o->count, p_no, inst->name, inst->member);
	}
      else
	{
	  emit_c("\tINSTANCE(obj_%d_p_%d, %s) = ", 
		 o->count, p_no, inst->name);
	}
      if (((Exp)inst->val)->op == OP_BR)
	{
	  emit_c("tmp;\n");
	  emit_c("\t}\n");
	}
      else
	{
	  emit_exp((Exp)inst->val, o);
	  emit_c(";\n");
	}
      break;
    }

  if (buf)
    inst->name [strlen (inst->name)] = ':';
}

static void
emit_instances_object(Object o)
{
  InstanceVal inst;
  int i;

  emit_c("\tobj_%d = CREATE_ALL(obj_%d, %s, %s, class_%s);\n\n", 
	 o->count, o->count, o->class->cid, 
	 o->class->type->part[o->class->info->number_of_parts - 1]->cid, 
	 o->class->cid);

  for (i = 0; i < o->class->info->number_of_parts; i++)
    {
      if (i == o->class->info->number_of_parts - 1)
	{
	  if (o->g == o)
	    {
	      emit_c("\tobj_%d_p_%d = CREATE_PART(%s, obj_%d, %d, class_%s, L_%s);\n\n",
		     o->count, i, o->class->type->part[i]->cid, o->count, i,
		     o->class->cid, o->g->name);
	    }
	  else
	    {
	      emit_c("\tobj_%d_p_%d = CREATE_PART(%s, obj_%d, %d, class_%s, L_%s_local_%s);\n\n",
		     o->count, i, o->class->type->part[i]->cid, o->count, i,
		     o->class->cid, o->g->name, o->name);
	    }
	}
      else
	{
	  emit_c("\tobj_%d_p_%d = CREATE_PART(%s, obj_%d, %d, class_%s, 0);\n\n",
		 o->count, i, o->class->type->part[i]->cid, o->count, i,
		 o->class->cid);
	}
    }


  inst = o->instance;
  while (inst)
    {
      char *buf;
      
      if ((buf = strstr (inst->name, ":")))
	{
	  emit_assign(o, atoi (buf + 1), inst);
	}
      inst = inst->next;
    }

  for (i = 0; i < o->class->info->number_of_parts; i++)
    {
      inst = o->instance;
      while (inst)
	{
	  char *buf;
	  int num;

	  if (!(buf = strstr (inst->name, ":")))
	    {
	      if ((num = search_part_no(o->class, inst->name)) == i)
		emit_assign(o, i, inst);
	      else if (num < 0)
		fprintf (stderr, "`%s' not found in `%s'\n", 
			 inst->name, o->name);

	    }
	  inst = inst->next;
	}
    }

  emit_c("\n");
}

static void
emit_instances_static(Object o)
{
  InstanceVal inst;

  emit_c("\tCREATE_STATIC(%s, obj_%d_p_0, class_%s, L_%s_local_%s);\n\n", 
	 o->class->cid, o->count, o->class->cid, o->g->name, o->name);

  inst = o->instance;
  while (inst)
    {
      emit_assign(o, 0, inst);
      inst = inst->next;
    }

  emit_c("\n");
}

static void
emit_instances(Object o)
{
  switch (o->class->kind)
    {
    case T_STATIC:
      emit_instances_static(o);
      break;
    case T_RECORD:
      break;
    default:
      emit_instances_object(o);
      break;
    }
}

static void
emit_local_objects(Object obj)
{
  Object l = obj->locals;

  while (l)
    {
      if (l->ref)
	{
	  if (l->class)
	    {
	      emit_label(l);
	      emit_instances(l);
	    }
	  else
	    {
	      emit_label(l);
	      emit_array(l);
	    }
	}
      l = l->next;
    }
}

static void
emit_objects()
{
  Object o = g_list;

  emit_c("#include \"objects.h\"\n\n");

  emit_class_declaration();

  while (o)
    {
      emit_c("create_object_%s()\n{\n", o->oid);

      emit_main_c("\n\tcreate_object_%s();\n", o->oid);

      emit_label(o);
      
      emit_declaration(o);

      emit_local_objects(o);

      emit_c("\tCreateGlobal();\n\n");
 
      emit_instances(o);

      emit_c("\tCalcGlobalSize(&obj_%d->head[%d]);\n\n", 
	     o->count, o->class->info->number_of_parts);

      emit_c("\tSetPtrs();\n");
      
      emit_c("\tWriteObjects(\"%s\");\n", o->oid);
      
      emit_c("}\n\n");

      o = o->next;
    }
}

static void
load_class_infos()
{
  Class c = c_list;

  while (c)
    {
      if (c->kind != T_RECORD)
	{
	  load_class_info(c);
	}
      c = c->next;
    }
}

/*
 * global functions
 */

void
EmitFile()
{
  if (!g_list)
    return;

  load_class_infos();

  open_files();
  
  emit_header_info();
  emit_classes();
  emit_records();
  
  emit_main_start();
  
  emit_objects();

  emit_main_end();
      
  close_files();
}
