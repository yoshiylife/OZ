#define _OZ00010000020002d2P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020002d1 1
#define OZClassPart0001000002fffffe_0_in_00010000020002d1 1
#define OZClassPart00010000020002d1_0_in_00010000020002d1 0

typedef struct OZ00010000020002d2Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozanExecutor;
  OZ_Object ozSuspension;

  /* protected (data) */
  OID ozO;
  int ozMyStatus;
  int ozPermanent;
  int ozRestoring;
  int ozSafelyShutdowned;
  int ozShutdownSign;
  int ozSomeoneFlushing;
  int ozSomeoneRemoving;
  int ozSuspending;

  /* protected (zero) */
  OZ_ConditionRec ozCelledIn;
  OZ_ConditionRec ozFlushed;
  OZ_ConditionRec ozLoaded;
  OZ_ConditionRec ozMelted;
  OZ_ConditionRec ozRestored;
  OZ_ConditionRec ozResumed;
} OZ00010000020002d2Part_Rec, *OZ00010000020002d2Part;

#ifdef OZ_ObjectPart_ObjectTableEntry
#undef OZ_ObjectPart_ObjectTableEntry
#endif
#define OZ_ObjectPart_ObjectTableEntry OZ00010000020002d2Part

#endif _OZ00010000020002d2P_H_
