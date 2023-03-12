#lang racket/base

(require racket/match
         racket/list
         racket/string
         racket/function

         threading
         html-parsing)

(provide parse
         (struct-out element)
         (struct-out text)
         (struct-out entity)
         (struct-out attribute))

(struct element (tag attributes children) #:transparent)
(struct text (text) #:transparent)
(struct entity (id) #:transparent)
(struct attribute (name value) #:transparent)

(define (parse str)
  ;; NOTE html-parsing's html->xexp has some issues: it doesn't support doctype
  ;; declarations, it gets hung up when the HTML starts right away for some
  ;; reason. Additional content type strings will have to be added, but since
  ;; HTML5 doctype is the most common right now, that'll be a good start.
  ;; Possibly other alterations will have to be done here as well, but luckly
  ;; this package will make swapping out HTML parsers easier in the future.
  (define prepared
    (~> str
        (string-replace "<!DOCTYPE html>" "")
        (string-append " " _ " ")))

  (define tree (cddr (html->xexp prepared)))

  (define (walk el)
    (match el
      [(? string?)
       (text el)]
      [(? symbol?)
       (entity el)]
      [(list (? symbol? tag)
             (list '@ attributes ...)
             children ...)
       (element tag
                (list->attributes attributes)
                (filter identity (map walk children)))]
      [(list '*COMMENT* _ ...)
       #f]
      [(list (? symbol? tag) children ...)
       (element tag
                empty
                (filter identity (map walk children)))]
      [(list siblings ...)
       (filter identity (map walk siblings))]
      [else
       (error "detected unknown element:" el)]))

  (walk tree))

(define (list->attributes lst)
  (map (lambda (item)
         (attribute (car item)
                    (if (not (empty? (cdr item)))
                        (cadr item)
                        #f))) lst))
