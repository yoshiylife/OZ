#define _OZ0001000002000698P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000697 1
#define OZClassPart0001000002fffffe_0_in_0001000002000697 1
#define OZClassPart0001000002000697_0_in_0001000002000697 0

typedef struct OZ0001000002000698Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ0001000002000698Part_Rec, *OZ0001000002000698Part;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_Directory_Package___
#undef OZ_ObjectPart_Iterator_Assoc_String_Directory_Package___
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_Directory_Package___ OZ0001000002000698Part

#endif _OZ0001000002000698P_H_
