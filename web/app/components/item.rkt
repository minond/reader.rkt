#lang racket/base

(require reader/lib/app/components/script)

(provide :item/add)

(define (:item/add)
  (:script/component 'AddItem))
