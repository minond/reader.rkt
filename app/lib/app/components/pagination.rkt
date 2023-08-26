#lang racket/base

(require racket/match
         racket/list

         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         "../../../lib/pair.rkt")

(provide :pagination)

(define (:pagination current-page page-count)
  (if (eq? page-count 1)
      null
      (let ([numbers (page-numbers current-page page-count)])
        (:div 'class: "page-links"
              (and (> current-page 1)
                   (:a 'class: "page-link"
                       'href: (format "?page=~a" (- current-page 1)) "<"))
              (map (lambda (num)
                     (match num
                       ['skip (:span 'class: "page-skip" "…")]
                       [else (:a 'class: (if (eq? num current-page) "page-link current" "page-link")
                                 'href: (format "?page=~a" num) num)])) numbers)
              (and (< current-page page-count)
                   (:a 'class: "page-link"
                       'href: (format "?page=~a" (+ current-page 1)) ">"))))))

(define (page-numbers current-page page-count)
  (if (< page-count 10)
      (inclusive-range 1 page-count)
      (let* ([start (inclusive-range 1 3)]
             [middle (inclusive-range (- current-page 2) (+ current-page 2))]
             [end (inclusive-range (- page-count 3) page-count)]
             [whole (filter (lambda (num)
                              (and (positive? num) (<= num page-count)))
                            (sort (remove-duplicates (append start middle end)) <))])
        (reduce-by-pair (lambda (acc a b)
                          (if (eq? (- b a) 1)
                              (append acc (list a))
                              (append acc (list a 'skip)))) whole))))
