#lang racket/base

(require json

         "../../lib/database/notify.rkt"
         "../../lib/websocket/message.rkt")

(provide listen)

(define (listen ch)
  (define thd
    (thread
     (lambda ()
       (let loop ()
         (sync
          (handle-evt
           ch
           (lambda (msg)
             (ws-send (message-channel msg)
                      (jsexpr->string
                       (hash 'channel (message-channel msg)
                             'payload (message-payload msg)))))))
         (loop)))))

  (lambda ()
    (thread-send thd 'stop)))
