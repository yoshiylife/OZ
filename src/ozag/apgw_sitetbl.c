/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

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
#include <strings.h>
#include <stdlib.h>
#include "apgw.h"
#include "apgw_defs.h"
#include "apgw_sitetbl.h"
#include "comm-packets.h"
  
  HashTableRec site_tbl;

extern ApgwEnvRec	envofapgw;
extern AcceptPortRec	event_act[];

extern int errno;
extern int	strhtoi(char *str);
void save_site_table();
void save_local_site_table();
extern void list_command(char *site);


SiteTable	ApgwEnterSiHash(HashTable hp, int siteid, SiteTable st);

int one_of_local_site;
char SiteTableLastModified[50];


static int	
  SiHash(int siteid, long hsize)
{
  return((int)(siteid % hsize));
}

int	
  ApgwInitSiHash(HashTable hp)
{
  hp->size	= SITE_TABLE_NUM;
  hp->count	= 0;
  hp->tp = (void *)malloc(SZ_SITETBL * SITE_TABLE_NUM);
  if(hp->tp == (void *)0) {
    perror("ApgwInitSiHash: malloc");
    return(1);
  }
  bzero((char *)hp->tp, SZ_SITETBL * SITE_TABLE_NUM);
  return(0);
}

static int	
  ApgwXpndSiHash(HashTable hp)
{
  HashTableRec	hh;
  SiteTable	sp, ep;
  
  hh.size		= hp->size * 2;
  
  hh.tp = (void *)malloc(SZ_SITETBL * hh.size);
  if(hh.tp == (void *)0) {
    perror("ApgwXpndSiHash: malloc");
    return(1);
  }
  
  bzero((char *)hh.tp, SZ_SITETBL * hh.size);
  
  hh.count	= 0;
  ep	= (SiteTable)hh.tp + hh.size;
  for(sp=(SiteTable)hh.tp; sp<ep; sp++) {
    if(sp->siteid == 0L) continue;
    ApgwEnterSiHash(&hh, sp->siteid, sp);
  }
  
  free((char *)hp->tp);
  hp->size	= hh.size;
  hp->tp		= hh.tp;
  return(0);
}

SiteTable
  ApgwEnterSiHash(HashTable hp, int siteid, SiteTable stp)
{
  SiteTable	sp;
  
  if(hp->size < (hp->count * 2)) {
    if(ApgwXpndSiHash(hp))
      return((SiteTable)0);
  }
  
  for (sp=((SiteTable)hp->tp+SiHash(siteid, hp->size));sp->siteid!=0L; ) 
    {
      if(sp->siteid==siteid)
	break;
      if(++sp >= ((SiteTable)hp->tp + hp->size))
	sp	= (SiteTable)hp->tp;
    }
  
  bcopy((char *)stp, (char *)sp, SZ_SITETBL);
  hp->count++;
#ifdef  DEBUG
  printf("ApgwEnterSiHash: entered SiteID(0x%08x) on Site Table, Count(%d)\n", siteid, hp->count);
#endif
  return(sp);
}

SiteTable	
  ApgwSearchSiHash(HashTable hp, int siteid)
{
  SiteTable	sp;
  
  for (sp=((SiteTable)hp->tp+SiHash(siteid, hp->size));sp->siteid!=0L; ) {
    if(sp->siteid == (ushort)siteid)
      return(sp);
    if(++sp >= ((SiteTable)hp->tp + hp->size))
      sp	= (SiteTable)hp->tp;
  }
  return((SiteTable)0);
}

void	
  ApgwRemoveSiHash(HashTable hp, long siteid)
{
  SiteTable	spp, dt_top, dt_s, dt_e;
  
  dt_top = dt_e = (SiteTable)malloc(SZ_SITETBL * hp->count);
  if(dt_s == (SiteTable)0) {
    perror("ApgwRemoveSiHash: malloc");
    return;
  }
  for (spp=((SiteTable)hp->tp+SiHash(siteid, hp->size));spp->siteid!=0L; ) {
    if(spp->siteid != siteid) {
      bcopy((char *)spp, (char *)dt_e, SZ_SITETBL);
      dt_e++;
    }
    bzero((char *)spp, SZ_SITETBL);
    hp->count--;
    if(++spp >= ((SiteTable)hp->tp + hp->size))
      spp	= (SiteTable)hp->tp;
  }
  for(dt_s=dt_top; dt_s<dt_e; dt_s++) {
    ApgwEnterSiHash(hp, dt_s->siteid, dt_s);
  }
  free((char *)dt_top);
  return;
}

void	
  set_ee_methodaddr(struct sockaddr_in *addr)
{
  bzero((char *)addr, sizeof(struct sockaddr_in));
  addr->sin_family	= AF_INET;
  addr->sin_addr.s_addr	= envofapgw.apgwid;
  addr->sin_port	= event_act[EE_METH_CALL].sin_port;
}

SiteTable	
  gt_sitetblrec(int site_id)
{
  SiteTable	call_sp;
  
  call_sp	= ApgwSearchSiHash(&site_tbl, site_id);
  if(call_sp == (SiteTable)0) {
#ifdef  DEBUG
    printf("gt_sitetblrec: Can't found SiteID(0x%04x) on site-table\n", site_id);
#endif
    return((SiteTable)0);
  }
  return(call_sp);
}

SiteTable	
  siteid2apgwaddr(int id, struct sockaddr_in *addr)
{
  SiteTable	sp;
  
  if((sp = ApgwSearchSiHash(&site_tbl, id)) == (SiteTable)0)
    return((SiteTable)0);
  
  bzero((char *)addr, sizeof(struct sockaddr_in));
  addr->sin_family	= AF_INET;
  addr->sin_addr.s_addr	= sp->apgwaddr;
/*
  addr->sin_port	= event_act[EE_METH_CALL].sin_port;
*/
  addr->sin_port	= event_act[AA_BROADCAST].sin_port;
  return((SiteTable)sp);
}

SiteTable	
  siteid2rncladdr(int id, struct sockaddr_in *addr)
{
  SiteTable	sp;
  
  if((sp = ApgwSearchSiHash(&site_tbl, id)) == (SiteTable)0)
    return((SiteTable)0);
  else if(sp->stype==INHIBITED_SITE)
    return((SiteTable)0); /* site is temporary removed */
  
  bzero((char *)addr, sizeof(struct sockaddr_in));
  addr->sin_family	= AF_INET;
  addr->sin_addr.s_addr	= sp->rnclid;
  addr->sin_port	= sp->rncl_port;
  return((SiteTable)sp);
}

static	long	
  hostn2addr(char *hostn)
{
  struct hostent	*hp;
  long		addr;
  
  addr = inet_addr(hostn);
  if(addr == (-1)) {
    if(!(hp = gethostbyname(hostn))) {
      fprintf(stderr, "get_hostaddr: unknown host(%s) in NCL_table\n", hostn);
      return(0);
    }
    bcopy(hp->h_addr, &addr, sizeof(long));
  }
  return(addr);
}

int readline(int s,char *buffer)
{
  char *cp,c;
  int i;

 for(cp=buffer,i=0;(read(s,&c,1))>0;cp++,i++)
   {
     /*     printf("read one character %d\n",c); */

     if(c=='\n')
       { *cp='\0';
	 return i;
       }
     else if(c=='\r')
       { /* ignore carridge return */
	 cp--;
	 i--;
       }
     else
       {
	 *cp = c;
       }
   }

  *cp='\0';
  if(i>0)
    return i;
  else
    return -1; /* End of Stream */
}

int
  register_site(char *buf)
{
  char *cp,*cp1;
  SiteTableRec	st;
  long		siteid, addr;

  if(buf[0] == '#' || buf[0] == '\n')
    return(0);
    
  if((cp = index(buf, ':')) == (char *)NULL)
    return(0);

  *cp = 0x00;
  if((siteid = strhtoi(buf)) <= 0) {
    fprintf(stderr, "Illegal data in  SITE talbe(%s)\n", buf);
    return(-1);
  }

  if((cp1 = index(cp + 1, ':')) == (char *)NULL)
    return(0);

  *cp1 = 0x00;
  if((addr = hostn2addr(cp + 1)) == 0) {
    fprintf(stderr, "Illegal data in  SITE talbe(%s)\n", buf);
    return(-1);
  }
 
  st.siteid	= siteid;
  st.stype	= STYPE_UNKNOWN;
  st.loc		= REMOTE_SITE;
  st.apgwaddr	= addr;
  st.rnclid	= 0L;
  st.rncl_port	= 0;
  ApgwEnterSiHash(&site_tbl, siteid, &st);
  return(1);
}

int update_site()
{
  return(update_site_table(SiteTableLastModified));
}

int 
  update_site_table(char *last_update)
{
  int s; /* fd of socket */
  int i;
  struct sockaddr_in www_address;
  struct hostent *www_host;
  short port_no;
  char  buf[256], *cp, *cp1;
  char  http_res[4];

  port_no = 
  http_res[0]='\0';

  if((s = socket(PF_INET,SOCK_STREAM,0))<0)
    { perror("Can't create socket to access WWW");
      return (-1);
    }


  if((www_host = gethostbyname(SITETABLE_MASTER_HOST))==0)
    { perror("Can't get address of www.etl.go.jp");
      return (-1);
    }
  bzero(&www_address,sizeof(struct sockaddr_in));

  www_address.sin_family = AF_INET;
  www_address.sin_port=SITETABLE_MASTER_PORT;
  www_address.sin_addr.s_addr = *((u_long *)(www_host->h_addr_list[0]));

  if((connect(s,(struct sockaddr *)(&www_address),sizeof(struct sockaddr)))!=0)
    { perror("Fail to connect to www.etl.go.jp:80");
      return(-1);
    }

  /* send GET command to www server */
  sprintf(buf,"%s%s",SITETABLE_MASTER_GET,CRLF);
  write(s,buf,strlen(buf));
#ifdef DEBUG
  printf("Write to socket:%s\n",buf);
#endif

  if(last_update != 0)
    { sprintf(buf,"%s %s%s",HTTP_IF_MODIFIED_SINCE,last_update,CRLF);
      write(s,buf,strlen(buf));
#ifdef DEBUG
      printf("Write to socket:%s\n",buf);
#endif
    }
  sprintf(buf,"%s%s%s",HTTP_NO_CACHE,CRLF,CRLF);
  write(s,buf,strlen(buf));
#ifdef DEBUG
  printf("Write to socket:%s\n",buf);
#endif

  printf("Accessing www.etl.go.jp\n");

  /* read result */
  while((i=readline(s,buf))>0)
    {
#ifdef DEBUG
      printf("HTTP_RESPONSE:%s\n",buf);
#endif
      if((strncmp(buf,HTTP_RESPONSE,strlen(HTTP_RESPONSE)))==0)
	{
#if DEBUG
	  printf("RESPONSE:%s\n",buf);
#endif
	  strncpy(http_res,&(buf[strlen(HTTP_RESPONSE)+1]),3);
	  http_res[3]='\0';
	}
      else if((strncmp(buf,HTTP_LAST_MODIFIED,strlen(HTTP_LAST_MODIFIED)))==0)
	{
#if DEBUG
	  printf("LAST_MODIFIED:%s\n",buf);
#endif
	  strcpy(SiteTableLastModified,&(buf[strlen(HTTP_LAST_MODIFIED)+1]));
	}
    }
  
  if(strcmp(http_res,"200")==0)
    {
      while((i=readline(s,buf))>0)
	{
	  register_site(buf);
	}
      printf("Site table is updated!\n");
      return(1);
    }
  else if(strcmp(http_res,"304")==0)
    {
      printf("Site table is up to date. No update necessary\n");
      return(0);
    }
  else
    {
      printf("Unexpected response from www server: response code=%s\n",http_res);
      return(-1);
    }
}


void
  save_site_table()
{
  char sitefile[128],sitefile_bak[128],tmpfile[128];
  SiteTable st;
  int i,c;
  FILE *fp;

  sprintf(sitefile, "%s/etc/%s", envofapgw.ozroot, APGW_SITETABLE);
  sprintf(sitefile_bak, "%s/etc/%s.bak", envofapgw.ozroot, APGW_SITETABLE);
  sprintf(tmpfile, "%s/etc/tmpSite", envofapgw.ozroot);

  if((fp = fopen(tmpfile, "w")) == (FILE *)NULL) 
    {
      perror("Can't open work file for site_table");
      return;
    }

  fprintf(fp,"#%s\n",SiteTableLastModified);
  for(i=0,c=site_tbl.count,st=(SiteTable)site_tbl.tp
      ;(i<site_tbl.size && c>0);i++,st++)
    {
      if(st->siteid !=0)
	{
	  fprintf(fp,"%04x:%s:\n",st->siteid,ipaddr2str(st->apgwaddr));
	}
    }
  fclose(fp);


  if(unlink(sitefile_bak)<0)
    {
      perror("unkink .bak");
    }
  
  
  if(link(sitefile,sitefile_bak)<0)
    {
      perror("link sitefile->sitefile.bak");
    }
  
  
  if(unlink(sitefile)<0)
    {
      perror("unkink .bak");
    }
  
  
  if(link(tmpfile,sitefile)<0)
    {
      perror("link tmpfile->sitefile");
    }
  
  
  if(unlink(tmpfile)<0)
    {
      perror("unlink tmpfile");
    }
  
}

void
  save_local_site_table()
{
  char sitefile[128],sitefile_bak[128],tmpfile[128];
  SiteTable st;
  int i,c;
  FILE *fp;
  char *policy;

  sprintf(sitefile, "%s/etc/%s", envofapgw.ozroot, "apgw_LSiteInfo");
  sprintf(sitefile_bak, "%s/etc/%s.bak", envofapgw.ozroot, "apgw_LSiteInfo");
  sprintf(tmpfile, "%s/etc/tmpLocalSite", envofapgw.ozroot);

  if((fp = fopen(tmpfile, "w")) == (FILE *)NULL) 
    {
      perror("Can't open work file for site_table");
      return;
    }

  
  for(i=0,c=site_tbl.count,st=(SiteTable)site_tbl.tp
      ;(i<site_tbl.size && c>0);i++,st++)
    {
      
      if((st->siteid !=0) && (st->loc==LOCAL_SITE))
	{
	  if(st->stype == PROGRESSIVE_SITE)
	    policy = "P";
	  else if(st->stype == CONSERVATIVE_SITE)
	    policy = "C";
	  else if(st->stype == INHIBITED_SITE)
	    policy = "I";
	  else
	    break;
	  
	  fprintf(fp,"%04x:%s:%d:%s\n",st->siteid,ipaddr2str(st->rnclid),st->rncl_port,policy);
	}
    }
  fclose(fp);
  
  if(unlink(sitefile_bak)<0)
    {
      perror("unkink .bak");
    }
  
  
  if(link(sitefile,sitefile_bak)<0)
    {
      perror("link sitefile->sitefile.bak");
    }
  
  
  if(unlink(sitefile)<0)
    {
      perror("unkink .bak");
    }
  
  
  if(link(tmpfile,sitefile)<0)
    {
      perror("link tmpfile->sitefile");
    }
  
  
  if(unlink(tmpfile)<0)
    {
      perror("unlink tmpfile");
    }
  
}


void	
  init_site_table()
{

  char		buf[256], *cp, *cp1;
  FILE		*fp;
  SiteTableRec	st;
  int s;
  char	*index();

  ApgwInitSiHash(&site_tbl);
  
  sprintf(buf, "%s/etc/%s", envofapgw.ozroot, APGW_SITETABLE);
  if((fp = fopen(buf, "r")) == (FILE *)NULL) 
    {
      fprintf(stderr, "Can't open SITE talbe file, try to download from original\n");
      if(update_site_table(0)<0)
	{
	  printf("Fail to update Sita table from original\n");
	  exit(1);
	}
      else
	save_site_table();
    }
  else
    {
      while(fgets(buf, 256, fp) != (char *)NULL) {
	if(buf[0]=='#')
	  strcpy(SiteTableLastModified,&(buf[1]));
	if(register_site(buf)<0)
	  {
	    fclose(fp);
	    printf("Fail to read Site table(bad format!)");
	    exit(1);
	  }
      }
    }
  fclose(fp);
}

int
  add_local_site(int site_id,char *rncl,int rncl_port,char *stype)
{
  SiteTable	stp;
  int   type;

  stp = ApgwSearchSiHash(&site_tbl, site_id);
  if(stp == (SiteTable)0) {
      printf("add: Can't found LocalSiteID(0x%04x) on site-table\n", site_id);
      printf("  Check site-table by list command\n");
      return(-1);
    }

  if((stp->stype == INHIBITED_SITE) || (stp->loc != LOCAL_SITE))
    {
      if(!strcmp(stype,"P"))
	type = PROGRESSIVE_SITE;
      else if(!strcmp(stype,"C"))
	type = CONSERVATIVE_SITE;
      else
	{
	  printf("add: policy must be \"P\" or \"C\" \n");
	  return(-1);
	}

      stp->loc = LOCAL_SITE;
      stp->rnclid = hostn2addr(rncl);
      stp->rncl_port = rncl_port;
      stp->stype = type;
      return(1);
    }
  else
    {
      printf("add: Local site (0x%04x) exists already\n", site_id);
      return(-1);
    }
}

int
  change_local_site(int site_id,char *stype)
{
  SiteTable	stp;
  int           type;
  
  stp = ApgwSearchSiHash(&site_tbl, site_id);
  if(stp == (SiteTable)0) {
    printf("change: No such local site (0x%04x)\n", site_id);
    return(-1);
  }

  if(stp->loc != LOCAL_SITE)
    {
      printf("change: site (%04x) is not local.\n",site_id);
      return(-1);
    }
  
  if(stp->stype == INHIBITED_SITE)
    {
      printf("change: site (%04x) had been removed already.\n",site_id);
      return(0);
    }
  
  if(!strcmp(stype,"P"))
    type = PROGRESSIVE_SITE;
  else if(!strcmp(stype,"C"))
    type = CONSERVATIVE_SITE;
  else
    {
      printf("change: policy must be \"P\" or \"C\" \n");
      return(-1);
    }
  
  if(stp->stype == type)
    {
      printf("change: policy is same as it it\n");
      return(0);
    }
  else
    {
      stp->stype = type;
      return(1);
    }
}


int
  remove_local_site(int site_id)
{
  SiteTable	stp;

  stp = ApgwSearchSiHash(&site_tbl, site_id);
  if(stp == (SiteTable)0) {
      printf("remove: No such site (0x%04x).\n", site_id);
      return(-1);
    }

  if(stp->loc != LOCAL_SITE)
    {
      printf("remove: site (%04x) is not local.\n",site_id);
      return(-1);
    }

  if(stp->stype == INHIBITED_SITE)
    {
      printf("remove: site (%04x) had been removed already.\n",site_id);
      return(0);
    }

  stp->stype = INHIBITED_SITE;
  return(1);
}

int
  register_local_site(char *buf)
{
  int		sid;
  SiteTable	stp;
  char		siteid[128], rncl[128], rncl_port[128], stype[128];
  char *cp,*cp1,*cp2;
  char	*index();
  
  if(buf[0] == '#' || buf[0] == '\n') {
    return(0);
  }
  
  if((cp = index(buf, ':')) == (char *)NULL) {
    printf("init_localsite_info: Illegal data on %s, Description is wrong\n", buf);
    return(-1);
  }
  *cp = 0x00;
  strcpy(siteid, buf);

  if((cp1 = index(cp + 1, ':')) == (char *)NULL) {
    printf("init_localsite_info: Illegal data on %s, Description is wrong\n", buf);
    return(-1);
  }
  *cp1 = 0x00;
  strcpy(rncl, cp + 1);

  if((cp2 = index(cp1 + 1, ':')) == (char *)NULL) {
    printf("init_localsite_info: Illegal data on %s, Description is wrong\n", buf);
    return(-1);
  }
  *cp2 = 0x00;
  strcpy(rncl_port, cp1 + 1);
  if((cp = index(cp2 + 1, '\n')) != (char *)NULL)
    *cp = 0x00;
  strcpy(stype, cp2 + 1);
    
  sid	= strhtoi(siteid);
  stp = ApgwSearchSiHash(&site_tbl, sid);
  if(stp == (SiteTable)0) {
      printf("init_localsite_info: Can't found LocalSiteID(0x%04x) on site-table\n", sid);
      return(-1);
    }

  if(!strcmp(stype, "P")) {
    stp->stype	= PROGRESSIVE_SITE;
  } else if(!strcmp(stype, "C")) {
    stp->stype	= CONSERVATIVE_SITE;
  } else if(!strcmp(stype, "I")) {
    stp->stype	= INHIBITED_SITE;
  } else {
    printf("init_localsite_info: Illegal data on %s, Site type is wrong\n", buf);
    return(-1);
  }
  stp->loc	= LOCAL_SITE;
  stp->rnclid	= hostn2addr(rncl);
  stp->rncl_port  = atoi(rncl_port);
  one_of_local_site = sid;
  return(1);
}


int
  init_localsite_info()
{
  FILE		*fp;
  char		buf[256], *cp, *cp1, *cp2;
  char		siteid[128], rncl[128], rncl_port[128], stype[128];
  int		sid;
  SiteTable	stp;
  
  char	*index();
  
  sprintf(buf, "%s/etc/apgw_LSiteInfo", envofapgw.ozroot);
  if((fp = fopen(buf, "r")) == (FILE *)NULL) {
    fprintf(stderr, "Can't found APGW information file %s\n Please add local site using add command\n", buf);
    return(0);
  }
  
  while(fgets(buf, 256, fp) != (char *)NULL) {
    register_local_site(buf);
  }
  fclose(fp);
  return(0);
}

