/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OBJECT_H_
#define _OBJECT_H_

#include "oz++/class-type.h"
#include "lang/types.h"

enum Operator {
  OP_VALUE,
  OP_PLUS,
  OP_MINUS,
  OP_MUL,
  OP_DIV,
  OP_MOD,

  OP_AND,
  OP_EOR,
  OP_OR,

  OP_LSHIFT,
  OP_RSHIFT,
  
  OP_NOT,
  OP_UMINUS,

  OP_EXP,

  OP_VAL,
  OP_ARRAY_VAL,

  OP_BR,
  OP_COM,

  OP_INDEX,
};

typedef struct RecordRec {
  char *name;
  struct TypePartRec *type;
  struct RecordRec *next;
} RecordRec, *Record;

typedef struct ExpRec {
  struct ExpRec *exp1;
  struct ExpRec *exp2;
  char *member;
  int op;
} ExpRec, *Exp;

typedef struct TypeListRec {
  char *name;
  char *type;
  enum Struct {
    T_STRUCT,
    T_UNION,
  } s;
  struct TypeListRec *next;
} TypeListRec, *TypeList;

typedef struct TypePartRec {
  int part_no;
  char *cid;
  TypeList list;
} TypePartRec, *TypePart;

typedef struct TypeRec {
  int no_parts;
  TypePart part[1];
} TypeRec, *Type;

typedef struct ClassRec {
  char *name;
  char *cid;
  int kind;
  OZ_ClassInfo info;
  struct TypeRec *type;
  struct ClassRec *next; 
} ClassRec, *Class;

typedef struct ObjectRec {
  char *name;
  struct ClassRec *class; /* if array, then NULL */
  char *oid; /* if array, then type */
  int count;
  OID type; /* if array, use */
  int ref;
  struct InstanceValRec *instance, *instance_tail;
  struct ObjectRec *locals; /* if array, then size */
  struct ObjectRec *g; 
  struct ObjectRec *next;
} ObjectRec, *Object;

#define T_GLOBAL -1
#define T_LOCAL -2
#define T_STATIC -3
#define T_RECORD -4
#define T_OID -5
#define T_ARRAY -6
#define T_EXP -7
#define T_STR -8
 
typedef struct InstanceValRec {
  char *name;
  char *val;
  int type;
  int index;
  char *member;
  struct InstanceValRec *next;
} InstanceValRec, *InstanceVal;

typedef struct ArrayRec {
  int no_elements;
  int so_element;
} ArrayRec, *Array;

typedef struct ScopeRec {
  struct ObjectRec *obj;
  struct ScopeRec *prev, *next;
} ScopeRec, *Scope;

extern Class c_list;
extern Object g_list;

extern int yylineno;
extern int error;

extern Exp CreateExp();
extern char *CreateObject(), *CreateArray(), *UpLevel();

#define RECORD_TYPE "Record"

static struct Types {
  char name[20];
  char ozname[20];
  int type;
} types[] = {
  "", "", NULL,
  "char", "char", OZ_CHAR, 
  "short", "short", OZ_SHORT,
  "int", "int", OZ_INT, "long long", "long", OZ_LONG_LONG,
  "float", "float", OZ_FLOAT, "double", "double", OZ_DOUBLE,
  "", "", NULL,
  "OZ_Condition", "condition", OZ_CONDITION,
  "", "", NULL,
  "", "", NULL,  "", "", NULL, "", "", NULL,
  "", "", NULL,
  "OZ_Object", "", OZ_LOCAL_OBJECT,
  "", "", NULL,
  "OZ_StaticObject", "", OZ_STATIC_OBJECT,

  "OID", "", OZ_GLOBAL_OBJECT,
  "OZ_Array", "", OZ_ARRAY,
};

#define NO_TYPES 7

#endif _OBJECT_H_

