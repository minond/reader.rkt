#lang racket/base

(provide (struct-out feed)
         (struct-out article))

(struct feed (link title articles))
(struct article (link title date content))
