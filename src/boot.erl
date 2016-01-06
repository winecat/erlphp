%% @author mxr
%% @doc @todo Add description to boot.


-module(boot).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
         start_apps/1
         ,stop_apps/1
        ]).


start_apps(Apps) ->
    apps_control(
      fun lists:foldl/3
      ,fun application:start/1
      ,fun application:stop/1
      ,already_started
      ,cannot_start_application
      ,Apps
                ).

stop_apps(Apps) ->
    apps_control(
      fun lists:foldl/3
      ,fun application:start/1
      ,fun application:stop/1
      ,already_started
      ,cannot_start_application
      ,lists:reverse(Apps)
                ).

%% ====================================================================
%% Internal functions
%% ====================================================================
apps_control(Iterate, Do, Undo, 
             InterruptError, ErrorNotice, 
             Apps) ->
    Fun = 
        fun(App, AccIn) ->
                case Do(App) of
                    ok -> [App|AccIn];
                    {error, {InterruptError, _}} -> AccIn;
                    {error, Reason} ->
                        lists:foreach(Undo, AccIn),
                        throw({error, {ErrorNotice, App, Reason}})
                end
        end,
    Iterate(Fun, [], Apps).

