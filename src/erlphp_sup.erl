%% @author winecat
%% @doc @todo Add description to erlphp_sup.


-module(erlphp_sup).
-behaviour(supervisor).
-export([init/1]).

-export([
         start_link/0
         ]).


start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    ChildList = child_list(),
    {ok,{{one_for_one,3,10}, ChildList}}.

child_list() ->
    [{'erlphp_monitor',{'erlphp_monitor',start_link,[]}, permanent,2000,worker,['erlphp_monitor']}
     ,{'erlphp_listener',{'erlphp_listener',start_link,[]}, permanent,2000,worker,['erlphp_listener']}].


