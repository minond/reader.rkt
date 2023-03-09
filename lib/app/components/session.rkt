#lang racket/base

(require (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/lib/app/parameters)

(provide :session/form)

(define (:session/form [email null])
  (:form 'action: "/sessions/create"
         'method: "post"
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
         (:input 'type: "submit"
                 'value: "Login")
         (:a 'href: "/users/new"
             "or register instead")))

(component-session/form :session/form)
