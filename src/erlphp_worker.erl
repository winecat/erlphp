%%% -------------------------------------------------------------------
%%% Author  : winecat
%%% Description : php事件处理进程
%%%
%%% Created : 2013-10-1
%%% -------------------------------------------------------------------
-module(erlphp_worker).

-behaviour(gen_server).


-include("erlphp.hrl").

-export([
         start_link/0
         ,test_exec/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

start_link() ->
	gen_server:start_link(?MODULE, [], []).

init([]) ->
    ?TEST_INFO("[~w] start...", [?MODULE]),
    erlang:process_flag(trap_exit, true),
    ?TEST_INFO("[~w]started", [?MODULE]),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({handle_request, Sock}, State) ->
	Reply = 
		try handle_request(Sock) 
		catch T:X ->
				  util:term_to_bitstring({T, X, erlang:get_stacktrace()})
		end,
	Length = byte_size(Reply),
	Response = list_to_binary([<<"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: ">>, integer_to_list(Length), <<"\r\n\r\n">>, Reply]), 
	%%回应
	gen_tcp:send(Sock, Response),
	%%关闭连接
	gen_tcp:close(Sock),
	{noreply, State};

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

%% 请求逻辑处理 
handle_request(Sock) ->
	%% 	?DEBUG("工作进程消息处理:~p", [Sock]),
	case gen_tcp:recv(Sock, 0, 80000) of
		{ok, Bin} -> 
			%% 收到请求
			case erlang:decode_packet(http_bin, Bin, []) of
				{ok, Packet, _Rest} ->
					PSrvIdPack = get_platform_server_id(),
					PSrvIdPackLength = byte_size(PSrvIdPack),
					case Packet of
						{http_request,'GET',{abs_path,<<"/php_req?", PSrvIdPack:PSrvIdPackLength/binary, Tail/binary>>},{1,1}} ->
							%% 强制性匹配当前平台Id和服务器Id，不合法的请求一律过滤
							%%?DEBUG("Tail:~p", [Tail]),
							Request = httpd_util:decode_hex(binary_to_list(Tail)),
							%%?DEBUG("Request:~p", [Request]),
							Return = util:exc_val(Request),
							%%?DEBUG("Return:~ts", [Return]),
							list_to_binary(rfc4627:encode(Return));
						_ER ->
							?TEST_ERR("[~w] receive bad request:~p", [?MODULE, _ER]),
							<<"bad request">>
					end;
				_E ->
					?TEST_ERR("[~w] decode packet error", [?MODULE]),
					<<"decode packet error">>
			end;
		_ ->
			?TEST_ERR("[~w] recv error", [?MODULE]),
			<<"recv error">>
	end.


%% @spec get_platform_server_id() -> Binary
%% @doc 获取平台名和服务器id
get_platform_server_id() ->
    Platform = util:to_string(sys_env:get(platform)),
    ServerId = util:to_string(sys_env:get(srv_id)),
    list_to_binary([
            <<"p=">>, Platform, 
            <<"&srv_id=">>, ServerId,
            <<"&do=">>
        ]).

%% ==========================================================
%% 测试案例
%% 浏览器地址调用  http://127.0.0.1:8007/php_req?p=0&srv_id=0&do=php_worker:test_exec().
%% ==========================================================
test_exec() ->
	List = db:get_all("select id from role"),
	?TEST_INFO("结果是：~w", [List]),
	ok.
