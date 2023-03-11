#lang racket/base

(require racket/match
         racket/list

         threading
         net/url-string
         (prefix-in x: xml)

         reader/lib/extractor/attribute
         reader/lib/extractor/url
         reader/lib/extractor/query)

(provide extract-media
         (struct-out media)
         (struct-out media:image)
         (struct-out media:video))

(struct media (images videos)
  #:constructor-name make-media
  #:mutable
  #:prefab)

(struct media:image (url type width height)
  #:mutable
  #:prefab)

(struct media:video (url type width height)
  #:mutable
  #:prefab)

(define metadata-icon-rels
  '("icon" "shortcut icon" "apple-touch-icon" "apple-touch-icon-precomposed" "mask-icon"))

(define (extract-media doc base-url)
  (let* ([metatags (find-elements 'meta doc)]
         [linktags (find-elements 'link doc)]
         [titletag (find-element 'title doc)]
         [attrgroups (map x:element-attributes (append metatags linktags))]
         [media (make-media empty empty)])
    (for* ([attributes attrgroups])
      (match (list (or (attr 'name attributes) (attr 'property attributes))
                   (attr 'content attributes)
                   (attr 'rel attributes)
                   (attr 'href attributes)
                   (attr 'charset attributes))
        [(list _ _ (? (lambda~> (member metadata-icon-rels)) type) url _)
         (set-media-images!
          media
          (append (media-images media)
                  (list (media:image (absolute-url base-url url) type #f #f))))]
        [(list "og:image" url _ _ _)
         (set-media-images!
          media
          (append (media-images media)
                  (list (media:image (absolute-url base-url url) "image" #f #f))))]
        [(list "og:image:width" content _ _ _)
         (let ([image (last (media-images media))])
           (when image
             (set-media:image-width! image content)))]
        [(list "og:image:height" content _ _ _)
         (let ([image (last (media-images media))])
           (when image
             (set-media:image-height! image content)))]
        [(list "og:video:url" url _ _ _)
         (set-media-videos!
          media
          (append (media-videos media)
                  (list (media:video (absolute-url base-url url) #f #f #f))))]
        [(list "og:video:width" content _ _ _)
         (let ([video (last (media-videos media))])
           (when video
             (set-media:video-width! video content)))]
        [(list "og:video:height" content _ _ _)
         (let ([video (last (media-videos media))])
           (when video
             (set-media:video-height! video content)))]
        [(list "og:video:type" content _ _ _)
         (let ([video (last (media-videos media))])
           (when video
             (set-media:video-type! video content)))]
        [_
         (void)]))
    media))
