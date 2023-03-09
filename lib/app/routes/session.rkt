#lang racket/base

(require deta
         web-server/servlet

         reader/lib/app/components/session
         reader/lib/app/parameters
         reader/lib/app/models/user
         reader/lib/web
         reader/lib/crypto)

(provide /sessions/new
         /sessions/create
         /sessions/destroy)

(define (/sessions/new req)
  (let* ([email (parameter 'email req)])
    (render ((component-session/form) email))))

(define (/sessions/create req)
  (let* ([email (parameter 'email req)]
         [password (parameter 'password req)]
         [user (lookup (current-database-connection) (find-user-by-email email))])
    (if (and user (check-password #:unencrypted password
                                  #:encrypted ((model-user-encrypted-password) user)
                                  #:salt ((model-user-salt) user)))
        (redirect-to "/" permanently
                     #:headers (list
                                (cookie->header
                                 (create-session+cookie #:user-id ((model-user-id) user)))))
        (with-flash #:notice "Invalid credentials, please try again."
          (redirect (format "/sessions/new?email=~a" email))))))

(define (/sessions/destroy req)
  (redirect-to "/sessions/new" permanently
               #:headers (list
                          (cookie->header
                           (destroy-session+cookie req)))))
