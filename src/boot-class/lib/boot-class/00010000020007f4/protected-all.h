#ifndef _PROTECTED_ALL_00010000020007f4_H
#define _PROTECTED_ALL_00010000020007f4_H

#ifndef _OZ00010000020007f4P_H_
#define _OZ00010000020007f4P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007f3 1
#define OZClassPart0001000002fffffe_0_in_00010000020007f3 1
#define OZClassPart00010000020007f3_0_in_00010000020007f3 0

typedef struct OZ00010000020007f4Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020007f4Part_Rec, *OZ00010000020007f4Part;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_Directory_global_ResolvableObject___
#undef OZ_ObjectPart_Iterator_Assoc_String_Directory_global_ResolvableObject___
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_Directory_global_ResolvableObject___ OZ00010000020007f4Part

#endif _OZ00010000020007f4P_H_


#endif _PROTECTED_ALL_00010000020007f4_H
