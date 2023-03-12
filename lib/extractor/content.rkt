#lang racket/base

(require racket/function
         racket/match
         racket/list
         racket/string

         threading

         reader/lib/extractor/attribute
         reader/lib/extractor/url
         reader/lib/extractor/query
         (prefix-in html- reader/lib/extractor/html))

(provide extract-content
         (struct-out heading)
         (struct-out paragraph)
         (struct-out pre)
         (struct-out code)
         (struct-out bold)
         (struct-out italic)
         (struct-out blockquote)
         (struct-out superscript)
         (struct-out ordered-list)
         (struct-out unordered-list)
         (struct-out list-item)
         (struct-out text)
         (struct-out entity)
         (struct-out image)
         (struct-out video)
         (struct-out link)
         (struct-out separator)
         (struct-out line-break)
         (struct-out id))

(struct heading (attributes level content) #:prefab)
(struct paragraph (attributes content) #:prefab)
(struct pre (attributes content) #:prefab)
(struct code (attributes content) #:prefab)
(struct bold (attributes content) #:prefab)
(struct italic (attributes content) #:prefab)
(struct blockquote (attributes content) #:prefab)
(struct superscript (attributes content) #:prefab)
(struct ordered-list (attributes items) #:prefab)
(struct unordered-list (attributes items) #:prefab)
(struct list-item (attributes content) #:prefab)
(struct text (text) #:prefab)
(struct entity (id) #:prefab)
(struct image (attributes src alt) #:prefab)
(struct video (attributes src) #:prefab)
(struct link (attributes href content) #:prefab)
(struct separator () #:prefab)
(struct line-break () #:prefab)

(struct id (value) #:prefab)

(define (extract-content doc url)
  (element-content (find-article-root doc) url))

(define p-worth (make-parameter 10))
(define lista-worth (make-parameter 4))
(define hs-worth (make-parameter 3))
(define article-worth (make-parameter 11))
(define main-worth (make-parameter 2))
(define worths `((,p-worth (p))
                 (,lista-worth (ul ol))
                 (,hs-worth (h1 h2 h3 h4 h5 h6))
                 (,main-worth (main))
                 (,article-worth (article))))

(struct scored-element (tag children score percentage ref)
  #:transparent
  #:mutable)

(define (find-article-root doc)
  (find-highest-score/list
   (filter identity
           (list (find* doc #:tag 'body)
                 (find* doc #:tag 'main)
                 (find* doc #:tag 'article)))))

(define (find-highest-score elem)
  (let* ([root
          (if (zero? (scored-element-percentage elem))
              (argmax scored-element-score (scored-element-children elem))
              elem)]
         [next
          (and root
               (findf (lambda (elem)
                        (> (scored-element-percentage elem) 80))
                      (scored-element-children root)))])
    (or (and next (find-highest-score next))
        (or root elem))))

(define (find-highest-score/list lst)
  (let* ([scored (map score-element lst)]
         [highs (map find-highest-score scored)])
    (argmax scored-element-score highs)))

(define (element-content elem base-url)
  (if (ignorable-element? elem)
      #f
      (match elem
        [(scored-element 'img _ _ _ el)
         (let* ([attributes (html-element-attributes el)]
                [data (read-attribute attributes 'data-src)]
                [src (read-attribute attributes 'src)]
                [alt (read-attribute attributes 'alt)])
           (image (extract-attributes el)
                  (or (and src (absolute-url base-url src)) data)
                  alt))]
        [(scored-element 'video _ _ _ el)
         (let* ([attributes (html-element-attributes el)]
                [src (read-attribute attributes 'src)])
           (video (extract-attributes el)
                  (and src (absolute-url base-url src))))]
        [(scored-element 'text _ _ _ el)
         (let ([str (html-text-text el)])
           (and str (text str)))]
        [(scored-element 'entity _ _ _ el)
         (let ([id (html-entity-id el)])
           (entity id))]
        [(scored-element 'a children _ _ el)
         (let* ([attributes (html-element-attributes el)]
                [href (read-attribute attributes 'href)]
                [content (element-content/list children base-url)])
           (link (extract-attributes el)
                 (and href (absolute-url base-url href))
                 content))]
        [(scored-element 'hr _ _ _ _)
         (separator)]
        [(scored-element 'br _ _ _ _)
         (line-break)]
        [(scored-element 'ol children _ _ el)
         (ordered-list (extract-attributes el)
                       (element-content/list children base-url))]
        [(scored-element 'ul children _ _ el)
         (unordered-list (extract-attributes el)
                         (element-content/list children base-url))]
        [(scored-element 'p children _ _ el)
         (paragraph (extract-attributes el)
                    (element-content/list children base-url))]
        [(scored-element 'pre children _ _ el)
         (pre (extract-attributes el)
              (element-content/list children base-url))]
        [(scored-element 'code children _ _ el)
         (code (extract-attributes el)
               (element-content/list children base-url))]
        [(scored-element (? (lambda~> (member '(b strong)))) children _ _ el)
         (bold (extract-attributes el)
               (element-content/list children base-url))]
        [(scored-element 'i children _ _ el)
         (italic (extract-attributes el)
                 (element-content/list children base-url))]
        [(scored-element 'blockquote children _ _ el)
         (blockquote (extract-attributes el)
                     (element-content/list children base-url))]
        [(scored-element 'sup children _ _ el)
         (superscript (extract-attributes el)
                      (element-content/list children base-url))]
        [(scored-element 'li children _ _ el)
         (list-item (extract-attributes el)
                    (element-content/list children base-url))]
        [(scored-element 'h1 children _ _ el)
         (heading (extract-attributes el)
                  1 (element-content/list children base-url))]
        [(scored-element 'h2 children _ _ el)
         (heading (extract-attributes el)
                  2 (element-content/list children base-url))]
        [(scored-element 'h3 children _ _ el)
         (heading (extract-attributes el)
                  3 (element-content/list children base-url))]
        [(scored-element 'h4 children _ _ el)
         (heading (extract-attributes el)
                  4 (element-content/list children base-url))]
        [(scored-element 'h5 children _ _ el)
         (heading (extract-attributes el)
                  5 (element-content/list children base-url))]
        [(scored-element 'h6 children _ _ el)
         (heading (extract-attributes el)
                  6 (element-content/list children base-url))]
        [(scored-element tag children _ _ (? html-element?))
         (and (not (member tag ignorable-tags))
              (element-content/list children base-url))]
        [else #f])))

(define (element-content/list lst base-url)
  (flatten
   (filter identity
           (map (lambda~>
                 (element-content base-url)) lst))))

(define (extract-attributes el)
  (let* ([attributes (html-element-attributes el)]
         [id-value (read-attribute attributes 'id)])
    (filter identity
            (list (and id-value (id id-value))))))

(define (score-element el)
  (cond
    [(html-element? el)
     (match-define (cons children-score-total children)
       (foldl (lambda (el acc)
                (let* ([scored (score-element el)]
                       [score (scored-element-score scored)])
                  (cons (+ score (car acc))
                        (append (cdr acc) (list scored)))))
              (cons 0 null)
              (html-element-children el)))
     (define parent-score
       (+ children-score-total (calculate-element-score el)))
     (unless (zero? parent-score)
       (for ([el children])
         (let ([percentage
                (* (/ (scored-element-score el) parent-score) 100.0)])
           (set-scored-element-percentage! el percentage))))
     (scored-element (html-element-tag el)
                     children
                     parent-score
                     0
                     el)]
    [else
     (scored-element (object-name el) null 0 0 el)]))

(define (calculate-element-score el)
  (let/cc return
    (unless (html-element? el)
      (return 0))
    (let ([el-tag (html-element-tag el)])
      (for ([item worths])
        (let ([worth (car item)]
              [tags (cadr item)])
          (for ([tag tags])
            (when (equal? tag el-tag)
              (return (worth))))))
      0)))

(define ignorable-tags
  '(aside header form footer nav script style))
(define (ignorable-element? elem)
  (let* ([el (scored-element-ref elem)]
         [attributes (if (html-element? el) (html-element-attributes el) empty)]
         [id (read-attribute attributes 'id #:default "")]
         [class (read-attribute attributes 'class #:default "")])
    (or
     (string-contains? id "sidebar") ; Lambda the Ultimate
     (string-contains? id "footer") ; Lambda the Ultimate
     (string-contains? class "breadcrumb") ; Lambda the Ultimate
     (string-contains? class "mailing-list")
     (string-contains? class "nomobile")
     (string-contains? class "sidebar")
     (string-contains? class "noprint")
     (string-contains? class "navbar")
     (string-contains? class "dpsp-networks-btns-share") ; WP plugin
     (string-contains? class "owl-carousel") ; WP plugin
     (string-contains? class "mw-editsection") ; Wikimedia edit links
     (string-contains? class "mw-indicators") ; Wikimedia
     (string-contains? class "navigation-not-searchable") ; Wikimedia
     (equal? "navigation" (read-attribute attributes 'role #:default "")))))
