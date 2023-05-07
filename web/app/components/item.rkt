#lang racket/base

(require gregor
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra))

(provide :item/add)

(define (:item/add)
  (:div 'data-component: "add-item"
        (:script 'type: 'module 'src: "/public/add-item.js")))
