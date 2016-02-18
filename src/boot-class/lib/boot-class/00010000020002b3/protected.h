#define _OZ00010000020002b3P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020002b2 1
#define OZClassPart0001000002fffffe_0_in_00010000020002b2 1
#define OZClassPart0001000002000336_0_in_00010000020002b2 -1
#define OZClassPart0001000002000337_0_in_00010000020002b2 -1
#define OZClassPart00010000020002b2_0_in_00010000020002b2 0

typedef struct OZ00010000020002b3Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozAID;
  OZ_Object ozOTM;
  OZ_Object ozaPreloader;
  OZ_Object ozaNameDirectoryHolder;
  OZ_Object ozaClassLookupper;
  OZ_Object ozConfigurationCache;
  OZ_Object ozBootConfiguration;
  OZ_Object ozaConfigurationTables;
  OZ_Object ozaConfigurationCacheExpirer;
  OZ_Object ozanExecutor;
  OZ_Object ozaClassBroadcastManager;
  OZ_Array ozOwner;
  OZ_Object ozaDaemons;
  OZ_Object ozOTEntryModifying;
  OZ_Array ozKeysOfInitialConfiguration;
  OZ_Array ozValuesOfInitialConfiguration;

  /* protected (data) */
  int ozConfigurationCacheExpiration;
  unsigned int ozConfigurationCacheExpirationTick;
  OID ozaStation;
  unsigned int ozNumberOfStartingExecutor;
  unsigned int ozSizeOfInitialConfiguration;
  unsigned int ozFirstWarningAtSearchClassImpl;
  unsigned int ozSuccessiveWarningAtSearchClassImpl;

  /* protected (zero) */
} OZ00010000020002b3Part_Rec, *OZ00010000020002b3Part;

#ifdef OZ_ObjectPart_ObjectManager
#undef OZ_ObjectPart_ObjectManager
#endif
#define OZ_ObjectPart_ObjectManager OZ00010000020002b3Part

#endif _OZ00010000020002b3P_H_
