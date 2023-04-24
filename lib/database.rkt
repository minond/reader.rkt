#lang racket/base

(require racket/class
         racket/async-channel

         db
         deta/reflect

         reader/lib/database/notify
         reader/lib/parameters)

(provide database-connect!)

(schema-registry-allow-conflicts? #t)

(put-dsn 'sqlite
         (sqlite3-data-source #:database (or (getenv "DATABASE_FILE") "data.db")
                              #:mode 'create))

(put-dsn 'postgres
         (postgresql-data-source #:database (getenv "DATABASE_NAME")
                                 #:server (or (getenv "DATABASE_SERVER") "localhost")
                                 #:port (or (getenv "DATABASE_PORT") 5432)
                                 #:user (getenv "DATABASE_USER")
                                 #:password (getenv "DATABASE_PASSWORD")))

(define (database-connect! #:dsn [dsn (string->symbol (getenv "DATABASE_DRIVER"))]
                           #:notify-ch [ch #f])
  (when (equal? ch #t)
    (set! ch (make-async-channel)))

  (current-database-connection
   (dsn-connect (get-dsn dsn)
                #:notification-handler (notification-handler ch)))

  (wait-for-notify! ch)
  ch)
