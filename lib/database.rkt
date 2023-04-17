#lang racket/base

(require db
         deta/reflect

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

(define (database-connect! [dsn (string->symbol (getenv "DATABASE_DRIVER"))])
  (let ([pool (connection-pool
               (lambda ()
                 (dsn-connect (get-dsn dsn))))])
    (current-database-connection (connection-pool-lease pool))))
