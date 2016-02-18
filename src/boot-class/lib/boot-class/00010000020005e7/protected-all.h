#define _PROTECTED_ALL_00010000020005e7_H

#ifndef _OZ00010000020005e7P_H_
#define _OZ00010000020005e7P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005e6 1
#define OZClassPart0001000002fffffe_0_in_00010000020005e6 1
#define OZClassPart00010000020005e6_0_in_00010000020005e6 0

typedef struct OZ00010000020005e7Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020005e7Part_Rec, *OZ00010000020005e7Part;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_int__
#undef OZ_ObjectPart_Iterator_Assoc_String_int__
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_int__ OZ00010000020005e7Part

#endif _OZ00010000020005e7P_H_


#endif _PROTECTED_ALL_00010000020005e7_H
