#lang racket/base

(require racket/match
         racket/list

         (prefix-in html- reader/lib/extractor/html)
         reader/lib/extractor/attribute)

(provide find*
         find*/list)

(define (find* el #:tag [tagq #f] #:attr [attrq #f])
  (define res (find*/list el #:tag tagq #:attr attrq))
  (and (not (empty? res))
       (car res)))

(define (find*/list el #:tag [tagq #f] #:attr [attrq #f] [acc empty])
  (match el
    [(? list?)
     (append (flatten
              (map (lambda (el)
                     (find*/list el #:tag tagq #:attr attrq))
                   el))
             acc)]
    [(? html-text?)
     acc]
    [(html-element tag attributes children)
     (cond
       [(and tagq attrq)
        (if (and (equal? tag tagq)
                 (contains-attribute attributes attrq))
            (cons el acc)
            acc)]
       [(and tagq (equal? tag tagq))
        (cons el acc)]
       [(and attrq (contains-attribute attributes attrq))
        (cons el acc)]
       [else
        (find*/list children #:tag tagq #:attr attrq acc)])]
    [else
     acc]))

(define (contains-attribute lst q)
  (match-define (list name value)
    (if (list? q)
        q
        (list q #f)))

  (define attribute (find-attribute lst name))

  (or (and (not value)
           attribute)
      (and value
           (equal? value (html-attribute-value attribute)))))
