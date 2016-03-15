%% @author winecat
%% @doc @todo Add description to erlphp_api.


-module(erlphp_api).

%% include files
%% ---------------------------------


%% API functions
%% ---------------------------------
-export([
         get_env/1
        ]).



get_env(Env) ->
    case application:get_env(erlphp, Env) of
        {ok, Value} -> Value;
        _ -> undefined
    end.

%% Internal functions
%% ---------------------------------


