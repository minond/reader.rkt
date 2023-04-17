#lang racket/base

(require (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/lib/web
         reader/lib/parameters)

(provide :user/form)

;; TODO URLs need to be dynamic
(define (:user/form [req #f] [error-message #f])
  (define email (and req (parameter 'email req)))
  (:form 'action: "/users/create"
         'method: "post"
         (and error-message
              (:p 'class: "error-message"
                  error-message))
         (:input 'type: "email"
                 'name: "email"
                 'value: email
                 'required: "true"
                 'autofocus: "true"
                 'autocapitalize: "false"
                 'placeholder: "Email")
         (:input 'type: "password"
                 'name: "password"
                 'required: "true"
                 'placeholder: "Password")
         (:input 'type: "password"
                 'name: "password-confirm"
                 'required: "true"
                 'placeholder: "Password confirmation")
         (:input 'type: "submit"
                 'value: "Register")
         (:span "or ")
         (:a 'href: "/sessions/new"
             "login instead")))

(component-user/form :user/form)
