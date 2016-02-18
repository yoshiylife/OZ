/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

shared SHCompiler
{
  AlreadyCompiled (String);
  IllegalPart (String);
  IllegalClass (String);

  char Public = 0, Protected = 1, Implementation = 2, If = 3, All = 4;
  char NewPublic = 5, NewProtected = 6, NewImplementation = 7;
}
