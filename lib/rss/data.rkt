#lang racket/base

(provide (struct-out feed)
         (struct-out article))

(struct feed (link title articles) #:transparent)
(struct article (link title date content) #:transparent)
