#define _PROTECTED_ALL_000100000200029b_H

#ifndef _PROTECTED_ALL_00010000020002cd_H
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
#ifndef _PROTECTED_ALL_00010000020001ac_H
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
#ifndef _OZ000100000200029bP_H_
#define _OZ000100000200029bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200029a 1
#define OZClassPart0001000002fffffe_0_in_000100000200029a 1
#define OZClassPart00010000020002cc_0_in_000100000200029a -2
#define OZClassPart00010000020002cd_0_in_000100000200029a -2
#define OZClassPart00010000020001ab_0_in_000100000200029a -1
#define OZClassPart00010000020001ac_0_in_000100000200029a -1
#define OZClassPart000100000200029a_0_in_000100000200029a 0

typedef struct OZ000100000200029bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200029bPart_Rec, *OZ000100000200029bPart;

#ifdef OZ_ObjectPart_OFStream
#undef OZ_ObjectPart_OFStream
#endif
#define OZ_ObjectPart_OFStream OZ000100000200029bPart

#endif _OZ000100000200029bP_H_


#endif _PROTECTED_ALL_000100000200029b_H
