/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _COMPILER_TYPE_H_
#define _COMPILER_TYPE_H_

typedef struct Type_Rec
{
  int process;
  int array;
  struct Type_Rec *next;
}  Type_Rec, *Type;

typedef struct TypedSymbol_Rec {
  Type type;
  char name[1];
} TypedSymbol_Rec, *TypedSymbol;

typedef struct MethodSymbol_Rec {
  TypedSymbol tsym;
  OO_List arg;
} MethodSymbol_Rec, *MethodSymbol;

static struct {
  char str[5];
} op_str[]={
  "++", "--", "&", "-", "+", 
  "~",  "!", "", "*", "/", "%", 
  "<<", ">>", "|", "^", "&&", "||",
  "", "<", ">", "<=", ">=", "==", "!=",
};

#ifdef OLD_EXEC_IF
static struct {
  char str[20];
} type_str[]={
  "void", 
  "char", 
  "short", 
  "int", "OZ_Long",
  "float", "double",
  "",
  "OZ_Condition",
  "OZ_Generic", 
};
#else
static struct {
  char str[20];
} type_str[]={
  "void", 
  "char", 
  "short", 
  "int", "OZ_Long",
  "float", "double",
  "",
  "OZ_ConditionRec",
  "OZ_Generic", 
};
#endif

static struct {
  char str[20];
} oz_type_str[]={
  "void", 
  "char", 
  "short", 
  "int", "long",
  "float", "double",
  "",
  "condition",
  "int", 
};

enum TypeConformance {
  TYPE_NG = -1,
  TYPE_OK,
  TYPE_SAFE,
};

enum TypeCheckMode {
  TYPE_NOT_EXACT,
  TYPE_EXACT,
  TYPE_NO_WARN = 0,
  TYPE_WARN,
};

extern void DestroyType (OO_Type);
extern OO_Type CreateType (int, char *, int, Type);

extern TypedSymbol CreateTypedSymbol (int, int, char *, TypedSymbol);
extern void DestroyTypedSymbol (TypedSymbol);

extern MethodSymbol CreateMethodSymbol (TypedSymbol, OO_List);
extern void DestroyMethodSymbol (MethodSymbol);

extern OO_ClassType GetClassType (OO_Expr, int *);

extern int CheckSignature (OO_TypeMethod, OO_TypeMethod, int);
extern int CheckType (OO_Type, OO_Type, int, int);
extern int CheckClassType (OO_ClassType, OO_ClassType, int, int);
extern int CheckArgs (OO_List, OO_List, int);
extern int CheckSimpleType (OO_Type, int);
extern int CheckTypeID (OO_Type, int);
extern int CheckReturnType (OO_Expr);

extern OO_Type CreateProcessType (OO_Type);

#endif _COMPILER_TYPE_H_

