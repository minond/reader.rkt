#lang racket/base

(require db
         deta
         deta/reflect

         reader/app/commands/fetch-feed-articles
         reader/app/models/article
         reader/app/models/feed
         reader/app/models/user
         reader/app/components/layout
         reader/app/dispatch

         reader/lib/app/models/job
         reader/lib/parameters
         reader/lib/logger
         reader/lib/job
         reader/lib/servlet)

(let ([pool (connection-pool
             (lambda ()
               (sqlite3-connect #:database "data.db" #:mode 'create)))])
  (current-database-connection (connection-pool-lease pool)))

(schema-registry-allow-conflicts? #t)

(create-table! (current-database-connection) 'article)
(create-table! (current-database-connection) 'feed)
(create-table! (current-database-connection) 'user)
(create-table! (current-database-connection) 'job)

(register-job-handler! fetch-feed-articles fetch-feed-articles/handler)

(parameterize ([current-logger application-logger]
               [servlet-app-dispatch app-dispatch]
               [default-layout layout])
  (define stop-manager (make-job-manager))
  (start-servlet)
  (stop-manager))
