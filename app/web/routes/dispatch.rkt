#lang racket/base

(require racket/match

         web-server/servlet
         web-server/dispatchers/dispatch

         reader/web/routes/article
         reader/web/routes/feed
         reader/web/routes/suggestions

         reader/lib/app/web/routes/session
         reader/lib/app/web/routes/user
         reader/lib/server/routes)

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
   [("feeds" (string-arg) "unsubscribe") #:method "put" (authenticated-route /feeds/<id>/unsubscribe)]
   [("feeds" (string-arg) "unsubscribe") (authenticated-route /feeds/<id>/unsubscribe)]
   [("feeds" (string-arg) "subscribe") #:method "put" (authenticated-route /feeds/<id>/subscribe)]
   [("feeds" (string-arg) "subscribe") (authenticated-route /feeds/<id>/subscribe)]
   [("feeds" (string-arg) "articles") (authenticated-route /feeds/<id>/articles)]
   [("feeds" (string-arg) "sync") (authenticated-route /feeds/<id>/sync)]

   [("articles") (authenticated-route /articles)]
   [("articles" (string-arg)) (authenticated-route /articles/<id>/show)]
   [("articles" (string-arg) "archive") #:method "put" (authenticated-route /articles/<id>/archive)]
   [("articles" (string-arg) "archive") (authenticated-route /articles/<id>/archive)]
   [("articles" (string-arg) "unarchive") #:method "put" (authenticated-route /articles/<id>/unarchive)]
   [("articles" (string-arg) "unarchive") (authenticated-route /articles/<id>/unarchive)]
   [("articles" (string-arg) "summary") (authenticated-route /articles/<id>/summary)]
   [("articles" (string-arg) "tags") (authenticated-route /articles/<id>/tags)]
   [("articles" (string-arg) "chat") #:method "post" (authenticated-route /articles/<id>/chat)]

   [("suggestions") (authenticated-route /suggestions)]

   [else
    (lambda (req)
      (match (url-path (request-uri req))
        [(list (path/param "public" _) _ ...)
         ; TODO this will respond with the default 404 page
         ((next-dispatcher) req)]
        [else
         ((authenticated-route /not-found) req)]))]))
