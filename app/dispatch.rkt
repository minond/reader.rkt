#lang racket/base

(require racket/match

         web-server/servlet
         web-server/dispatchers/dispatch

         reader/app/routes/article
         reader/app/routes/feed
         reader/lib/app/routes/session
         reader/lib/app/routes/user
         reader/lib/web/routes)

(provide app-dispatch app-url)

(define-values (app-dispatch app-url)
  (dispatch-rules
   [("") (authenticated-route /articles)]

   [("sessions" "new") (route /sessions/new)]
   [("sessions" "create") #:method "post" (route /sessions/create)]
   [("sessions" "destroy") #:method "delete"  (route /sessions/destroy)]
   [("sessions" "destroy") (route /sessions/destroy)]

   [("users" "new") (route /users/new)]
   [("users" "create") #:method "post" (route /users/create)]

   [("feeds") (authenticated-route /feeds)]
   [("feeds" "new") (authenticated-route /feeds/new)]
   [("feeds" "create") #:method "post" (authenticated-route /feeds/create)]
   [("feeds" (integer-arg) "unsubscribe") #:method "put" (authenticated-route /feeds/<id>/unsubscribe)]
   [("feeds" (integer-arg) "unsubscribe") (authenticated-route /feeds/<id>/unsubscribe)]
   [("feeds" (integer-arg) "subscribe") #:method "put" (authenticated-route /feeds/<id>/subscribe)]
   [("feeds" (integer-arg) "subscribe") (authenticated-route /feeds/<id>/subscribe)]
   [("feeds" (integer-arg) "articles") (authenticated-route /feeds/<id>/articles)]
   [("feeds" (integer-arg) "sync") (authenticated-route /feeds/<id>/sync)]

   [("articles") (authenticated-route /articles)]
   [("articles" (integer-arg)) (authenticated-route /articles/<id>/show)]
   [("articles" (integer-arg) "archive") #:method "put" (authenticated-route /articles/<id>/archive)]
   [("articles" (integer-arg) "archive") (authenticated-route /articles/<id>/archive)]
   [("articles" (integer-arg) "unarchive") #:method "put" (authenticated-route /articles/<id>/unarchive)]
   [("articles" (integer-arg) "unarchive") (authenticated-route /articles/<id>/unarchive)]
   [("articles" (integer-arg) "summary") (authenticated-route /articles/<id>/summary)]
   [("articles" (integer-arg) "chat") #:method "post" (authenticated-route /articles/<id>/chat)]

   [else
    (lambda (req)
      (match (url-path (request-uri req))
        [(list (path/param "public" _) _ ...)
         ; TODO this will respond with the default 404 page
         ((next-dispatcher) req)]
        [else
         ((authenticated-route /not-found) req)]))]))
