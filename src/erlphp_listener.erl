%%% -------------------------------------------------------------------
%%% Author  : xianrongMai
%%% Description :侦听php请求进程, 仅负责端口侦听,事件处理交付给php_mgr
%%%
%%% 以'GET'的方式调用url
%%% http://${IP}:8007/php_req?p=${Platform}&srv_id=${Srv_id}&do={M,F,A}.
%%% 例子:http://127.0.0.1:8007/php_req?p=0&srv_id=0&do=php_worker:test_exec().
%%% 
%%% Created : 2013-9-30
%%% -------------------------------------------------------------------
-module(erlphp_listener).

-behaviour(gen_server).


-include("erlphp.hrl").

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


init([]) ->
	?TEST_INFO("[~w] start...", [?MODULE]),
	%%开启工作管理进程
	case application:get_env(tcp_php_port) of
		{ok, Port} when is_integer(Port) ->
			case gen_tcp:listen(Port, parse_tcp_php_opts()) of
				{ok, LSock} ->
					erlang:spawn_link(fun() -> loop(LSock) end),
					?TEST_INFO("[~w]成功监听到端口:~w", [?MODULE, Port]),
					{ok, #state{}};
				{error, Reason} ->%%侦听失败.端口重用了?
					?TEST_ERR("无法监听到 ~w:~w~n", [Port, Reason]),
					{stop, listen_fail, #state{}}
			end;
		_ErrPort ->
			?TEST_ERR("php port error:~p",[_ErrPort]),   %% 端口没加载到
			{stop, port_error, #state{}}
	end.


handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
loop(LSock) ->
	case gen_tcp:accept(LSock) of
		{ok, Sock} ->
			case check_ip(Sock) of
				{true, _OkIP} ->
					?TEST_INFO("[~w]收到来自[~s]的请求", [?MODULE, _OkIP]),
					gen_server:cast(welphp_monitor, {accept_php, Sock});
				{false, ErIp} ->%%不是合法的ip地址,直接忽略
					?TEST_ERR("收到异常ip发送的http请求,[Ip:~s]", [ErIp]),
					invalid_ip
			end;
		{erroe, Reason} -> Reason
	end,
	loop(LSock).

%% 检查ip合法性
check_ip(Sock) ->
	IP = get_ip(Sock),
	MyIP = util:to_binary(IP),
	case lists:any(fun(OkIP) -> MyIP =:= util:to_binary(OkIP) end, sys_env:get(tcp_php_ips)) of
		true ->
			{true, IP};
		false -> 
			{false, IP} 
	end.

%% 获取来源IP 
get_ip(Socket) ->
	case inet:peername(Socket) of 
		{ok, {PeerIP,_Port}} ->
%% 			?DEBUG("PeerIp:~p", [PeerIP]),
			ip_to_binary(PeerIP);
		{error, _NetErr} -> 
			""
	end.

ip_to_binary(Ip) ->
	case Ip of 
		{A1,A2,A3,A4} -> 
			[integer_to_list(A1), ".", integer_to_list(A2), ".", integer_to_list(A3), ".", integer_to_list(A4)];
		_ -> 
			"-"
	end.

parse_tcp_php_opts() ->
    case application:get_env(tcp_php_opts) of
        {ok, Opts} -> parse_tcp_php_opts(Opts);
        _ -> []
    end.
parse_tcp_php_opts(Opts) -> parse_tcp_php_opts(Opts, []).
parse_tcp_php_opts([], List) -> List;
parse_tcp_php_opts([{Key, Value}|Tail], List) ->
    parse_tcp_php_opts(Tail, [{Key, Value}|List]);
parse_tcp_php_opts([_Unknow|Tail], List) -> 
    parse_tcp_php_opts(Tail, List).
