#define _PROTECTED_ALL_00010000020005c0_H

#ifndef _OZ00010000020005c0P_H_
#define _OZ00010000020005c0P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005bf 1
#define OZClassPart0001000002fffffe_0_in_00010000020005bf 1
#define OZClassPart00010000020005bf_0_in_00010000020005bf 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020005c0Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020005c0Part_Rec, *OZ00010000020005c0Part;

#ifdef OZ_ObjectPart_Iterator_Assoc_OIDAsKey_0__0__
#undef OZ_ObjectPart_Iterator_Assoc_OIDAsKey_0__0__
#endif
#define OZ_ObjectPart_Iterator_Assoc_OIDAsKey_0__0__ OZ00010000020005c0Part

#endif _OZ00010000020005c0P_H_


#endif _PROTECTED_ALL_00010000020005c0_H
