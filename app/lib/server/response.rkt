#lang racket/base

(require racket/string

         threading
         json
         web-server/servlet
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/extra)

         reader/lib/parameters
         reader/lib/server/session)

(provide json
         render
         redirect
         redirect-back)

(define (json . args)
  (define obj (apply hash args))
  (respond-with #:data (jsexpr->string obj)
                #:content-type APPLICATION/JSON-MIME-TYPE))

(define (render content
                #:code [code 200]
                #:layout [layout (or (default-layout) basic-layout)])
  (let* ([json? (wants-json? (current-request))]
         [content-type (if json?
                           APPLICATION/JSON-MIME-TYPE
                           TEXT/HTML-MIME-TYPE)]
         [data (if json?
                   (jsexpr->string (hash 'html (:xml->string content)))
                   (layout content))])
    (respond-with #:data data
                  #:code code
                  #:content-type content-type)))

(define (respond-with #:data data
                      #:code [code 200]
                      #:content-type [content-type TEXT/HTML-MIME-TYPE])
  (let* ([request (current-request)]
         [session (current-session)]
         [user-id (current-user-id)])
    (response/output
     #:code code
     #:headers (list (header #"Content-Type" content-type))
     (lambda (op)
       (parameterize ([current-request request]
                      [current-session session]
                      [current-user-id user-id])
         (display data op))))))

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
