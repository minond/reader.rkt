#lang racket/base

(require web-server/servlet

         reader/lib/app/routes/session
         reader/lib/app/routes/user
         reader/app/routes
         reader/lib/web)

(provide app-dispatch app-url)

(require (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra))

(define (/index req)
  (render (:h1 "Welcome")))

(define-values (app-dispatch app-url)
  (eval
   `(dispatch-rules
     [("") (authenticated-route /index)]

     ,@(session-routes)
     ,@(user-routes)

     [("feeds") (authenticated-route /feeds)]
     [("feeds" "new") (authenticated-route /feeds/new)]
     [("feeds" "create") #:method "post" (authenticated-route /feeds/create)]
     [("feeds" (integer-arg) "unsubscribe") #:method "put" (authenticated-route /feeds/<id>/unsubscribe)]
     [("feeds" (integer-arg) "unsubscribe") (authenticated-route /feeds/<id>/unsubscribe)]
     [("feeds" (integer-arg) "subscribe") #:method "put" (authenticated-route /feeds/<id>/subscribe)]
     [("feeds" (integer-arg) "subscribe") (authenticated-route /feeds/<id>/subscribe)]
     ; [("feeds" (integer-arg) "articles") (authenticated-route /feeds/<id>/articles)]
     [("feeds" (integer-arg) "sync") (authenticated-route /feeds/<id>/sync)]
     ; [("articles") (authenticated-route /articles)]
     ; [("articles" (integer-arg)) (authenticated-route /arcticles/<id>/show)]
     ; [("articles" (integer-arg) "archive") #:method "put" (authenticated-route /articles/<id>/archive)]
     ; [("articles" (integer-arg) "archive") (authenticated-route /articles/<id>/archive)]
     ; [("articles" (integer-arg) "unarchive") #:method "put" (authenticated-route /articles/<id>/unarchive)]
     ; [("articles" (integer-arg) "unarchive") (authenticated-route /articles/<id>/unarchive)]
     [else (authenticated-route /not-found)])))
