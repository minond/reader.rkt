#lang racket/base

(require net/rfc6455
         json

         "../../lib/database/notify.rkt"
         "../../lib/websocket/connection.rkt")

(provide ws-publish
         ws-send)

(define (ws-publish key message)
  (notify (gen-channel-id key)
          (encode message)))

(define (ws-send key message)
  (for ([ws-conn (lookup-connections key)]
        #:unless (ws-conn-closed? ws-conn))
    (ws-send! ws-conn (encode message))))

(define (encode message)
  (if (hash? message)
      (jsexpr->string message)
      message))
