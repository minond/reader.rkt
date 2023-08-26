#lang racket/base

(require rackunit
         "deducer/kind.rkt")

(module+ test
  (require rackunit/text-ui)
  (run-tests tests))

(define checks
  (list (hash 'kind 'feed 'input "http://lambda-the-ultimate.org/rss.xml")
        (hash 'kind 'feed 'input "http://steve-yegge.blogspot.com/feeds/posts/default?alt=rss")
        (hash 'kind 'feed 'input "https://2ality.com/feeds/posts.atom")
        (hash 'kind 'feed 'input "https://bernsteinbear.com/feed.xml")
        (hash 'kind 'feed 'input "https://blog.regehr.org/feed")
        (hash 'kind 'feed 'input "https://defn.io/index.xml")
        (hash 'kind 'feed 'input "https://eli.thegreenplace.net/feeds/all.atom.xml")
        (hash 'kind 'feed 'input "https://esoteric.codes/rss")
        (hash 'kind 'feed 'input "https://feeds.feedburner.com/martinkl")
        (hash 'kind #f    'input "Bad")
        (hash 'kind 'feed 'input "https://lexi-lambda.github.io/feeds/all.rss.xml")
        (hash 'kind 'feed 'input "https://matt.might.net/articles/feed.rss")
        (hash 'kind 'feed 'input "https://matt.sh/.rss")
        (hash 'kind 'feed 'input "https://shopify.engineering/blog.atom")
        (hash 'kind 'feed 'input "https://stevelosh.com/rss.xml")
        (hash 'kind 'feed 'input "https://wingolog.org/feed/atom")
        (hash 'kind 'feed 'input "https://www.allthingsdistributed.com/atom.xml")
        (hash 'kind 'feed 'input "https://www.jntrnr.com/atom.xml")
        (hash 'kind 'feed 'input "http://100r.co/links/rss.xml")
        (hash 'kind 'feed 'input "https://wiki.xxiivv.com/links/rss.xml")
        (hash 'kind 'feed 'input "https://kokorobot.ca/links/rss.xml")
        (hash 'kind 'feed 'input "lexi-lambda.github.io/feeds/all.rss.xml")
        (hash 'kind 'html 'input "https://lexi-lambda.github.io")))

(define tests
  (test-suite
   "Kind deduction"

   (for ([check checks])
     (check-equal? (deduce-kind (hash-ref check 'input))
                   (hash-ref check 'kind)))))
