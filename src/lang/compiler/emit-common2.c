/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <varargs.h>

#include "lang/internal.h"
#include "emit-common2.h"

static char indent[256];

#define BUFSIZE 1024
static int print_buf_len = BUFSIZE;
static char *print_buf = NULL, sub_print_buf[256];

static int
  emit_indent (FILE *fp)
{
  strcat (print_buf, indent);

  return strlen (indent);
}

void
Emit2 (FILE *fp, char *format, va_list pvar)
{
  char *current = format, form[256], *buf;
  static char emit_priv = 0;
  int i = 0;

  if (!print_buf)
    print_buf = (char *) malloc (print_buf_len + 1);

  bzero (print_buf, print_buf_len + 1);

  while (*current)
    {
      if (emit_priv == '\n' && fp != stderr)
	i += emit_indent (fp);

      switch (*current)
	{
	case '%':
	  buf = form;
	  *buf++ = *current++;
	  while (isdigit (*current) || *current == '-')
	    *buf++ = *current++;
	  *buf++ = *current;
	  *buf = '\0';
	  switch (*current)
	    {
	    case 'd':
	      sprintf (sub_print_buf, form, va_arg (pvar, int));
	      print_buf[i] = '\0';

	      if ((i += strlen (sub_print_buf)) > print_buf_len)
		{
		  print_buf_len += BUFSIZE;
		  print_buf = (char *) realloc (print_buf, print_buf_len + 1);
		}

	      strcat (print_buf, sub_print_buf);
	      break;
	    case 's':
	      buf = va_arg (pvar, char *);
	      print_buf[i] = '\0';

	      if ((i += strlen (buf)) > print_buf_len)
		{
		  do
		    {
		      print_buf_len += BUFSIZE;
		      print_buf 
			= (char *) realloc (print_buf, print_buf_len + 1);
		      if (! print_buf)
			{
			  perror (0);
			  abort ();
			}
		    }
		  while (i > print_buf_len);
		}

	      strcat (print_buf, buf);
	      break;
	    case 'c':
	      sprintf (sub_print_buf, form, va_arg (pvar, char *)[0]);
	      print_buf[i] = '\0';

	      if ((i += strlen (sub_print_buf)) > print_buf_len)
		{
		  print_buf_len += BUFSIZE;
		  print_buf = (char *) realloc (print_buf, print_buf_len + 1);
		}

	      strcat (print_buf, sub_print_buf);
	      break;
	    case 'x':
	      sprintf (sub_print_buf, form, va_arg (pvar, int));
	      print_buf[i] = '\0';

	      if ((i += strlen (sub_print_buf)) > print_buf_len)
		{
		  print_buf_len += BUFSIZE;
		  print_buf = (char *) realloc (print_buf, print_buf_len + 1);
		}

	      strcat (print_buf, sub_print_buf);
	      break;
	    case '%':
	      if (i > print_buf_len)
		{
		  print_buf_len += BUFSIZE;
		  print_buf = (char *) realloc (print_buf, print_buf_len + 1);
		}

	      print_buf[i++] = '%';
	      break;
	    }
	  break;
	case '\n':
	  if (i > print_buf_len)
	    {
	      print_buf_len += BUFSIZE;
	      print_buf = (char *) realloc (print_buf, print_buf_len + 1);
	    }

	  print_buf[i++] = '\n';
	  break;
	default:
	  if (i > print_buf_len)
	    {
	      print_buf_len += BUFSIZE;
	      print_buf = (char *) realloc (print_buf, print_buf_len + 1);
	    }

	  print_buf[i++] = *current;
	  break;
	}
      emit_priv = *current;
      current++;
    }
  print_buf[i] = '\0';
  fprintf (fp, "%s", print_buf);
}

void
EmitIndentReset ()
{
  indent[0] = '\0';
}

void
EmitIndentDown ()
{
  int len = strlen (indent) + 2, i;

  for (i = 0; i < len; i++)
    indent[i] = ' ';

  indent[i] = '\0';
}

void
EmitIndentUp ()
{
  int len = strlen (indent) - 2;

  indent[len < 0 ? 0 : len] = '\0';
}

#if 0
void
EmitSCQF (char *buf, int qual)
{
  if (qual & QF_UNSIGNED)
    {
      strcat (buf, "unsigned ");
    }

  if (qual & QF_CONST)
    {
      strcat (buf, "const ");
    }
    
  if (qual & SC_GLOBAL)
    {
      strcat (buf, "global ");
    }
}
#endif


