#lang racket/base

(require net/url-string

         reader/app/commands/deduce-item-info
         reader/app/components/item

         reader/lib/web)

(provide /item/add
         /item/deduce)

(define (/item/add req)
  (render (:item/add)))

(define (/item/deduce req)
  (define deductions (deduce-item-info (parameter 'url req)))
  (json 'deductions
        (map (lambda (deduction)
               (hash 'kind (symbol->string (deduction-kind deduction))
                     'url (url->string (deduction-url deduction))
                     'title (deduction-title deduction)))
             deductions)))
