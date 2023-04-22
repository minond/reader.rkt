#lang racket/base

(require net/rfc6455
         json

         reader/lib/websocket/connection)

(provide ws-send)

(define (ws-send session-key message)
  (for ([ws-conn (lookup-connections session-key)])
    (when (ws-conn? ws-conn)
      (ws-send! ws-conn (encode message)))))

(define (encode message)
  (if (hash? message)
      (jsexpr->string message)
      message))
