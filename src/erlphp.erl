%% @author mxr
%% @doc @todo Add description to erlphp.


-module(erlphp).
-behaviour(application).
-export([start/2, stop/1]).

-include("erlphp.hrl").

-export([
         start/0
        ]).

-define(APPS, [erlphp]).

start() ->
    io:setopts([{encoding, unicode}]),
    boot:start_apps(?APPS).


-spec start(Type :: normal | {takeover, Node} | {failover, Node}, Args :: term()) ->
	{ok, Pid :: pid()}
	| {ok, Pid :: pid(), State :: term()}
	| {error, Reason :: term()}.
start(_Type, _StartArgs) ->
    case erlphp_sup:start_link() of
		{ok, Pid} ->
			{ok, Pid};
		Error ->
            ?TEST_ERR("error :~p", [Error]),
			Error
    end.

-spec stop(State :: term()) ->  Any :: term().
stop(_State) ->
    ok.


