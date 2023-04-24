#lang racket/base

(require racket/match
         racket/string

         net/rfc6455

         reader/lib/websocket/connection
         reader/lib/websocket/session)

(provide start-authenticated-websocket-server
         authenticated-websocket-server)

(define (start-authenticated-websocket-server)
  (log-info "starting authenticated-pong websocket server")
  (define stop
    (ws-serve authenticated-websocket-server
              #:port 8082))
  (lambda ()
    (log-info "stopping authenticated websocket server")
    (stop)))

(define (authenticated-websocket-server ws-conn state)
  (define session (lookup-ws-session ws-conn))
  (when (authenticated? session)
    (let loop ([channels null])
      (define message (ws-recv ws-conn #:payload-type 'text))
      (match message
        [(? eof-object?) (handle-disconnect channels ws-conn)]
        ["ping" (loop (handle-ping channels ws-conn))]
        [(regexp #rx"^subscribe (.)") (loop (handle-subscribe channels ws-conn message))]
        [(regexp #rx"^unsubscribe (.)") (loop (handle-unsubscribe channels ws-conn message))]
        [else (loop channels)])))
  (ws-close! ws-conn))

(define (handle-disconnect channels ws-conn)
  (for ([channel channels])
    (log-info "untracking connection for ~a" channel)
    (untrack-connection! channel ws-conn)))

(define (handle-ping channels ws-conn)
  (ws-send! ws-conn "pong")
  channels)

(define (handle-subscribe channels ws-conn message)
  (define channel (string-replace message "subscribe " "" #:all? #f))
  (log-info "tracking connection for ~a" channel)
  (track-connection! channel ws-conn)
  (cons channel channels))

(define (handle-unsubscribe channels ws-conn message)
  (define channel (string-replace message "unsubscribe " "" #:all? #f))
  (log-info "untracking connection for ~a" channel)
  (untrack-connection! channel ws-conn)
  (remove channel channels))
