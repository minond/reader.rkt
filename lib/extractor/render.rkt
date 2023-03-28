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
  (let ([id (findf id? attributes)]
        [height (findf height? attributes)]
        [width (findf width? attributes)]
        [name (findf name? attributes)])
    (append
     (if id `(id: ,(element-attribute-value id)) empty)
     (if height `(height: ,(element-attribute-value height)) empty)
     (if width `(width: ,(element-attribute-value width)) empty)
     (if name `(name: ,(element-attribute-value name)) empty)
     empty)))

(define (render-element tagf attributes content)
  (apply tagf (append (attributes-arguments attributes)
                      (list (render-content content)))))

(define (render-content elem-or-lst)
  (if (list? elem-or-lst)
      (for/list ([elem elem-or-lst])
        (render-content elem))
      (match elem-or-lst
        [(heading attributes content level)
         ((hash-ref headings-by-level level)
          (render-content content))]
        [(paragraph attributes content)
         (render-element :p attributes content)]
        [(division attributes content)
         (render-element :div attributes content)]
        [(link attributes content href)
         (apply :a (append (attributes-arguments attributes)
                           (list 'href: href
                                 (render-content content))))]
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
        [(table attributes content)
         (render-element :table attributes content)]
        [(table-row attributes content)
         (render-element :tr attributes content)]
        [(table-cell attributes content)
         (render-element :td attributes content)]
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
         (apply :element 'video
                (append (attributes-arguments attributes)
                        (list 'src: src
                              'autoplay: "autoplay"
                              'muted: "true"
                              'loop: "true"
                              #f)))]
        [(iframe attributes src)
         (apply :iframe
                (append (attributes-arguments attributes)
                        (list 'src: src)))]
        [(image attributes src alt)
         (apply :img
                (append (attributes-arguments attributes)
                        (list 'src: src
                              'alt: alt)))]
        [(object attributes content type data)
         (apply :object
                (append (attributes-arguments attributes)
                        (list 'type: type
                              'data: data
                              (render-content content))))]
        [(entity id)
         (:entity id)]
        [(text text)
         text]
        [else
         (error "unable to render" elem-or-lst)])))
