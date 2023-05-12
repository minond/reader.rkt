#lang racket/base

(require reader/jobs/fetch-feed-articles
         reader/jobs/save-new-feed
         reader/jobs/crontab
         reader/entities/article
         reader/entities/feed
         reader/entities/feedback
         reader/entities/registration-invitation
         reader/entities/user
         reader/web/routes/user
         reader/web/components/layout
         reader/web/components/user
         reader/web/routes/dispatch

         reader/lib/app/models/job
         reader/lib/parameters
         reader/lib/logger
         reader/lib/job
         reader/lib/database
         reader/lib/websocket
         reader/lib/websocket/listen
         reader/lib/servlet)

(define ch (database-connect! #:notify-ch #t))

(register-job-handler! fetch-feed-articles fetch-feed-articles/handler)
(register-job-handler! save-new-feed save-new-feed/handler)

(parameterize ([current-logger application-logger]
               [servlet-app-dispatch app-dispatch]
               [default-layout layout]
               [component-user/form :user/form]
               [user-registration/validate user-registration/validate+override]
               [user-registration/registered user-registration/registered+override])
  (define stop-job-manager (make-job-manager))
  (define stop-websocket-server (start-authenticated-websocket-server))
  (define stop-notify-listens (listen ch))
  (define stop-crontab (start-crontab))

  (start-servlet)

  (stop-crontab)
  (stop-notify-listens)
  (stop-websocket-server)
  (stop-job-manager)

  (clear-connections!))
