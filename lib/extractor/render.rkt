#lang racket/base

(require racket/list
         racket/match

         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)

         reader/lib/extractor/content)

(provide render-content)

(define headings-by-level
  (hash
   1 :h1
   2 :h2
   3 :h3
   4 :h4
   5 :h5
   6 :h6))

(define (attributes-arguments attributes)
  (let ([id (findf id? attributes)])
    (if id `('id: ,(id-value id)) empty)))

(define (render-element tagf attributes content)
  (eval `(,tagf ,@(attributes-arguments attributes)
                ',(render-content content))))

(define (render-content elem-or-lst)
  (if (list? elem-or-lst)
      (for/list ([elem elem-or-lst])
        (render-content elem))
      (match elem-or-lst
        [(heading attributes level content)
         ((hash-ref headings-by-level level)
          (render-content content))]
        [(paragraph attributes content)
         (render-element :p attributes content)]
        [(link attributes href content)
         (eval `(,:a ,@(attributes-arguments attributes)
                     'href: ,href
                     ',(render-content content)))]
        [(bold attributes content)
         (render-element :b attributes content)]
        [(italic attributes content)
         (render-element :i attributes content)]
        [(code attributes content)
         (render-element :code attributes content)]
        [(ordered-list attributes content)
         (render-element :ol attributes content)]
        [(unordered-list attributes content)
         (render-element :ul attributes content)]
        [(list-item attributes content)
         (render-element :li attributes content)]
        [(blockquote attributes content)
         (render-element :blockquote attributes content)]
        [(superscript attributes content)
         (render-element :sup attributes content)]
        [(pre attributes content)
         (render-element :pre attributes content)]
        [(separator)
         (:hr)]
        [(line-break)
         (:br)]
        [(video attributes src)
         (eval `(,:element 'video
                           ,@(attributes-arguments attributes)
                           'src: ,src
                           'autoplay: "autoplay"
                           'muted: "true"
                           'loop: "true"
                           '(#f)))]
        [(image attributes src alt)
         (eval `(,:img ,@(attributes-arguments attributes)
                       'src: ,src
                       'alt: ,alt))]
        [(entity id)
         (:entity id)]
        [(text text)
         text]
        [else
         ; (printf "[error] unimplemented ~a\n" elem-or-lst)
         ""])))
