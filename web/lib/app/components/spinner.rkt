#lang racket/base

(require (prefix-in : scribble/html/html))

(provide :spinning-ring)

(define (:spinning-ring size)
  (define size-half (floor (/ size 2)))
  (:div 'class: "spinning-ring"
        'style: (format "height: ~apx; width: ~apx" size size)
        (:div 'style: (format "height: ~apx; width: ~apx" size-half size-half))
        (:div 'style: (format "height: ~apx; width: ~apx" size-half size-half))
        (:div 'style: (format "height: ~apx; width: ~apx" size-half size-half))
        (:div 'style: (format "height: ~apx; width: ~apx" size-half size-half))))
