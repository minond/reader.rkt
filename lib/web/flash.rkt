#lang racket/base

(require
  (for-syntax racket
              syntax/parse))

(require racket/match
         gregor
         reader/lib/web/session
         reader/lib/web/parameters)

(provide current-flash
         read-flash
         with-flash)

(struct flash (expires alert notice) #:prefab)

(define (make-flash #:from [from #f]
                    #:alert [alert #f]
                    #:notice [notice #f])
  (flash (+seconds (now/utc) 1)
         (if alert
             alert
             (and (flash-active? from)
                  (flash-alert from)))
         (if notice
             notice
             (and (flash-active? from)
                  (flash-notice from)))))

(define (flash-active? flash)
  (and (flash? flash)
       (datetime>? (flash-expires flash) (now/utc))))

(define read-flash
  (case-lambda
    [(field) (read-flash (current-request) field)]
    [(req field) (let* ([session (lookup-session req)]
                        [flash (and (session? session)
                                    (session-flash session))])
                   (if (not (flash-active? flash))
                       #f
                       (match field
                         ['alert (flash-alert flash)]
                         ['notice (flash-notice flash)])))]))

(define-syntax (with-flash stx)
  (syntax-parse stx
    [(with-flash (~or (~seq #:alert alert:expr)
                      (~seq))
       (~or (~seq #:notice notice:expr)
            (~seq))
       e ...)
     #'(parameterize ([current-flash (make-flash #:from (current-flash)
                                                 #:alert (~? alert #f)
                                                 #:notice (~? notice #f))])
         e ...)]))
