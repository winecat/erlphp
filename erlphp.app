{application, erlphp,
    [
     {description, "a listener from php by erlang app"}
     ,{svn, "1.0"}
     ,{modules, [erlphp]}
     ,{registered, []}
     ,{applications, [kernel, stdlib]}
     ,{mod, {erlphp, []}}
     ,{env, [
             {tcp_php_opts, [
                            binary
                            ,{packet, 0}
                            ,{active, false}
                            ,{reuseaddr, true}
                            ,{nodelay, true}
                            ,{delay_send, true}
                            ,{exit_on_close, false}
                            ,{send_timeout, 10000}
                            ,{send_timeout_close, false}
                            ]}
             ,{tcp_php_port, 8009}
			 ,{tcp_php_ips, ["127.0.0.1", "183.60.40.93"]}
            ]
     }
    ]
}.