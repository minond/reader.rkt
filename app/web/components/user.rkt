#lang racket/base

(require racket/string

         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/lib/string
         reader/lib/server
         reader/lib/parameters)

(provide :user/form)

(define (:user/form [req #f] [error-message #f])
  (define code (and req (parameter 'code req)))
  (define email (and req (parameter 'email req)))

  (:div 'class: "registration-form"
        (and error-message
             (:p 'class: "error-message"
                 error-message))
        (if (not (non-empty-string? code))
            (list
             (:p "Thank you for your interest in Reader, unfortunately we're currently in private beta mode and you'll need an invite before you can register."))
            (list
             (:p "Thank you for your interest in Reader, I hope that you find this application both helpful and enjoyable to use.")
             (:p "If you have any issues or feedback, don't hesitate to submit them via the feedback form or email me directly.")
             (:form 'action: "/users/create"
                    'method: "post"
                    'class: "user-registration-form"
                    (:input 'type: "text"
                            'name: "code"
                            'value: code
                            'readonly: "true"
                            'required: "true"
                            'placeholder: "Invite code")
                    (:input 'type: "email"
                            'name: "email"
                            'value: email
                            'required: "true"
                            'autofocus: (not email)
                            'autocapitalize: "false"
                            'placeholder: "Email")
                    (:input 'type: "password"
                            'name: "password"
                            'required: "true"
                            'autofocus: (string->boolean email)
                            'placeholder: "Password")
                    (:input 'type: "password"
                            'name: "password-confirm"
                            'required: "true"
                            'placeholder: "Password confirmation")
                    (:input 'type: "submit"
                            'value: "Register")
                    (:span "or ")
                    (:a 'href: "/sessions/new"
                        "login instead"))))))
