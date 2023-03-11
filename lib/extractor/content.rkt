#lang racket/base

(require racket/function
         racket/match
         racket/list
         racket/string

         threading
         (prefix-in x: xml)

         reader/lib/extractor/attribute
         reader/lib/extractor/url
         reader/lib/extractor/query)

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

(struct element (tag children score percentage ref)
  #:transparent
  #:mutable)

;; Due to an issue where the HTML parser is not properly handling nested
;; elements (sometimes a node's children are not included as its content but as
;; it siblings instead), we have to aggressively check a few places when
;; looking for the root element. This is just a workaround, since this issue
;; could cause parts of the content to be split into separate sections in the
;; document and only one gets tagged as the root.
;;
;; TODO Fix issue where nested elements are not captured as children, but
;; captured as siblings instead.
(define (find-article-root doc)
  (find-highest-score/list
   (filter (lambda (elem)
             (and (x:element? elem)
                  (not (empty? (x:element-content elem)))))
           (append (list (find-element 'body doc)
                         (find-element 'main doc)
                         (find-element 'article doc))
                   (find-elements 'div doc)))))

(define (find-highest-score elem)
  (let* ([root
          (if (zero? (element-percentage elem))
              (argmax element-score (element-children elem))
              elem)]
         [next
          (and root
               (findf (lambda (elem)
                        (> (element-percentage elem) 80))
                      (element-children root)))])
    (or (and next (find-highest-score next))
        (or root elem))))

(define (find-highest-score/list lst)
  (let* ([scored (map score-element lst)]
         [highs (map find-highest-score scored)])
    (argmax element-score highs)))

(define (element-content elem base-url)
  (if (ignorable-element? elem)
      #f
      (match elem
        [(element 'img _ _ _ el)
         (let* ([attributes (x:element-attributes el)]
                [data (attr 'data-src attributes)]
                [src (attr 'src attributes)]
                [alt (attr 'alt attributes)])
           (image (extract-attributes el)
                  (or (and src (absolute-url base-url src)) data)
                  alt))]
        [(element 'video _ _ _ el)
         (let* ([attributes (x:element-attributes el)]
                [src (attr 'src attributes)])
           (video (extract-attributes el)
                  (and src (absolute-url base-url src))))]
        [(element 'pcdata _ _ _ el)
         (let ([str (pcdata-string el)])
           (and str (text str)))]
        [(element 'entity _ _ _ el)
         (let ([id (x:entity-text el)])
           (entity id))]
        [(element 'a children _ _ el)
         (let* ([attributes (x:element-attributes el)]
                [href (read-attr (find-attr 'href attributes))]
                [content (element-content/list children base-url)])
           (link (extract-attributes el)
                 (and href (absolute-url base-url href))
                 content))]
        [(element 'hr _ _ _ _)
         (separator)]
        [(element 'br _ _ _ _)
         (line-break)]
        [(element 'ol children _ _ el)
         (ordered-list (extract-attributes el)
                       (element-content/list children base-url))]
        [(element 'ul children _ _ el)
         (unordered-list (extract-attributes el)
                         (element-content/list children base-url))]
        [(element 'p children _ _ el)
         (paragraph (extract-attributes el)
                    (element-content/list children base-url))]
        [(element 'pre children _ _ el)
         (pre (extract-attributes el)
              (element-content/list children base-url))]
        [(element 'code children _ _ el)
         (code (extract-attributes el)
               (element-content/list children base-url))]
        [(element (? (lambda~> (member '(b strong)))) children _ _ el)
         (bold (extract-attributes el)
               (element-content/list children base-url))]
        [(element 'i children _ _ el)
         (italic (extract-attributes el)
                 (element-content/list children base-url))]
        [(element 'blockquote children _ _ el)
         (blockquote (extract-attributes el)
                     (element-content/list children base-url))]
        [(element 'sup children _ _ el)
         (superscript (extract-attributes el)
                      (element-content/list children base-url))]
        [(element 'li children _ _ el)
         (list-item (extract-attributes el)
                    (element-content/list children base-url))]
        [(element 'h1 children _ _ el)
         (heading (extract-attributes el)
                  1 (element-content/list children base-url))]
        [(element 'h2 children _ _ el)
         (heading (extract-attributes el)
                  2 (element-content/list children base-url))]
        [(element 'h3 children _ _ el)
         (heading (extract-attributes el)
                  3 (element-content/list children base-url))]
        [(element 'h4 children _ _ el)
         (heading (extract-attributes el)
                  4 (element-content/list children base-url))]
        [(element 'h5 children _ _ el)
         (heading (extract-attributes el)
                  5 (element-content/list children base-url))]
        [(element 'h6 children _ _ el)
         (heading (extract-attributes el)
                  6 (element-content/list children base-url))]
        [(element tag children _ _ (x:element _ _ _ _ _))
         (and (not (member tag ignorable-tags))
              (element-content/list children base-url))]
        [else #f])))

(define (element-content/list lst base-url)
  (flatten
   (filter identity
           (map (lambda~>
                 (element-content base-url)) lst))))

(define (extract-attributes el)
  (let* ([attributes (x:element-attributes el)]
         [id-value (attr 'id attributes)])
    (filter identity
            (list (and id-value (id id-value))))))

(define (score-element el)
  (cond
    [(x:element? el)
     (match-define (cons children-score-total children)
       (foldl (lambda (el acc)
                (let* ([scored (score-element el)]
                       [score (element-score scored)])
                  (cons (+ score (car acc))
                        (append (cdr acc) (list scored)))))
              (cons 0 null)
              (x:element-content el)))
     (define parent-score
       (+ children-score-total (calculate-element-score el)))
     (unless (zero? parent-score)
       (for ([el children])
         (let ([percentage
                (* (/ (element-score el) parent-score) 100.0)])
           (set-element-percentage! el percentage))))
     (element (x:element-name el)
              children
              parent-score
              0
              el)]
    [else
     (element (object-name el) null 0 0 el)]))

(define (calculate-element-score el)
  (let/cc return
    (unless (x:element? el)
      (return 0))
    (let ([el-tag (x:element-name el)])
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
  (let* ([el (element-ref elem)]
         [attributes (if (x:element? el) (x:element-attributes el) empty)]
         [id (attr 'id attributes #:default "")]
         [class (attr 'class attributes #:default "")])
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
     (equal? "navigation" (attr 'role attributes #:default "")))))

(define (pcdata-string el)
  (let ([str (x:pcdata-string el)])
    (if (equal? str "")
        #f
        str)))

(define (show elem [level 0])
  (let ([el (element-ref elem)]
        [padding (string-join (make-list level " "))])
    (cond
      [(x:element? el)
       (printf "~a~a (~a ~a%) {\n" padding
               (element-tag elem)
               (element-score elem)
               (element-percentage elem))
       (for ([ch (element-children elem)])
         (show ch (add1 level)))
       (printf "~a}\n" padding)]
      [(x:pcdata? el)
       (printf "~apcdata [~a]\n" padding (or (pcdata-string el) ""))]
      [else
       (printf "~a~a (0%)\n" padding (object-name el))])))
