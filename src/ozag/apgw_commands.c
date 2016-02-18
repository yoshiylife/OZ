/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* commands */

#include <sys/types.h> 
#include <sys/wait.h> 
#include <sys/time.h> 
#include <sys/resource.h> 
#include <sys/socket.h> 
#include <sys/uio.h> 
#include <sys/stat.h> 
#include <sys/ioctl.h> 
#include <sys/file.h> 
#include <sys/param.h> 
#include <net/if.h> 
#include <netinet/in.h> 
#include <nlist.h> 
#include <stdio.h> 
#include <signal.h> 
#include <errno.h> 
#include <utmp.h> 
#include <ctype.h>
#include <netdb.h>
#include <syslog.h>
#include <pwd.h>

#include "apgw.h"
#include "apgw_defs.h"
#include "apgw_sitetbl.h"
#include "comm-packets.h"
  
#include "ncl.h"
#include "ncl_defs.h"
#include "ncl_table.h"
#include "apgw_ethash.h"
#include "ex_ncl_event.h"

extern  HashTableRec	site_tbl;
extern char SiteTableLastModified[];

extern SiteTable   ApgwSearchSiHash(HashTable hp, int siteid);
extern int update_site_table(char *last_update);
extern void save_site_table();
extern int add_local_site();
extern int change_local_site();
extern int remove_local_site();

void
local_command()
{
  SiteTable st;
  int i,c;

      printf("----------------------------------------\n");
      printf("SITE :       policy      : relay NCL\n");

      for(i=0,c=site_tbl.count,st=(SiteTable)site_tbl.tp
	  ;(i<site_tbl.size && c>0);i++,st++)
	{
	  if((st->siteid !=0) && (st->loc == LOCAL_SITE))
	    {
	      printf("%04x :",st->siteid);
	      if(st->stype == PROGRESSIVE_SITE)
		printf("   PROGRESSIVE     ");
	      else if(st->stype == CONSERVATIVE_SITE)
		printf("   CONSERVATIVE    ");
	      else if(st->stype == INHIBITED_SITE)
		printf(" removed temporary ");
	      else
		printf(" ????????????????? ");
	      printf(": %s\n",ipaddr2str(st->rnclid));
	    }
	}
      printf("----------------------------------------\n");
}

void
add_command(char *sid,char *rncl_host,char *rncl_p,char *policy)
{
  int site_id,rncl_port;
  char s[256];

  if((site_id = strhtoi(sid))<=0 || site_id>0xffff)
    {
      printf("Illegal site_id (%s).  1<= site_id <0xffff\n",sid);
      return;
    }

  rncl_port = atoi(rncl_p);

  if(add_local_site(site_id,rncl_host,rncl_port,policy)==1)
    {
      printf("Local site (%04x) added\n",site_id);
      save_local_site_table();
      sprintf(s,"Add local site (%04x: %s : %d :%s)",site_id,rncl_host,rncl_port,policy); 
      syslog(s);
    }
}

void
remove_command(char *sid)
{
  int site_id;
  char s[256];

  if((site_id = strhtoi(sid))<=0 || site_id>0xffff)
    {
      printf("Illegal site_id (%s).  1<= site_id <0xffff\n",sid);
      return;
    }

  if(remove_local_site(site_id)==1)
    {
      printf("Local site (%04x) removed\n",site_id);
      save_local_site_table();
      sprintf(s,"Remove local site (%04x)",site_id); 
      syslog(s);
    }
}


void
change_command(char *sid,char *policy)
{
  int site_id;
  char s[256];

  if((site_id = strhtoi(sid))<=0 || site_id>0xffff)
    {
      printf("Illegal site_id (%s).  1<= site_id <0xffff\n",sid);
      return;
    }

  if(change_local_site(site_id,policy)==1)
    {
      printf("Local site (%04x) changed\n",site_id);
      save_local_site_table();
      sprintf(s,"Change local site (%04x:%s)",site_id,policy); 
      syslog(s);
    }
}

void
update_command()
{
  if(update_site_table(SiteTableLastModified)==1)
    { 
      save_site_table();
      init_localsite_info();
      syslog("Update site table");
    }

}

void
list_command(char *site)
{
  SiteTable st;
  int i,c;

  if((site==0)||(site[0]=='\0'))
    {
      printf("========================================\n");
      printf("SITE : IP address of application gateway\n");

      for(i=0,c=site_tbl.count,st=(SiteTable)site_tbl.tp
	  ;(i<site_tbl.size && c>0);i++,st++)
	{
	  if(st->siteid !=0)
	    {
	      printf("%04x : %s\n",st->siteid,ipaddr2str(st->apgwaddr));
	    }
	}

      printf("========================================\n");
    }
  else
    {
      if(((i=strhtoi(site))<0)||(i>0xffff))
	{
	  printf("illegal site-ID (%s)\n",site);
	}
      else if((st=ApgwSearchSiHash(&site_tbl,i))==0)
	{
	  printf("No such site (%04x)\n",i);
	}
      else
	{
	  printf("Site = %04x : Application gateway = %s\n",i,ipaddr2str(st->apgwaddr));
	}
    }
}


/* for console inputs */
void
command_parser(char *command)
{
  char args[10][256];
  int i,ii,argc;
  char *cp1,*cp2;

  /* clear buffer */
  for(i=0;i<10;i++)
    {
      for(ii=0;ii<256;ii++)
	args[i][ii]='\0';
    }

  for(cp1=command,i=0,cp2=args[0];*cp1!='\0';cp1++)
    {
      if((IS_WHITESPACE(*cp1))&&(strlen(args[i])!=0))
	{
	  i++;
	  cp2 = args[i];
	}
      else
	{
	  *(cp2++) = *cp1;
	}
    }

  if(strlen(args[i])==0)
    argc=i;
  else
    argc=i+1;

  if(argc==0)
    {
      return;
    }

  if(strcmp(args[0],"exit")==0)
    {
      end_apgw();
    }
  else if(strcmp(args[0],"list")==0)
    {
      list_command(args[1]);
    }
  else if(strcmp(args[0],"update")==0)
    {
      update_command();
    }
  else if(strcmp(args[0],"local")==0)
    {
      local_command();
    }
  else if(strcmp(args[0],"add")==0)
    {
      if(argc==5)
	add_command(args[1],args[2],args[3],args[4]);
      else
	printf("add command:: add site_id rncl_host rncl_port policy\n");
    }
  else if(strcmp(args[0],"remove")==0)
    {
      if(argc==2)
	remove_command(args[1]);
      else
	printf("remove command:: remove site_id\n");
    }
  else if(strcmp(args[0],"change")==0)
    {
      if(argc==3)
	change_command(args[1],args[2]);
      else
	printf("change command:: change site_id policy\n");
    }
  else if(strcmp(args[0],"help")==0)
    {
      printf("** List of Commands **\n");
      printf("  -- Site List -- \n");
      printf("list [site_id]\n");
      printf("   List site table. If site_id is specified, list that site only.\n\n");
      printf("update\n");
      printf("   Update site table by getting from master data.\n\n");
      printf("  -- Local Site --\n");
      printf("local\n");
      printf("   List local sites.\n\n");
      printf("add site_id RNCL_host RNCL_port policy");
      printf("   Add a local site.\n\n");
      printf("remove site_id\n");
      printf("   Remove a local site.\n\n");
      printf("change site_id policy\n");
      printf("   Change policy of a local site. policy must be C or P.\n\n");
      printf("  -- Miscellaneous --\n");
      printf("help \n");
      printf("   Print this help message.\n\n");
      printf("exit\n");
      printf("   Terminate OZ++ application geteway.\n\n");
    }
  else
    {
      printf("unknown command: %s %s %s %s %s %s %s %s %s %s\n",
	     args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9]);
      printf("Use help command for available commands\n");
      return;
    }
}
