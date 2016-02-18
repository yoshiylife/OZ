/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _INTERNAL_H_
#define _INTERNAL_H_

/* Definitions of Structures of Internal Object */

/* Type of Objects */
enum ObjectID {
  /* NULL NODE */
  TO_NULL,

  /* Expression */
  /* Constant   */ TO_Constant,
  /* Primary    */ TO_ArrayReference, TO_MethodCall, TO_Member, TO_IncDec,
  /* Unary      */ TO_Unary, TO_Join, TO_Fork,
  /* Binary     */ TO_Binary, TO_ArithCompare, TO_EqCompare, TO_Assignment,
  /* Trinary    */ TO_Conditional,
  /* Comma      */ TO_Comma, TO_Comma2,

  /* Type       */ TO_SimpleType, TO_ClassType,

  /* SCQF       */ TO_TypeSCQF,
  /* Array      */ TO_TypeArray,
  /* Process    */ TO_TypeProcess,
  /* Method     */ TO_TypeMethod,

  /* Statement  */
  /* exception  */ TO_ExceptionName, 
  /* exception  */ TO_ExceptionHandler, 
  /* label      */ TO_CaseLabel,
  /* compound   */ TO_CompoundStatement,
  /* expr       */ TO_ExprStatement,
  /* if         */ TO_IfStatement,
  /* while      */ TO_WhileStatement,
  /* do         */ TO_DoStatement,
  /* for        */ TO_ForStatement,
  /* switch     */ TO_SwitchStatement,
  /* jump       */ TO_JumpStatement,
  /* inline     */ TO_InlineStatement,
  /* withexpr   */ TO_WithExprStatement, 
  /* noexpr     */ TO_NoExprStatement, 
  /* exception  */ TO_ExceptionStatement,
  /* debug 1    */ TO_DebugPrintStatement,
  /* debug 2    */ TO_DebugBlockStatement,

  /* rename     */
  TO_RenameAlias,

  /* Misc.      */
  TO_Symbol,  TO_List, TO_Block, TO_ParentDesc,
};

/* Miscellaneous objects . */

/* access */
enum ACCESS {
  CONSTRUCTOR_PART = -1,
  PUBLIC_PART,
  PROTECTED_PART,
  PRIVATE_PART,

  NOT_PART,
};

/* Symbol */
/* Symbol is also used as expression. */
typedef struct OO_Symbol_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  /* level of scope */
  /* int level;	*/

  /* links used by hash table maintainance */
  /* struct OO_Symbol_Rec *prev, *next; */

  /* link for same level (scope) symbols */
  struct OO_Symbol_Rec *link;

  char is_class;
  char access; /* short cut for...?? private, public, protected, constructor */
  char kind;   /* short cut for kind of object */

  union OO_Object_Com *init;	/* initialization */
  int is_used;

  struct OO_ClassType_Rec *class_part_defined;
  struct OO_Symbol_Rec *orig_name;

  long long class_id;
  int func_no;
  int slot_no2;
  struct OO_Symbol_Rec *alias;
  char rename;

  char   is_constructor;
  char   is_variable;

  union OO_Expr_Com *value;
  int is_created;
  int conflict;
  int is_arg;

  char string[1];
} OO_Symbol_Rec, *OO_Symbol;

/* List */
typedef struct OO_List_Rec {
  enum ObjectID id;
  union OO_Object_Com *car, *cdr;
} OO_List_Rec, *OO_List;

/* Block */
typedef struct OO_Block_Rec {
  enum ObjectID id;

  struct OO_Block_Rec *up, *down;
  struct OO_Symbol_Rec *vars;

  /* and so on. */
} OO_Block_Rec, *OO_Block;

/* Expression:
   Every expression contains the type of expression.
 */

/* Expression */
/* Common fields of expression.
   TYPE field specifies the type of expression. */
typedef struct OO_ExprCommon_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;
} OO_ExprCommon_Rec, *OO_ExprCommon;

/* Expression: Constants */
/* TYPE field specifies the type of constant.
   STRING contains its representation as string. */
typedef struct OO_Constant_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  char string[1];
} OO_Constant_Rec, *OO_Constant;

/* Expression: array reference */
/* TYPE field specifies the type of elements of array.
   ARRAY points to an expression of type array.
   INDEX points to an expression of type integer. */
typedef struct OO_ArrayReference_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  union OO_Expr_Com *array;
  union OO_Expr_Com *index;
} OO_ArrayReference_Rec, *OO_ArrayReference;

/* Expression: method call */
/* TYPE field specifies the type of return value.
   OBJ points to an expression of type object.
   METHOD points to a symbol of this method.
   The symbol has its name and must have type of method.
   ARGS points to an arguments list. */
typedef struct OO_MethodCall_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  union OO_Expr_Com *obj;
  struct OO_Symbol_Rec *method;
  struct OO_List_Rec *args;	/* List of OO_Expr */

  union OO_Expr_Com *om;

  int is_global;
  int is_mine;
  int is_constructor;
} OO_MethodCall_Rec, *OO_MethodCall;

typedef struct OO_Member_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  union OO_Expr_Com *obj;
  char *member;
} OO_Member_Rec, *OO_Member;

/* Expression: incdec */
#define OP_COMMA2     -3
#define OP_COMMA      -2
#define OP_PARE       -1
#define OP_INC         0
#define OP_DEC         1
/* TYPE field specifies the type of incdec expression,
   which is same the type of LVALUE.
   OP specifies the kind of operation (its value is defined above).
   LVALUE points to an lvalue expression. */
typedef struct OO_IncDec_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  char op;			/* OP_INC or OP_DEC */
  union OO_Expr_Com *lvalue;
} OO_IncDec_Rec, *OO_IncDec;

/* Expression: unary */
/*      OP_INC         0
        OP_DEC         1 */
#define OP_AND         2
#define OP_MINUS       3
#define OP_PLUS        4
#define OP_TILDE       5
#define OP_EXCLAIM     6 
#define OP_LENGTH      7
/* TYPE field specifies the type of unary expression,
   which is deduced by EXPR.
   OP specifies the kind of operation (its value is defined above).
   EXPR points to an expression. */
typedef struct OO_Unary_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  char op;			/* OP_*  */
  union OO_Expr_Com *expr;
} OO_Unary_Rec, *OO_Unary;

/* TYPE field specifies the type of expression.
   EXPR points to an expression. */
typedef struct OO_Join_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  union OO_Expr_Com *expr;
} OO_Join_Rec, *OO_Join;

/* TYPE field specifies the type of expression.
   EXPR points to an expression. */
typedef struct OO_Fork_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  union OO_Expr_Com *expr;
} OO_Fork_Rec, *OO_Fork;

/* Expression: Binary */
/*      OP_PLUS       
        OP_MINUS       */
#define OP_MULT        8
#define OP_DIV         9
#define OP_MOD        10   
#define OP_LSHIFT     11
#define OP_RSHIFT     12
/*      OP_AND */
#define OP_IOR        13
#define OP_EOR        14
#define OP_ANDAND     15
#define OP_OROR       16
#define OP_NARROW     17

/* TYPE field specifies the type of expression, which is deduced by EXPR1
   and EXPR2.
   OP specifies the kind of operation (its value is defined above).
   EXPR1 points to an expression, so does EXPR2. */
typedef struct OO_Binary_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  char op;			/* OP_* */
  union OO_Expr_Com *expr1, *expr2;
} OO_Binary_Rec, *OO_Binary;

/* Expression: arith comp */
#define OP_LT         18
#define OP_GT         19
#define OP_LE         20
#define OP_GE         21
/* TYPE field specifies the type of expression, which is always integer.
   OP specifies the kind of comparation (its value is defined above).
   EXPR1 points to an expression, so does EXPR2. */
typedef struct OO_ArithCompare_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  char op;			/* OP_*  */
  union OO_Expr_Com *expr1, *expr2;
} OO_ArithCompare_Rec, *OO_ArithCompare;

/* Expression: equal comp */
#define OP_EQ         22
#define OP_NE         23
/* TYPE field specifies the type of expression, which is always integer.
   OP specifies the kind of comparation (its value is defined above).
   EXPR1 points to an expression, so does EXPR2. */
typedef struct OO_EqCompare_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  char op;			/* OP_*  */
  union OO_Expr_Com *expr1, *expr2;
} OO_EqCompare_Rec, *OO_EqCompare;

/* Expression: conditional */
/* TYPE field specifies the type of expression, which is deduced by
   EXPR2 and EXPR3.
   EXPR1 points to an expression of integral type.
   EXPR2 points to an expression, so does EXPR3. */
typedef struct OO_Conditional_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  union OO_Expr_Com *expr1, *expr2, *expr3;
} OO_Conditional_Rec, *OO_Conditional;

/* Expression: assignment */
/*      OP_PLUS       
        OP_MINUS
        OP_MULT
        OP_DIV
        OP_MOD
        OP_LSHIFT
        OP_RSHIFT
        OP_AND 
        OP_IOR
        OP_EOR
	OP_EQ             */
/* TYPE field specifies the type of expression, which is the type of LVALUE.
   OP specifies the kind of assignment (its value is defined above).
   EXPR points to an expression. */
typedef struct OO_Assignment_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  char op;			/* OP_*  */
  union OO_Expr_Com *lvalue;
  union OO_Expr_Com *expr;
} OO_Assignment_Rec, *OO_Assignment;

/* Expression: Comma */
/* TYPE field specifies the type of expression, which is the type of
   last entry of EXPR_LIST.
   EXPR_LIST is a list of expressions.  */
typedef struct OO_Comma_Rec {
  enum ObjectID id;
  union OO_Type_Com *type;

  struct OO_List_Rec *expr_list;
} OO_Comma_Rec, *OO_Comma;

/* Expression */
/* Union of all expression */
typedef union OO_Expr_Com {
  enum ObjectID id;
  struct OO_ExprCommon_Rec        expr_common_rec;
  struct OO_Symbol_Rec		  symbol_rec;
  struct OO_Constant_Rec	  constant_rec;
  struct OO_ArrayReference_Rec    array_reference_rec;
  struct OO_MethodCall_Rec        method_call_rec;
  struct OO_Member_Rec            member_rec;
  struct OO_IncDec_Rec            inc_dec_rec;
  struct OO_Unary_Rec             unary_rec;
  struct OO_Binary_Rec            binary_rec;
  struct OO_ArithCompare_Rec      arith_compare_rec;
  struct OO_EqCompare_Rec         eq_compare_rec;
  struct OO_Assignment_Rec        assignment_rec;
  struct OO_Conditional_Rec       conditional_rec;
  struct OO_Comma_Rec             comma_rec;
  struct OO_Fork_Rec              fork_rec;
  struct OO_Join_Rec              join_rec;
} OO_Expr_Com, *OO_Expr;

/*
  There are two type specifiers (say, nouns of type).
  One is 'simple type' and another is 'class type'.
  They can be qualified with type qualifiers, strage class modifiers
  and declarators (as noun is qualified by adjectives).

  Every type specifier contains `id' and `classification.'
 */

/* classification of OZ objects */
enum TypeCL {
  TC_None = -1,
  TC_Void,
  TC_Char,
  TC_Short,
  TC_Int,
  TC_Long,
  TC_Float,
  TC_Double,
  TC_Condition = 8,

  TC_Generic,
  TC_Zero,

  TC_Object = 14,
  TC_Record,
  TC_StaticObject,
  TC_Shared,
};

/*
  Simple types are predetermined types.
  Thier name and characteristics are given and hard-coded.
 */
/*
  CL is classification of the type.
  SYMBOL points to a symbol which contains the string representation
  of this type.
  Note that, SYMBOL's type field points back to this type itself.
 */
typedef struct OO_SimpleType_Rec {
  enum ObjectID id;
  enum TypeCL cl;

  struct OO_Symbol_Rec *symbol;
} OO_SimpleType_Rec, *OO_SimpleType;

/*
  Class type is user defined type.

  Note that there is class qualifier and type qualifier.
  Class qualifier is specified when defining class, and
  type qualifier is used when a class is used.
 */
enum CLASS_STATUS {
  CLASS_NONE,
  CLASS_IMPLEMENTING,
  CLASS_ID_DEFINED,
  CLASS_PUBLIC_LOADED,
  CLASS_PROTECTED_LOADED,
  CLASS_RECORD_EMITED,
  CLASS_FAIL,
};

typedef struct OO_ClassType_Rec {
  enum ObjectID id;
  enum TypeCL cl;

  long long class_id_protected;
  long long class_id_public;
  long long class_id_implementation;

  struct OO_ClassType_Rec *next;

  int qualifiers;
  struct OO_Symbol_Rec *symbol; /* class name */
  struct OO_Block_Rec  *block;
  struct OO_ParentDesc_Rec *parent_desc;

  /* internal states */
  enum CLASS_STATUS status;
  int has_lock;

  struct OO_List_Rec *constructor_list;	/* List of Symbol */
  struct OO_List_Rec *public_list;      /* List of Symbol */
  struct OO_List_Rec *protected_list;   /* List of Symbol */
  struct OO_List_Rec *exception_list;   /* List of Symbol */

  struct OO_List_Rec *private_list;   /* List of Symbol */
  int no_parents;
  struct OO_List_Rec *class_part_list;
  int slot_no2;

  int class_id_suffix;
  int size;

  char used_for_instanciate;
  char used_for_invoke;
  
} OO_ClassType_Rec, *OO_ClassType;

/*
  Type qualifiers are defined here.
  They are OR-ed.
 */
#define QF_CONST    1
#define QF_UNSIGNED 2

/* Strage classes are defined here.
   They are OR-ed.
 */
#if 0
#define SC_GLOBAL  16
#define SC_LOCAL   32
#define SC_STATIC  64
#define SC_LOCKED 128
#define SC_RECORD 256

#define SC_ABSTRACT 512

#define SC_SHARED 1024
#else
#define SC_GLOBAL  4

#define SC_SHARED 5
#define SC_STATIC  6
#define SC_RECORD  7
#define SC_ABSTRACT 8
#endif

/* Adjectives of type */
/* SCQF is a bitmap of strage class specifiers and qualifiers.
   TYPE specifies the type qualified. */
typedef struct OO_TypeSCQF_Rec {
  enum ObjectID id;

  int scqf;
  union OO_Type_Com *type;
} OO_TypeSCQF_Rec, *OO_TypeSCQF;

/* Type: array */
/* TYPE specifies the type of elements. */
typedef struct OO_TypeArray_Rec {
  enum ObjectID id;

  union OO_Type_Com *type;
} OO_TypeArray_Rec, *OO_TypeArray;

/* Type: process */
/* TYPE specifies the return value of process. */
typedef struct OO_TypeProcess_Rec {
  enum ObjectID id;

  union OO_Type_Com *type;
} OO_TypeProcess_Rec, *OO_TypeProcess;


/* method qualifiers */
#if 0
#define MQ_LOCAL	1
#define MQ_LOCKED	2
#define MQ_ABSTRACT	4
#define MQ_GLOBAL	8
#else
#define MQ_LOCKED	1
#define MQ_ABSTRACT	2
#define MQ_GLOBAL	4
#endif

/* Type: method */
/* TYPE specifies the return value of method.
   ARGS specifies the method prototypes. */
typedef struct OO_TypeMethod_Rec {
  enum ObjectID id;

  union OO_Type_Com *type;
  struct OO_List_Rec *args; /* list of symbol/type */
  int qualifier;
} OO_TypeMethod_Rec, *OO_TypeMethod;

/* Type */
typedef union OO_Type_Com {
  enum ObjectID id;

  struct OO_SimpleType_Rec  simple_type_rec;
  struct OO_ClassType_Rec   class_type_rec;

  struct OO_TypeSCQF_Rec    type_scqf_rec;
  struct OO_TypeArray_Rec   type_array_rec;
  struct OO_TypeProcess_Rec type_process_rec;
  struct OO_TypeMethod_Rec  type_method_rec;
} OO_Type_Com, *OO_Type;

/* Statement */
/* common */
typedef struct OO_StatementCommon_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;
} OO_StatementCommon_Rec, *OO_StatementCommon;

typedef struct OO_ExceptionName_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;
  struct OO_Symbol_Rec *name;
  struct OO_Symbol_Rec *arg;
} OO_ExceptionName_Rec, *OO_ExceptionName;

typedef struct OO_ExceptionHandler_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;
  struct OO_ExceptionName_Rec *labels;
  union OO_Statement_Com *statement;
} OO_ExceptionHandler_Rec, *OO_ExceptionHandler;

/* case label */
typedef struct OO_CaseLabel_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;
  union OO_Expr_Com *expr;
} OO_CaseLabel_Rec, *OO_CaseLabel;

/* compound */
typedef struct OO_CompoundStatement_Rec {
  enum ObjectID id;
  union  OO_Statement_Com *next;
  unsigned int lineno;

  struct OO_Block_Rec *block; /* ?? */
  union  OO_Statement_Com   *statements;

  union OO_Statement_Com *prev;
} OO_CompoundStatement_Rec, *OO_CompoundStatement;

/* expr */
typedef struct OO_ExprStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Expr_Com *expr;
} OO_ExprStatement_Rec, *OO_ExprStatement;

/* if */
typedef struct OO_IfStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Expr_Com *expr;
  union OO_Statement_Com *then_part, *else_part;
} OO_IfStatement_Rec, *OO_IfStatement;

/* while */
typedef struct OO_WhileStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Expr_Com *expr;
  union OO_Statement_Com *statement;
} OO_WhileStatement_Rec, *OO_WhileStatement;

/* do */
typedef struct OO_DoStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Statement_Com *statement;
  union OO_Expr_Com *expr;
} OO_DoStatement_Rec, *OO_DoStatement;

/* for */
typedef struct OO_ForStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Expr_Com *expr1, *expr2, *expr3;
  union OO_Statement_Com *statement;
} OO_ForStatement_Rec, *OO_ForStatement;

/* switch */
typedef struct OO_SwitchStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Expr_Com *expr;
  union OO_Statement_Com *statement;
} OO_SwitchStatement_Rec, *OO_SwitchStatement;

#define OP_BREAK    24
#define OP_CONTINUE 25

/* jump */
typedef struct OO_JumpStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  char op;	/* continue or break */
} OO_JumpStatement_Rec, *OO_JumpStatement;

/* inline language */
typedef struct OO_InlineStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  char *lang_name;
  char *statement;
} OO_InlineStatement_Rec, *OO_InlineStatement;

#define OP_RETURN    26
#define OP_WAIT      27
#define OP_SIGNAL    28
#define OP_SIGNALALL 29
#define OP_DETACH    30
#define OP_RAISE     31
#define OP_KILL      32
#define OP_ABORT     33
#define OP_ABORTABLE 34

/* with expr */
typedef struct OO_WithExprStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  char op;
  union OO_Expr_Com *expr1;
  union OO_Expr_Com *expr2;
} OO_WithExprStatement_Rec, *OO_WithExprStatement;

typedef struct OO_NoExprStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  char op;
} OO_NoExprStatement_Rec, *OO_NoExprStatement;

typedef struct OO_ExceptionStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Statement_Com *try_part;
  struct OO_ExceptionHandler_Rec *handler_part;
} OO_ExceptionStatement_Rec, *OO_ExceptionStatement;

typedef struct OO_DebugPrintStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Expr_Com *exp;
  char *format;
  struct OO_List_Rec *args;
} OO_DebugPrintStatement_Rec, *OO_DebugPrintStatement;

typedef struct OO_DebugBlockStatement_Rec {
  enum ObjectID id;
  union OO_Statement_Com *next;
  unsigned int lineno;

  union OO_Statement_Com *block;
} OO_DebugBlockStatement_Rec, *OO_DebugBlockStatement;

/* Statement */
typedef union OO_Statement_Com {
  enum ObjectID id;
  struct OO_StatementCommon_Rec statement_common_rec;
  struct OO_ExceptionName_Rec exception_name_rec;
  struct OO_ExceptionHandler_Rec exception_handler_rec;
  struct OO_CaseLabel_Rec case_label_rec;
  struct OO_CompoundStatement_Rec compound_statement_rec;
  struct OO_ExprStatement_Rec expr_statement_rec;
  struct OO_IfStatement_Rec if_statement_rec;
  struct OO_WhileStatement_Rec while_statement_rec;
  struct OO_DoStatement_Rec do_statement_rec;
  struct OO_ForStatement_Rec for_statement_rec;
  struct OO_SwitchStatement_Rec switch_statement_rec;
  struct OO_JumpStatement_Rec jump_statement_rec;
  struct OO_InlineStatement_Rec inline_statement_rec;
  struct OO_WithExprStatement_Rec with_expr_statement_rec;
  struct OO_NoExprStatement_Rec no_expr_statement_rec;
  struct OO_ExceptionStatement_Rec exception_statement_rec;
  struct OO_DebugPrintStatement_Rec debug_print_statement_rec;
  struct OO_DebugBlockStatement_Rec debug_block_statement_rec;
} OO_Statement_Com, *OO_Statement;

enum RENAME_ALIAS { RA_RENAME, RA_ALIAS };

/* rename/alias */
typedef struct OO_RenameAlias_Rec {
  enum ObjectID id;

  enum RENAME_ALIAS kind;
  struct OO_RenameAlias_Rec *next;
  struct OO_Symbol_Rec *from, *to;
} OO_RenameAlias_Rec, *OO_RenameAlias;

/* parent description */
typedef struct OO_ParentDesc_Rec {
  enum ObjectID id;

  struct OO_ParentDesc_Rec *next;
  struct OO_ClassType_Rec *class;
  struct OO_RenameAlias_Rec *rename_alias;

} OO_ParentDesc_Rec, *OO_ParentDesc;

typedef union OO_Object_Com {
  enum ObjectID id;
  struct OO_Symbol_Rec		  symbol_rec;
  struct OO_Constant_Rec	  constant_rec;
  struct OO_ArrayReference_Rec    array_reference_rec;
  struct OO_MethodCall_Rec        method_call_rec;
  struct OO_Member_Rec            member_rec;
  struct OO_IncDec_Rec            inc_dec_rec;
  struct OO_Unary_Rec             unary_rec;
  struct OO_Binary_Rec            binary_rec;
  struct OO_ArithCompare_Rec      arith_compare_rec;
  struct OO_EqCompare_Rec         eq_compare_rec;
  struct OO_Assignment_Rec        assignment_rec;
  struct OO_Conditional_Rec       conditional_rec;
  struct OO_Comma_Rec             comma_rec;

  struct OO_SimpleType_Rec        simple_type_rec;
  struct OO_ClassType_Rec         class_type_rec;
  struct OO_TypeSCQF_Rec          type_scqf_rec;
  struct OO_TypeArray_Rec         type_array_rec;
  struct OO_TypeProcess_Rec       type_process_rec;
  struct OO_TypeMethod_Rec        type_method_rec;

  struct OO_StatementCommon_Rec   statement_common_rec;
  struct OO_ExceptionName_Rec    exception_name_rec;
  struct OO_ExceptionHandler_Rec    exception_handler_rec;
  struct OO_CaseLabel_Rec         case_label_rec;
  struct OO_CompoundStatement_Rec compound_statement_rec;
  struct OO_ExprStatement_Rec     expr_statement_rec;
  struct OO_IfStatement_Rec       if_statement_rec;
  struct OO_WhileStatement_Rec    while_statement_rec;
  struct OO_DoStatement_Rec       do_statement_rec;
  struct OO_ForStatement_Rec      for_statement_rec;
  struct OO_SwitchStatement_Rec   switch_statement_rec;
  struct OO_JumpStatement_Rec     jump_statement_rec;
  struct OO_InlineStatement_Rec   inline_statement_rec;
  struct OO_WithExprStatement_Rec with_expr_statement_rec;
  struct OO_NoExprStatement_Rec   no_expr_statement_rec;
  struct OO_ExceptionStatement_Rec      exception_statement_rec;
  struct OO_DebugPrintStatement_Rec      debug_print_statement_rec;
  struct OO_DebugBlockStatement_Rec      debug_block_statement_rec;

  struct OO_RenameAlias_Rec    rename_alias_rec;
  struct OO_ParentDesc_Rec        parent_desc_rec;

  struct OO_List_Rec              list_rec;

} OO_Object_Com, *OO_Object;



#endif _INTERNAL_H_
