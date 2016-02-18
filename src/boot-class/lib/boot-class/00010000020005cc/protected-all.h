#define _PROTECTED_ALL_00010000020005cc_H

#ifndef _PROTECTED_ALL_0001000002000540_H
#define _PROTECTED_ALL_0001000002000540_H

#ifndef _OZ0001000002000540P_H_
#define _OZ0001000002000540P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200053f 1
#define OZClassPart0001000002fffffe_0_in_000100000200053f 1
#define OZClassPart000100000200053f_0_in_000100000200053f 0

typedef struct OZ0001000002000540Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ0001000002000540Part_Rec, *OZ0001000002000540Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_String__
#undef OZ_ObjectPart_Collection_Assoc_String_String__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_String__ OZ0001000002000540Part

#endif _OZ0001000002000540P_H_


#endif _PROTECTED_ALL_0001000002000540_H
#ifndef _OZ00010000020005ccP_H_
#define _OZ00010000020005ccP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005cb 1
#define OZClassPart0001000002fffffe_0_in_00010000020005cb 1
#define OZClassPart000100000200053f_0_in_00010000020005cb -1
#define OZClassPart0001000002000540_0_in_00010000020005cb -1
#define OZClassPart00010000020005cb_0_in_00010000020005cb 0

typedef struct OZ00010000020005ccPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020005ccPart_Rec, *OZ00010000020005ccPart;

#ifdef OZ_ObjectPart_Set_Assoc_String_String__
#undef OZ_ObjectPart_Set_Assoc_String_String__
#endif
#define OZ_ObjectPart_Set_Assoc_String_String__ OZ00010000020005ccPart

#endif _OZ00010000020005ccP_H_


#endif _PROTECTED_ALL_00010000020005cc_H
