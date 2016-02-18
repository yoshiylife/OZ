%{
/* parser for 'Object Image Compiler' */

#include <stdio.h>
#include "object.h"
%}
%token CLASS
%token ARRAY
%token LOCAL
%token GLOBAL
%token UNSIGNED
%token STATIC
%token RECORD
%token UMINUS
%token LSHIFT
%token RSHIFT
%token OID
%token <id> ID_L, ID_S
%token <str> IDENTIFIER, TYPE, INTEGER, CONST_CHAR, STR, OCT, HEX, CHAR
%token <str> LLINTEGER, UINTEGER ULLINTEGER, UHEX, UOCT, LLOCT, ULLOCT, LLHEX, ULLHEX
%token <str> DOUBLEVAL, FLOATVAL
%type <str> type, index, integer, llinteger, direct_array_def, direct_local_def
%type <str> record_members, record_value_normal, record_value_array instance_val class_name gparams gparam
%type <exp> exp_normal, exp_array, exp_value, exp_normal_lists, exp_array_lists
%type <exp> array_element, index_lists
%left '|' 
%left '^' 
%left '&' 
%left '<' '>'
%left LSHIFT RSHIFT
%left '+' '-'
%left '*' '/' '%'
%right UMINUS '~'
%union {
  char *str;
  char *id;
  Exp exp;
}
%%
file 
  : class_defs global_defs
  ;
class_defs
  : /* empty */
  | class_defs class_def
  ;
class_def
  : CLASS class_name_lists ';'
  | STATIC CLASS static_class_name_lists ';' 
  | RECORD record_class_name_lists ';'
  | error ';' { yyerrok; }
  ; 
class_name_lists
  : class_name'=' ID_L ',' 
		{
		  CreateClass($1, $3, 0); 
		} class_name_lists
  | class_name'=' INTEGER ',' 
		{
		  if (strlen ($3) != 16) 
		    yyerror ("not class ID");

		  CreateClass($1, $3, 0); 
		} class_name_lists
  | class_name '=' ID_L 
		{ 
		  CreateClass($1, $3, 0); 
		}
  | class_name'=' INTEGER 
		{
		  if (strlen ($3) != 16) 
		    yyerror ("not class ID");

		  CreateClass($1, $3, 0); 
		} 
  ;
static_class_name_lists
  : class_name '=' ID_L ',' 
		{
		  CreateClass($1, $3, T_STATIC); 
		} static_class_name_lists
  | class_name '=' INTEGER ',' 
		{
		  if (strlen ($3) != 16) 
		    yyerror ("not class ID");

		  CreateClass($1, $3, T_STATIC); 
		} static_class_name_lists
  | class_name '=' ID_L
		{ 
		  CreateClass($1, $3, T_STATIC); 
		}
  | class_name '=' INTEGER
		{ 
		  if (strlen ($3) != 16) 
		    yyerror ("not class ID");

		  CreateClass($1, $3, T_STATIC); 
		}
  ;
record_class_name_lists
  : class_name '=' ID_L ',' 
		{
		  CreateClass($1, $3, T_RECORD); 
		} record_class_name_lists
  | class_name '=' INTEGER ',' 
		{
		  if (strlen ($3) != 16) 
		    yyerror ("not class ID");

		  CreateClass($1, $3, T_RECORD); 
		} record_class_name_lists
  | class_name '=' ID_L
		{ 
		  CreateClass($1, $3, T_RECORD); 
		}
  | class_name '=' INTEGER
		{ 
		  if (strlen ($3) != 16) 
		    yyerror ("not class ID");

		  CreateClass($1, $3, T_RECORD); 
		}
  ;
class_name
  : IDENTIFIER
	{
	  $$ = $1;
	}
  | IDENTIFIER '<' gparams '>'
	{  
	  char *str = (char *) malloc (strlen ($1) + strlen ($3) + 3);

	  sprintf (str, "%s<%s>", $1, $3);
	  free ($1);
	  free ($3);
	  $$ = str;
	}
  ;
gparam
  : TYPE
	{
	  $$ = $1;
	}
  | CHAR
	{
	  $$ = $1;
	}
  | UNSIGNED TYPE
	{
	  char *str = (char *) malloc (9 + strlen ($2) + 1);

	  sprintf (str, "unsigned %s", $2);
	  free ($2);
	  $$ = str;
	}
  | class_name
	{
	  $$ = $1;
	}
  | GLOBAL class_name
	{
	  char *str = (char *) malloc (7 + strlen ($2) + 1);

	  sprintf (str, "global %s", $2);
	  free ($2);
	  $$ = str;
	}
  ;
gparams
  : gparam
	{
	  $$ = $1;
	}
  | gparams ',' gparam
	{
	  char *str = (char *) malloc (strlen ($1) + strlen ($3) + 2);

	  sprintf (str, "%s,%s", $1, $3);
	  free ($1);
	  free ($3);
	  $$ = str;
	}
  ;
global_defs 
  : /* empty */
  | global_defs global_def
  ;
global_def 
  : GLOBAL class_name IDENTIFIER '=' ID_S '{' 
		{
		  CreateGlobalObject($3, $2, $5);
		} local_defs instance_val_lists '}' 
  | GLOBAL class_name ID_S '{' 
		{
		  CreateGlobalObject(NULL, $2, $3);
		} local_defs instance_val_lists '}' 
  | GLOBAL class_name IDENTIFIER'{' 
		{
		  CreateGlobalObject($3, $2, NULL);
		} local_defs instance_val_lists '}' 
  | GLOBAL class_name '{' 
		{
		  CreateGlobalObject(NULL, $2, NULL);
		} local_defs instance_val_lists '}' 
  ;
local_defs
  : /* empty */
  | local_defs local_def
  ;
local_def
  : LOCAL class_name IDENTIFIER '{' 
		{
		  CreateObject($3, $2);
		} instance_val_lists '}' 
		{
		  UpLevel();
		}
  | ARRAY CHAR IDENTIFIER '[' ']' '{' STR ';'
		{
		  CreateArray($3, $2, 0, T_STR);
		  CreateInstanceVal(NULL, $7, T_STR, -1, NULL);
		} '}'
		{
		  UpLevel();
		}
  | ARRAY CHAR IDENTIFIER '[' index ']' '{'
		{
		  CreateArray($3, $2, atoi($5), 0);
		} element_lists '}'
		{
		  UpLevel();
		}
  | ARRAY type IDENTIFIER '[' index ']' '{'
		{
		  CreateArray($3, $2, atoi($5), 0);
		} element_lists '}'
		{
		  UpLevel();
		}
  | ARRAY IDENTIFIER '[' index ']' '{'
		{
		  CreateArray($2, NULL, atoi($4), T_ARRAY);
		} element_lists '}'
		{
		  UpLevel();
		}
  | ARRAY ARRAY IDENTIFIER '[' index ']' '{'
		{
		  CreateArray($3, NULL, atoi($5), T_ARRAY);
		} element_lists '}'
		{
		  UpLevel();
		}
  | ARRAY GLOBAL class_name IDENTIFIER '[' index ']' '{'
		{
		  CreateArray($4, $3, atoi($6), T_GLOBAL);
		} element_lists '}'
		{
		  UpLevel();
		}
  ;
direct_local_def
  : LOCAL class_name '{' 
		{
		  CreateObject(NULL, $2);
		} instance_val_lists '}' 
		{
		  char *buf = UpLevel();
		  $$ = (char *)malloc(strlen(buf) + 1);
		  strcpy($$, buf);
		}
  ;
direct_array_def
  : ARRAY CHAR '[' ']' '{' STR ';'
		{
		  CreateArray(NULL, $2, 0, T_STR);
		  CreateInstanceVal(NULL, $6, T_STR, -1, NULL);
		} '}'
		{
		  char *buf = UpLevel();
		  $$ = (char *)malloc(strlen(buf) + 1);
		  strcpy($$, buf);
		}
  | ARRAY CHAR '[' index ']' '{'
		{
		  CreateArray(NULL, $2, atoi($4), 0);
		} element_lists '}'
		{
		  char *buf = UpLevel();
		  $$ = (char *)malloc(strlen(buf) + 1);
		  strcpy($$, buf);
		}
  | ARRAY type '[' index ']' '{'
		{
		  CreateArray(NULL, $2, atoi($4), 0);
		} element_lists '}'
		{
		  char *buf = UpLevel();
		  $$ = (char *)malloc(strlen(buf) + 1);
		  strcpy($$, buf);
		}
  | ARRAY '[' index ']' '{'
		{
		  CreateArray(NULL, NULL, atoi($3), T_ARRAY);
		} element_lists '}'
		{
		  char *buf = UpLevel();
		  $$ = (char *)malloc(strlen(buf) + 1);
		  strcpy($$, buf);
		}
  | ARRAY ARRAY '[' index ']' '{'
		{
		  CreateArray(NULL, NULL, atoi($4), T_ARRAY);
		} element_lists '}'
		{
		  char *buf = UpLevel();
		  $$ = (char *)malloc(strlen(buf) + 1);
		  strcpy($$, buf);
		}
  | ARRAY GLOBAL class_name '[' index ']' '{'
		{
		  CreateArray(NULL, $3, atoi($5), T_GLOBAL);
		} element_lists '}'
		{
		  char *buf = UpLevel();
		  $$ = (char *)malloc(strlen(buf) + 1);
		  strcpy($$, buf);
		}
  ;
  ; 
instance_val_lists
  : /* empty */
  | instance_val_lists instance_val_list
  ;
instance_val_list
  : instance_val '=' LOCAL '(' IDENTIFIER ')' ';' 
		{ 
		  CreateInstanceVal($1, $5, T_LOCAL, -1, NULL); 
		}
  | instance_val '=' OID '(' ID_L ')' ';' 
		{
		  CreateInstanceVal($1, $5, T_OID, -1, NULL); 
		}
  | instance_val '=' OID '(' INTEGER ')' ';' 
		{
		  if (strlen ($5) != 16) 
		    yyerror ("not OID");

		  CreateInstanceVal($1, $5, T_OID, -1, NULL); 
		}
  | instance_val '=' GLOBAL '(' IDENTIFIER ')' ';' 
		{ 
		  CreateInstanceVal($1, $5, T_GLOBAL, -1, NULL); 
		}
  | instance_val '=' ARRAY '(' IDENTIFIER ')' ';' 
		{ 
		  CreateInstanceVal($1, $5, T_ARRAY, -1, NULL); 
		}
  | instance_val '=' exp_normal ';' 
		{ 
		  CreateInstanceVal($1, (char *)$3, T_EXP, -1, NULL); 
		}
  | instance_val '.' record_members '=' exp_normal ';' 
		{ 
		  CreateInstanceVal($1, (char *)$5, T_EXP, -1, $3); 
		}
  | instance_val '=' direct_local_def 
		{  
		  CreateInstanceVal($1, $3, T_LOCAL, -1, NULL);
		}
  | instance_val '=' direct_array_def 
		{  
		  CreateInstanceVal($1, $3, T_ARRAY, -1, NULL);
		}
  | instance_val '=' record_value_normal 
		{  
		  CreateInstanceVal($1, $3, T_EXP, -1, NULL);
		}
  | instance_val '.' record_members '=' record_value_normal 
		{  
		  CreateInstanceVal($1, $5, T_EXP, -1, $3);
		}
  | error ';' { yyerrok; } 
  ;
record_value_normal
  : '{' exp_normal_lists '}'
		{  
		  $$ = (char *)CreateExp($2, NULL, OP_BR, NULL);
		}
  ;
exp_normal_lists
  : /* empty */
		{  
		  $$ = NULL;
		}
  | exp_normal
		{  
		  $$ = $1;
		}
  | exp_normal ',' exp_normal_lists
		{  
		  $$ = CreateExp($1, $3, OP_COM, NULL);
		}
  | '{' exp_normal_lists '}'
		{  
		  $$ = CreateExp($2, NULL, OP_BR, NULL);
		}
  | '{' exp_normal_lists '}' ',' exp_normal_lists
		{  
		  Exp buf = CreateExp($2, NULL, OP_BR, NULL);
		  $$ = CreateExp(buf, $5, OP_COM, NULL);
		}
  ;
record_value_array
  : '{' exp_array_lists '}'
		{  
		  $$ = (char *)CreateExp($2, NULL, OP_BR, NULL);
		}
  ;
exp_array_lists
  : /* empty */
		{  
		  $$ = NULL;
		}
  | exp_array
		{  
		  $$ = $1;
		}
  | exp_array ',' exp_array_lists
		{  
		  $$ = CreateExp($1, $3, OP_COM, NULL);
		}
  | '{' exp_array_lists '}'
		{  
		  $$ = CreateExp($2, NULL, OP_BR, NULL);
		}
  | '{' exp_array_lists '}' ',' exp_array_lists
		{  
		  Exp buf = CreateExp($2, NULL, OP_BR, NULL);
		  $$ = CreateExp(buf, $5, OP_COM, NULL);
		}
  ;
record_members
  : IDENTIFIER '.' record_members
		{  
		  char *buf;
		  buf = (char *)malloc(strlen($1) + strlen($3) + 3);
		  $$ = sprintf(buf, "oz%s.%s", $1, $3);
		  free($1);
		  free($3);
		}
  | IDENTIFIER
		{
		  char *buf;
		  buf = (char *)malloc(strlen($1) + 2);
		  $$ = sprintf(buf, "oz%s", $1);
		  free($1);
		}
  ;
element_lists
  : /* empty */
  | element_lists element_list
  ;
element_list
  : IDENTIFIER '[' index ']' '=' LOCAL '(' IDENTIFIER ')' ';' 
		{ 
		  CreateInstanceVal($1, $8, T_LOCAL, atoi($3), NULL); 
		}
  | IDENTIFIER '[' index ']' '=' OID '(' ID_L ')' ';' 
		{ 
		  CreateInstanceVal($1, $8, T_OID, atoi($3), NULL); 
		}
  | IDENTIFIER '[' index ']' '=' OID '(' INTEGER ')' ';' 
		{ 
		  if (strlen ($8) != 16) 
		    yyerror ("not OID");

		  CreateInstanceVal($1, $8, T_OID, atoi($3), NULL); 
		}
  | IDENTIFIER '[' index ']' '=' GLOBAL '(' IDENTIFIER ')' ';' 
		{ 
		  CreateInstanceVal($1, $8, T_GLOBAL, atoi($3), NULL); 
		}
  | IDENTIFIER '[' index ']' '=' ARRAY '(' IDENTIFIER ')' ';' 
		{ 
		  CreateInstanceVal($1, $8, T_ARRAY, atoi($3), NULL); 
		}
  | IDENTIFIER '[' index ']' '=' exp_array ';'
		{ 
		  CreateInstanceVal($1, (char *)$6, T_EXP, atoi($3), NULL); 
		}
  | IDENTIFIER '[' index ']' '=' record_value_array ';'
		{ 
		  CreateInstanceVal($1, $6, T_EXP, atoi($3), NULL); 
		}
  | IDENTIFIER '[' index ']' '.' record_members '=' exp_array ';'
		{ 
		  CreateInstanceVal($1, (char *)$8, T_EXP, atoi($3), $6); 
		}
  | IDENTIFIER '[' index ']' '.' record_members '=' record_value_array ';'
		{ 
		  CreateInstanceVal($1, (char *)$8, T_EXP, atoi($3), $6); 
		}
  | IDENTIFIER '[' index ']' '=' direct_array_def
		{ 
		  CreateInstanceVal($1, $6, T_ARRAY, atoi($3), NULL); 
		}
  | IDENTIFIER '[' index ']' '=' direct_local_def
		{ 
		  CreateInstanceVal($1, $6, T_LOCAL, atoi($3), NULL); 
		}
  | error ';' { yyerrok; } 
  ;
index
  : integer
		{
		  if (atoi($1) < 0)
		    {
		      fprintf(stderr, "%d:index must greater than 0\n",
			      yylineno);
		      exit(1);
		    }
		  $$ = $1;
		}
  | llinteger
		{
		  if (atoi($1) < 0)
		    {
		      fprintf(stderr, "%d:index must greater than 0\n",
			      yylineno);
		      exit(1);
		    }
		  $$ = $1;
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
  | UINTEGER 
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
llinteger
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
  | ULLINTEGER 
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
type 
  : TYPE
		{
		  $$ = $1;
		}
  | class_name 
		{	
		  $$ = $1;
		}
  ;
exp_normal
  : instance_val
		{
		  $$ = CreateExp((Exp)$1, NULL, OP_VAL, NULL, 0);
		}
  | instance_val '.' record_members
		{
		  $$ = CreateExp((Exp)$1, NULL, OP_VAL, $3, 0);
		}
  | array_element
		{
		  $$ = $1;
		}
  | exp_value
		{
		  $$ = $1;
		}
  | '-' exp_normal %prec UMINUS
		{
		  $$ = CreateExp($2, NULL, OP_UMINUS, NULL, 0);
		}
  | '~' exp_normal 
		{
		  $$ = CreateExp($2, NULL, OP_NOT, NULL, 0);
		}
  | '(' exp_normal ')'
		{
		  $$ = CreateExp($2, NULL, OP_EXP, NULL, 0);
		}
  | exp_normal '+' exp_normal
		{
		  $$ = CreateExp($1, $3, OP_PLUS, NULL, 0);
		}
  | exp_normal '-' exp_normal
		{
		  $$ = CreateExp($1, $3, OP_MINUS, NULL, 0);
		}
  | exp_normal '*' exp_normal
		{
		  $$ = CreateExp($1, $3, OP_MUL, NULL, 0);
		}
  | exp_normal '/' exp_normal
		{
		  $$ = CreateExp($1, $3, OP_DIV, NULL, 0);
		}
  | exp_normal '%' exp_normal
		{
		  $$ = CreateExp($1, $3, OP_MOD, NULL, 0);
		}
  | exp_normal '|' exp_normal
		{
		  $$ = CreateExp($1, $3, OP_OR, NULL, 0);
		}
  | exp_normal '^' exp_normal
		{
		  $$ = CreateExp($1, $3, OP_EOR, NULL, 0);
		}
  | exp_normal '&' exp_normal
		{
		  $$ = CreateExp($1, $3, OP_AND, NULL, 0);
		}
  | exp_normal '<' '<' exp_normal %prec LSHIFT 
		{
		  $$ = CreateExp($1, $4, OP_LSHIFT, NULL, 0);
		}
  | exp_normal '>' '>' exp_normal %prec RSHIFT 
		{
		  $$ = CreateExp($1, $4, OP_RSHIFT, NULL, 0);
		}
  ;
array_element
  : IDENTIFIER index_lists
		{
		  $$ = CreateExp((Exp)$1, $2, OP_ARRAY_VAL, NULL, 1);
		}
  | IDENTIFIER index_lists '.' record_members
		{
		  $$ = CreateExp((Exp)$1, $2, OP_ARRAY_VAL, $4, 1);
		}
  | ARRAY '(' IDENTIFIER ')' index_lists
		{
		  $$ = CreateExp((Exp)$3, $5, OP_ARRAY_VAL, NULL, 2);
		}
  | ARRAY '(' IDENTIFIER ')' index_lists '.' record_members
		{
		  $$ = CreateExp((Exp)$3, $5, OP_ARRAY_VAL, $7, 2);
		}
  ;
instance_val
  : IDENTIFIER
	{
	  $$ = $1;
	}
  | IDENTIFIER ':' integer
	{
	  char *buf = (char *) malloc (strlen ($1) + strlen ($3) + 2);

	  sprintf (buf, "%s:%s", $1, $3);
	  free ($1);
	  free ($3);
	  $$ = buf;
	}
  
index_lists
  : '[' index ']' 
		{  
		  $$ = CreateExp((Exp)$2, NULL, OP_INDEX, NULL, 0);
		}
  | '[' index ']' index_lists
		{  
		  $$ = CreateExp((Exp)$2, $4, OP_INDEX, NULL, 0);
		}
  ;
exp_array
  : array_element
		{
		  $$ = $1;
		}
  | exp_value
		{
		  $$ = $1;
		}
  | '-' exp_array %prec UMINUS
		{
		  $$ = CreateExp($2, NULL, OP_UMINUS, NULL, 0);
		}
  | '~' exp_array 
		{
		  $$ = CreateExp($2, NULL, OP_NOT, NULL, 0);
		}
  | '(' exp_array ')'
		{
		  $$ = CreateExp($2, NULL, OP_EXP, NULL, 0);
		}
  | exp_array '+' exp_array
		{
		  $$ = CreateExp($1, $3, OP_PLUS, NULL, 0);
		}
  | exp_array '-' exp_array
		{
		  $$ = CreateExp($1, $3, OP_MINUS, NULL, 0);
		}
  | exp_array '*' exp_array
		{
		  $$ = CreateExp($1, $3, OP_MUL, NULL, 0);
		}
  | exp_array '/' exp_array
		{
		  $$ = CreateExp($1, $3, OP_DIV, NULL, 0);
		}
  | exp_array '%' exp_array
		{
		  $$ = CreateExp($1, $3, OP_MOD, NULL, 0);
		}
  | exp_array '|' exp_array
		{
		  $$ = CreateExp($1, $3, OP_OR, NULL, 0);
		}
  | exp_array '^' exp_array
		{
		  $$ = CreateExp($1, $3, OP_EOR, NULL, 0);
		}
  | exp_array '&' exp_array
		{
		  $$ = CreateExp($1, $3, OP_AND, NULL, 0);
		}
  | exp_array '<' '<' exp_array %prec LSHIFT
		{
		  $$ = CreateExp($1, $4, OP_LSHIFT, NULL, 0);
		}
  | exp_array '>' '>' exp_array %prec RSHIFT
		{
		  $$ = CreateExp($1, $4, OP_RSHIFT, NULL, 0);
		}
  ;
exp_value
  : integer
		{
		  $$ = CreateExp((Exp)$1, NULL, OP_VALUE, NULL, 0);
		}
  | llinteger
		{
		  $$ = CreateExp((Exp)$1, NULL, OP_VALUE, NULL, 0);
		}
  | CONST_CHAR
		{
		  $$ = CreateExp((Exp)$1, NULL, OP_VALUE, NULL, 0);
		}
  ;
%%

yyerror(char *s)
{
  fprintf(stderr,"%d: %s\n", yylineno, s);
  error = 1;
}
  
  
