%{
#include "ozc.h"

#include "lang/sysexcept.h"
#include "type.h"
#include "class-list.h"
#include "generic.h"
#include "error.h"
#include "block.h"
#include "y.tab.h"
#include "emit-method.h"
#include "lang/school.h"
#include "class.h"

static char *class_name;
static char *shared_name;

static int start_depth;
static int previous;

static void copy_to_buffer (char *);
static void count_newline (char *);
static int reserved (char *);
static void create_inline_buf ();
static void append_inline_buf (char *);
static int check_sys_except (char *);

static int inline_buf_len;
static int inline_buf_max;
static char *inline_buf;
#define INLINE_BUF_SIZE 1024

static int maybe_class_name = 0;
static int this_is_class_name = 0;
static int inside_method_args = 0;
static int only_identifier = 0;
static int not_class_name = 0;
static int maybe_member = 0;

static int last = 0;
static YYSTYPE last_yylval;

static int inside_inline = 0;

#define CLASSNAME_SIZE 256
static int class_name_len;

#undef YY_DECL
#define YY_DECL int orig_yylex ()

typedef struct ReservedWordRec 
{
  char *name;
  int token;
} ReservedWordRec, *ReservedWord;

static ReservedWordRec reserved_words[] = {
  "abort", ABORT, 
  "abortable", ABORTABLE,
  "abstract", ABSTRACT,
  "alias", ALIAS,
  "break", BREAK,
  "case", CASE,
  "cell", CELL,
  "char", CHAR,
  "class", CLASS,
  "condition", CONDITION,
  "constructor", CONSTRUCTOR,
  "continue", CONTINUE,
  "debug", DEBUG,
  "default", DEFAULT,
  "detach", DETACH,
  "do", DO,
  "double", DOUBLE,
  "else", ELSE,
  "except", EXCEPT,
  "float", FLOAT,
  "for", FOR,
  "fork", FORK,
  "global", GLOBAL,
  "if", IF,
  "inline", INLINE,
  "int", INT,
  "join", JOIN,
  "kill", KILL,
  "length", LENGTH,
  "locked", LOCKED,
  "long", LONG,
  "narrow", NARROW,
  "oid", OID,
  "protected", PROTECTED,
  "public", PUBLIC,
  "raise", RAISE,
  "record", RECORD,
  "rename", RENAME,
  "return", RETURN,
  "self", SELF,
  "shared", SHARED,
  "short", SHORT,
  "signal", SIGNAL,
  "signalall", SIGNALALL,
  "static", STATIC,
  "switch", SWITCH,
  "try", TRY,
  "unsigned", UNSIGNED,
  "until", UNTIL,
  "void", VOID,
  "wait", WAIT,
  "while", WHILE,
};

#define RESERVED_SIZE sizeof (reserved_words) / sizeof (ReservedWordRec)

%}
%start COMMENT BLOCK 
%%
<INITIAL>";" return ';';
<INITIAL>"{" { 
	  BlockDepth++;

	  if (Debug > 1)
	    fprintf (stderr, "enter block %d (%d)\n", yylineno, BlockDepth);

	  if (inside_inline || (!Pass && BlockDepth == 2))
	    {
	      if (Debug > 1)
		fprintf(stderr, "*** enter method body\n");
	      
	      start_depth = BlockDepth - 1; 
	      BEGIN BLOCK;
	    } 
	  if (!inside_inline)
	    return '{'; 
	  else
  	    create_inline_buf ();
	}
<INITIAL>"}" {
	  if (Debug > 1)
	    fprintf (stderr, "exit block %d (%d)\n", yylineno, BlockDepth);
	  BlockDepth--;
	  return '}';
	}
<INITIAL>"(" return '(';
<INITIAL>")" return ')';
<INITIAL>"[" return '[';
<INITIAL>"]" return ']';
<INITIAL>"<" return '<';
<INITIAL>":" return ':';
<INITIAL>"::" return DCOLON;
<INITIAL>"?" return '?';
<INITIAL>"+" return '+'; 
<INITIAL>"-" return '-'; 
<INITIAL>"*" return '*'; 
<INITIAL>"/" return '/'; 
<INITIAL>"%" return '%'; 
<INITIAL>"|" return '|'; 
<INITIAL>"^" return '^'; 
<INITIAL>"&" return '&'; 
<INITIAL>"~" return '~'; 
<INITIAL>"!" return '!'; 
<INITIAL>"." return '.';
<INITIAL>"," return ',';
<INITIAL>"=" { yylval.val = OP_EQ; return ASSIGN; }
<INITIAL>"+=" { yylval.val = OP_PLUS; return ASSIGNOP; }
<INITIAL>"-=" { yylval.val = OP_MINUS; return ASSIGNOP; }
<INITIAL>"*=" { yylval.val = OP_MULT; return ASSIGNOP; }
<INITIAL>"/=" { yylval.val = OP_DIV; return ASSIGNOP; }
<INITIAL>"%=" { yylval.val = OP_MOD; return ASSIGNOP; }
<INITIAL>"&=" { yylval.val = OP_AND; return ASSIGNOP; }
<INITIAL>"|=" { yylval.val = OP_IOR; return ASSIGNOP; }
<INITIAL>"^=" { yylval.val = OP_EOR; return ASSIGNOP; }
<INITIAL>"<<=" { yylval.val = OP_LSHIFT; return ASSIGNOP; }
<INITIAL>">>=" { yylval.val = OP_RSHIFT; return ASSIGNOP; }
<INITIAL>"||" return OR;
<INITIAL>"&&" return AND;
<INITIAL>"==" return EQUAL;
<INITIAL>"!=" return NEQUAL;
<INITIAL>"<=" return LE;
<INITIAL>">=" return GE;
<INITIAL>"++" return INCR;
<INITIAL>"--" return DECR;
<INITIAL>"->" return INVOKE;
<INITIAL>"=>" return INST;
<INITIAL>">" return '>';
<INITIAL>"@" return '@';
<INITIAL>[ \t] ;
<INITIAL>\n yylineno++;
<INITIAL>"0" { copy_to_buffer (yytext); return ZERO; }
<INITIAL>[1-9][0-9]* { copy_to_buffer (yytext); return INTEGER; }
<INITIAL>[1-9][0-9]*[uU] { copy_to_buffer (yytext); return UINTEGER; }
<INITIAL>[1-9][0-9]*[lL][lL] { copy_to_buffer (yytext); return LLINTEGER; }
<INITIAL>[1-9][0-9]*[uU][lL][lL] { copy_to_buffer (yytext); return ULLINTEGER; }
<INITIAL>[0-9]+"."[0-9]+ { copy_to_buffer (yytext); return DOUBLEVAL; }
<INITIAL>[0-9]"."[0-9]+[eE]-[1-9]+ { copy_to_buffer (yytext); return DOUBLEVAL; }
<INITIAL>[0-9]+"."[0-9]+[fF] { copy_to_buffer (yytext); return FLOATVAL; }
<INITIAL>[0-9]"."[0-9]+[eE]-[1-9]+[fF] { copy_to_buffer (yytext); return FLOATVAL; }
<INITIAL>"__"[0-9a-zA-Z]{16} { copy_to_buffer (yytext) ; return IDENTIFIER; }
<INITIAL>[_a-zA-Z][_0-9a-zA-Z]* { 
	  int ret; 

	  not_class_name = 0;

	  if (ret = reserved (yytext))
	    return ret;
	  
	  if (shared_name)
	    {
	      OO_ClassType cl = NULL;
	      OO_List vars; 

	      not_class_name = 1;

	      if (Mode == NORMAL)
		{
		  long long vid = str2oid (GetVID (shared_name, PUBLIC_PART));
		  cl = GetClassFromUsedList (vid);
		}

	      vars = cl ? cl->public_list : NULL;
	      while (vars)
		{
		  if (!strcmp (vars->car->symbol_rec.string, yytext))
		    {
		      shared_name = NULL;
		      yylval.str = (char *)&vars->car->symbol_rec;
		      return IDENTIFIER;
		    }
		  vars = &vars->cdr->list_rec;
		}
	      
	      if (Mode == NORMAL)
		FatalError ("shared member: `%s' not defined "
			    "in shared: `%s'.\n",
			    yytext, shared_name);
	      yylval.str = NULL;
	      shared_name = NULL;

	      return IDENTIFIER;
	    }

	  copy_to_buffer (yytext);

          if (SearchTypeParameter (yytext))
	    return TYPEPARAM;

	  else if (check_sys_except (yytext))
            not_class_name = 1;

	  else if (BlockDepth > 1)
	    {
	      if (GetMethod (yytext, ThisClass, 0, PRIVATE_PART) ||
		  GetSymbol (yytext))
		not_class_name = 1;
	    }

	  return IDENTIFIER;
	}
<INITIAL>0[0-7]* { copy_to_buffer (yytext); return OCT; }
<INITIAL>0[0-7]*[uU] { copy_to_buffer (yytext); return UOCT; }
<INITIAL>0[0-7]*[lL][lL] { copy_to_buffer (yytext); return LLOCT; }
<INITIAL>0[0-7]*[uU][lL][lL] { copy_to_buffer (yytext); return ULLOCT; }
<INITIAL>0[xX][0-9a-fA-F]* { copy_to_buffer (yytext); return HEX; }
<INITIAL>0[xX][0-9a-fA-F]*[uU] { copy_to_buffer (yytext); return UHEX; }
<INITIAL>0[xX][0-9a-fA-F]*[lL][lL] { copy_to_buffer (yytext); return LLHEX; }
<INITIAL>0[xX][0-9a-fA-F]*[uU][lL][lL] { copy_to_buffer (yytext); return ULLHEX; }
<INITIAL>\'.\'|\'\\.\' { copy_to_buffer (yytext); return CONST_CHAR; }
<INITIAL>\"(\\.|[^\"])*\" {
	  copy_to_buffer (yytext);
	  count_newline (yytext);
	  return STRING;
	}
<INITIAL>"//"[^\n]*\n yylineno++;
<INITIAL>"/*" {
  	  BEGIN COMMENT;
	  previous = INITIAL;
	}
<COMMENT>[^*\n]*
<COMMENT>[^*\n]*\n      yylineno++;
<COMMENT>"*"+[^*/\n]*
<COMMENT>"*"+[^*/\n]*\n yylineno++;
<COMMENT>"*"+"/"        BEGIN previous;
<BLOCK>"//"[^\n]*\n yylineno++;
<BLOCK>"/*" {
  	  BEGIN COMMENT;
	  previous = BLOCK;
	}
<BLOCK>([^'"/{}]|\/[^*/])+ {
  	  if (Debug > 1)
    	    fprintf (stderr, "%d (%d) : %s\n", yylineno, BlockDepth, yytext);
	  
	  if (inside_inline && Pass && Mode == NORMAL)
	    append_inline_buf (yytext);

	  count_newline (yytext);
	}
<BLOCK>\'.\'|\'\\.\' { 
	  if (inside_inline && Pass && Mode == NORMAL)
	    append_inline_buf (yytext);
	}
<BLOCK>\"(\\.|[^\"])*\" {
	  if (inside_inline && Pass && Mode == NORMAL)
	    append_inline_buf (yytext);

	  count_newline (yytext);
	}
<BLOCK>"{" { 
	  BlockDepth++; 
	  if (Debug > 1)
	    fprintf(stderr, "\t*** enter block (depth = %d)\n", BlockDepth);

	  if (inside_inline && Pass && Mode == NORMAL)
	    append_inline_buf (yytext);
	}
<BLOCK>"}" { 
	  BlockDepth--;
	  if (BlockDepth == start_depth) 
	    {
	      if (Debug > 1)
		fprintf(stderr, "*** exit method body\n");

	      BEGIN INITIAL; 

	      if (inside_inline)
		{
	          inside_inline = 0;
		  yylval.str = inline_buf;
		  return INLINE_CONTENTS;
		}
	      else
          	return '}';
	    } 
	 else
	  {
	    if (Debug > 1)
	      fprintf(stderr, "\t*** exit block (depth = %d)\n", 
		      BlockDepth + 1);
  	    if (inside_inline && Pass && Mode == NORMAL)
  	      append_inline_buf (yytext);
	  }
	}
<<EOF>>	{
  	  yy_init = 1;
  	  return EOF;
	}
%%
static int
reserved (char *str)
{
  int l, h, m, ret;

  for (l = 0, h = RESERVED_SIZE; l < h; ) 
    {
      m = (l + h) >> 1;
      if ((ret = strcmp (reserved_words[m].name, str)) < 0)
	l = m + 1;
      else if (ret > 0)
	h = m;
      else
	{
	  yylval.str = reserved_words[m].name;
	  return reserved_words[m].token;
	}
    }
  return 0;
}

static void
copy_to_buffer (char *str)
{
  char *buf = (char *) malloc (strlen (str) + 1);
  if (!buf)
    {
      fprintf (stderr, "cannot alloc\n");
      exit (1);
    }
  strcpy (buf, str);
  yylval.str = buf;
}  

static void
count_newline (char *str)
{
  while (*str)
    if (*str++ == '\n')
      yylineno++;
}

static void
append_to_class_name (char *str)
{
  int len = strlen (class_name) + strlen (str);

  if (len > class_name_len)
    {
      while (len > class_name_len)
	class_name_len += CLASSNAME_SIZE;

      class_name = (char *) realloc (class_name, class_name_len + 1);
    }

  strcat (class_name, str);
}

static int
create_generic_class_name ()
{
  int t = 0, t2;
  int gen_param, space = 0;
  char *base = yylval.str;

  class_name_len = CLASSNAME_SIZE;
  class_name = (char *) malloc (class_name_len + 1);

  strcpy (class_name, yylval.str);
  free (yylval.str);

  gen_param = 1;
  append_to_class_name ("<");
  
  while (gen_param)
    {
      char c;
      
      if (t != IDENTIFIER)
	t = orig_yylex ();
      else
	t = t2;

      switch (t)
	{
	case '>':
	  gen_param--;
	  append_to_class_name (">");
	  break;
	case '<':
	  gen_param++;
	  append_to_class_name ("<");
	  break;
	case ',':
	  append_to_class_name (",");
	  break;
	case IDENTIFIER:
	  if (((t2 = orig_yylex ()) == '>' || t2 == ',') && !Pass && 
	      Mode == GENERIC_PARAMS)
	    SetTypeParameter (yylval.str);

	  append_to_class_name (yylval.str);
	  free (yylval.str);
	  break;
	case TYPEPARAM:
	  if (Generic)
	    append_to_class_name ("*");

	  else
	    append_to_class_name (yylval.str);

	  free (yylval.str);
	  break;
	default:
	  if (t == GLOBAL)
	    append_to_class_name ("global ");

	  else if (t == UNSIGNED)
	    append_to_class_name ("unsigned ");

	  else if (t == '@' || t == '(' || t == ')' || t == '[' || t == ']')
	    {
	      char *p = &class_name[strlen (class_name)];
	      if (!space)
		{
		  *p++ = ' ';
		  space = 1;
		}
	      *p++ = t;
	      *p = 0;
	    }
	  else if (t != CHAR && t != SHORT && t != INT && t != LONG &&
		   t != FLOAT && t != DOUBLE && t != CONDITION)
	    {
	      FatalError ("maybe \"%s\" not defined\n", base);
	      return t;
	    }
	  
	  else
	    {
	      append_to_class_name (yylval.str);
	      free (yylval.str);
	    }
	}
    }
  
  return 0;
}

int
yylex ()
{
  int t;

  if (last)
    {
      t = last;
      last = 0;
      yylval = last_yylval;
    }
  else
    t = orig_yylex ();

  if (BlockDepth < 2 && t == ';')
    only_identifier = 0;

  if (BlockDepth == 1 && (t == ':' || t == '{' || t == ';'))
    inside_method_args = 0;

  if (t == NARROW)
    this_is_class_name = 1;

  else if (t == TYPEPARAM && this_is_class_name)
    this_is_class_name = 0;

  else if (t == INLINE)
    inside_inline = 1;

  else if (t == PUBLIC || t == PROTECTED || t == CONSTRUCTOR ||
	   t == RENAME || t == ALIAS)
    only_identifier = 1;

  else if ((!inside_inline && t == '{') || 
	   (BlockDepth == 1 && 
	    (t == '}' || ((t == '(' || t == ',') && inside_method_args) ||
	     not_class_name)) ||
	   t == ';')
    {
      maybe_class_name = 1;
    }

  else if (t == IDENTIFIER && !not_class_name && !only_identifier &&
	   !maybe_member)
    {
      int block_depth = BlockDepth;

      class_name = yylval.str;
      t = orig_yylex ();

      /* for Generic Class */
      if (t == '<')
	{
	  if (t = create_generic_class_name ())
	    return t;
	  t = orig_yylex ();
	}

      /* for Module */
      else if (t == '.')
	{
	  char *tmp;
	  
	  maybe_member = 0;
	  t = orig_yylex ();
	  tmp 
	    = (char *) malloc (strlen (class_name) + strlen (yylval.str) + 2);
	  sprintf (tmp, "%s.%s", class_name, yylval.str);
	  free (class_name);
	  class_name = tmp;
	  t = orig_yylex ();
	}

      else if (block_depth != 0 && !this_is_class_name && t != DCOLON &&
	       (!maybe_class_name || t == '('))
	{
	  if (t == '(')
	    inside_method_args = 1;

	identifier:
	  last = t;
	  last_yylval = yylval;
	  yylval.str = class_name;
	  return IDENTIFIER;
	  /* not reached */
	}

      this_is_class_name = 0;
      maybe_class_name = 0;
      AddClassList (class_name);
	       
      /* for Shared */
      if (t == DCOLON)
	{
	  shared_name = class_name;
	  yylval.str = class_name;
	  return SHAREDNAME;
	}

      else
	{
	  last = t;
	  last_yylval = yylval;
	  yylval.str = class_name;
	  return CLASSNAME;
	}
    }
  else if (t == IDENTIFIER && not_class_name == 1)
    {
      char *tmp = yylval.str;

      if ((last = orig_yylex ()) == '.')
	maybe_member = 1;
      last_yylval = yylval;
      yylval.str = tmp;
    }

  else if (maybe_class_name && t != GLOBAL)
    maybe_class_name = 0;

  else if (maybe_member)
    maybe_member = 0;

  return t;
}

static void
  append_inline_buf (char *str)
{
  if ((inline_buf_len += strlen (str)) > inline_buf_max)
    {
      while (inline_buf_len > inline_buf_max)
        {
          inline_buf_max += INLINE_BUF_SIZE;
        }
      inline_buf = (char *) realloc (inline_buf, inline_buf_max + 1);
      if (!inline_buf)
        {
          perror (0);
          abort ();
        }
    }

  strcat (inline_buf, str);
}

static void
  create_inline_buf ()
{
  inline_buf_len = 0;
  inline_buf_max = INLINE_BUF_SIZE;
  inline_buf = (char *) malloc (inline_buf_max + 1);
  bzero (inline_buf, inline_buf_max + 1);
}

static int
check_sys_except (char *name)
{
  int i;

  for (i = 0; i < NO_SYS_EXCEPTION; i++)
    {
      if (!strcmp (sys_except[i], name))
	return 1;
    }

  return 0;
}
