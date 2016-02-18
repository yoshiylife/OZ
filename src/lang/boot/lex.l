%{
  /* lex for 'Object Image Compiler' */
#include "object.h"
#include "y.tab.h"
%}
%a=4000
%o=5500
%start COMM ONECOMM
%%
<INITIAL>global return(GLOBAL);
<INITIAL>local return(LOCAL);
<INITIAL>class return(CLASS);
<INITIAL>oid return(OID);
<INITIAL>array return(ARRAY);
<INITIAL>static return(STATIC);
<INITIAL>record return(RECORD);
<INITIAL>unsigned return(UNSIGNED);
<INITIAL>char { copy(yytext); return(CHAR); }
<INITIAL>short { copy(yytext); return(TYPE); }
<INITIAL>int { copy(yytext); return(TYPE); }
<INITIAL>long { copy(yytext); return(TYPE); }
<INITIAL>float { copy(yytext); return(TYPE); }
<INITIAL>double { copy(yytext); return(TYPE); }
<INITIAL>">" return('>');
<INITIAL>"<" return('<');
<INITIAL>"=" return('=');
<INITIAL>";" return(';');
<INITIAL>"{" return('{');
<INITIAL>"}" return('}');
<INITIAL>"(" return('(');
<INITIAL>")" return(')');
<INITIAL>"[" return('[');
<INITIAL>"]" return(']');
<INITIAL>":" return(':');
<INITIAL>"+" return('+');
<INITIAL>"-" return('-');
<INITIAL>"*" return('*');
<INITIAL>"/" return('/');
<INITIAL>"%" return('%');
<INITIAL>"|" return('|');
<INITIAL>"^" return('^');
<INITIAL>"&" return('&');
<INITIAL>"~" return('~');
<INITIAL>"." return('.');
<INITIAL>"," return(',');
<INITIAL>[ \t\n] ;
<INITIAL>"0" { copy(yytext); return(INTEGER); }
<INITIAL>[1-9][0-9]* { copy(yytext); return(INTEGER); }
<INITIAL>[1-9][0-9]*[uU] { copy(yytext); return(UINTEGER); }
<INITIAL>[1-9][0-9]*[lL][lL] { copy(yytext); return(LLINTEGER); }
<INITIAL>[1-9][0-9]*[uU][lL][lL] { copy(yytext); return(ULLINTEGER); }
<INITIAL>[0-9]+"."[0-9]+ { copy(yytext); return(DOUBLEVAL); }
<INITIAL>[0-9]"."[0-9]+[eE]-[1-9]+ { copy(yytext); return(DOUBLEVAL); }
<INITIAL>[0-9]+"."[0-9]+[fF] { copy(yytext); return(FLOATVAL); }
<INITIAL>[0-9]"."[0-9]+[eE]-[1-9]+[fF] { copy(yytext); return(FLOATVAL); }
<INITIAL>[0-9a-fA-F]{16} { copy(yytext); return(ID_L); }
<INITIAL>[0-9a-fA-F]{6} { copy(yytext); return(ID_S); }
<INITIAL>[_a-zA-Z][_0-9a-zA-Z]* { copy(yytext); return(IDENTIFIER); }
<INITIAL>'.' { copy(yytext); return(CONST_CHAR); }
<INITIAL>0[0-7]* { copy(yytext); return(OCT); }
<INITIAL>0[0-7]*[uU] { copy(yytext); return(UOCT); }
<INITIAL>0[0-7]*[uU][lL][lL] { copy(yytext); return(ULLOCT); }
<INITIAL>0[xX][0-9a-fA-F]* { copy(yytext); return(HEX); }
<INITIAL>0[xX][0-9a-fA-F]*[uU] { copy(yytext); return(UHEX); }
<INITIAL>0[xX][0-9a-fA-F]*[lL][lL] { copy(yytext); return(LLHEX); }
<INITIAL>0[xX][0-9a-fA-F]*[uU][lL][lL] { copy(yytext); return(ULLHEX); }
<INITIAL>\".*\" { copy(yytext); return(STR); }
<INITIAL>"/*" BEGIN COMM;
<INITIAL>"//" BEGIN ONECOMM;
<ONECOMM>\n BEGIN INITIAL;
<ONECOMM>. ;
<COMM>"*/" BEGIN INITIAL;
<COMM>\n ;
<COMM>. ;
%%

copy(char *str)
{
  char *buf = (char *)malloc(strlen(str) + 1);
  yylval = strcpy(buf, str);
}  


