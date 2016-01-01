%% @author mxr
%% @doc @todo Add description to erlphp.


-module(erlphp).
-behaviour(application).
-export([start/2, stop/1]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
         start/0
        ]).

-define(APPS, [erlphp]).


%% ====================================================================
%% Behavioural functions
%% ====================================================================
start() ->
    io:setopts([{encoding, unicode}]),
    io:format("2222222"),
    boot:start_apps(?APPS),
io:format("1111111").


%% start/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/apps/kernel/application.html#Module:start-2">application:start/2</a>
-spec start(Type :: normal | {takeover, Node} | {failover, Node}, Args :: term()) ->
	{ok, Pid :: pid()}
	| {ok, Pid :: pid(), State :: term()}
	| {error, Reason :: term()}.
%% ====================================================================
start(_Type, _StartArgs) ->
    io:format("111111111111111111111"),
    case erlphp_sup:start_link() of
		{ok, Pid} ->
			{ok, Pid};
		Error ->
            io:format("error :~p", [Error]),
			Error
    end.

%% stop/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/apps/kernel/application.html#Module:stop-1">application:stop/1</a>
-spec stop(State :: term()) ->  Any :: term().
%% ====================================================================
stop(_State) ->
    ok.

%% ====================================================================
%% Internal functions
%% ====================================================================


