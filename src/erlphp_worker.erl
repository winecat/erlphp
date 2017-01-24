%%% -------------------------------------------------------------------
%%% Author  : winecat
%%% Description : php事件处理进程
%%%
%%% Created : 2013-10-1
%%% -------------------------------------------------------------------
-module(erlphp_worker).

-behaviour(gen_server).


-include("erlphp.hrl").
-include("admin.hrl").

-define(D(MSG), ok).
-define(D(F,ARGS), ok).
%%测试输出
%% -define(D(MSG), ?TEST_DEBUG(MSG)).
%% -define(D(F,ARGS), ?TEST_DEBUG(F, ARGS)).

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
    %%?INFO("[~w] start...", [?MODULE]),
    erlang:process_flag(trap_exit, true),
    %%?INFO("[~w]started", [?MODULE]),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({handle_request, Sock}, State) ->
    Reply = 
        try handle_request(Sock) 
        catch T:X ->
                  ?ERR("handle request { ~w } error:~w/~w/~w", [erlang:get("php request"), T, X, erlang:get_stacktrace()]),
                  ?OPERATE_SERVER_FAIL
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
    ?D("工作进程消息处理:~p", [Sock]),
	case gen_tcp:recv(Sock, 0, 8000) of
		{ok, Bin} -> 
			%% 收到请求
            %%?D("接收到二进制:~ts", [Bin]),
            ToBinary = util:to_binary(Bin),
			case erlang:decode_packet(http_bin, ToBinary, []) of
				{ok, Packet, _Rest} ->
                    %%?D("接收到信息:~w", [Packet]),
					PSrvIdPack = get_platform_server_id(),
					PSrvIdPackLength = byte_size(PSrvIdPack),
                    %%?D("PSrvIdPack:~ts", [PSrvIdPack]),
                    erlang:erase("php request"),
                    case Packet of
                        {http_request,'GET',{abs_path, <<"/favicon.ico">>},{1,1}} -> <<"ok">>;
                        {http_request,'GET',{abs_path,<<"/php_req?", PSrvIdPack:PSrvIdPackLength/binary, Tail/binary>>},{1,1}} ->
                            %% 强制性匹配当前平台Id和服务器Id，不合法的请求一律过滤
                            ?D("Tail:~p", [Tail]),
                            Request = httpd_util:decode_hex(binary_to_list(Tail)),
                            ?D("Request:~p", [Request]),
                            erlang:put("php request", Request),
                            Return = util:exec_val(Request),
                            ?D("Return:~w", [Return]),
                            list_to_binary(rfc4627:encode(Return));
                        _ER ->
                            ?ERR("[~w] receive bad request:~p", [?MODULE, _ER]),
                            ?OPERATE_BAD_REQUEST
                    end;
				_E ->
					?ERR("[~w] decode packet error:~w", [?MODULE, _E]),
					?OPERATE_BAD_PACKET_ERROR
			end;
		_Err ->
			?ERR("[~w] recv error:~w", [?MODULE, _Err]),
			?OPERATE_RECEIVE_ERROR
	end.


%% @spec get_platform_server_id() -> Binary
%% @doc 获取平台名和服务器id
get_platform_server_id() ->
    Platform = config:get_platform(),
    ServerNum = config:get_server_num(),
    list_to_binary([
            <<"platform=">>, Platform, 
            <<"&server_num=">>, integer_to_binary(ServerNum),
            <<"&do=">>
        ]).

%% ==========================================================
%% 测试案例
%% 浏览器地址调用  http://127.0.0.1:8007/php_req?p=0&srv_id=0&do=php_worker:test_exec().
%% ==========================================================
test_exec() ->
    ?D("1111111111111111"),
	List = db:get_all("select id from player"),
	%%?INFO("select id from player 结果是：~w", [List]),
	List.
