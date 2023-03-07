#lang racket/base

(require racket/string

         json
         web-server/servlet
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/extra)

         reader/lib/web/parameters)

(provide render)

(define (render content #:layout [layout (default-layout)] #:code [code 200])
  (let* ([request (current-request)]
         [json? (wants-json? request)]
         [content-type (if json?
                           #"application/json; charset=utf-8"
                           #"text/html; charset=utf-8")])
    (response/output
     #:code code
     #:headers (list (header #"Content-Type" content-type))
     (lambda (op)
       (parameterize ([current-request request])
         (display (if json?
                      (jsexpr->string (hash 'html (:xml->string content)))
                      (layout content)) op))))))

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

(default-layout basic-layout)
