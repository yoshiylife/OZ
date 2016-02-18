/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OBJECT_IMAGE_H_
#define _OBJECT_IMAGE_H_

#include <stdio.h>

#include "oz++/object-type.h"
#include "oz++/class-type.h"
#include "oz++/type.h"

#include "executor/exception.h"
#include "executor/monitor.h"

typedef struct ObjectListRec {
  OZ_Header obj;
  char *label;
  int offset;
  struct ObjectListRec *next;
} ObjectListRec, *ObjectList;

typedef struct PtrListRec {
  int *addr;
  char *label;
  struct PtrListRec *next;
} PtrListRec, *PtrList;

extern OZ_ClassInfo LoadClass();
extern void WriteObjects();
extern void AppendList();
extern void SetAllocInfo();
extern void SetPtrs();
extern void AppendPtrList();
extern OZ_Array CreateArray();
extern OID ConvertClassID();
extern void Init();
extern long long Str2OID(), Str2OIDwith();
extern void CreateIDs();

#define CREATE_ALL(obj, cid, vid, class) \
  (OZ##vid##All)malloc(sizeof(OZ##vid##All_Rec)); \
  bzero(obj, sizeof(OZ##vid##All_Rec)); \
  if (!class) \
    class = LoadClass(#cid); \
  obj->head[0].h = class->number_of_parts; \
  obj->head[0].a = (OID) ConvertClassID(#cid)

#define CREATE_PART(c_id, obj, part_no, class, label) \
  (OZ##c_id##Part)obj->head[part_no + 1].d = (OZ_ObjectPart)malloc(sizeof(OZ##c_id##Part_Rec)); \
  bzero(obj->head[part_no + 1].d, sizeof(OZ##c_id##Part_Rec)); \
  obj->head[part_no + 1].e = part_no; \
  obj->head[part_no + 1].a = class->parts[part_no]->compiled_vid; \
  obj->head[part_no + 1].h = sizeof(OZ##c_id##Part_Rec); \
  obj->head[part_no + 1].h *= -1; \
  SetAllocInfo(&((OZ_ObjectPart)obj->head[part_no + 1].d)->info, class, part_no); \
  if (label) \
    AppendList(&obj->head[part_no + 1], label)

#define CREATE_STATIC(c_id, obj, class, label) \
  (OZ##c_id##Static)obj = (OZ##c_id##Static)malloc(sizeof(OZ##c_id##Static_Rec)); \
  bzero(obj, sizeof(OZ##c_id##Static_Rec)); \
  obj->head.h = -1; \
  if (!class) \
    class = LoadClass(#c_id); \
  obj->head.a = class->parts[0]->compiled_vid; \
  obj->head.e = sizeof(OZ##c_id##Static_Rec); \
  if (obj->head.e % 8) \
    obj->head.e += 8 - obj->head.e % 8; \
  SetAllocInfo(&obj->info, class, 0); \
  AppendList(obj, label)

#define INSTANCE(ptr, member) ptr->oz##member

#define ELEMENT(ptr, type, i) (*(((type *)ptr->mem)+i))

#define CREATE_ARRAY(ptr, t_size, size, label, id) \
  CreateArray(t_size, size, label); \
  ptr->head.a = Str2OID(id); \
  AppendList(ptr, label)

#endif _OBJECT_IMAGE_H
