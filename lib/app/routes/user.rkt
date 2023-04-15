#lang racket/base

(require deta
         web-server/servlet

         reader/lib/app/components/user
         reader/lib/parameters
         reader/lib/web
         reader/lib/crypto)

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
      (let-values ([(ok notice) ((user-registration/validate) req)])
        (if (not ok)
            (registration-err req notice)
            (registration-ok req)))))

(define (registration-err req notice)
  (with-flash #:notice notice
    (redirect (format "/users/new?email=~a&~a"
                      (parameter 'email req)
                      (parameter 'for-retry req #:default "")))))

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
