#ifndef _PROTECTED_ALL_000100000200089d_H
#define _PROTECTED_ALL_000100000200089d_H

#ifndef _OZ000100000200089dP_H_
#define _OZ000100000200089dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200089c 1
#define OZClassPart0001000002fffffe_0_in_000100000200089c 1
#define OZClassPart000100000200089c_0_in_000100000200089c 0

typedef struct OZ000100000200089dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ000100000200089dPart_Rec, *OZ000100000200089dPart;

#ifdef OZ_ObjectPart_Iterator_MirrorOperation_
#undef OZ_ObjectPart_Iterator_MirrorOperation_
#endif
#define OZ_ObjectPart_Iterator_MirrorOperation_ OZ000100000200089dPart

#endif _OZ000100000200089dP_H_


#endif _PROTECTED_ALL_000100000200089d_H
