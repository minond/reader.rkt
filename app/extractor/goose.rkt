#lang racket/base

(require net/url-string
         reader/lib/html
         reader/ffi/python
         (only-in reader/extractor/text extract-text)
         (only-in reader/extractor/render render-html)
         (only-in reader/extractor/content normalize-content))

(import goose3)

;; The default document cleaner is replacing certain elements with `p` tags,
;; which we don't want to do. https://tinyurl.com/mcy9ftx6
(run* "goose3.cleaners.DocumentCleaner.div_to_para = lambda self, doc, div: doc")

(provide (struct-out article-info)
         extract)

(struct article-info (title description content-html content-text) #:transparent)

(define (extract url-or-string)
  (define config (goose3.Configuration))
  (config.__setattr__ "strict" #f)
  (define goose (goose3.Goose))
  (goose.__setattr__ "config" config)

  (with-handlers ([exn? (lambda (e)
                          (goose.close)
                          (log-info "unable to extract content for ~a" url-or-string)
                          (error "unable to extract content page:"
                                 url-or-string e))])
    (define url
      (if (url? url-or-string)
          url-or-string
          (string->url url-or-string)))
    (define url-string (url->string url))
    (define article (goose.extract #:url url-string))
    (goose.close)
    (define content (normalize-content article.top_node_raw_html url))
    (article-info article.title
                  (string-replace-html-entities article.meta_description)
                  (render-html content)
                  (extract-text content))))
