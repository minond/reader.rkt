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
         (struct-out childless-element)
         (struct-out container-element)
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
         (struct-out table)
         (struct-out table-row)
         (struct-out table-cell)
         (struct-out text)
         (struct-out entity)
         (struct-out image)
         (struct-out video)
         (struct-out iframe)
         (struct-out object)
         (struct-out link)
         (struct-out separator)
         (struct-out line-break)
         (struct-out element-attribute)
         (struct-out id)
         (struct-out height)
         (struct-out width)
         (struct-out name))

(struct childless-element (attributes) #:prefab)
(struct container-element (attributes content) #:prefab)

(struct heading container-element (level) #:prefab)
(struct paragraph container-element () #:prefab)
(struct pre container-element () #:prefab)
(struct code container-element () #:prefab)
(struct bold container-element () #:prefab)
(struct italic container-element () #:prefab)
(struct blockquote container-element () #:prefab)
(struct superscript container-element () #:prefab)
(struct ordered-list container-element () #:prefab)
(struct unordered-list container-element () #:prefab)
(struct list-item container-element () #:prefab)
(struct table container-element () #:prefab)
(struct table-row container-element () #:prefab)
(struct table-cell container-element () #:prefab)
(struct link container-element (href) #:prefab)
(struct object container-element (type data) #:prefab)

(struct image childless-element (src alt) #:prefab)
(struct video childless-element (src) #:prefab)
(struct iframe childless-element (src) #:prefab)

(struct separator () #:prefab)
(struct line-break () #:prefab)

(struct text (text) #:prefab)
(struct entity (id) #:prefab)


(struct element-attribute (value) #:prefab)

(struct id element-attribute () #:prefab)
(struct height element-attribute () #:prefab)
(struct width element-attribute () #:prefab)
(struct name element-attribute () #:prefab)

(define (extract-content doc url)
  (element-content (find-article-root doc) url))

(define text-worth (make-parameter 0.1))
(define p-worth (make-parameter 10))
(define hs-worth (make-parameter 3))
(define article-worth (make-parameter 11))
(define main-worth (make-parameter 2))
(define dldddt-worth (make-parameter -5))
(define a-worth (make-parameter -2))
(define list-item-worth (make-parameter -0.2))
(define worths `((,p-worth (p))
                 (,hs-worth (h1 h2 h3 h4 h5 h6))
                 (,main-worth (main))
                 (,dldddt-worth (dl dd dt))
                 (,list-item-worth (li))
                 (,a-worth (a))
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
        [(scored-element 'img _ _ _ (html-element _ attributes _))
         (let ([data (read-attribute attributes 'data-src)]
               [src (read-attribute attributes 'src)]
               [alt (read-attribute attributes 'alt)])
           (image (extract-attributes attributes)
                  (or (and src (absolute-url base-url src)) data)
                  alt))]
        [(scored-element 'video _ _ _ (html-element _ attributes _))
         (let ([src (read-attribute attributes 'src)])
           (video (extract-attributes attributes)
                  (and src (absolute-url base-url src))))]
        [(scored-element 'iframe _ _ _ (html-element _ attributes _))
         (let ([src (read-attribute attributes 'src)])
           (iframe (extract-attributes attributes)
                   (and src (absolute-url base-url src))))]
        [(scored-element 'object children _ _ (html-element _ attributes _))
         (let ([type (read-attribute attributes 'type)]
               [data (read-attribute attributes 'data)])
           (object (extract-attributes attributes)
                   (element-content/list children base-url)
                   type
                   (and data (absolute-url base-url data))))]
        [(scored-element 'text _ _ _ (html-text value))
         (and value (text value))]
        [(scored-element 'entity _ _ _ (html-entity id))
         (entity id)]
        [(scored-element 'a children _ _ (html-element _ attributes _))
         (let ([href (read-attribute attributes 'href)])
           (link (extract-attributes attributes)
                 (element-content/list children base-url)
                 (and href (absolute-url base-url href))))]
        [(scored-element 'hr _ _ _ _)
         (separator)]
        [(scored-element 'br _ _ _ _)
         (line-break)]
        [(scored-element 'ol children _ _ el)
         (ordered-list (extract-attributes el)
                       (element-content/list children base-url))]
        [(scored-element 'table children _ _ el)
         (table (extract-attributes el)
                (element-content/list children base-url))]
        [(scored-element 'tr children _ _ el)
         (table-row (extract-attributes el)
                    (element-content/list children base-url))]
        [(scored-element (? (lambda~> (member '(td th)))) children _ _ el)
         (table-cell (extract-attributes el)
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
        [(scored-element (? (lambda~> (member '(i em)))) children _ _ el)
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
                  (element-content/list children base-url) 1)]
        [(scored-element 'h2 children _ _ el)
         (heading (extract-attributes el)
                  (element-content/list children base-url) 2)]
        [(scored-element 'h3 children _ _ el)
         (heading (extract-attributes el)
                  (element-content/list children base-url) 3)]
        [(scored-element 'h4 children _ _ el)
         (heading (extract-attributes el)
                  (element-content/list children base-url) 4)]
        [(scored-element 'h5 children _ _ el)
         (heading (extract-attributes el)
                  (element-content/list children base-url) 5)]
        [(scored-element 'h6 children _ _ el)
         (heading (extract-attributes el)
                  (element-content/list children base-url) 6)]
        [(scored-element tag children _ _ (? html-element?))
         (and (not (member tag ignorable-tags))
              (element-content/list children base-url))]
        [else #f])))

(define (element-content/list lst base-url)
  (flatten
   (filter identity
           (map (lambda~>
                 (element-content base-url)) lst))))

(define (extract-attributes el-or-attributes)
  (let* ([attributes (if (html-element? el-or-attributes)
                         (html-element-attributes el-or-attributes)
                         el-or-attributes)]
         [id-value (read-attribute attributes 'id)]
         [height-value (read-attribute attributes 'height)]
         [width-value (read-attribute attributes 'width)]
         [name-value (read-attribute attributes 'name)])
    (filter identity
            (list (and id-value (id id-value))
                  (and height-value (height height-value))
                  (and width-value (width width-value))
                  (and name-value (name name-value))))))

(define (score-element el)
  (cond
    [(and (html-element? el) (ignorable-element? el))
     (scored-element (html-element-tag el) null 0 0 el)]
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
    [(html-text? el)
     (scored-element (object-name el) null (text-worth) 0 el)]
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
  (let* ([el (if (scored-element? elem) (scored-element-ref elem) elem)]
         [tag (if (html-element? el) (html-element-tag el) #f)]
         [attributes (if (html-element? el) (html-element-attributes el) empty)]
         [id (or (read-attribute attributes 'id #:default "") "")]
         [class (or (read-attribute attributes 'class #:default "") "")])
    (or
     (equal? tag 'script)
     (string-contains? id "comments") ; steve-yegge.blogspot.com
     (string-contains? id "sidebar") ; Lambda the Ultimate
     (string-contains? id "footer") ; Lambda the Ultimate
     (string-contains? id "header") ; steve-yegge.blogspot.com
     (string-contains? class "breadcrumb") ; Lambda the Ultimate
     (string-contains? class "mailing-list")
     (string-contains? class "nomobile")
     (string-contains? class "sidebar")
     (string-contains? class "noprint")
     (string-contains? class "navbar")
     (string-contains? class "footer") ; steve-yegge.blogspot.com
     (string-contains? class "dpsp-networks-btns-share") ; WP plugin
     (string-contains? class "owl-carousel") ; WP plugin
     (string-contains? class "wp-block-post-date") ; WP
     (string-contains? class "wp-block-post-author") ; WP
     (string-contains? class "wp-block-post-terms") ; WP
     (string-contains? class "mw-editsection") ; Wikimedia edit links
     (string-contains? class "mw-indicators") ; Wikimedia
     (string-contains? class "navigation-not-searchable") ; Wikimedia
     (equal? "navigation" (read-attribute attributes 'role #:default "")))))

(define (show elem [level 0])
  (define padding (string-append* (make-list level " ")))
  (match elem
    [(scored-element tag children score percentage
                     (html-element _ attributes _))
     (printf "~a~a (~a = ~a%) ~a {\n"
             padding tag score percentage
             (map (lambda (attr)
                    (format "~a=\"~a\""
                            (html-attribute-name attr)
                            (html-attribute-value attr))) attributes))
     (map (lambda~> (show (add1 level))) children)
     (printf "~a}\n" padding)]
    [(scored-element 'text _ _ _ _)
     (printf "~a[text]\n" padding)]
    [(scored-element tag children score percentage _)
     (printf "~a~a (~a = ~a%) {\n"
             padding tag score percentage)
     (map (lambda~> (show (add1 level))) children)
     (printf "~a}\n" padding)]))
