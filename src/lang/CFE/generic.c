/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "generic.h"
#include "cfe.h"
#include "command.h"

enum MODE {
  ANY,
  METHOD_PARAM,
};

enum EMITMODE {
  NOT_EMIT,
  EMIT,
};
   
static ParameterList params = NULL, tail = NULL;

static FILE *src, *dest;

static char buffer[1024];
static int space_len;

static char try_convert (char, enum MODE, enum EMITMODE);

static void
  print_usage ()
{
  fprintf (stderr, "gen [-dh] <orig> <used> < orignal_file\n");
  fprintf (stderr, "\tgenerate source file from orignal source file\n");
  fprintf (stderr, "gen -p <orig>\n");
  fprintf (stderr, "\tprint generic parameters\n");
  fprintf (stderr, "gen -g <used>\n");
  fprintf (stderr, "gen -g1 <used>\n");
  fprintf (stderr, "\tprint original class name\n");
  fprintf (stderr, "\tif `-g1', "
	   "convert generic parameter to any characters\n");
}

static char 
read_next ()
{
  char c = getc (src), p;

  while (c == '/')
    {
      p = getc (src);
      if (p == '/')
	{
	  putc (c, dest);
	  while (p != '\n')
	    {
	      putc (p, dest);
	      p = getc (src);
	    }
	  putc (p, dest);
	  c = getc (src);
	}
      else if (p == '*')
	{
	  char prev;
	  
	  putc (c, dest);
	  putc (p, dest);
	  c = getc (src);

	  do
	    {
	      prev = c;
	      putc (prev, dest);
	      c = getc (src);
	    }
	  while (!(prev == '*' && c == '/'));
	  putc (c, dest);
	  c = getc (src);
	}
      else 
	{
	  ungetc (p, src);
	  return c;
	}
    }

  return c;
}

static char
read_process (char c)
{
  int level = 0;

  while (c == '(' || c == '@' || isspace (c))
    {
      do 
	{
	  if (c == '(')
	    level++;
	  else if (c == ')')
	    level--;

	  putc (c, dest);
	  c = read_next ();
	}
      while (level > 1);
    }

  return c;
}
	  
static char 
convert_param (char *str, int slen, enum MODE method_param)
{
  ParameterList buf = params;
  char c;
  int level = 0;

  c = str[strlen (str) + 1];

  while (buf)
    {
      char *q;

      /* compare with TypeParameter */
#if 0
      if (!strncmp (buf->param, str, slen))
#else
      if (buf->len == slen && !strncmp (buf->param, str, slen))
#endif
	break;

      /* convert parameters in class name */

      q = str;
      while (q = strstr (q, buf->param))
	{
	  char *r;

	  q--;
	  if (isspace (*q) || *q == '<' || *q == ',')
	    {
	      r = q + 1 + strlen (buf->param);
	      if (isspace (*r) || *r == '>' || *r == ',')
		{
		  *++q = 0;
		  fprintf (dest,"%s%s", str, buf->type1);
		  if (*buf->type2 || *buf->type3)
		    fprintf (dest," %s%s", buf->type2, buf->type3);

		  str = r;

		  if (!buf->next)
		    {
		      fprintf (dest,"%s", str);
		      return c;
		    }
		}
	    }
	  q += 2;
	}

      buf = buf->next;
    }

  /* not TypeParameter */
  if (!buf) 
    {
      fprintf (dest,"%s", str);
      return c;
    }
  
  /* emit base type */
  fprintf (dest,"%s%s", buf->type1, &str[slen]);

  /* emit process part */
  c = read_process (c);
  
  /* prototype defininition or exception definition */
  if (!isalpha (c) && c != '_')
    {
      fprintf (dest," %s", buf->type2);
      method_param = METHOD_PARAM;
    }
  /* emit identifier */
  else
    {
      fprintf (dest,"%s", buf->type2);
      c = try_convert (c, ANY, EMIT);
    }

  /* check wheter function */
  while (c == '(' || isspace (c))
    {
      if (c == '(')
	level++;
      putc (c, dest);
      c = read_next ();
    }

  /* this is function */
  if (isalpha (c) || c == '_' || (method_param == ANY && level && c == ')'))
    {
      /* emit each parameters */
      do
	{
	  int count;

	  while (isspace (c))
	    {
	      putc (c, dest);
	      c = read_next ();
	    }

	  /* test and emit type of parameter */
	  if (c != ')')
	    c = try_convert (c, METHOD_PARAM, EMIT);

	  if (!isalpha (c) && c != '_' && c != ')')
	    {
	      putc (c, dest);
	      c = read_next ();
	    }
	}
      while (c != ')');
    }
  
  /* search end */
  while (c != ';' && c != '{' && c != ':' && c != ',' &&
	 c != '=' && 
	 (method_param == ANY && level || c != ')'))
    {
      putc (c, dest);
      c = read_next ();
    }

  /* emit array part */
  fprintf (dest,"%s", buf->type3);

  /* case for containing some optional definitions */
  if (c == '=' || (method_param == ANY && c == ','))
    {
      int level = 0;

      /* execute for each variable definitions */
      do
	{
	  /* skip expressions */
	  if (c == '=')
	    {
	      while (!level && c != ';' && c != ',') 
		{
		  if (c == '(')
		    level++;
		  else if (c == ')')
		    level--;
	      
		  putc (c, dest);
		  c = read_next ();
		}
	    }
	  else
	    {
	      putc (c, dest);
	      c = read_next ();
	    }
	  
	  if (c == ';')
	    break;

	  c = read_process (c);
	  
	  if (!isalpha (c) && c != '_')
	    {
	      /* emit process part */
	      fprintf (dest," %s", buf->type2);
	    }
	  else
	    {
	      /* get next string */
	      c = try_convert (c, ANY, NOT_EMIT);

	      /* 
	       * looked like variable definitions, 
	       * but this is method parameters 
	       */
	      if (isalpha (c) || c == '_')
		{
		  return convert_param (buffer, strlen (buffer) - space_len, 
					METHOD_PARAM);
		}
	      else
		{
		  /* emit process part */
		  fprintf (dest,"%s%s", buf->type2, buffer);
		}
	    }

	  /* skip optional characters */
	  while (c != ';' && c != '=' && c != ',')
	    {
	      putc (c, dest);
	      c = read_next ();
	    }

	  /* emit array part */
	  fprintf (dest,"%s", buf->type3);
	}
      while (c != ';');
    }
  
  return c;
}

static char
try_convert (char c, enum MODE method_param, enum EMITMODE mode)
{
  char buf[1024], *p = buf;
  int count = 0;

  while (isalpha (c) || c == '_' || isdigit (c))
    {
      int level = 0;
      
      do
	{
	  if (level &&
	      strchr ("+-*/%^!?:;=|&~\"'", c))
	    {
	      *p = 0;
	      fprintf (dest,"%s", buf);
	      return c;
	    }

	  if (c == '<')
	    level++;
	  else if (level && c == '>')
	    level--;
	  
	  *p++ = c;
	  c = read_next ();
	  
	  if (isspace (c))
	    {
	      while (isspace (c))
		{
		  count++;
		  *p++ = c;
		  c = read_next ();
		}
	      if (!level && c != '<')
		goto convert;
	    }
	  else
	    count = 0;
	}
      while (c == '<' || level);
    }
 convert:
  *p++ = 0;
  *p = c;

/* ??? */
  if (!*buf)
    return c;

  if (mode == NOT_EMIT)
    {
      strcpy (buffer, buf);
      buffer[strlen (buffer) + 1] = c;
      space_len = count;
      return c;
    }
  else
    return convert_param (buf, strlen (buf) - count, method_param);
}


static
check_param (char *param)
{
  if (!strcmp (param, "char") || !strcmp (param, "short") || 
      !strcmp (param, "int") || !strcmp (param, "long") ||
      !strcmp (param, "float") || !strcmp (param, "double") ||
      !strcmp (param, "condition"))
    return;

  printf ("%s\n", param);
}

static
print_param_list ()
{
  ParameterList buf = params;

  while (buf)
    {
      char *c = buf->param;

      while (*c)
	{
	  if (*c == '<')
	    break;
	  c++;
	}

      if (!*c && (c = strchr (buf->param, ' ')))
	{
	  char *p;

	  while (c)
	    {
	      p = c;
	      c = strchr (p + 1, ' ');
	    }

	  check_param (++p);
	}
      else
	check_param (buf->param);

      buf = buf->next;
    }
}

static char *
get_param (char **str)
{
  char *p, *buf = NULL;
  int i = 0, level = 0;

  while (1)
    {
      if (**str == '<' || **str == ',')
	{
	  ++(*str);
	  while (**str == ' ' || **str == '\t')
	    (*str)++;

	  p = *str;

	  do 
	    {
	      if (**str == '<')
		level++;
	      else if (level && **str == '>')
		level--;

	      (*str)++;
	      i++;
	    }
	  while (level || (**str != '>' && **str != ','));
	  break;
	}
      else if (!**str)
	break;

      (*str)++;
    }

  if (i)
    {
      buf = (char *) malloc (i + 1);
      strncpy (buf, p, i);
      buf[i] = 0;
    }

  return buf;
}

static 
add_param_list (char *param, char *type)
{
  int param_len = strlen (param);
  ParameterList buf;
  char *c, types[256], *p = types;
  int len1 = 0, len2 = 0, len3 = 0, optional_len = 0;

  c = type ? type : "";

  while (*c == ' ') c++;

  while (*c && *c != '(' && *c != '@' && *c != '[')
    {
      int level = 0;
      int space = 0;

      do 
	{
	  if (space)
	    while (*c == ' ') c++;

	  if (*c == '<')
	    level++;
	  else if (*c == '>')
	    {
	      space = 0;
	      level--;
	    }

	  if (level && *c == ' ')
	    {
	      *p++ = ' ';
	      while (*c == ' ') c++;

	      if (*c == '(' || *c == '@' || *c == '[')
		space = 1;
	    }
	  else if (level && !space && (*c == '(' || *c == '@' || *c == '['))
	    {
	      *p++ = ' ';
	      space = 1;
	    }

	  *p++ = *c++;
	}
      while (level);
    }

  if (*(p - 1) == ' ')
    p--;
  *p++ = 0;
  len1 = strlen (types);

  while (*c && *c == ' ') c++;

  while (*c && *c != '[' && *(c + 1) != '[')
    *p++ = *c++;

  if (*c && *c != '[' && *c != ')')
    *p++ = *c++;

  *p++ = 0;
  len2 = strlen (&types[len1 + 1]);

  while (*c && *c == ' ') c++;

  while (*c)
    *p++ = *c++;

  *p = 0;
  len3 = strlen (&types[len1 + 1 + len2 + 1]);

 next:

  if (len2 > 0)
    optional_len = 1;
  
  buf = (ParameterList) malloc (sizeof (ParameterListRec)
				+ param_len + len1 + len2 + len3 
				+ optional_len * 2 + 3);
  buf->type1 = &buf->param[param_len + 1];
  buf->type2 = &buf->type1[len1 + 1 + optional_len];
  buf->type3 = &buf->type2[len2 + 1 + optional_len];
  buf->next = NULL;

  strcpy (buf->param, param);
  buf->len = strlen (buf->param);
  free (param);

  if (type)
    {
      strcpy (buf->type1, types);
      if (optional_len)
	{
	  sprintf (buf->type2, "%s(", &types[len1 + 1]);
	  sprintf (buf->type3, ")%s", 
		   &types[len1 + 1 + len2 + 1]);
	}
      else
	{
	  strcpy (buf->type2, &types[len1 + 1]);
	  strcpy (buf->type3, &types[len1 + 1 + len2 + 1]);
	}

#if 0
      fprintf (stderr, "1 = %s\n2 = %s\n3 = %s\n", 
	       buf->type1, buf->type2, buf->type3);
#endif
  
      free (type);
    }

  if (tail)
    tail->next = buf;
  else
    params = buf;

  tail = buf;
}

static int
  create_parameter_list (char *orig, char *used)
{
  char *param, *type = NULL;

  if (params)
    {
      ParameterList buf;

      while (params)
	{
	  buf = params;
	  free (params);
	  params = buf->next;
	}

      params = tail = NULL;
    }

  while (1)
    {
      if (!(param = get_param (&orig)))
	break;

      if (used)
	{
	  if (!(type = get_param (&used)))
	    {
	      fprintf (stderr, "cannot generate\n");
	      return 1;
	    }
	}

      add_param_list (param, type);
    }

  if (!used)
    print_param_list ();

  return 0;
}

static char *
  get_original_name (char *name, int mode)
{
  int level = 0, i = 0;
  char *buf, *p;

  if (!name)
    return NULL;

  p = buf = (char *) malloc (strlen (name) * 2);
  
  while (*name != '<' && *name)
    *p++ = *name++;
  
  if (*name)
    *p++ = *name++;
  else
    return NULL;

  if (!mode)
    {
      while (*name)
	{
	  while (*name != ',' && *name != '>' && *name != '<')
	    name++;
	  
	  if (*name == '<')
	    level++;
	  
	  if (!level)
	    {
	      *p++ = '*';
	      *p++ = *name;
	    }
	  
	  if (*name == '>' && level)
	    level--;
	  
	  name++;
	}
    }
  else 
    {
      while (*name)
	{
	  if (*name == '*')
	    {
	      *p++ = 'T';
	      sprintf (p, "%d", i++);
	      p = buf + strlen(buf);
	      name++;
	    }
	  else
	    *p++ = *name++;
	}
    }

  *p = 0;

  return buf;
}

static int
  convert (char *from, char *to)
{
  char c, prev;
  int str = 0;

  if (from)
    {
      if (!(src = fopen (from, "r")))
	{
	  fprintf (stderr, "cannot open file: %s", from);
	  return 1;
	}
    }
  else
    src = stdin;

  if (to)
    {
      if (!(dest = fopen (to, "w")))
	{
	  fprintf (stderr, "cannot open file: %s\n", to);
	  return 1;
	}
    }
  else
    dest = stdout;

  prev = 0;
  c = read_next ();
  while (c != EOF)
    {
      if (!str && (isalpha (c) || c == '_'))
	{
	  prev = c;
	  c = try_convert (c, ANY, EMIT);
	}
      else
	{
	  if (c == '"')
	    {
	      if (prev != '\\')
		str = str ? 0 : 1;
	    }
	  putc (c, dest);
	  prev = c;
	  c = read_next ();
	}
    }

  if (from)
    fclose (src);

  if (to)
    fclose (dest);

  return 0;
}

int 
  Generic (int argc, char **argv)
{
  int i, print_params = 0, print_original = 0;
  int arg_num = 2, status;
  char *name;

  for (i = 1; i < argc && *argv[i] == '-'; i++)
    {
      char *p;

      for (p = &argv[i][1]; *p; p++)
	{
	  switch (*p)
	    {
	    case 'p':
	      print_params = 1;
	      arg_num = 1;
	      break;
	    case 'g':
	      if (*(p + 1) == '1') 
		{
		  print_original = 2;
		  p++;
		}
	      else
		print_original = 1;
	      arg_num = 1;
	      break;
	    case 'h':
	    default:
	      print_usage ();
	      return 0;
	    }
	}
    }

  if (argc < i + arg_num)
    {
      print_usage ();
      return 1;
    }

  name = CleanupName (argv[i]);

  if (print_params)
    {
      status =  create_parameter_list (name, NULL);
      free (name);

      return status;
    }

  else if (print_original)
    {
      char *buf;

      if (buf = get_original_name (name, print_original - 1))
	{
	  printf ("%s\n", buf);
	  free (buf);
	  free (name);
	  return 0;
	}

      free (name);

      return 1;
    }

  else
    {
      char *name2 = CleanupName (argv[i + 1]);
      
      status = GenerateNew (name, name2, NULL, NULL);

      free (name);
      free (name2);
      
      return status;
    }
}

char *
  GetOriginalName (char *name, int convert)
{
  return get_original_name (name, convert);
}

int
  GenerateNew (char *orig, char *new, char *from, char *to)
{
  if (create_parameter_list (orig, new))
    return NULL;

  return convert (from, to);
}
