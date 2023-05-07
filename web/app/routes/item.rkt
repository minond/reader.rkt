#lang racket/base

(require net/url-string

         reader/app/commands/suggestions
         reader/app/components/item

         reader/lib/web)

(provide /add
         /suggestions)

(define (/add req)
  (render (:item/add)))

(define (/suggestions req)
  (define suggestions (make-suggestions (parameter 'url req)))
  (json 'suggestions
        (map (lambda (suggestion)
               (hash 'kind (symbol->string (suggestion-kind suggestion))
                     'url (url->string (suggestion-url suggestion))
                     'title (suggestion-title suggestion)))
             suggestions)))
