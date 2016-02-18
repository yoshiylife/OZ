%{
#include "ozc.h"

#include "type.h"
#include "exp.h"
#include "class.h"
#include "common.h"
#include "block.h"
#include "symbol.h"
#include "error.h"
#include "class-list.h"
#include "class-z.h"
#include "generic.h"
#include "emit-method.h"
#include "emit-header.h"

#include "emit-stmt.h"
#include "stmt.h"

char *yyfile;
int yylineno = 1;

int BlockDepth = 0;
int Error = 0;

static int cur_type, cur_m_type = TC_None;
static int cur_qual = 0, m_qual = 0, cur_m_qual = 0;
static char *cur_type_str, *cur_m_type_str;

static OO_Expr cur_obj;

static char *concat (char *, char *, char *);
static char *create_quals (int);
static int create_class (char *, int);
static void create_method (int, char *, int, MethodSymbol, int, int);
static OO_Symbol create_var (TypedSymbol, OO_Expr);
static void after_exception (OO_List);
static int emit_exit_except (int);
static int check_sys_except (char *);
%}
%token INLINE
%token CLASS
%token PUBLIC
%token PROTECTED
%token CONSTRUCTOR
%token UNSIGNED  
%token LOCKED
%token GLOBAL
%token ABSTRACT STATIC RECORD SHARED
%token RENAME
%token ALIAS
%token ASSIGN OR AND EQUAL NEQUAL LE GE INCR DECR UPLUS
%token UMINUS LSHIFT RSHIFT INVOKE INST PARE FORK JOIN 
%token DETACH ABORT KILL ABORTABLE WAIT SIGNAL SIGNALALL LENGTH NARROW OM
%token UNTIL
%token TRY EXCEPT RAISE RETURN
%token <str> BREAK CONTINUE 
%token WHILE DO FOR
%token CASE DEFAULT
%token IF ELSE SWITCH 
%token SELF DCOLON 
%token <str> OID CELL INLINE_CONTENTS
%token <str> TYPEPARAM
%token <val> ASSIGNOP 
%token <str> INTEGER LLINTEGER CONST_CHAR STRING OCT HEX LLHEX DOUBLEVAL FLOATVAL LLOCT ULLOCT ZERO
%token <str> UINTEGER ULLINTEGER UHEX ULLHEX UOCT
%token <str> IDENTIFIER CHAR INT LONG SHORT
%token <str> FLOAT DOUBLE CONDITION VOID SHAREDNAME CLASSNAME
%type <str> type quals_type strs
%type <str> uinteger integer ulong long exp_var var 
%type <str> simple_quals_type class_quals_type
%type <val> process processes non_zero_processes arrays array class_sc
%type <tsym> vars
%type <msym> m_members 
%type <exp> exp exp_value exp_comma exp_no_comma exp_or_null inst_option 
%type <list> args member_lists arg_list exception_label_for_raise
%type <stmt> exception_label exception_labels debug_stmt
%type <sym> arg exception_name exception_name_not_default
%type <stmt> block block_contents stmts not_comp_stmts stmt not_comp_stmt
%type <stmt> exp_stmt select_stmt iterate_stmt jump_stmt except_stmt c_stmt
%type <stmt> concur_stmt comp_stmt label_stmt 
%type <list> if_body 
%type <exp> label exp_with_block exp_with_block_content
%type <stmt> except_body
%nonassoc IF
%nonassoc ELSE
%left ',' DEBUG
%right ASSIGN ASSIGNOP
%right '?' ':' 
%left OR
%left AND
%left '|' 
%left '^' 
%left '&' 
%left EQUAL NEQUAL
%left '<' LE '>' GE
%left LSHIFT RSHIFT
%left '+' '-'
%left '*' '/' '%'
%right '!' '~' INCR DECR UPLUS UMINUS LENGTH FORK JOIN NARROW
%left PARE '[' INST INVOKE OM '.' 
%union 
{
  int val;
  char *str;
  TypedSymbol tsym;
  MethodSymbol msym;
  OO_Expr exp;
  OO_List list;
  OO_Symbol sym;
  OO_Statement stmt;
}
%%
file 
  : inlines class_def 
	{ 
	  if (Mode != NORMAL && Mode != GENERIC_PARAMS &&
	      (Pass || Part != PRIVATE_PART))
	    {
	      if (!Error)
		PrintClassList ();
	    }
  	  BlockDepth = 0;
	  if (ThisClass->cl == TC_Object)
	    EmitMethodsAfter ();

#if 0
	  else if (ThisClass->cl == TC_StaticObject)
	    EmitMethodsAfterInStatic ();

	  else if (ThisClass->cl == TC_Record)
	    EmitImportedForRecord ();
#else
	  else 
	    EmitMethodsAfterInStatic ();
#endif
	}
  ;
inlines
  : /* empty */
  | inlines c_stmt
	{
	  EmitStatement ($2);
	}
  | error ';' { yyerrok; }
  ;
class_def
  : class_sc CLASSNAME
	{
	  if (Mode == GENERIC_PARAMS)
	    {
	      if (!Error)
		PrintTypeParameters ();
	      return;
	    }
	  if (create_class ($2, $1))
	    return;
	}
  parents 
	{
	  if (!Pass && (Mode == NORMAL || Part == PRIVATE_PART))
	    SetParents ();  

	  switch (Mode)
	    {
	    case NORMAL:
	      if (!Pass)
		{
		  if (Part != PUBLIC_PART && CheckParents () < 0)
		    FatalError ("the definition of parent classes "
				"has changed\n");
		}
	      else
		EmitMethodsBefore (PrivateOutputFileC);
	      break;
	    case THIS_CLASS:
	    case USED_CLASSES:
	    case ALL_CLASSES:
	      break;
	    case INHERITED_CLASSES:
	      if (!Error)
		PrintClassList ();
	      return;
	    }
	}
		'{' class_body '}' 
  | SHARED CLASSNAME
	{
	  if (Mode == GENERIC_PARAMS)
	    {
	      if (!Error)
		PrintTypeParameters ();
	      return;
	    }
	  if (create_class ($2, SC_SHARED))
	    return;

	  if (PrivateOutputFileC)
	    {
	      fclose (PrivateOutputFileC);
	      PrivateOutputFileC = NULL;
	    }
	}
		'{' shared_body '}'
  | STATIC CLASS CLASSNAME
	{
	  if (Mode == GENERIC_PARAMS)
	    {
	      if (!Error)
		PrintTypeParameters ();
	      return;
	    }
	  if (create_class ($3, SC_STATIC))
	    return;

	  if (Mode == NORMAL && Pass)
	    EmitMethodsBefore (PrivateOutputFileC);
	}
		'{' static_class_body '}' 
  | RECORD CLASSNAME
	{
	  if (Mode == GENERIC_PARAMS)
	    {
	      if (!Error)
		PrintTypeParameters ();
	      return;
	    }
	  if (create_class ($2, SC_RECORD))
	    return;
	  
	  if (Mode == NORMAL && Pass)
	    EmitMethodsBefore (PrivateOutputFileC);
	}
		'{' record_body '}'
  ;
class_sc
  : CLASS
	{
	  $$ = 0;  
	}
  | ABSTRACT CLASS
	{
	  $$ = SC_ABSTRACT;  
	}
  ;
parents
  : /* empty */
  | ':' parent_lists
  ;
parent_lists
  : parent
  | parent_lists ',' parent
  ;
parent
  : CLASSNAME
	{	
	  if (!Pass && (Mode == NORMAL ||  Part == PRIVATE_PART))
	    AddParent ($1);
	  
	  if ((!Pass && Mode == NORMAL) || Mode == USED_CLASSES)
	    RemoveFromClassList ($1);

	  free ($1);
	}
  | CLASSNAME
	{	
	  if (!Pass && (Mode == NORMAL ||  Part == PRIVATE_PART))
	    AddParent ($1);

	  if ((!Pass && Mode == NORMAL) || Mode == USED_CLASSES)
	    RemoveFromClassList ($1);

	  free ($1);
	}
  '(' rename_alias_lists ')'
  ;
rename_alias_lists
  : rename_alias
  | rename_alias_lists rename_alias
  | error ';' { yyerrok; }
  ;
rename_alias
  : RENAME IDENTIFIER IDENTIFIER ';'
	{  
	  if (!Pass && (Mode == NORMAL ||  Part == PRIVATE_PART))
	    AddRenameAlias ($2, $3, RA_RENAME);
	  free ($2);
	  free ($3);
	}
  | ALIAS IDENTIFIER IDENTIFIER ';'
	{  
	  if (!Pass && (Mode == NORMAL ||  Part == PRIVATE_PART))
	    AddRenameAlias ($2, $3, RA_ALIAS);
	  free ($2);
	  free ($3);
	}
  ;
class_body
  : access_ctrls 
	{
	  if (!Pass && (Mode == NORMAL || Part == PRIVATE_PART))
	    {
	      if (Mode == NORMAL && Part != PUBLIC_PART && 
		  CheckAccessCtrls () < 0)
		FatalError ("the definition of access controls has changed\n");
	      SetParentMethods ();
	    }
	}
    member_decls
	{
          if (!Pass && Mode == NORMAL)
	    CheckMembers ();
	}
  ;
shared_body
  : shared_member_decls
  ;
static_class_body
  : access_ctrls_no_protected
	{
	  if (!Pass && Mode == NORMAL)
	    {
	      if (Part != PUBLIC_PART && CheckAccessCtrls () < 0)
		FatalError ("the defiinition of access controls "
			    "has changed\n");
	    }
	}
		member_decls
	{
          if (!Pass && Mode == NORMAL)
	    CheckMembers ();
	}
  ;	
record_body
  : record_member_decls
  ;
access_ctrls
  : /* empty */
  | access_ctrls acess_ctrl_not_protected
  | access_ctrls acess_ctrl_protected
  ;
access_ctrls_no_protected
  : /* empty */
  | access_ctrls_no_protected acess_ctrl_not_protected
  ;
acess_ctrl_not_protected
  : PUBLIC ':' member_lists ';'
	{
	  if (!Pass)
	    {
	      CheckList (ThisClass->public_list, $3);
	      AppendList (&ThisClass->public_list, $3);
	    }
	}
  | CONSTRUCTOR ':' member_lists ';'
	{
	  if (!Pass)
	    {
	      CheckList (ThisClass->constructor_list, $3);
	      AppendList (&ThisClass->constructor_list, $3);
	    }
	}
  ;
acess_ctrl_protected
  : PROTECTED ':' member_lists ';'
	{
	  if (!Pass && Part != PUBLIC_PART)
	    {
	      CheckList (ThisClass->protected_list, $3);
	      AppendList (&ThisClass->protected_list, $3);
	    }
	}
  ;
member_lists
  : IDENTIFIER 
	{
  	  OO_Symbol sym = CreateSymbol ($1);
	  sym->class_part_defined = ThisClass;
	  $$ = CreateList ((OO_Object) sym, NULL);
	  free ($1);
	}
  | member_lists ',' IDENTIFIER 
	{
  	  OO_Symbol sym = CreateSymbol ($3);
	  sym->class_part_defined = ThisClass;
	  CheckSymInList ($1, sym);
	  $$ = AppendList (&$1, CreateList ((OO_Object) sym, NULL));
	  free ($3);
	}
  | error ';' { yyerrok; }
  | error ',' { yyerrok; }
  ;
member_decls
  : /* empty */
  | member_decls member_decl
  | error ';' { yyerrok; }
  | error '{' { yyerrok; }
	block_contents '}'
  | error ')' ';' { yyerrok; }
  ;
member_decl
  : member_var_decl
  | member_method_decl
  ;
member_method_decl
  : quals_type m_members ':' ABSTRACT m_quals_with_abstract ';'
	{
	  create_method (cur_m_qual, cur_m_type_str, cur_m_type, 
			 $2, m_qual | MQ_ABSTRACT, 0);
	}
  | IDENTIFIER '(' args ')' ':' ABSTRACT m_quals_with_abstract ';'
	{  
	  create_method (0, "int", TC_Int, 
			 CreateMethodSymbol (CreateTypedSymbol (0, 0, $1, 0), 
					     $3),
			 m_qual | MQ_ABSTRACT, 0);
	}
  | quals_type m_members m_quals
	{
	  create_method (cur_m_qual, cur_m_type_str, cur_m_type,
			 $2, m_qual, 1);
	}
		block
  | IDENTIFIER '(' args ')' m_quals 
	{ 
	  create_method (0, "int", TC_Int, 
			 CreateMethodSymbol (CreateTypedSymbol (0, 0, $1, 0),
					     $3),
			 m_qual, 1);
	}
		block
  ;
shared_member_decls
  : /* empty */
  | shared_member_decls shared_member_decl
  | error ';' { yyerrok; }
  | error ')' ';' { yyerrok; }
  ;
shared_member_decl
  : exception_decl ';'
  | constant_decl ';'
  ;
exception_decl
  : exception
  | exception_decl ',' exception
  ;
exception
  : IDENTIFIER '(' ')' 
	{ 
	  create_method (0, "int", TC_Int, 
			 CreateMethodSymbol (CreateTypedSymbol (0, 0, $1, 0), 
					     NULL),
			 m_qual, 0);
	}
  | IDENTIFIER '(' arg ')' 
	{ 
	  create_method (0, "int", TC_Int, 
			 CreateMethodSymbol (CreateTypedSymbol (0, 0, $1, 0),
					     CreateList ((OO_Object) $3, 0)),
			 m_qual, 0);
	}
  ;
constant_decl
  : simple_quals_type simple_vars_list_with_exp
	{
	}
  ;
simple_vars_list_with_exp
  : exp_vars
  | simple_vars_list_with_exp ',' exp_vars
  ;
record_member_decls
  : member_decls
	{
	  /* not implemented */
	}
  ;
quals_type
  : simple_quals_type
	{
	  $$ = $1;
	}
  | class_quals_type
	{
	  $$ = $1;
	}
  ;
simple_quals_type
  : quals type
	{ 
	  $$ = $2;
	}
  ;
class_quals_type
  : CLASSNAME
	{ 
	  cur_qual = 0;
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Object; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | GLOBAL CLASSNAME
	{ 
	  cur_qual = SC_GLOBAL; 
	  $$ = cur_type_str = $2; 
	  cur_type = TC_Object; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_qual = cur_qual;
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | TYPEPARAM
	{ 
	  cur_qual = 0;
	  
	  if (Generic)
	    {
	      $$ = cur_type_str = (char *) malloc (2);
	      strcpy (cur_type_str, "*");
	    }
	  else
	    $$ = cur_type_str = $1; 
	  cur_type = TC_Generic;
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | GLOBAL TYPEPARAM
	{ 
	  cur_qual = SC_GLOBAL;
	  
	  if (Generic)
	    {
	      $$ = cur_type_str = (char *) malloc (2);
	      strcpy (cur_type_str, "*");
	    }
	  else
	    $$ = cur_type_str = $2; 
	  cur_type = TC_Generic;
	  if (cur_m_type == TC_None)
	    {
	      cur_m_qual = cur_qual;
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  ;
quals
  : /* empty */ 
	{  
	  cur_qual = 0;
	}
  | UNSIGNED 
	{ 
	  cur_qual = QF_UNSIGNED; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_qual = cur_qual;
	    }
	}
  ;
type
  : CHAR 
	{ 
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Char; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | SHORT
	{ 
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Short; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | INT 
	{ 
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Int; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | LONG
	{ 
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Long; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | FLOAT 
	{ 
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Float; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | DOUBLE 
	{ 
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Double; 
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | CONDITION
	{ 
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Condition;
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  | VOID 
	{ 
	  $$ = cur_type_str = $1; 
	  cur_type = TC_Void;
	  if (cur_m_type == TC_None)
	    {
	      cur_m_type = cur_type;
	      cur_m_type_str = cur_type_str;
	    }
	}
  ;
arrays 
  : /* empty */ { $$ = 0; }
  | arrays array { $$ = $1 + $2; }
  ;
array
  : '[' ']' { $$ = 1; }
  ;
processes
  : /* empty */ { $$ = 0; }
  | non_zero_processes { $$ = $1; }
  ;
non_zero_processes
  : process { $$ = $1; }
  | non_zero_processes process { $$ = $1 + $2; }
  ;
process
  : '@' { $$ = 1; }
  ;
m_members
  : processes IDENTIFIER '(' args ')' arrays 
	{ 
	  $$ = CreateMethodSymbol (CreateTypedSymbol ($1, $6, $2, 0),
				   $4);
	  free ($2);
	}
  | non_zero_processes '(' m_members ')' arrays 
	{ 
	  $$ = CreateMethodSymbol (CreateTypedSymbol ($1, $5, 0, $3->tsym),
				   $3->arg);
	}
  ;
vars_list_noinit
  : vars_noinit
  | vars_list_noinit ',' vars_noinit
  ;
vars_noinit
  : vars
	{ 
	  OO_Symbol sym = create_var ($1, NULL);
	  if (sym && Part != PRIVATE_PART && Mode != NORMAL && 
	      sym->access > Part && cur_type == TC_Object)
	    RemoveFromClassList (cur_type_str);
	}
  ;
simple_vars_list
  : vars_only 
  | simple_vars_list ',' vars_only
  | exp_vars
  | simple_vars_list ',' exp_vars
  ;
vars_only 
  : vars
	{
	  create_var ($1, NULL);
	}
  ;
exp_vars
  : vars ASSIGN exp
	{ 
	  if (Mode != NORMAL)
	    create_var ($1, NULL);
	  else
	    create_var ($1, $3);
	}
  | vars ASSIGN exp_with_block
	{ 
	  if (Mode != NORMAL)
	    create_var ($1, NULL);
	  else
	    {
	      OO_ClassType cl = SearchClass (cur_type_str);

	      if (!cl || cl->cl != TC_Record)
		{
		  FatalError ("type of this symbol: %s not record\n",
			      $1->name);
		  create_var ($1, NULL);
		}
	      else
		create_var ($1, $3);
	    }
	}
  ;
class_vars_list
  : vars_only  
  | class_vars_list ',' vars_only 
  | exp_vars
  | class_vars_list ',' exp_vars
  | inst_init_vars
  | class_vars_list ',' inst_init_vars
  ;
inst_init_vars
  : vars INST IDENTIFIER '(' arg_list ')' inst_option
	{
	  if (Mode == NORMAL)
	    {
	      OO_Symbol sym = CreateSymbol ($1->name);
	      sym->type = CreateType (cur_qual, cur_type_str, cur_type, NULL);
	      DestroyTypedSymbol ($1);
	      cur_obj 
		= CreateExpMethodCall ((OO_Expr) sym, $3, $5,
				       CONSTRUCTOR_PART, 
				       $7);
	      create_var (NULL, cur_obj);
	    }
	  else
	    {
	      create_var ($1, NULL);
	    }
	}
	exp_invokes
  ;
exp_invokes
  : /* empty */
  | exp_invokes exp_invoke
  ;
exp_invoke
  : INVOKE IDENTIFIER '(' arg_list ')' 
	{
	  if (cur_obj && cur_obj->expr_common_rec.type->id == TO_ClassType &&
	      cur_obj->expr_common_rec.type->class_type_rec.cl == TC_Record)
	    FatalError ("cannot use '->' for record operator: %s\n", $2);

	  cur_obj = CreateExpMethodCall (cur_obj, $2, $4, 
					 PUBLIC_PART, NULL);
	}
  ;
inst_option
  : /* empty */
	{
	  $$ = NULL;	
	}
  | '@' exp %prec OM
	{
	  $$ = $2;
	}		
  ;
vars
  : processes var arrays 
	{ 
	  $$ = CreateTypedSymbol ($1, $3, $2, 0); 
	  free ($2);
	}
  | processes arrays 
	{ 
	  $$ = CreateTypedSymbol ($1, $2, NULL, 0); 
	}
  | non_zero_processes '(' vars ')' arrays 
	{ 
	  $$ = CreateTypedSymbol ($1, $5, 0, $3); 
	}
  ;
var
  : IDENTIFIER 
	{ 
	  $$ = $1;
	}
  ;
exp_with_block
  : '{' exp_with_block_content '}' 
	{ 
	  $$ = $2;
	}
  ;
exp_with_block_content
  : exp_with_block ',' exp_with_block
	{
	  OO_List list;

	  list = CreateList ((OO_Object) $1, (OO_Object) $3);

	  $$ = CreateExp2 ((OO_Expr) list, NULL, OP_COMMA2);
	}
  | exp_with_block ',' exp
	{
	  OO_List list;

	  list = CreateList ((OO_Object) $1, (OO_Object) $3);

	  $$ = CreateExp2 ((OO_Expr) list, NULL, OP_COMMA2);
	}
  | exp ',' exp_with_block
	{
	  OO_List list;

	  if ($1 && $1->id == TO_Comma)
	    list = AppendList (&$1->comma_rec.expr_list,
			       CreateList ((OO_Object) $3, NULL));
	  else
	    list = CreateList ((OO_Object) $1, (OO_Object) $3);

	  $$ = CreateExp2 ((OO_Expr) list, NULL, OP_COMMA2);
	}
  | exp
	{
	  if ($1)
	    {
	      $1->id = TO_Comma2;
	      $1->expr_common_rec.type = NULL;
	    }
	  $$ = $1;
	}
   ;
exp_or_null
  : /* empty */
	{
	  $$ = NULL;
	}
  | exp
	{
	  $$ = $1;
	}
  ;
exp
  : exp_no_comma
	{
	  $$ = $1;
	}
  | exp_comma
	{
	  $$ = $1;
	}
  ;
exp_no_comma
  : exp_value 
	{
	  $$ = $1;
	}
  | exp_var 
	{
	  if (Mode == NORMAL)
	    {
	      if ($1)
		{
		  if (!($$ = (OO_Expr) GetSymbol ($1)))
		    FatalError ("symbol: `%s' not defined\n", $1);
		} 
	      else
		$$ = (OO_Expr) Self;  
	    }
	  else
	    $$ = NULL;
	}
  | exp '.' IDENTIFIER	
	{
	  $$ = CreateExpMember ($1, $3);
	}
  | exp ASSIGN exp 
	{
	  $$ = CreateExpAssign ($1, $3, OP_EQ);
	}
  | exp ASSIGNOP exp 
	{
	  $$ = CreateExpAssign ($1, $3, $2);
	}
  | exp OR exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_OROR);
	}
  | exp AND exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_ANDAND);
	}
  | exp '|' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_IOR);
	}
  | exp '^' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_EOR);
	}
  | exp '&' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_AND);
	}
  | exp EQUAL exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_EQ);
	}
  | exp NEQUAL exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_NE);
	}
  | exp '<' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_LT);
	}
  | exp LE exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_LE);
	}
  | exp '>' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_GT);
	}
  | exp GE exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_GE);
	}
  | exp '<' '<' exp %prec LSHIFT
	{
	  $$ = CreateExp2 ($1, $4, OP_LSHIFT);
	}
  | exp '>' '>' exp %prec RSHIFT
	{
	  $$ = CreateExp2 ($1, $4, OP_RSHIFT);
	}
  | exp '+' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_PLUS);
	}
  | exp '-' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_MINUS);
	}
  | exp '*' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_MULT);
	}
  | exp '/' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_DIV);
	}
  | exp '%' exp 
	{
	  $$ = CreateExp2 ($1, $3, OP_MOD);
	}
  | '!' exp 
	{
	  $$ = CreateExp1 ($2, OP_EXCLAIM);
	}
  | '~' exp 
	{
	  $$ = CreateExp1 ($2, OP_TILDE);
	}
  | INCR exp 
	{
	  $$ = CreateExp1 ($2, OP_INC);
	}
  | exp INCR
	{
	  $$ = CreateExp0 ($1, OP_INC);
	}
  | DECR exp 
	{
	  $$ = CreateExp1 ($2, OP_DEC);
	}
  | exp DECR
	{
	  $$ = CreateExp0 ($1, OP_DEC);
	}
  | '+' exp %prec UPLUS
	{
	  $$ = CreateExp1 ($2, OP_PLUS);
	}
  | '-' exp %prec UMINUS 
	{
	  $$ = CreateExp1 ($2, OP_MINUS);
	}
  | exp '?' exp ':' exp
	{
	  $$ = CreateExp3 ($1, $3, $5);
	}
  | '(' exp ')' %prec PARE
	{
	  $$ = CreateExp1 ($2, OP_PARE);
	}
  | exp INVOKE IDENTIFIER '(' arg_list ')'
	{
	  if ($1 && $1->expr_common_rec.type && 
	      $1->expr_common_rec.type->id == TO_ClassType &&
	      $1->expr_common_rec.type->class_type_rec.cl == TC_Record)
	    FatalError ("cannot use '->' for record operator: %s\n", $3);

	  $$ = CreateExpMethodCall ($1, $3, $5, PUBLIC_PART, NULL);
	}
  | exp INST IDENTIFIER '(' arg_list ')' inst_option
	{
	  $$ = CreateExpMethodCall ($1, $3, $5, CONSTRUCTOR_PART, $7);
	}
  | IDENTIFIER '(' arg_list ')' 
	{
	  $$ = CreateExpMethodCall (NULL, $1, $3, PRIVATE_PART, NULL);
	}
  | exp '.' IDENTIFIER '(' arg_list ')' 
	{
	  $$ = CreateExpMethodCall ($1, $3, $5, PUBLIC_PART, NULL);
	}
  | LENGTH exp 
	{
	  $$ = CreateExp1 ($2, OP_LENGTH);
	}
  | exp '[' exp ']' 
	{
	  $$ = CreateExpArray ($1, $3);
	}
  | FORK exp
	{
	  $$ = CreateExpFork ($2);
	}
  | JOIN exp
	{
	  $$ = CreateExpJoin ($2);
	}
  | NARROW '(' CLASSNAME ',' exp ')'
	{
          OO_Symbol sym;

	  if (Mode == NORMAL)
	    {
	      sym = CreateSymbol ($3);
	      sym->type = CreateType (0, $3, TC_Object, NULL);
	      $$ = CreateExpNarrow  ((OO_Expr) sym, $5);
	    }
	  else
	    $$ = NULL;
	  free ($3);
	}
  | NARROW '(' TYPEPARAM ',' exp ')'
	{
          OO_Symbol sym;

	  if (Mode == NORMAL)
	    {
	      sym = CreateSymbol ($3);
	      sym->type = CreateType (0, $3, TC_Generic, NULL);
	      $$ = CreateExpNarrow  ((OO_Expr) sym, $5);
	    }
	  else
	    $$ = NULL;
	  free ($3);
	}
  ;
exp_comma
  : exp ',' exp
	{
	  OO_List list;

	  if ($1 && $1->id == TO_Comma)
	    list = AppendList (&$1->comma_rec.expr_list,
			       CreateList ((OO_Object) $3, NULL));
	  else
	    list = CreateList ((OO_Object) $1, (OO_Object) $3);

	  $$ = CreateExp2 ((OO_Expr) list, NULL, OP_COMMA);
	}
  ;
arg_list
  : /* empty */
	{
	  $$ = NULL;
	}
  | exp_no_comma
	{
	  if (Mode == NORMAL)
	    $$ = CreateList ((OO_Object) $1, NULL);
	  else
	    $$ = NULL;
	}
  | exp_comma 
	{
	  if (Mode == NORMAL)
	    $$ = $1->comma_rec.expr_list;
	  else
	    $$ = (OO_List) $1;
	}
  ;
exp_value
  : DOUBLEVAL
	{
	  $$ = CreateExpConstant (0, "double", TC_Double, $1);
	  free ($1);
	}
  | FLOATVAL
	{
	  $$ = CreateExpConstant (0, "float", TC_Float, $1);
	  free ($1);
	}
  | integer
	{
	  $$ = CreateExpConstant (0, "int", TC_Int, $1);
	  free ($1);
	}
  | ZERO
	{
	  $$ = CreateExpConstant (0, "int", TC_Zero, $1);
	  free ($1);
	}
  | uinteger
	{
	  $$ = CreateExpConstant (QF_UNSIGNED, "int", TC_Int, $1);
	  free ($1);
	}
  | long
	{
	  $$ = CreateExpConstant (0, "long", TC_Long, $1);
	  free ($1);
	}
  | ulong
	{
	  $$ = CreateExpConstant (QF_UNSIGNED, "long", TC_Long, $1);
	  free ($1);
	}
  | CONST_CHAR
	{
	  $$ = CreateExpConstant (0, "char", TC_Char, $1);
	  free ($1);
	}
  | CELL
	{
	  $$ = CreateExpConstant (0, NULL, TC_Object, $1);
	}
  | OID
	{
	  $$ = CreateExpConstant (SC_GLOBAL, NULL, TC_Object, $1);
	}
  | strs
	{
	  $$ = CreateExpConstant (0, NULL, -1, $1);
	  free ($1);
	}
  | SHAREDNAME IDENTIFIER
	{
	  free ($1);
	  $$ = (OO_Expr) $2;
	}
  ;
strs
  : STRING
	{
	  $$ = $1;
	}
  | strs STRING
	{
	  char *buf = (char *) malloc (strlen ($1) + strlen ($2) + 1);

	  sprintf (buf, "%s%s", $1, $2);
	  free ($1);
	  free ($2);
	  $$ = buf;
	}
  ;
integer
  : INTEGER 
	{
	  $$ = $1;  
	}	
  | HEX
	{
	  $$ = $1;  
	}	
  | OCT
	{
	  $$ = $1;  
	}	
  ;
uinteger
  : UINTEGER 
	{
	  $$ = $1;  
	}	
  | UHEX
	{
	  $$ = $1;  
	}	
  | UOCT
	{
	  $$ = $1;  
	}	
  ;
long
  : LLINTEGER
	{
	  $$ = $1;  
	}	
  | LLHEX
	{
	  $$ = $1;  
	}
  | LLOCT
	{
	  $$ = $1;  
	}
  ;
ulong
  : ULLINTEGER
	{
	  $$ = $1;  
	}	
  | ULLHEX
	{
	  $$ = $1;  
	}
  | ULLOCT
	{
	  $$ = $1;  
	}
  ;
exp_var
  : IDENTIFIER
	{  
	  $$ = $1;
	}
  | SELF
	{  
	  $$ = NULL;
	}
  ;
args
  : /* empty */
	{  
          $$ = NULL;
	}
  | arg
	{
	  $$ = CreateList ((OO_Object) $1, NULL);
	}
  | args ',' arg
	{
	  CheckSymInList ($1, $3);
	  $$ = AppendList (&$1, 
			   CreateList ((OO_Object) $3, NULL));
	}
  ;
arg
  : quals_type vars
	{
	  if (CurrentBlock == ThisClass->block)
	    CreateBlock ();
	  
	  $$ = AddVar(cur_qual, $1, cur_type, $2, NULL, 1);  
	  if (cur_type == TC_Generic || cur_type == TC_Object)
	    free ($1);
	  cur_qual = 0;
	}  
  ;
m_quals
  : /* empty */ 
  | ':' m_qual
  ;
m_qual
  : m_qualifier
  | m_qual ',' m_qualifier
  ;
m_qualifier
  : LOCKED { m_qual |= MQ_LOCKED; }
  | GLOBAL { m_qual |= MQ_GLOBAL; }
  ;
m_quals_with_abstract
  : /* empty */
  | ',' m_qual
  ;
block
  : '{' 
	{ 
	  $<stmt>$ = CreateCompoundStatement (CreateBlock ());
	}
  block_contents '}'
	{ 
	  $$ = SetCompoundStatement ((OO_CompoundStatement) $<stmt>2, $3);

	  if (BlockDepth == 1)
	    {
	      CheckReturnStatement ($$);

	      EmitStatement ($$);
#if 0
	      if (ThisClass->cl == TC_Record)
		EmitMethodAfter (PublicOutputFileH);
	      else
#endif
		EmitMethodAfter (PrivateOutputFileC);
	      DestroyStatement ($$);

	      if (CurrentMethod->type->type_method_rec.args)
		UpBlock ();
	      DestroyBlock ();
	    }
	  else
	    UpBlock ();
	}
  ;
block_contents 
  : var_decls stmts
	{
	  $$ = $2;
	}
  ;
var_decls
  : /* empty */
  | var_decls var_decl 
  | error ';' { yyerrok; }
  ;
var_decl
  : simple_quals_type simple_vars_list ';'
	{  
	  cur_qual = 0;
	  cur_m_qual = 0;
	  cur_m_type = TC_None;
	}
  | class_quals_type class_vars_list ';'
	{  
	  cur_qual = 0;
	  cur_m_qual = 0;
	  cur_m_type = TC_None;
	  free (cur_type_str);
	}
  ; 
member_var_decl
  : quals_type vars_list_noinit ';'
	{  
	  cur_qual = 0;
	  cur_m_qual = 0;
	  cur_m_type = TC_None;
	  if (cur_type == TC_Generic || cur_type == TC_Object)
	    free (cur_type_str);
	}
  ; 
stmts
  : /* emtpy */
	{
	  $$ = NULL;
	}
  | stmts stmt
	{
	  $$ = $1 ? $1 : $2;
	}
  ;
not_comp_stmts
  : /* empty */
	{
	  $$ = NULL;
	}
  | not_comp_stmts not_comp_stmt
	{
	  $$ = $1 ? $1 : $2;
	}
  ;
stmt
  : comp_stmt
	{
	  $$ = $1;
	}
  | not_comp_stmt
	{
	  $$ = $1;
	}
  ;
not_comp_stmt
  : ';'
	{
	  $$ = CreateExprStatement (NULL);
	}
  | exp_stmt
	{
	  $$ = $1;
	}
  | select_stmt
	{
	  $$ = $1;
	}
  | iterate_stmt
	{
	  $$ = $1;
	}
  | jump_stmt
	{
	  $$ = $1;
	}
  | except_stmt
	{
	  $$ = $1;
	}
  | c_stmt
	{
	  $$ = $1;
	}
  | concur_stmt
	{
	  $$ = $1;
	}
  | debug_stmt
	{
	  $$ = $1;
	}
  ;
debug_stmt
  : DEBUG '(' exp_comma ')' ';'
	{
	  OO_List list = $3 ? $3->comma_rec.expr_list : NULL;

	  if (list)
	    {
	      OO_Expr exp, buf;
	      OO_Type type;
	      char *format;

	      exp = (OO_Expr) list->car;
	      type = exp->expr_common_rec.type;

	      if (CheckSimpleType (type, TC_Zero) == TYPE_NG &&
		  (type->id != TO_TypeSCQF || 
		   type->type_scqf_rec.scqf ^ SC_GLOBAL))
		FatalError ("1st argument of `debug ()' must be "
			    "global object type, `0' or `default'.\n");
	      
	      list = &list->cdr->list_rec;
	      
	      buf= (OO_Expr) list->car;
	      if (buf->id != TO_Constant ||
		  buf->constant_rec.type->id != TO_TypeArray ||
		  CheckSimpleType (buf->constant_rec.type->type_array_rec.type,
				   TC_Char) == TYPE_NG)
		FatalError ("2nd argument of `debug ()' must be a string.\n");
	      
	      format = (char *) malloc (strlen (buf->constant_rec.string) + 1);
	      strcpy (format, buf->constant_rec.string);
	      DestroyExp (buf);

	      $$ = CreateDebugPrintStatement (exp, format, 
					      &list->cdr->list_rec);
	    }
	  else
	    $$ = NULL;
	}  
  | DEBUG '(' DEFAULT ',' strs ')' ';'
	{
	  $$ = CreateDebugPrintStatement (NULL, $5, NULL);
	}  
  | DEBUG '(' DEFAULT ',' strs ',' exp ')' ';'
	{
	  OO_List list = $7 && $7->id == TO_Comma ? $7->comma_rec.expr_list :
	    CreateList ((OO_Object) $7, NULL);
	  
	  $$ = CreateDebugPrintStatement (NULL, $5, list);
	}  
  | DEBUG 
	{
	  $<stmt>$ = CreateDebugBlockStatement ();
	} 
	block 
	{
	  $$ = SetDebugBlock ((OO_DebugBlockStatement) $<stmt>2, $3);
	}
  ;
exp_stmt
  : exp ';'
	{ 
	  $$ = CreateExprStatement ($1);
	}
  ;
comp_stmt
  : block
	{
	  $$ = $1;
	}
  ;
select_stmt
  : IF '(' exp ')' 
	{
	  $<stmt>$ = CreateIfStatement ($3);
	}
	if_body
	{
	  OO_Statement else_part 
	    = $6->cdr ? (OO_Statement) $6->cdr->list_rec.car : NULL;

	  $$ = SetIfStatement ((OO_IfStatement) $<stmt>5, 
			       (OO_Statement) $6->car, else_part);
	}
  | SWITCH '(' exp ')' '{'
	{
	  $<stmt>$ = CreateSwitchStatement ($3);
	}
	label_stmt '}'
	{
	  $$ = SetSwitchStatement ((OO_SwitchStatement) $<stmt>6, $7);
	}
  ;
if_body 
  : stmt %prec IF
	{	
	  $$ = CreateList ((OO_Object) $1, NULL);
	}
  | stmt ELSE stmt
	{	
	  $$ = CreateList ((OO_Object) $1, (OO_Object) $3);
	}
  ;
label_stmt
  : label 
	{
	  $<stmt>$ = CreateCaseLabel ($1);
	}
	not_comp_stmts
	{
	  $$ = $<stmt>2;
	}
  | label_stmt label 
	{
	  $<stmt>$ = $1;
	  CreateCaseLabel ($2);
	}
	not_comp_stmts 
	{
	  $$ = $<stmt>3;
	}
  ;
label
  : CASE exp ':'
	{
	  $$ = $2;
	}
  | DEFAULT ':'
	{
	  $$ = NULL;
	}	
  ;
iterate_stmt
  : WHILE '(' exp ')' 
	{
	  $<stmt>$ = CreateWhileStatement ($3);
	}
	stmt
	{
	  $$ = SetWhileStatement ((OO_WhileStatement) $<stmt>5, $6);
	}
  | DO 
	{
	  $<stmt>$ = CreateDoStatement ();
	}
	stmt WHILE '(' exp ')' ';'
	{
	  $$ = SetDoStatement ((OO_DoStatement) $<stmt>2, $3, $6);
	}
  | FOR '(' exp_or_null ';' exp_or_null ';' exp_or_null ')' 
	{
	  $<stmt>$ = CreateForStatement ($3, $5, $7);
	}
	stmt
	{
	  $$ = SetForStatement ((OO_ForStatement) $<stmt>9, $10);
	}
  ;
jump_stmt
  : BREAK ';'
	{
	  $$ = CreateJumpStatement (OP_BREAK);
	}
  | CONTINUE ';'
	{
	  $$ = CreateJumpStatement (OP_CONTINUE);
	}
  | RETURN ';'
	{
	  $$ = CreateWithExprStatement (OP_RETURN, NULL, NULL);
	}
  | RETURN exp ';'
	{
	  $$ = CreateWithExprStatement (OP_RETURN, $2, NULL);
	}
  ;
except_stmt
  : TRY 
	{
	  $<stmt>$ = CreateExceptionStatement ();
	}
	block EXCEPT '{' 
	{
	  $<stmt>$ = SetExceptionTry ((OO_ExceptionStatement) $<stmt>2, $3);
	}
	except_body '}'
	{
	  $$ = SetExceptionHandlerList ((OO_ExceptionStatement) $<stmt>6, 
					(OO_ExceptionHandler) $7);
	}
  | RAISE exception_label_for_raise ';'
	{
	  OO_Expr exp1 = (OO_Expr) $2->car;
	  OO_Expr exp2 = $2->cdr ? (OO_Expr) $2->cdr->list_rec.car : NULL;

	  $$ 
	    = CreateWithExprStatement (OP_RAISE, exp1, exp2);
	}
  | RAISE ';'
	{
	  $$ = CreateWithExprStatement (OP_RAISE, NULL, NULL);
	}
  ;
except_body
  : /* empty */
	{
	  $$ = NULL;
	}
  | except_body 
	{
	  $<stmt>$ = CreateExceptionHandler ();
	}  
	exception_labels 
	{
	  $<stmt>$ = SetExceptionNames ((OO_ExceptionHandler) $<stmt>2, 
					(OO_ExceptionName) $3);
	}	
	block 
	{
	  OO_Statement buf 
	    = SetExceptionHandler ((OO_ExceptionHandler) $<stmt>4, $5);
	  $$ = $1 ? $1 : buf;
	}
  ;
exception_labels
  : exception_label 
	{
	  $$ = $1;
	}
  | exception_labels ',' exception_label 
	{
	  $$ = $1;
	}
  ;
exception_label
  : exception_name 
	{
	  $$ = CreateExceptionName ($1, NULL);
	}
  | exception_name_not_default '(' IDENTIFIER ')'
	{
	  OO_Symbol arg = NULL;

	  if (Mode == NORMAL)
	    {
	      CreateBlock ();
	      arg = CreateSymbol ($3);
	      arg->type = $1->type->type_method_rec.args->car->symbol_rec.type;
	      AddVar (0, NULL, 0, NULL, (OO_Expr) arg, 0) ;
	    }

	  $$ = CreateExceptionName ($1, arg);
	}
  ;
exception_label_for_raise
  : exception_name_not_default 
	{
	  $$ = CreateList ((OO_Object) $1, NULL);
	}
  | exception_name_not_default '(' exp ')'
	{
	  $$ = CreateList ((OO_Object) $1, (OO_Object) $3);
	}
  ;
exception_name
  : exception_name_not_default
	{
	  $$ = $1;
	}
  | DEFAULT
	{
	  $$ = CreateSymbol ("Any");
	}	  
  ;
exception_name_not_default
  : SHAREDNAME IDENTIFIER
	{
	  $$ = (OO_Symbol) $2;
	  free ($1);
	}  
  | IDENTIFIER
	{  
	  $$ = CreateSymbol ($1);
	  free ($1);
	}
  ;
c_stmt
  : INLINE STRING INLINE_CONTENTS
	{
	  $$ = CreateInlineStatement ($2, $3);
	}
  ;
concur_stmt
  : DETACH exp ';'
	{
	  $$ = CreateWithExprStatement (OP_DETACH, $2, NULL);
	}
  | WAIT exp ';'
	{
	  $$ = CreateWithExprStatement (OP_WAIT, $2, NULL);
	}
  | WAIT exp UNTIL exp ';'
	{
	  $$ = CreateWithExprStatement (OP_WAIT, $2, $4);
	}
  | SIGNAL exp ';'
	{
	  $$ = CreateWithExprStatement (OP_SIGNAL, $2, NULL);
	}
  | SIGNALALL exp ';'
	{
	  $$ = CreateWithExprStatement (OP_SIGNALALL, $2, NULL);
	}
  | KILL exp ';'
	{
	  $$ = CreateWithExprStatement (OP_KILL, $2, NULL);
	}
  | ABORT ';'
	{
	  $$ = CreateNoExprStatement (OP_ABORT);
	}
  | ABORTABLE ';'
	{
	  $$ = CreateNoExprStatement (OP_ABORTABLE);
	}
  ;
%%

static 
char *concat (char *str1, char *str2, char *str3)
{
  int len = strlen (str1) + strlen (str2);
  char *buf;

  if (str3)
    len += strlen (str3);

  buf = (char *) malloc (len + 1);
  strcpy (buf, str1);
  strcat (buf, str2);

  free(str1);
  free(str2);

  if (str3) {
    strcat (buf, str3);
    free(str3);
  }

  return buf;
}

static char *
  create_quals (int qual)
{
  char *buf;

  if (qual <= 0)
    return NULL;

  buf = (char *) malloc (100);
  *buf = '\0';

  if (qual & QF_UNSIGNED)
    {
      strcat (buf, "unsigned ");
    }

  if (qual & SC_GLOBAL)
    {
      strcat (buf, "global ");
    }
  
  return buf;
}

static int
 create_class (char *name, int qual)
{
  if (!ThisClass)
    {
      if (Mode == NORMAL)
	{
	  ThisClass = CreateClass(name, qual, 1);
	  
	  if (Part != PUBLIC_PART)
	    PrivClass = LoadClassFromZ (name, 
					Part == PROTECTED_PART || 
					ThisClass->cl == TC_StaticObject ? 
					1 : 0);

#if 0
	  if (!Object && qual != SC_SHARED)
#endif
	  if (!Object && (!qual || qual == SC_ABSTRACT))
	    AddParent ("Object");
	}
      else
	{
	  ThisClass = CreateClass(NULL, qual, 1);
	  if (!Object && qual != SC_SHARED && Part == PRIVATE_PART && !Pass)
	    AddParent ("Object");
	}
      Self = CreateSymbol ("self");
      Self->type = (OO_Type) ThisClass;
      ThisClass->status = CLASS_IMPLEMENTING;
    }
  switch (Mode)
    {
    case NORMAL:
    case USED_CLASSES:
    case INHERITED_CLASSES:
      RemoveFromClassList (name);
      break;
    case THIS_CLASS:
      if (!Error) 
	printf ("%d %s\n", qual, name);
      return 1;
    case ALL_CLASSES:
      break;
    }

  free (name);
  return 0;
}

static void
create_method (int qual, char *type_str, int type, MethodSymbol msym, 
	       int mq, int emit)
{
  OO_List buf = msym->arg;
  OO_Symbol sym;
  
  if (buf)
    UpBlock ();
  sym = AddMethod (qual, type_str, type, msym, mq);
  if (Part != PRIVATE_PART && Mode != NORMAL && sym->access > Part)
    {
      OO_List args = msym->arg;
      
      if (type == TC_Object)
	RemoveFromClassList (type_str);
      
      while (args)
	{
	  if (args->car->symbol_rec.type->id == TO_ClassType)
	    RemoveFromClassList (args->car->symbol_rec.type
				 ->class_type_rec.symbol->string);
	  args = &args->cdr->list_rec;
	}
    }

  DestroyMethodSymbol (msym);

  if (emit)
#if 0
    if (ThisClass->cl == TC_Record)
      EmitMethod (PublicOutputFileH, sym);
    else
#endif
      EmitMethod (PrivateOutputFileC, sym);
  

  if (buf)
    DownBlock ();

  if (!emit && buf)
    DestroyBlock ();

  cur_qual = 0;
  cur_m_qual = 0;
  m_qual = 0;
  cur_m_type = TC_None;

  if (cur_m_type == TC_Generic || cur_m_type == TC_Object)
    free (cur_m_type_str);
}

static OO_Symbol
create_var (TypedSymbol tsym, OO_Expr exp)
{
  OO_Symbol sym;

  sym = AddVar (cur_qual, cur_type_str, cur_type, tsym, exp, 0);
  return sym;
}

yyerror(char *s)
{
  FatalError ("%s\n", s);
  Error = 1;
}
