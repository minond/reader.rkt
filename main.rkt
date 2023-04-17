#lang racket/base

(require reader/app/commands/fetch-feed-articles
         reader/app/commands/save-new-feed
         reader/app/routes/user
         reader/app/models/article
         reader/app/models/feed
         reader/app/models/feedback
         reader/app/models/registration-invitation
         reader/app/models/user
         reader/app/components/layout
         reader/app/components/user
         reader/app/dispatch

         reader/lib/app/models/job
         reader/lib/parameters
         reader/lib/logger
         reader/lib/job
         reader/lib/database
         reader/lib/servlet)

(database-connect! 'postgres)

(register-job-handler! fetch-feed-articles fetch-feed-articles/handler)
(register-job-handler! save-new-feed save-new-feed/handler)

(parameterize ([current-logger application-logger]
               [servlet-app-dispatch app-dispatch]
               [default-layout layout]
               [component-user/form :user/form]
               [user-registration/validate user-registration/validate+override]
               [user-registration/registered user-registration/registered+override])
  (define stop-manager (make-job-manager))
  (start-servlet)
  (stop-manager))
