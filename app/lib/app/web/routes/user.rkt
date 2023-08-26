#lang racket/base

(require deta
         web-server/servlet

         "../../../../lib/app/components/user.rkt"
         "../../../../lib/parameters.rkt"
         "../../../../lib/server.rkt"
         "../../../../lib/crypto.rkt")

(provide /users/new
         /users/create)

(define (/users/new req)
  (render ((component-user/form) req)))

;; TODO URLs need to be dynamic
(define (/users/create req)
  (define passwords-match
    (and (parameter 'email req)
         (equal? (parameter 'password req)
                 (parameter 'password-confirm req))))

  (if (not passwords-match)
      (registration-err req "Your password and confirmation did not match, please try again.")
      (let-values ([(ok error-message) ((user-registration/validate) req)])
        (if (not ok)
            (registration-err req error-message)
            (registration-ok req)))))

(define (registration-err req error-message)
  (render ((component-user/form) req error-message)))

(define (registration-ok req)
  (define email (parameter 'email req))
  (define password (parameter 'password req))
  (define-values (encrypted-password salt) (make-password password))
  (define user
    (insert-one! (current-database-connection)
                 ((model-make-user) #:email email
                                    #:salt salt
                                    #:encrypted-password encrypted-password)))

  ((user-registration/registered) req user)

  (define session-cookie
    (create-session+cookie #:user-id ((model-user-id) user)))
  (redirect-to "/" permanently
               #:headers (list (cookie->header session-cookie))))

(user-registration/validate
 (lambda (req)
   (values #t "")))

(user-registration/registered
 (lambda (req user)
   (void)))
