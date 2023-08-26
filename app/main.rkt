#lang racket/base

(require "jobs/fetch-feed-articles.rkt"
         "jobs/save-new-feed.rkt"
         "jobs/crontab.rkt"
         "web/routes/user.rkt"
         "web/components/layout.rkt"
         "web/components/user.rkt"
         "web/routes/dispatch.rkt"

         "lib/parameters.rkt"
         "lib/logger.rkt"
         "lib/job.rkt"
         "lib/database.rkt"
         "lib/websocket.rkt"
         "lib/websocket/listen.rkt"
         "lib/servlet.rkt")

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
