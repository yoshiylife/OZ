/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * Shared memory test
 */

#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/ipc.h>
#include	<sys/shm.h>
#include	"thread/thread.h"
#include	"oz++/ozlibc.h"

#include	"switch.h"
#include	"ncl/ncl_defs.h"

#if	!defined(SVR4)
int	shmget( key_t key, int size, int shmflg ) ;
char	*shmat( int shmid, char *shmaddr, int shmflg ) ;
int	shmdt( char *shmaddr ) ;
int	shmctl( int shmid, int cmd, struct shmid_ds *buf ) ;
#endif
void	bzero( char *b, int length ) ;

typedef	struct {
	int	shmid;
	char	*addr;
} SHM_TABLE;

SHM_TABLE	shm_table[MAX_OF_SHMTBL];
int	shm_cnt = 0;

/*
*  Shared memory get
*
*    flg:  0:Shared memory get only   1:Shared memory creat/get
*/
int	gt_shmid(key_t key, int size, int flg)
{
int	shmid;

	if(flg) {
		shmid = shmget(key, size, IPC_CREAT|IPC_EXCL|0666);
	} else {
		shmid = shmget(key, size, 0666);
	}
	if(shmid == (-1)) {
		return(-1);
	}

	return(shmid);
}

/*
*  Shared memory attach
*/
static char	*gt_shmaddr(int shmid)
{
char	*ataddr;

	if((ataddr = (char *)shmat(shmid, (char*)0, 0)) == (char *)(-1)) {
		OzDebugf("gt_shmaddr: shmat failed\n");
		OzShutdownExecutor() ;
	}
	return(ataddr);
}

/*
*  Shared memory remove
*/
static int	rm_shmaddr(int shmid, char *ataddr)
{
	/*
	*  Shared memory dettach
	*/
	if(shmdt(ataddr)) {
		OzDebugf("rm_shmaddr: shmdt failed\n");
		return((int)(-1));
	}
	/*
	*  Shared memory dettach
	*/
	return((int)(shmctl(shmid, IPC_RMID, (struct shmid_ds *)0)));
}

char	*alloc_shmmem(int size)
{
char	*addr;

	if(shm_cnt == MAX_OF_SHMTBL) {
		OzDebugf("alloc_shmmem: shm table over\n");
		return((char *)(-1));
	}
	if(shm_cnt == 0) {
		bzero((char *)shm_table, sizeof(SHM_TABLE) * MAX_OF_SHMTBL);
	}

#ifndef	_NCL_CODE_
	shm_table[shm_cnt].shmid = gt_shmid(START_SHMKEY + shm_cnt, size, 0);
#else
	shm_table[shm_cnt].shmid = gt_shmid(START_SHMKEY + shm_cnt, size, 1);
#endif
	if(shm_table[shm_cnt].shmid == (-1)) {
		OzDebugf("alloc_shmmem: get shmid failed\n");
		return((char *)(-1));
	}
	addr = shm_table[shm_cnt].addr = gt_shmaddr(shm_table[shm_cnt].shmid);
	shm_cnt++;

	return(addr);
}

int	free_shmmem(char *addr)
{
int	i, j;
int	shmid;
char	*raddr;

	for(i=0, j=0; i<MAX_OF_SHMTBL; i++) {
		if(shm_table[i].addr == (char *)0)
			continue;
		if(j == shm_cnt) return((int)(-1));
		if(addr == shm_table[i].addr)
			break;
		j++;
	}
	shmid	= shm_table[i].shmid;
	raddr	= shm_table[i].addr;
	shm_table[i].shmid	= 0;
	shm_table[i].addr	= (char *)0;
	shm_cnt--;
	
	return((int)rm_shmaddr(shmid, raddr));
}


