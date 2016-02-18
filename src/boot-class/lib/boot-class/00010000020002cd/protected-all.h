#define _PROTECTED_ALL_00010000020002cd_H

#ifndef _OZ00010000020002cdP_H_
#define _OZ00010000020002cdP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020002cc 1
#define OZClassPart0001000002fffffe_0_in_00010000020002cc 1
#define OZClassPart00010000020002cc_0_in_00010000020002cc 0

typedef struct OZ00010000020002cdPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020002cdPart_Rec, *OZ00010000020002cdPart;

#ifdef OZ_ObjectPart_OStream
#undef OZ_ObjectPart_OStream
#endif
#define OZ_ObjectPart_OStream OZ00010000020002cdPart

#endif _OZ00010000020002cdP_H_


#endif _PROTECTED_ALL_00010000020002cd_H
