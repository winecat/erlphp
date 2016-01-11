# erlphp
一个用于侦听指定端口，获取PHP通信信息的erlang 监控树
---
配置文件
erlphp.app
侦听端口: {tcp_php_port, 8009}

启动方式
1. sh run.sh
2. 加入项目中，erlphp:start().