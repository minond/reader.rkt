#lang racket/base

(require racket/class
         racket/async-channel

         db

         "../../lib/crypto.rkt"
         "../../lib/parameters.rkt")

(provide (struct-out message)
         gen-channel-id
         listen
         unlisten
         notify
         notification-handler
         wait-for-notify!)

(struct message (channel payload) #:transparent)

(define (gen-channel-id str)
  (if (> (string-length str) 63)
      (hexsha1 str)
      str))

(define (listen channel [conn (current-database-connection)])
  (query conn (format "listen ~a" (escape channel)))
  (void))

(define (unlisten channel [conn (current-database-connection)])
  (query conn (format "unlisten ~a" (escape channel)))
  (void))

(define (notify channel payload [conn (current-database-connection)])
  (query conn "select pg_notify($1, $2)" channel payload)
  (void))

(define ((notification-handler ch) channel payload)
  (when ch
    (async-channel-put ch (message channel payload))))

(define wait-for-notify-thd #f)
(define (wait-for-notify)
  (let loop ()
    (sync
     (handle-evt
      (send+ (current-database-connection)
             (get-base)
             (async-message-evt))
      (lambda _
        (loop)))
     (handle-evt
      (thread-receive-evt)
      (lambda _
        (void))))))

(define (wait-for-notify! ch)
  (when wait-for-notify-thd
    (thread-send wait-for-notify-thd 'stop)
    (set! wait-for-notify-thd #f))

  (when ch
    (set! wait-for-notify-thd (thread wait-for-notify))))

(define (escape s)
  (string-append "\"" s "\""))
