%%% -------------------------------------------------------------------
%%% Author  : weinecat
%%% Description : php时间接收管理进程
%%%
%%% Created : 2013-9-30
%%% -------------------------------------------------------------------
-module(erlphp_monitor).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("erlphp.hrl").

-define(WORKER_NUM, 20).		%%工作进程个数

%% --------------------------------------------------------------------
%% External exports
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {worker = [],
				pid_list = []}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
	?TEST_INFO("[~w] start...", [?MODULE]),
	WorkerPidList = start_worker(?WORKER_NUM),
	?TEST_INFO("[~w] started", [?MODULE]),
	{ok, #state{worker = WorkerPidList, pid_list = WorkerPidList}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({accept_php, Sock}, State) ->
%% 	?DEBUG("php 工作管理进程收到 监听进程发送的信息:~p", [Sock]),
	case State#state.worker of
		[Pid] ->
			gen_server:cast(Pid, {handle_request, Sock}),
			{noreply, State#state{worker = State#state.pid_list}};
		[Pid|Tail] ->
			gen_server:cast(Pid, {handle_request, Sock}),
			{noreply, State#state{worker = Tail}};
		_E ->%%保险匹配？
			case State#state.pid_list of
				[Pid|Tail] ->
					gen_server:cast(Pid, {handle_request, Sock}),
					{noreply, State#state{worker = Tail}};
				_OER ->%%这里真的出大问题了！
					?TEST_ERR("php worker pids error, has no worker pid"),
					{noreply, State#state{worker = []}}
			end
	end;
			
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({'EXIT', WorkerPid, _Reason}, #state{worker = WorkerList, pid_list = PidList} = State) ->
    NWorkerList = lists:delete(WorkerPid, WorkerList),
    NPidList = start_worker(lists:delete(WorkerPid, PidList)),
    {noreply, State#state{worker = NWorkerList, pid_list = NPidList}};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%%批量启动工作进程组
start_worker(Num) ->
	start_worker(Num, []).

%% --------------------------------------------------------------------
%% Function: start_worker/2
%% Description: 开启php工作进程
%% Returns: PidList
%% -------------------------------------------------------------------
start_worker(Num, PidList) when Num =< 0 ->
	PidList;
start_worker(Num, PidList) ->
	case erlphp_worker:start_link() of
		{ok, Pid} ->
			start_worker(Num-1, [Pid|PidList]);
		_Error ->
			?TEST_ERR("start php worker error because of [~p]", [_Error]),
			start_worker(Num-1, PidList)
	end.
