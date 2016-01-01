%% ==========================
%%  module macro定义 
%% ==========================
-ifdef(debug).
-define(TEST_DEBUG(Msg), logger:debug(Msg, [], ?MODULE, ?LINE)).
-define(TEST_DEBUG(F, A), logger:debug(F, A, ?MODULE, ?LINE)).
-define(TEST_DEBUG_CATCH(S), catch S).
-define(TEST_INFO(Msg), catch logger:info(Msg, [], ?MODULE, ?LINE)).       %% 输出普通信息
-define(TEST_INFO(F, A), catch logger:info(F, A, ?MODULE, ?LINE)).
-define(TEST_ERR(Msg), catch logger:error(Msg, [], ?MODULE, ?LINE)).       %% 输出错误信息
-define(TEST_ERR(F, A), catch logger:error(F, A, ?MODULE, ?LINE)).
-else.
-define(TEST_DEBUG(Msg), ok).
-define(TEST_DEBUG(F, A), ok).
-define(TEST_DEBUG_CATCH(S), ok).
-define(TEST_INFO(Msg), ok).       %% 输出普通信息
-define(TEST_INFO(F, A), ok).
-define(TEST_ERR(Msg), catch logger:error(Msg, [], ?MODULE, ?LINE)).       %% 输出错误信息
-define(TEST_ERR(F, A), catch logger:error(F, A, ?MODULE, ?LINE)).
-endif.