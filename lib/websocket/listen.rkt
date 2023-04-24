#lang racket/base

(require reader/lib/database/notify
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
                      (message-payload msg)))))
         (loop)))))

  (lambda ()
    (thread-send thd 'stop)))
