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
shared SHCompiler
{
  AlreadyCompiled (String);
  IllegalPart (String);
  IllegalClass (String);

  char Public = 0, Protected = 1, Implementation = 2, If = 3, All = 4;
  char NewPublic = 5, NewProtected = 6, NewImplementation = 7;
}
