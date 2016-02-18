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

static char buf[1024];

static void print_var (OO_Symbol);

static void
  print_scqf (char *buf, int qual)
{
  if (qual & QF_UNSIGNED)
    {
      strcat (buf, "unsigned ");
    }

  if (qual & QF_CONST)
    {
      strcat (buf, "const ");
    }
    
  if (qual & SC_GLOBAL)
    {
      strcat (buf, "global ");
    }
}

static void
  print_access_ctrl(OO_ClassType cl)
{
  OO_List list;

  if (list = cl->public_list) 
    {
      Emit (stdout, "public: ");
      while (list)
	{
	  if (list != cl->public_list)
	    Emit (stdout, ", ");
	  Emit (stdout, "%s", list->car->symbol_rec.string);
	  list = (OO_List) list->cdr;
	}
      Emit (stdout, ";\n");
    }

  if (list = cl->protected_list) 
    {
      Emit (stdout, "protected: ");
      while (list)
	{
	  if (list != cl->protected_list)
	    Emit (stdout, ", ");
	  Emit (stdout, "%s", list->car->symbol_rec.string);
	  list = (OO_List) list->cdr;
	}
      Emit (stdout, ";\n");
    }

  if (list = cl->constructor_list) 
    {
      Emit (stdout, "constructor: ");
      while (list)
	{
	  if (list != cl->constructor_list)
	    Emit (stdout, ", ");
	  Emit (stdout, "%s", list->car->symbol_rec.string);
	  list = (OO_List) list->cdr;
	}
      Emit (stdout, ";\n");
    }

  if (list = cl->exception_list) 
    {
      Emit (stdout, "exception: ");
      while (list)
	{
	  if (list != cl->exception_list)
	    Emit (stdout, ", ");
	  Emit (stdout, "%s", list->car->symbol_rec.string);
	  list = (OO_List) list->cdr;
	}
      Emit (stdout, ";\n");
    }
}

static void
  print_symbol(OO_Symbol sym)
{
  strcat (buf, sym->string);
}

static void
  print_type (OO_Type type, OO_Symbol var, int val)
{
  char _buf[1024], vid[17], *p;

  switch (type->id) 
    {
    case TO_SimpleType:
      strcat(buf, type->simple_type_rec.symbol->string);

      break;
    case TO_ClassType:
      sprintf(vid, "0x%08x%08x", 
	      (int) (type->class_type_rec.class_id_public >> 32),
	      (int) (type->class_type_rec.class_id_public & 0xffffffff));
      p = GetVID2 (vid, -1);
      if (*buf != '\0')
	{
	  if (p)
	    {
	      strcat(buf, vid);
	      strcat(buf, " (");
	      strcat(buf, p);
	      strcat(buf, ")");
	    }
	  else
	    {
	      strcat(buf, vid);
	    }
	}
      else
	{
	  if (p)
	    sprintf (buf, "%s (%s)", vid, p);
	  else
	    sprintf (buf, "%s", vid);
	}

      break;
    case TO_TypeSCQF:
      print_scqf (buf, type->type_scqf_rec.scqf);
#if 0
      if (type->type_scqf_rec.scqf & SC_GLOBAL)
	sprintf (buf, "%08x%08x",
		 (int) (type->type_scqf_rec.type->class_type_rec.class_id_public >> 32),
		 (int) (type->type_scqf_rec.type->class_type_rec.class_id_public & 0xffffffff));
      else
	strcat(buf, type->type_scqf_rec.type->simple_type_rec.symbol->string);
#endif
      print_type (type->type_scqf_rec.type, var, val);
      break;
    case TO_TypeProcess:
      print_type (type->type_process_rec.type, var, val);
      strcpy(_buf, buf);
      if (type->type_process_rec.type->id == TO_TypeArray)
	sprintf(buf, "(@%s)", _buf);
      else
	sprintf(buf, "@%s", _buf);
      break;
    case TO_TypeArray:
      print_type (type->type_array_rec.type, var, val);
      strcpy(_buf, buf);
      if (type->type_array_rec.type->id == TO_TypeProcess)
	sprintf(buf, "(%s[])", _buf);
      else
	sprintf(buf, "%s[]", _buf);
      break;
    }
}

static char *
  print_access (int access)
{
  switch (access)
    {
    case PUBLIC_PART:
      return "public";
    case PROTECTED_PART:
      return "protected";
    case CONSTRUCTOR_PART:
      return "constructor";
    }
}

static void
  print_defined_part (OO_Symbol sym)
{
  *buf = '\0';
  print_type ((OO_Type) sym->class_part_defined, NULL, 1);
  Emit (stdout, "defined in `%s'\n", buf);
}

static void
  print_var(OO_Symbol var)
{
#if 1
  Emit (stdout, "%s : %s\n", var->string, print_access (var->access));
  EmitIndentDown ();
#endif

  *buf = '\0';
  print_type (var->type, var, 1);
#if 1
  Emit (stdout, "type: %s\n", buf);
#else
  Emit (stdout, "%s ", buf);

  Emit (stdout, "%s;\n", var->string);
  EmitIndentDown ();
  Emit (stdout, "%s\n", print_access (var->access));
#endif
  
  print_defined_part (var);

  EmitIndentUp ();
}

static void
  print_method_qual(int qual)
{
  int comma = 0;

  if (qual & MQ_LOCKED)
    {
      if (comma)
	strcat(buf, ", ");
#if 0
      else
	strcat(buf, " : ");
#endif

      strcat(buf, "locked");
      comma = 1;
    }

  if (qual & MQ_ABSTRACT)
    {
      if (comma)
	strcat(buf, ", ");
#if 0
      else
	strcat (buf, " : ");
#endif

      strcat (buf, "abstract");
      comma = 1;
    }

  if (qual & MQ_GLOBAL)
    {
      if (comma)
	strcat (buf, ", ");
#if 0
      else
	strcat (buf, " : ");
#endif

      strcat (buf, "global");
      comma = 1;
    }
}

static void
  print_method_arg (OO_TypeMethod method)
{
  OO_List list = method->args;
  OO_Symbol sym;
  OO_Type type;
  char _buf[1024];

  while (list)
    {
      sym = (OO_Symbol) list->car;
      if (sym->type->id == TO_TypeSCQF)
	{
	  print_scqf (buf, sym->type->type_scqf_rec.scqf);
	  type = sym->type->type_scqf_rec.type;
	}
      else
	{
	  type = sym->type;
	}

      print_type (type, sym, -1);

      if (list = (OO_List) list->cdr)
	{
	  strcat(buf, ", ");
	}
    }
}

static void
  print_method (OO_Symbol member)
{
  OO_TypeMethod method = &member->type->type_method_rec;

#if 1  
  Emit (stdout, "%s : %s\n", 
	member->string, print_access (member->access));
  EmitIndentDown ();
  
  *buf = '\0';
  print_method_qual(method->qualifier);
  Emit (stdout, "qualifier: %s\n", buf);
  
  *buf = '\0';
  print_type (method->type, member, 0);
  Emit (stdout, "return type: %s\n", buf);
  
  *buf = '\0';
  print_method_arg(method); 
  Emit (stdout, "args: %s\n", buf);
  
  print_defined_part (member);

  Emit (stdout, "slot #2: %d\n", member->slot_no2);
#else
  *buf = '\0';
  print_type (method->type, member, 0);

  Emit (stdout, "%s %s (", buf, member->string);

  *buf = '\0';
  print_method_arg(method); 
  Emit (stdout, "%s) ", buf);
  
  *buf = '\0';
  print_method_qual(method->qualifier);
  if (*buf) {
    Emit (stdout, ": %s\n", buf);
  } else {
    Emit (stdout, "\n", buf);
  }
  EmitIndentDown ();
  
  Emit (stdout, "%s\n", print_access (member->access));
  print_defined_part (member);

  Emit (stdout, "slot #2: %d\n", member->slot_no2);
#endif

  EmitIndentUp ();
}

static void
  print_member (OO_List list, int command)
{
  OO_Symbol member;

  if (!list)
    return;

  while (list)
    {
      PrintMember (&list->car->symbol_rec, command, 0);
      list = &list->cdr->list_rec;
    }
}

static void
  print_parents (OO_ClassType cl)
{
  OO_List parents = cl->class_part_list;
  OO_RenameAlias ra;
  char vid[17], *p;

  Emit (stdout, "parents :\n");
  if (!parents)
    return;

  EmitIndentDown ();

  while (parents)
    {
      sprintf (vid, "0x%08x%08x",
	       (int) (parents->car->class_type_rec.class_id_protected >> 32),
	       (int) (parents->car->class_type_rec.class_id_protected 
		      & 0xffffffff));
      if (p = GetVID2 (vid, -1))
	Emit (stdout, "%s (%s)\n", vid, p);
      else
	Emit (stdout, "%s\n", vid);
      parents = &parents->cdr->list_rec;
    }
  EmitIndentUp ();
}

static void
  print_class_before (OO_ClassType cl, int public)
{
  EmitIndentReset ();

  buf[0] = '\0';
  if (cl->qualifiers == SC_ABSTRACT)
    printf ("abstract ");

  Emit (stdout, "class : %s (%08x%08x)\n", cl->symbol->string,
	(int) (cl->class_id_public >> 32),
	(int) (cl->class_id_public & 0xffffffff));

  EmitIndentDown ();
  print_parents(cl);
  Emit (stdout, "\n");
}

static void
  print_class_after ()
{
  EmitIndentUp ();
}

void
  PrintClass (OO_ClassType cl, int command, int public)
{
  print_class_before (cl, public);

  Emit (stdout, "members :\n");
  EmitIndentDown ();

  if (command == 0 || command == 1 || command == 3)
    print_member (cl->public_list, command);
  if (command == 0 || command == 2 || command == 3)
    print_member (cl->constructor_list, command);
  if (command == 0 || command > 3)
    print_member (cl->protected_list, command);

  EmitIndentUp ();
  
  print_class_after ();
}

void
  PrintMember (OO_Symbol member, int command, int only_name)
{
  if (only_name)
    {
      Emit (stdout, "%s\n", member->string);
      return;
    }

  if (member->is_variable)
    {
      if (command != 5) 
	print_var (member);
    }
  else 
    {
      if (command != 6)
	print_method (member);
    }
}
