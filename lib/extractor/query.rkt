#lang racket/base

(require racket/function
         racket/match
         racket/list

         (prefix-in x: xml)

         reader/lib/extractor/attribute)

(provide find-elements
         find-element
         find*/list
         find*)

;; TODO Replace with find*/list
(define (find-elements tag root [acc null])
  (cond
    [(list? root)
     (append (flatten (map (curry find-elements tag) root))
             acc)]
    [(x:element? root)
     (if (eq? tag (x:element-name root))
         (cons root acc)
         (append (flatten (map (curry find-elements tag) (x:element-content root)))
                 acc))]
    [else acc]))

;; TODO Replace with find*
(define (find-element tag root)
  (let ([res (find-elements tag root)])
    (if (not (empty? res))
        (car res)
        #f)))

(define (find* el #:tag [tagq #f] #:attr [attrq #f])
  (define res (find*/list el #:tag tagq #:attr attrq))
  (and (not (empty? res))
       (car res)))

(define (find*/list el #:tag [tagq #f] #:attr [attrq #f] [acc empty])
  (cond
    [(list? el)
     (append (flatten
              (map (lambda (el)
                     (find*/list el #:tag tagq #:attr attrq))
                   el))
             acc)]
    [(not (x:element? el)) acc]
    [(and tagq attrq)
     (if (and (tag-equal? el tagq)
              (attribute-equal? el attrq))
         (cons el acc)
         (find*/list (x:element-content el)
                     #:tag tagq #:attr attrq acc))]
    [tagq
     (if (tag-equal? el tagq)
         (cons el acc)
         (find*/list (x:element-content el)
                     #:tag tagq #:attr attrq acc))]
    [attrq
     (if (attribute-equal? el attrq)
         (cons el acc)
         (find*/list (x:element-content el)
                     #:tag tagq #:attr attrq acc))]
    [else acc]))

(define (tag-equal? el q)
  (eq? q (x:element-name el)))

(define (attribute-equal? el q)
  (match-define (list name value)
    (if (list? q)
        q
        (list q #f)))

  (define attributes (x:element-attributes el))
  (define attribute (find-attr name attributes))

  (if (or (and (not value)
               attribute)
          (and value
               (equal? value (read-attr attribute))))
      el
      #f))
