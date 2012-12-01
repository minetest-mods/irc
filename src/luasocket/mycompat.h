
#ifndef FUCK_THAT
#define FUCK_THAT

typedef t_buffer t_buf;
typedef t_socket t_sock;
typedef t_timeout t_tm;

typedef p_buffer p_buf;
typedef p_socket p_sock;
typedef p_timeout p_tm;

#define aux_add2group auxiliar_add2group
#define aux_checkboolean auxiliar_checkboolean
#define aux_checkclass auxiliar_checkclass
#define aux_checkgroup auxiliar_checkgroup
#define aux_newclass auxiliar_newclass
#define aux_open auxiliar_open
#define aux_setclass auxiliar_setclass
#define aux_tostring auxiliar_tostring
#define buf_init buffer_init
#define buf_isempty buffer_isempty
#define buf_meth_getstats buffer_meth_getstats
#define buf_meth_receive buffer_meth_receive
#define buf_meth_send buffer_meth_send
#define buf_meth_setstats buffer_meth_setstats
#define buf_open buffer_open
#define sock_accept socket_accept
#define sock_bind socket_bind
#define sock_close socket_close
#define sock_connect socket_connect
#define sock_create socket_create
#define sock_destroy socket_destroy
#define sock_gethostbyaddr socket_gethostbyaddr
#define sock_gethostbyname socket_gethostbyname
#define sock_ioerror socket_ioerror
#define sock_listen socket_listen
#define sock_open socket_open
#define sock_recvfrom socket_recvfrom
#define sock_recv socket_recv
#define sock_select socket_select
#define sock_send socket_send
#define sock_sendto socket_sendto
#define sock_setblocking socket_setblocking
#define sock_setnonblocking socket_setnonblocking
#define sock_shutdown socket_shutdown
#define sock_strerror socket_strerror
#define sock_waitfd socket_waitfd
#define tm_getretry timeout_getretry
#define tm_getstart timeout_getstart
#define tm_get timeout_get
#define tm_gettime timeout_gettime
#define tm_init timeout_init
#define tm_lua_sleep timeout_lua_sleep
#define tm_markstart timeout_markstart
#define tm_meth_settimeout timeout_meth_settimeout
#define tm_open timeout_open

#endif /* FUCK_THAT */
