/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <sys/types.h> 
#include <netinet/in.h> 

#include "ex_ncl_event.h"
#include "ncl_shell.h"

/*
 * Event header Convert Network to Host
 */
static void conv_ntoh_head(EventData hp)
{
	hp->arch_id	= ntohl((u_long)hp->arch_id);
	hp->event_num	= ntohl((u_long)hp->event_num);
	hp->req_siteid	= ntohl((u_long)hp->req_siteid);
	hp->req_rnclid	= ntohl((u_long)hp->req_rnclid);
	hp->req_hnclid	= ntohl((u_long)hp->req_hnclid);
	hp->req_nclid	= ntohl((u_long)hp->req_nclid);
	hp->res_nclid	= ntohl((u_long)hp->res_nclid);
	hp->req_nclfd	= ntohl((u_long)hp->req_nclfd);
	hp->req_exfd	= ntohl((u_long)hp->req_exfd);
	hp->comm_mng_flg	= ntohl((u_long)hp->comm_mng_flg);
	hp->req_uid	= ntohl((u_long)hp->req_uid);
	hp->reserve	= ntohl((u_long)hp->reserve);
}

static void conv_ntoh_sockaddr(struct sockaddr_in *addr)
{
}

static void conv_ntoh_nfe(NfeMent nmp)
{
NfeExTable	nep;
NfeGtNewExid	ngp;
NfeTermEx	ntp;
NfeShutdown	nsp;

	nmp->nfe_comm		= ntohl(nmp->nfe_comm);
	switch(nmp->nfe_comm) {
		case NFE_CONNECT:
			break;
		case NFE_EXSTATUS:
			break;
		case NFE_EXTABLE:
			nep	= (NfeExTable)&(nmp->data);
			nep->entry_cnt_total	= ntohl(nep->entry_cnt_total);
			nep->ref_cnt		= ntohl(nep->ref_cnt);
			nep->entry_cnt		= ntohl(nep->entry_cnt);
			break;
		case NFE_NCLTABLE:
			break;
		case NFE_SHUTDOWN:
			nsp	= (NfeShutdown)&(nmp->data);
			break;
		case NFE_RWHO:
			break;
		case NFE_GETNEWEXID:
			ngp	= (NfeGtNewExid)&(nmp->data);
			ngp->exid	= ntohll(ngp->exid);
			ngp->status	= ntohl(ngp->status);
			break;
		case NFE_KILLTOEX:
			ntp	= (NfeTermEx)&(nmp->data);
			ntp->exid	= ntohl(ntp->exid);
			ntp->signum	= ntohl(ntp->signum);
			ntp->status	= ntohl(ntp->status);
			break;
	}
}

/*
 * Event Convert Network to Host
 */
void	conv_ntoh(EventData hp)
{
SolutAddress	sap;
SearchClassName	scp;
CreatExecutor	cep;
NclGetExid	ngp;

	conv_ntoh_head(hp);
	switch(hp->head.event_num) {
		case EN_UNKNOWN_EXID:
		case NCL_NN_PRIMARY:
		case NCL_NN_SECONDARY:
		case NCL_NN_RELAY:
		case NCL_NN_REPLY:
			sap	= (SolutAddress)&(hp->data);
			sap->unknown_exid	= ntohll(sap->unknown_exid);
			conv_ntoh_sockaddr(&(sap->address));
			sap->localtion		= ntohl(sap->localtion);
			sap->req_exid		= ntohll(sap->req_exid);
			conv_ntoh_sockaddr(&(sap->req_exaddr));
			break;
		case EN_SEARCH_C_N:
		case NCL_BC_PRIMARY:
		case NCL_BC_SECONDARY:
		case NCL_BC_RELAY:
			scp	= (SearchClassName)&(hp->data);
			break;
		case EN_CREAT_EXECUTOR:
		case EN_START_EXECUTOR:
			cep	= (CreatExecutor)&(hp->data);
			conv_ntoh_sockaddr(&(scp->exaddress));
			cep->request_id		= ntohl(cep->request_id);
			cep->inst_exid		= ntohll(cep->inst_exid);
			cep->creat_nclid	= ntohl(cep->creat_nclid);
			cep->status		= ntohl(cep->status);
			break;
		case NCL_NN_EXID_REQUEST:
		case NCL_NN_EXID_RESPONCE:
			ngp	= (NclGetExid)&(hp->data);
			ngp->start_exid		= ntohl(ngp->start_exid);
			ngp->num_of_exid	= ntohl(ngp->num_of_exid);
			break;
		case NCL_MENT_COMMAND:
			conv_ntoh_nfe((NfeMent)&(hp->data));
			break;
		case NCL_DEBUGGER_COMM:
			break;
		default:
			break;
	}
}

/*
 * Event header Convert Host to Network
 */
static void conv_hton_head(EventData hp)
{
	hp->arch_id	= htonl((u_long)hp->arch_id);
	hp->event_num	= htonl((u_long)hp->event_num);
	hp->req_siteid	= htonl((u_long)hp->req_siteid);
	hp->req_rnclid	= htonl((u_long)hp->req_rnclid);
	hp->req_hnclid	= htonl((u_long)hp->req_hnclid);
	hp->req_nclid	= htonl((u_long)hp->req_nclid);
	hp->res_nclid	= htonl((u_long)hp->res_nclid);
	hp->req_nclfd	= htonl((u_long)hp->req_nclfd);
	hp->req_exfd	= htonl((u_long)hp->req_exfd);
	hp->comm_mng_flg	= htonl((u_long)hp->comm_mng_flg);
	hp->req_uid	= htonl((u_long)hp->req_uid);
}

static void conv_hton_sockaddr(struct sockaddr_in *addr)
{
}

static void conv_hton_nfe(NfeMent nmp)
{
NfeExTable	nep;
NfeGtNewExid	ngp;
NfeTermEx	ntp;
NfeShutdown	nsp;

	nmp->nfe_comm		= htonl(nmp->nfe_comm);
	switch(nmp->nfe_comm) {
		case NFE_CONNECT:
			break;
		case NFE_EXSTATUS:
			break;
		case NFE_EXTABLE:
			nep	= (NfeExTable)&(nmp->data);
			nep->entry_cnt_total	= htonl(nep->entry_cnt_total);
			nep->ref_cnt		= htonl(nep->ref_cnt);
			nep->entry_cnt		= htonl(nep->entry_cnt);
			break;
		case NFE_NCLTABLE:
			break;
		case NFE_SHUTDOWN:
			nsp	= (NfeShutdown)&(nmp->data);
			break;
		case NFE_RWHO:
			break;
		case NFE_GETNEWEXID:
			ngp	= (NfeGtNewExid)&(nmp->data);
			ngp->exid	= htonll(ngp->exid);
			ngp->status	= htonl(ngp->status);
			break;
		case NFE_KILLTOEX:
			ntp	= (NfeTermEx)&(nmp->data);
			ntp->exid	= htonl(ntp->exid);
			ntp->signum	= htonl(ntp->signum);
			ntp->status	= htonl(ntp->status);
			break;
	}
}

/*
 * Event header Convert Host to Network
 */
conv_hton(EventData hp)
{
SolutAddress	sap;
SearchClassName	scp;
CreatExecutor	cep;
NclGetExid	ngp;

	switch(hp->head.event_num) {
		case EN_UNKNOWN_EXID:
		case NCL_NN_PRIMARY:
		case NCL_NN_SECONDARY:
		case NCL_NN_RELAY:
		case NCL_NN_REPLY:
			sap	= (SolutAddress)&(hp->data);
			sap->unknown_exid	= htonll(sap->unknown_exid);
			conv_hton_sockaddr(&(sap->address));
			sap->localtion		= htonl(sap->localtion);
			sap->req_exid		= htonll(sap->req_exid);
			conv_hton_sockaddr(&(sap->req_exaddr));
			break;
		case EN_SEARCH_C_N:
		case NCL_BC_PRIMARY:
		case NCL_BC_SECONDARY:
		case NCL_BC_RELAY:
			scp	= (SearchClassName)&(hp->data);
			break;
		case EN_CREAT_EXECUTOR:
		case EN_START_EXECUTOR:
			cep	= (CreatExecutor)&(hp->data);
			conv_hton_sockaddr(&(scp->exaddress));
			cep->request_id		= htonl(cep->request_id);
			cep->inst_exid		= htonll(cep->inst_exid);
			cep->creat_nclid	= htonl(cep->creat_nclid);
			cep->status		= htonl(cep->status);
			break;
		case NCL_NN_EXID_REQUEST:
		case NCL_NN_EXID_RESPONCE:
			ngp	= (NclGetExid)&(hp->data);
			ngp->start_exid		= htonl(ngp->start_exid);
			ngp->num_of_exid	= htonl(ngp->num_of_exid);
			break;
		case NCL_MENT_COMMAND:
			conv_hton_nfe((NfeMent)&(hp->data));
			break;
		case NCL_DEBUGGER_COMM:
			break;
		default:
			break;
	}
	conv_hton_head(hp);
}
