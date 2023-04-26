#lang racket/base

(require (for-syntax racket/base
                     racket/function
                     racket/syntax
                     racket/list
                     racket/string
                     syntax/parse
                     threading
                     yaml))

(require racket/string
         racket/function
         racket/list
         racket/sequence

         net/http-easy
         monotonic
         json)

(provide openapi)

(define charset
  (map integer->char
       (append (inclusive-range 48 57)
               (inclusive-range 65 90)
               (inclusive-range 97 122))))

(define (random-item xs)
  (sequence-ref xs (random (sequence-length xs))))

(define (random-string [len 16])
  (list->string
   (map (lambda (x)
          (random-item charset))
        (make-list len 0))))

(begin-for-syntax
  (struct endpoint (id path method content-type request-properties) #:transparent)
  (struct request-property (id label kwd nullable) #:transparent)

  (define (request-property->arg prop)
    (if (request-property-nullable prop)
        `(,(request-property-kwd prop)
          ,(list (request-property-id prop) (void)))
        `(,(request-property-kwd prop)
          ,(request-property-id prop))))

  (define (request-property->arg/list lst)
    (foldl (lambda (prop acc)
             (append acc (request-property->arg prop)))
           null lst))

  (define (request-property->hash-set prop)
    (if (request-property-nullable prop)
        `(when (not (void? ,(request-property-id prop)))
           (hash-set! req
                      ',(request-property-label prop)
                      ,(request-property-id prop)))
        `(hash-set! req
                    ',(request-property-label prop)
                    ,(request-property-id prop))))

  (define (deep-hash-ref value parts)
    (if (null? parts)
        value
        (deep-hash-ref (hash-ref value (car parts))
                       (cdr parts))))

  (define (kind-of-equal? a b)
    (equal? (if (string? a)
                (string->symbol a)
                a)
            (if (string? b)
                (string->symbol b)
                b)))

  (define (normalize-id str)
    (~> str
        (string-replace "_" "-")
        (regexp-replace* #px"([A-Z])" _
                         (lambda (_ ch)
                           (string-append "-" (string-downcase ch)))))))

(define-syntax (openapi stx)
  (syntax-parse stx
    [(_ name:id path:str
        (~optional (~seq #:only only:expr))
        (~optional (~seq #:bearer bearer:expr))
        (~optional (~seq #:headers headers:expr)))
     (define definition (file->yaml (syntax->datum #'path)))

     (define servers (hash-ref definition "servers"))
     (define paths (hash-ref definition "paths"))
     (define urls (map (lambda~> (hash-ref "url")) servers))

     (define only-generate
       (if (attribute only)
           (syntax->datum #'only)
           null))

     (define endpoints
       (filter
        identity
        (flatten
         (for/list ([path (hash-keys paths)])
           (let/cc return
             (define by-method (hash-ref paths path))
             (for/list ([method (hash-keys by-method)])
               (define info (hash-ref by-method method))
               (define action-name (normalize-id (hash-ref info "operationId")))

               (when (and (not (null? only-generate))
                          (not (member action-name only-generate kind-of-equal?)))
                 (return #f))

               (define id (format-id #'name action-name))
               (define request-body
                 (and (hash-has-key? info "requestBody")
                      (hash-ref info "requestBody")))

               ;; TODO handle endpoints that don't have request bodies
               (unless request-body
                 (return #f))

               (define content (hash-ref request-body "content"))
               (define content-types (hash-keys content))
               (define content-type (car content-types))

               (define ref (deep-hash-ref content (list content-type "schema" "$ref")))
               (define schema-path (cdr (string-split ref "/")))
               (define schema (deep-hash-ref definition schema-path))
               (define properties (hash-ref schema "properties"))

               (define request-properties
                 (hash-map properties
                           (lambda (label attributes)
                             (define normal (normalize-id label))
                             (define id (format-id #'name normal))
                             (define kwd (string->keyword normal))
                             ; We'll treat both nullable properties and
                             ; properties that have a default value as a
                             ; nullable argument.
                             (define nullable (or (and (hash-has-key? attributes "nullable")
                                                       (hash-ref attributes "nullable"))
                                                  (hash-has-key? attributes "default")))
                             (request-property id (string->symbol label) kwd nullable))))

               (endpoint id path (string->symbol method) content-type request-properties)))))))

     #`(begin
         (define urls '#,urls)
         (define (gen-url p)
           (string-join (list (car (shuffle urls)) p) ""))

         (define gen-headers
           (~? headers
               (lambda (-method -path content-type req)
                 (define bearer-value (~? bearer #f))
                 (make-immutable-hash
                  (filter (negate void?)
                          (list*
                           (cons 'Content-Type content-type)
                           (when bearer-value
                             (cons 'Authorization (format "Bearer ~a" bearer-value)))
                           null))))))

         #,@(for/list ([endpoint endpoints])
              (define args (request-property->arg/list
                            (endpoint-request-properties endpoint)))
              (define set-fields
                (map request-property->hash-set
                     (endpoint-request-properties endpoint)))

              `(define (,(endpoint-id endpoint) ,@args)
                 (define req (make-hash))

                 ,@set-fields

                 (define method ',(endpoint-method endpoint))
                 (define content-type ,(endpoint-content-type endpoint))
                 (define path ,(endpoint-path endpoint))
                 (define url (gen-url path))
                 (define headers (gen-headers method path content-type req))
                 (define data (string->bytes/utf-8
                               (jsexpr->string req)))
                 (define id (random-string))

                 (log-info "~a ~a ~a ~aB"
                           id method path
                           (bytes-length data))

                 (define start-time (current-monotonic-nanoseconds))
                 (define res
                   (,(endpoint-method endpoint) url
                                                #:headers headers
                                                #:json req))
                 (define end-time (current-monotonic-nanoseconds))

                 (log-info "~a ~a ~a ~aB ~ams"
                           id method path
                           (bytes-length (response-body res))
                           (ceiling (/ (- end-time start-time) 1000000)))

                 (response-json res))))]))
