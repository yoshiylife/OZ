/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_ALLOC_H_
#define _EXEC_ALLOC_H_

#include "executor/executor.h"
#include "oz++/object-type.h"
#include "oz++/type.h"

typedef long long OZ_Types;

inline	extern OZ_ObjectAll
OzExecGetObjectTop(OZ_Object obj)
{
    OZ_Pointer top;
    
    top = (OZ_Pointer) obj;
    top -= (sizeof (OZ_HeaderRec) * (obj->head.e + 1));
    
    return (OZ_ObjectAll)top;
}

OZ_ClassID OzExecGetConfigID( OZ_ClassID pvid );
extern OZ_StaticObject OzExecAllocateStaticObject (OZ_ClassID pvid);
extern OZ_Array OzExecReAllocateArray
  (OZ_Types type, int size, int number, OZ_Array array);
extern OZ_Object OzExecAllocateLocalObject (OZ_ClassID pvid);
extern void OzExecFree(OZ_Pointer ptr);  /* for Object Manager */
extern OID OzExecGetOID(OZ_Object obj);

#endif _EXEC_ALLOC_H_
