#lang racket/base

(require racket/string

         threading
         json
         web-server/servlet
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/extra)

         reader/lib/parameters
         reader/lib/web/session)

(provide render
         redirect
         redirect-back)

(define (render content
                #:layout [layout (or (default-layout) basic-layout)]
                #:code [code 200])
  (let* ([request (current-request)]
         [session (current-session)]
         [user-id (current-user-id)]
         [json? (wants-json? request)]
         [content-type (if json?
                           #"application/json; charset=utf-8"
                           #"text/html; charset=utf-8")])
    (response/output
     #:code code
     #:headers (list (header #"Content-Type" content-type))
     (lambda (op)
       (parameterize ([current-request request]
                      [current-session session]
                      [current-user-id user-id])
         (display (if json?
                      (jsexpr->string (hash 'html (:xml->string content)))
                      (layout content)) op))))))

(define (redirect url)
  (~> (current-session)
      (update-session+cookie _ #:flash (current-flash))
      (cookie->header _)
      (list _)
      (redirect-to url temporarily #:headers _)))

(define (redirect-back)
  (let ([referer (assq 'referer (request-headers (current-request)))])
    (if referer
        (redirect (cdr referer))
        (redirect "/"))))

(define (wants-json? req)
  (let ([accept (assq 'accept (request-headers req))])
    (and accept
         (string-contains?
          (cdr accept)
          "json"))))

(define (basic-layout content)
  (:xml->string
   (list (:doctype 'html)
         (:html
          (:head
           (:meta 'charset: "utf-8")
           (:meta 'name: "viewport"
                  'content: "width=device-width, initial-scale=1.0")
           (:body
            (:main content)))))))
