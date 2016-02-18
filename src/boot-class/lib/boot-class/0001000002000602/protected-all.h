#define _PROTECTED_ALL_0001000002000602_H

#ifndef _OZ0001000002000602P_H_
#define _OZ0001000002000602P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000601 1
#define OZClassPart0001000002fffffe_0_in_0001000002000601 1
#define OZClassPart0001000002000601_0_in_0001000002000601 0

typedef struct OZ0001000002000602Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ0001000002000602Part_Rec, *OZ0001000002000602Part;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_Command__
#undef OZ_ObjectPart_Iterator_Assoc_String_Command__
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_Command__ OZ0001000002000602Part

#endif _OZ0001000002000602P_H_


#endif _PROTECTED_ALL_0001000002000602_H
