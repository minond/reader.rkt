#lang racket/base

(require json

         reader/lib/database/notify
         reader/lib/websocket/message)

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
