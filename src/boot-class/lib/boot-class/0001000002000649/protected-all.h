#define _PROTECTED_ALL_0001000002000649_H

#ifndef _OZ0001000002000649P_H_
#define _OZ0001000002000649P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000648 1
#define OZClassPart0001000002fffffe_0_in_0001000002000648 1
#define OZClassPart0001000002000648_0_in_0001000002000648 0

typedef struct OZ0001000002000649Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ0001000002000649Part_Rec, *OZ0001000002000649Part;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_global_ResolvableObject__
#undef OZ_ObjectPart_Iterator_Assoc_String_global_ResolvableObject__
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_global_ResolvableObject__ OZ0001000002000649Part

#endif _OZ0001000002000649P_H_


#endif _PROTECTED_ALL_0001000002000649_H
