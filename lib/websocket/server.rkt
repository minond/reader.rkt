#lang racket/base

(require racket/match
         net/rfc6455
         reader/lib/websocket/connection
         reader/lib/websocket/session)

(provide start-authenticated-ping-pong-websocket-server
         authenticated-ping-pong-websocket-server)

(define (start-authenticated-ping-pong-websocket-server)
  (log-info "starting authenticated-ping-pong websocket server")
  (define stop
    (ws-serve authenticated-ping-pong-websocket-server
              #:port 8082))
  (lambda ()
    (log-info "stopping authenticated-ping-pong websocket server")
    (stop)))

(define (authenticated-ping-pong-websocket-server ws-conn state)
  (define session (lookup-ws-session ws-conn))
  (when (authenticated? session)
    (track-connection! session ws-conn)

    (let loop ()
      (match (ws-recv ws-conn #:payload-type 'text)
        [(? eof-object?)
         (void)]
        ["ping"
         (ws-send! ws-conn "pong")
         (loop)]
        [else
         (loop)]))

    (untrack-connection! session ws-conn))
  (ws-close! ws-conn))
