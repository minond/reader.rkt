#lang racket/base

(require web-server/servlet

         reader/lib/web)

(provide app-dispatch app-url)

(require (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra))

(define (/index req)
  (render (:main (:h1 "Welcome"))))

(define-values (app-dispatch app-url)
  (dispatch-rules
   [("") (authenticated-route /index)]
   [else (authenticated-route /not-found)]))
