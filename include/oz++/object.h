/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _LANG_OBJECT_H_
#define _LANG_OBJECT_H_

#include "executor/exec.h"
#include "oz++/ozlibc.h"
#include "oz++/debug.h"

#include "oz++/sysexcept.h"

inline static int
OzLangArrayLength (OZ_Array array)
{
  if (array)
    return array->head.h;
  else
    return 0;
}

inline static OZ_Object
OzLangNarrowToClass (OZ_Object from, OZ_ClassID class_id)
{
  OZ_Object o, end;
  OZ_ObjectAll all;
  
  if (from)
    {
      all = OzExecGetObjectTop (from);
      end = (OZ_Object) &all->head[all->head[0].h];
      for (o = from; o <= end; o++)
        {
          if (o->head.a == class_id)
	    return o;
        }
    }
  else
    return 0;

  OzExecRaise (OzExceptionNarrowFailed, 0, 0);
}

inline static OZ_Object
OzLangConvertToClass (OZ_Object from, OZ_ClassID class_id)
{
  OZ_Object o, end;
  OZ_ObjectAll all;
  
  all = OzExecGetObjectTop (from);
  end = (OZ_Object) &all->head[all->head[0].h];
  for (o = (OZ_Object) (all + 1); o <= end; o++)
    {
      if (o->head.a == class_id)
	return o;
    }

  OzExecRaise (OzExceptionTypeCorrectionFailed, 0, 0);
}

inline static int
OzLangArrayAlloc (OZ_Array *array, long long type, int size, int len)
{
  *array = (OZ_Array) OzExecReAllocateArray (type, size, len, *array);
  return len;
}

inline static OZ_Array
OzLangString (char *str)
{
  OZ_Array array;

  array = OzExecReAllocateArray (1LL, 1, OzStrlen (str) + 1, 0);
  OzStrcpy ((char *)array->mem, str); 
  return array;
}

inline static OZ_Monitor
OzLangMonitor (OZ_Object obj)
{
  OZ_ObjectAll all;

  all = OzExecGetObjectTop (obj);
  return (OZ_Monitor) all->head[0].t;
}

inline static OZ_Monitor
OzLangStaticMonitor (OZ_StaticObject obj)
{
  return (OZ_Monitor) obj->head.t;
}

#define OzLangAsClassOf(ClassPart, Class, Instance) \
  ({ \
    OZ_Object _obj = Instance; \
    if (_obj) \
      if (OZClassPart ## ClassPart ## _in_ ## Class ## == 1) \
	_obj = ((OZ_Object) &(OzExecGetObjectTop (_obj)->head[1])); \
      else \
        _obj = ((OZ_Object) \
	   (_obj + OZClassPart ## ClassPart ## _in_ ## Class ##)); \
    _obj; \
  })

#define OzLangInstance(Class, ClassPart, Suffix, Var) \
  ((OZ ## ClassPart ## Part) \
    OzLangAsClassOf(## ClassPart ## _ ## Suffix ##, Class, self)->head.d)->oz ## Var 

#if 1
#define OzLangInstanceInStatic(SClass, Var) \
  ((OZ ## SClass ## StaticObject) self)->oz ## Var

#define OzLangInstanceInRecord(Class, Var) \
  ((OZ ## Class ## Record) self)->oz ## Var

#define OzLangInstanceInRecordSub(Class, Var) \
  ((OZ ## Class ## Record) self->data)->oz ## Var
#endif

#define OZ_ArrayElement(Array, Type) \
  (## Type ## *) ## Array ## ->mem

#endif _LANG_OBJECT_H_



