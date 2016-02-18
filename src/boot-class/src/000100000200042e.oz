/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
 */
/*
  Copyright (c) 1994 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class WorkingObjectInClass
{
 constructor: Initialize;
 public: GetRequester, GetResult, GetWork, Start;
 protected: errorMessage, Status, Work;

   String aRequester;

   String errorMessage;
   int Status;

   int Work;

   void Initialize (char kind[])
     {
       aRequester=>NewFromArrayOfChar (kind);
     }

   void Start (Class cls) : abstract;

   String GetRequester ()
     {
       return aRequester;
     }

   int GetResult (String result)
     {
       result->Assign (errorMessage);

       return Status;
     }

   int GetWork ()
     {
       return Work;
     }
}
