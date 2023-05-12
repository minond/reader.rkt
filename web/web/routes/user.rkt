#lang racket/base

(require threading
         deta
         gregor

         reader/entities/registration-invitation
         reader/entities/user
         reader/lib/parameters
         reader/lib/web)

(provide user-registration/validate+override
         user-registration/registered+override)

;; Triggered before creating a user. Checks if the invitation code in the
;; request is valid and hasn't been used yet.
(define (user-registration/validate+override req)
  (let* ([code (parameter 'code req)]
         [valid-code? (and code
                           (lookup (current-database-connection)
                                   (find-available-registration-invitation #:code code)))])
    (values valid-code?
            "This registration code is not valid. Please ensure you provided the correct code.")))

;; Triggered after the user is created. Marks the invitation code as used and
;; associates it to the new user.
(define (user-registration/registered+override req user)
  (let* ([code (parameter 'code req)]
         [invite (lookup (current-database-connection)
                         (find-available-registration-invitation #:code code))])
    (update-one! (current-database-connection)
                 (~> invite
                     (set-registration-invitation-user-id (user-id user))
                     (set-registration-invitation-user-registered-at (now/utc))
                     (set-registration-invitation-available #f)))))
