#ifndef _PROTECTED_ALL_00010000020006c0_H
#define _PROTECTED_ALL_00010000020006c0_H

#ifndef _PROTECTED_ALL_00010000020006c5_H
#define _PROTECTED_ALL_00010000020006c5_H

#ifndef _PROTECTED_ALL_00010000020006cf_H
#define _PROTECTED_ALL_00010000020006cf_H

#ifndef _OZ00010000020006cfP_H_
#define _OZ00010000020006cfP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006ce 1
#define OZClassPart0001000002fffffe_0_in_00010000020006ce 1
#define OZClassPart00010000020006ce_0_in_00010000020006ce 0

typedef struct OZ00010000020006cfPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020006cfPart_Rec, *OZ00010000020006cfPart;

#ifdef OZ_ObjectPart_Collection_Assoc_String_Package__
#undef OZ_ObjectPart_Collection_Assoc_String_Package__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_Package__ OZ00010000020006cfPart

#endif _OZ00010000020006cfP_H_


#endif _PROTECTED_ALL_00010000020006cf_H
#ifndef _OZ00010000020006c5P_H_
#define _OZ00010000020006c5P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006c4 1
#define OZClassPart0001000002fffffe_0_in_00010000020006c4 1
#define OZClassPart00010000020006ce_0_in_00010000020006c4 -1
#define OZClassPart00010000020006cf_0_in_00010000020006c4 -1
#define OZClassPart00010000020006c4_0_in_00010000020006c4 0

typedef struct OZ00010000020006c5Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020006c5Part_Rec, *OZ00010000020006c5Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_Package__
#undef OZ_ObjectPart_Set_Assoc_String_Package__
#endif
#define OZ_ObjectPart_Set_Assoc_String_Package__ OZ00010000020006c5Part

#endif _OZ00010000020006c5P_H_


#endif _PROTECTED_ALL_00010000020006c5_H
#ifndef _OZ00010000020006c0P_H_
#define _OZ00010000020006c0P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006bf 1
#define OZClassPart0001000002fffffe_0_in_00010000020006bf 1
#define OZClassPart00010000020006ce_0_in_00010000020006bf -2
#define OZClassPart00010000020006cf_0_in_00010000020006bf -2
#define OZClassPart00010000020006c4_0_in_00010000020006bf -1
#define OZClassPart00010000020006c5_0_in_00010000020006bf -1
#define OZClassPart00010000020006bf_0_in_00010000020006bf 0

typedef struct OZ00010000020006c0Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020006c0Part_Rec, *OZ00010000020006c0Part;

#ifdef OZ_ObjectPart_Dictionary_String_Package_
#undef OZ_ObjectPart_Dictionary_String_Package_
#endif
#define OZ_ObjectPart_Dictionary_String_Package_ OZ00010000020006c0Part

#endif _OZ00010000020006c0P_H_


#endif _PROTECTED_ALL_00010000020006c0_H
