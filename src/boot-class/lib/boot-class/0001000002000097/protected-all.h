#define _PROTECTED_ALL_0001000002000097_H

#ifndef _PROTECTED_ALL_00010000020003ea_H
#define _PROTECTED_ALL_00010000020003ea_H

#ifndef _OZ00010000020003eaP_H_
#define _OZ00010000020003eaP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003e9 1
#define OZClassPart0001000002fffffe_0_in_00010000020003e9 1
#define OZClassPart00010000020003e9_0_in_00010000020003e9 0

typedef struct OZ00010000020003eaPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozBuffer;
  OZ_Array ozExtractorTable;

  /* protected (data) */
  int ozEOF;

  /* protected (zero) */
  OZ_ConditionRec ozaTokenIsReady;
} OZ00010000020003eaPart_Rec, *OZ00010000020003eaPart;

#ifdef OZ_ObjectPart_TokenReader
#undef OZ_ObjectPart_TokenReader
#endif
#define OZ_ObjectPart_TokenReader OZ00010000020003eaPart

#endif _OZ00010000020003eaP_H_


#endif _PROTECTED_ALL_00010000020003ea_H
#ifndef _OZ0001000002000097P_H_
#define _OZ0001000002000097P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000096 1
#define OZClassPart0001000002fffffe_0_in_0001000002000096 1
#define OZClassPart00010000020003e9_0_in_0001000002000096 -1
#define OZClassPart00010000020003ea_0_in_0001000002000096 -1
#define OZClassPart0001000002000096_0_in_0001000002000096 0

typedef struct OZ0001000002000097Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000097Part_Rec, *OZ0001000002000097Part;

#ifdef OZ_ObjectPart_ClassListFileTokenReader
#undef OZ_ObjectPart_ClassListFileTokenReader
#endif
#define OZ_ObjectPart_ClassListFileTokenReader OZ0001000002000097Part

#endif _OZ0001000002000097P_H_


#endif _PROTECTED_ALL_0001000002000097_H
