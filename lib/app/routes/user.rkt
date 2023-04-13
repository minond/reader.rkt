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
  (let* ([email (parameter 'email req)])
    (render ((component-user/form) email))))

;; TODO URLs need to be dynamic
(define (/users/create req)
  (define-values (ok notice) ((user-registration/validate) req))
  (if (not ok)
      (registration-err req notice)
      (registration-ok req)))

(define (registration-err req notice)
  (with-flash #:notice notice
    (redirect (format "/users/new?email=~a"
                      (parameter 'email req)))))

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
   (define ok
     (and (parameter 'email req)
          (equal? (parameter 'password req)
                  (parameter 'password-confirm req))))
   (values ok "Your password and confirmation did not match, please try again.")))

(user-registration/registered
 (lambda (req user)
   (void)))
