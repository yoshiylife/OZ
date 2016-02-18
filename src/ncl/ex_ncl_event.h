/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	EX_NCL_EVENT_H_
#define	EX_NCL_EVENT_H_

/************************
EXECUTOR -> NCL Request
   EN_UNKNOWN_EXID 
   EN_SEARCH_C_N
   EN_CREAT_EXECUTOR
   EN_START_EXECUTOR

NCL -> EXECUTOR Request
   NE_SOLUT_ADDR
   NE_DOYOUKNOW_C_N
   NE_EXEC_INFO
   NE_CREATED_EXID
*************************/

typedef struct  {
	enum {NOP, SPARC}	arch_id;
	enum {
	EN_UNKNOWN_EXID, EN_SEARCH_C_N, EN_CREAT_EXECUTOR, EN_START_EXECUTOR, 
	NE_SOLUT_ADDR, NE_DOYOUKNOW_C_N, NE_CREATED_EXID, NE_EXEC_INFO,
	NCL_NN_PRIMARY, NCL_NN_SECONDARY, NCL_NN_RELAY, NCL_NN_REPLY,
	NCL_BC_PRIMARY, NCL_BC_SECONDARY, NCL_BC_RELAY,
	NCL_NN_CREAT_EXECUTOR, NCL_NN_CREATED_EXID,
	NCL_NN_EXID_REQUEST, NCL_NN_EXID_RESPONCE,
	NCL_MENT_COMMAND, NCL_DEBUGGER_COMM,
	AG_AR_QUERY, AG_AR_REPLY
	} event_num;
	long	req_siteid;	/* Requester Site ID			*/
	long	site_info;	/* Information of Site			*/
	long	req_hnclid;	/* Requester Half-router Nucleus ID	*/
	long	req_nclid;	/* Requester Nucleus ID			*/
	long	res_nclid;	/* Responder Nucleus ID			*/
	long	req_nclfd;	/* Requester Nucleus fd for TCP connect	*/
	long	req_exfd;	/* Requester Executor socket fd		*/
	long	comm_mng_flag;	/* Communication management flag	*/
	long	req_uid;	/* Requester User ID			*/
	long	req_nclid_sav;	/* Responder Relay Nucleus ID		*/
} EventHeaderRec, *EventHeader;

typedef struct { 	/* Event for EN_UNKNOWN_EXID, NE_SOLUT_ADDR	*/
	long long		unknown_exid;	/* Unknown Executor-ID	*/
	struct sockaddr_in	address;	/* Unknown Ex Address	*/
	int			location;	/* Location of Executor	*/
	long long		req_exid;	/* Requester Executor-ID */
	struct sockaddr_in	req_exaddr;	/* Requester Ex Address	*/
} SolutAddressRec, *SolutAddress;

#define	SZ_SolutAddress		sizeof(SolutAddressRec)

typedef struct {        /* Search of Class or Name      */
        long long       sender;
        long            id;
        long long       param1;
        long            param2;
} BroadcastParamRec, *BroadcastParam;

typedef struct { 	/* Event for EN_SEARCH_C_N, NE_DOYOUKNOW_C_N	*/
	BroadcastParamRec	params;
} SearchClassNameRec, *SearchClassName;

#define	SZ_SearchClassName	sizeof(SearchClassNameRec)

typedef struct { 	/* Event for EN_CREAT_EXECUTOR, NE_CREATED_EXID	*/
	struct sockaddr_in	exaddress;
	long			request_id;
	long long		inst_exid;
	long			creat_nclid;
	long			status;
} CreatExecutorRec, *CreatExecutor;

#define	SZ_CreatExecutor	sizeof(CreatExecutorRec)

typedef struct {	/* Event for NN_EXID_REQUEST, NN_EXID_RESONCE	*/
	long long	start_exid;
	long		num_of_exid;
} NclGetExidRec, *NclGetExid;

#define SZ_NclGetExid		sizeof(NclGetExidRec)

typedef struct {
	EventHeaderRec	head;
	union	{
		char			data[984];
		SolutAddressRec		so_addr;
		SearchClassNameRec	sc_name;
		CreatExecutorRec	cr_exec;
		NclGetExidRec		gt_exid;
	} data;
} EventDataRec, *EventData;

#define SZ_EventData		sizeof(EventDataRec)

#endif	EX_NCL_EVENT_H_
