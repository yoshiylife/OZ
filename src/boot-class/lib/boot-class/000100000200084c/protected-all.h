#ifndef _PROTECTED_ALL_000100000200084c_H
#define _PROTECTED_ALL_000100000200084c_H

#ifndef _PROTECTED_ALL_0001000002000847_H
#define _PROTECTED_ALL_0001000002000847_H

#ifndef _PROTECTED_ALL_0001000002000829_H
#define _PROTECTED_ALL_0001000002000829_H

#ifndef _OZ0001000002000829P_H_
#define _OZ0001000002000829P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000828 1
#define OZClassPart0001000002fffffe_0_in_0001000002000828 1
#define OZClassPart0001000002000828_0_in_0001000002000828 0

typedef struct OZ0001000002000829Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozTable;
  int pad0;

  /* protected (data) */
  unsigned int ozExpansionFactor;
  unsigned int ozInitialTableSize;
  unsigned int ozNbits;
  unsigned int ozNumberOfElement;

  /* protected (zero) */
} OZ0001000002000829Part_Rec, *OZ0001000002000829Part;

#ifdef OZ_ObjectPart_OIDSet_global_ClassID_
#undef OZ_ObjectPart_OIDSet_global_ClassID_
#endif
#define OZ_ObjectPart_OIDSet_global_ClassID_ OZ0001000002000829Part

#endif _OZ0001000002000829P_H_


#endif _PROTECTED_ALL_0001000002000829_H
#ifndef _OZ0001000002000847P_H_
#define _OZ0001000002000847P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000846 1
#define OZClassPart0001000002fffffe_0_in_0001000002000846 1
#define OZClassPart0001000002000828_0_in_0001000002000846 -1
#define OZClassPart0001000002000829_0_in_0001000002000846 -1
#define OZClassPart0001000002000846_0_in_0001000002000846 0

typedef struct OZ0001000002000847Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  OID ozID;

  /* protected (zero) */
} OZ0001000002000847Part_Rec, *OZ0001000002000847Part;

#ifdef OZ_ObjectPart_ClassPackage
#undef OZ_ObjectPart_ClassPackage
#endif
#define OZ_ObjectPart_ClassPackage OZ0001000002000847Part

#endif _OZ0001000002000847P_H_


#endif _PROTECTED_ALL_0001000002000847_H
#ifndef _OZ000100000200084cP_H_
#define _OZ000100000200084cP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200084b 1
#define OZClassPart0001000002fffffe_0_in_000100000200084b 1
#define OZClassPart0001000002000828_0_in_000100000200084b -2
#define OZClassPart0001000002000829_0_in_000100000200084b -2
#define OZClassPart0001000002000846_0_in_000100000200084b -1
#define OZClassPart0001000002000847_0_in_000100000200084b -1
#define OZClassPart000100000200084b_0_in_000100000200084b 0

typedef struct OZ000100000200084cPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200084cPart_Rec, *OZ000100000200084cPart;

#ifdef OZ_ObjectPart_MirroredClassPackage
#undef OZ_ObjectPart_MirroredClassPackage
#endif
#define OZ_ObjectPart_MirroredClassPackage OZ000100000200084cPart

#endif _OZ000100000200084cP_H_


#endif _PROTECTED_ALL_000100000200084c_H
