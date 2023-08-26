#lang racket/base

(require racket/match
         racket/string

         net/rfc6455

         "../../lib/database/notify.rkt"
         "../../lib/websocket/connection.rkt"
         "../../lib/websocket/session.rkt")

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
    (untrack-channel channel ws-conn)))

(define (handle-ping channels ws-conn)
  (ws-send! ws-conn "pong")
  channels)

(define (handle-subscribe channels ws-conn message)
  (define channel (gen-channel-id (string-replace message "subscribe " "" #:all? #f)))
  (track-channel channel ws-conn)
  (cons channel channels))

(define (handle-unsubscribe channels ws-conn message)
  (define channel (gen-channel-id (string-replace message "unsubscribe " "" #:all? #f)))
  (untrack-channel channel ws-conn)
  (remove channel channels))

(define (track-channel channel ws-conn)
  (log-info "tracking connection for ~a" channel)
  (when (equal? (track-connection! channel ws-conn) 1)
    (listen channel)))

(define (untrack-channel channel ws-conn)
  (log-info "untracking connection for ~a" channel)
  (when (zero? (untrack-connection! channel ws-conn))
    (unlisten channel)))
