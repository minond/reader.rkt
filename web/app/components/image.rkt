#lang racket/base

(require (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra))

(provide :image/archive)

(define (:image/archive [size "15px"])
  (:svg 'class: "image image-archive"
        'width: size
        'height: size
        'viewBox: "0 0 16 16"
        'xmlns: "http://www.w3.org/2000/svg"
        (:element 'path
                  'd: "M3 6v8h10V6H3zM1 6H0V0h16v6h-1v10H1V6zm4 2h6v2H5V8zM2 2v2h12V2H2z"
                  'fill-rule: "evenodd")))
