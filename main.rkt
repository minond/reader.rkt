#lang racket/base

(require deta

         reader/app/commands/fetch-feed-articles
         reader/app/commands/save-new-feed
         reader/app/models/article
         reader/app/models/feed
         reader/app/models/user
         reader/app/components/layout
         reader/app/dispatch

         reader/lib/app/models/job
         reader/lib/parameters
         reader/lib/logger
         reader/lib/job
         reader/lib/database
         reader/lib/servlet)

(database-connect! 'postgres)

(create-table! (current-database-connection) 'article)
(create-table! (current-database-connection) 'feed)
(create-table! (current-database-connection) 'user)
(create-table! (current-database-connection) 'job)

(register-job-handler! fetch-feed-articles fetch-feed-articles/handler)
(register-job-handler! save-new-feed save-new-feed/handler)

(parameterize ([current-logger application-logger]
               [servlet-app-dispatch app-dispatch]
               [default-layout layout])
  (define stop-manager (make-job-manager))
  (start-servlet)
  (stop-manager))
