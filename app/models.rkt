#lang racket/base

(require db
         deta
         deta/reflect

         reader/app/models/article
         reader/app/models/feed
         ; reader/app/models/job
         reader/app/models/user
         reader/lib/app/parameters)

(provide (all-from-out reader/app/models/article)
         (all-from-out reader/app/models/feed)
         ; (all-from-out reader/app/models/job)
         (all-from-out reader/app/models/user))

; For interactive mode
(schema-registry-allow-conflicts? #t)

(define pool
  (connection-pool
   (lambda ()
     (sqlite3-connect #:database "data.db" #:mode 'create))))

(current-database-connection (connection-pool-lease pool))

(create-table! (current-database-connection) 'article)
(create-table! (current-database-connection) 'feed)
(create-table! (current-database-connection) 'user)
; (create-table! (current-database-connection) 'job)
