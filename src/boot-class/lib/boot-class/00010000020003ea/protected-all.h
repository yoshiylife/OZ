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
