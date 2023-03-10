#lang racket/base

(require db
         deta
         deta/reflect

         reader/app/models/article
         reader/app/models/feed
         reader/app/models/user
         reader/app/components/layout
         reader/app/dispatch

         reader/lib/app/models/job
         reader/lib/parameters
         reader/lib/logger
         reader/lib/servlet)

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
(create-table! (current-database-connection) 'job)

(servlet-app-dispatch app-dispatch)
(default-layout layout)

(parameterize ([current-logger application-logger])
  (start-servlet))
