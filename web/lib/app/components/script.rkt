#lang racket/base

(require (prefix-in : scribble/html/html))

(provide :script/component)

(define template "
import { html, render } from '/public/preact.js';
import Component from '/public/components/~a.js';
const el = document.querySelector('[data-component=~a]');
if (el) {
  delete el.dataset.component;
  render(html`<${Component} ...${el.dataset} />`,
         el.parentNode,
         el);
} else {
  console.warn('unable to locate [data-component=~a]')
}")

(define (code name)
  (:script/inline 'type: 'module
                  (format template name name name)))

(define (:script/component name . data)
  (apply :span
         (append data
                 (list 'data-component: name
                       (code  name)))))
