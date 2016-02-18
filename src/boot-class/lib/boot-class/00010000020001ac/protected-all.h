#define _PROTECTED_ALL_00010000020001ac_H

#ifndef _OZ00010000020001acP_H_
#define _OZ00010000020001acP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001ab 1
#define OZClassPart0001000002fffffe_0_in_00010000020001ab 1
#define OZClassPart00010000020001ab_0_in_00010000020001ab 0

typedef struct OZ00010000020001acPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozFname;
  int pad0;

  /* protected (data) */
  int ozFd;

  /* protected (zero) */
} OZ00010000020001acPart_Rec, *OZ00010000020001acPart;

#ifdef OZ_ObjectPart_FStream
#undef OZ_ObjectPart_FStream
#endif
#define OZ_ObjectPart_FStream OZ00010000020001acPart

#endif _OZ00010000020001acP_H_


#endif _PROTECTED_ALL_00010000020001ac_H
