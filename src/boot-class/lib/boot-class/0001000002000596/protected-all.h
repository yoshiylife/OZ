#define _PROTECTED_ALL_0001000002000596_H

#ifndef _PROTECTED_ALL_000100000200059b_H
#define _PROTECTED_ALL_000100000200059b_H

#ifndef _PROTECTED_ALL_00010000020005a5_H
#define _PROTECTED_ALL_00010000020005a5_H

#ifndef _OZ00010000020005a5P_H_
#define _OZ00010000020005a5P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005a4 1
#define OZClassPart0001000002fffffe_0_in_00010000020005a4 1
#define OZClassPart00010000020005a4_0_in_00010000020005a4 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020005a5Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020005a5Part_Rec, *OZ00010000020005a5Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_0___
#undef OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_0___
#endif
#define OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_0___ OZ00010000020005a5Part

#endif _OZ00010000020005a5P_H_


#endif _PROTECTED_ALL_00010000020005a5_H
#ifndef _OZ000100000200059bP_H_
#define _OZ000100000200059bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200059a 1
#define OZClassPart0001000002fffffe_0_in_000100000200059a 1
#define OZClassPart00010000020005a4_0_in_000100000200059a -1
#define OZClassPart00010000020005a5_0_in_000100000200059a -1
#define OZClassPart000100000200059a_0_in_000100000200059a 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200059bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ000100000200059bPart_Rec, *OZ000100000200059bPart;

#ifdef OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_0___
#undef OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_0___
#endif
#define OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_0___ OZ000100000200059bPart

#endif _OZ000100000200059bP_H_


#endif _PROTECTED_ALL_000100000200059b_H
#ifndef _OZ0001000002000596P_H_
#define _OZ0001000002000596P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000595 1
#define OZClassPart0001000002fffffe_0_in_0001000002000595 1
#define OZClassPart00010000020005a4_0_in_0001000002000595 -2
#define OZClassPart00010000020005a5_0_in_0001000002000595 -2
#define OZClassPart000100000200059a_0_in_0001000002000595 -1
#define OZClassPart000100000200059b_0_in_0001000002000595 -1
#define OZClassPart0001000002000595_0_in_0001000002000595 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000596Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000596Part_Rec, *OZ0001000002000596Part;

#ifdef OZ_ObjectPart_Dictionary_String_global_DirectoryServer_0__
#undef OZ_ObjectPart_Dictionary_String_global_DirectoryServer_0__
#endif
#define OZ_ObjectPart_Dictionary_String_global_DirectoryServer_0__ OZ0001000002000596Part

#endif _OZ0001000002000596P_H_


#endif _PROTECTED_ALL_0001000002000596_H
