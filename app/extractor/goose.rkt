#lang racket/base

(require net/url-string
         "../lib/html.rkt"
         "../ffi/python.rkt"
         (only-in "../extractor/text.rkt" extract-text)
         (only-in "../extractor/render.rkt" render-html)
         (only-in "../extractor/content.rkt" normalize-content))

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
