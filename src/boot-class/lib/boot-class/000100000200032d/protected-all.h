#define _PROTECTED_ALL_000100000200032d_H

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
#ifndef _OZ000100000200032dP_H_
#define _OZ000100000200032dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200032c 1
#define OZClassPart0001000002fffffe_0_in_000100000200032c 1
#define OZClassPart00010000020003e9_0_in_000100000200032c -1
#define OZClassPart00010000020003ea_0_in_000100000200032c -1
#define OZClassPart000100000200032c_0_in_000100000200032c 0

typedef struct OZ000100000200032dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200032dPart_Rec, *OZ000100000200032dPart;

#ifdef OZ_ObjectPart_PrivateDotsTokenReader
#undef OZ_ObjectPart_PrivateDotsTokenReader
#endif
#define OZ_ObjectPart_PrivateDotsTokenReader OZ000100000200032dPart

#endif _OZ000100000200032dP_H_


#endif _PROTECTED_ALL_000100000200032d_H
