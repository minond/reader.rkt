#lang racket/base

(require css-expr

         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/lib/app/components/flash
         reader/lib/web/session)

(provide layout)

(define (layout content)
  (:xml->string
   (list (:doctype 'html)
         (:html
          (:head
           (:meta 'charset: "utf-8")
           (:meta 'name: "viewport"
                  'content: "width=device-width, initial-scale=1.0")
           (:title "Reader")
           (:style (:literal css))
           (:body
            (:header
             (:table
              (:tr
               (:td
                (:a 'class: "serif" 'href: "/" "Reader")
                (:flash))
               (:td 'class: "actions"
                    (if (authenticated?)
                        (list (:a 'href: "/feeds/new" "Add feed")
                              (:a 'href: "/feeds" "Manage feeds")
                              (:a 'href: "/sessions/destroy" "Sign out"))
                        null)))))
            (:div 'class: "separator")
            (:main content)
            #;(:script
               'type: "text/javascript"
               'src: "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-AMS-MML_HTMLorMML")
            #;(:script
               "MathJax.Hub.Config({
               TeX: { equationNumbers: { autoNumber: 'AMS' } },
               CommonHTML: { linebreaks: { automatic: true } },
               'HTML-CSS': { linebreaks: { automatic: true } },
               SVG: { linebreaks: { automatic: true } }
             });")
            ))))))

(define font-styles-url
  "https://fonts.googleapis.com/css2?family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&family=Nunito:wght@200;400;700&display=swap")

(define body-background-color (css-expr (apply rgba 250 247 239 0.1)))
(define border-color-lighter (css-expr (apply rgb 230 230 230)))
(define border-color-light (css-expr (apply rgb 187 187 187)))
(define border-color-normal (css-expr (apply rgb 138 138 138)))
(define failure-color-dark (css-expr (apply rgb 207 10 10)))
(define failure-color-light (css-expr (apply rgb 255 240 240)))
(define failure-color-normal (css-expr (apply rgb 233 170 170)))
(define link-color-normal (css-expr (apply rgb 28 28 255)))
(define separator-color-light (css-expr (apply rgb 235 235 235)))
(define separator-color-normal (css-expr (apply rgb 223 223 223)))
(define success-color-dark (css-expr (apply rgb 1 166 1)))
(define success-color-light (css-expr (apply rgb 245 255 245)))
(define success-color-normal (css-expr (apply rgb 163 223 163)))
(define text-color-light (css-expr (apply rgb 83 83 83)))
(define text-color-lighter (css-expr (apply rgb 136 136 136)))
(define highlight-color-light (css-expr (apply rgb 254 252 233)))

(define code-color-border (css-expr (apply rgb 215 215 215)))
(define code-color-background (css-expr (apply rgb 250 250 250)))

(define content-max-width (css-expr 100%))
(define article-max-width (css-expr 40em))
(define content-horizontal-padding (css-expr 2em))

(define css
  (css-expr->css
   (css-expr
    [@import ,font-styles-url]

    [body #:cursor default
          #:font-family (Nunito) (sans-serif)
          #:background-color ,@body-background-color
          #:margin 0
          #:line-height 1.6
          #:font-size 16px
          #:color |#444|
          #:padding 0]

    [.serif #:font-family (Libre Baskerville) (serif)]
    [.sans-serif #:font-family (Nunito) (sans-serif)]

    [header #:font-weight bold
            #:padding (.5em ,@content-horizontal-padding)
            [a #:color initial]
            [.actions #:text-align right
                      [a #:font-size 0.8em
                         #:margin-left 2em
                         #:color ,@text-color-light
                         #:font-weight bold]]]
    [header main
            #:margin (0 auto)
            #:max-width ,@content-max-width]

    [main #:padding ,@content-horizontal-padding]

    [table #:width 100%
           #:border-collapse collapse
           [td #:padding 0]
           [(> td p) #:margin-top 0]]

    [.table-content
     [td th
         #:padding 0.75em
         #:margin 0]
     [th #:text-align left
         #:font-weight 900]
     [td #:border-top (1px solid ,@border-color-light)]]

    [a #:color ,@link-color-normal
       #:text-decoration none]
    [a:hover #:text-decoration underline]
    [h1 h2 h3 h4 h5 h6
        #:line-height 1.2
        #:color initial
        [a #:color initial]]

    [form #:margin (3em auto)
          #:max-width 40em
          [(attribute input (= type "url"))
           (attribute input (= type "input"))
           (attribute input (= type "email"))
           (attribute input (= type "password"))
           #:border-width (1px 1px 1.5px 1px)
           #:border-style solid
           #:border-color (,@border-color-light
                           ,@border-color-light
                           ,@border-color-normal
                           ,@border-color-light)
           #:padding 0.5em
           #:width 100%
           #:font-size 1.1em
           #:margin (0.25em 0)]
          [(attribute input (= type "button"))
           (attribute input (= type "submit"))
           (attribute input (= type "cancel"))
           #:font-size 1.1em
           #:margin-top 0.5em
           #:margin-right 0.5em]
          [a #:font-size 0.8em]]

    [.reading #:max-width ,@article-max-width
              #:font-family (Libre Baskerville) (serif)
              #:margin (0 auto)
              #:overflow hidden
              [h1 h2 h3
                  #:margin (1em 0)]
              [h3 h4 h5 h6
                  #:margin (0.6em 0)]
              [blockquote #:font-style italic]
              [time .action
                    #:font-size 0.75em
                    #:color ,@text-color-light]
              [img iframe
                   #:max-width 100%
                   #:max-height 90vh
                   #:border none]
              [pre #:overflow scroll
                   #:border (1px solid ,@code-color-border)
                   #:padding (4px 12px)
                   #:background-color ,@code-color-background]
              [td #:max-width ,@article-max-width
                  #:vertical-align top
                  #:padding (10px 0)]
              [(: tr (apply not (: first-child)))
               [td #:border-top (1px solid ,@border-color-light)]]]
    [(> (.reading article) object)
     (> (.reading article) img)
     (> (.reading article) iframe)
     #:margin (0 auto)
     #:display block]
    [(> (.reading article) object)
     #:min-height 20px]

    [.system-error #:color ,@failure-color-dark
                   #:text-align center
                   #:font-size 1.25em
                   #:margin-top 2em]

    [@keyframes fadein
                [from #:opacity 0]
                [to #:opacity 1]]

    [@keyframes fadeout
                [from #:opacity 1
                      #:left 0]
                [to #:opacity 0
                    #:left 10px]]

    [.flash #:display inline-block
            #:animation (fadein .15s linear 0s) (fadeout .3s linear forwards 5s)
            #:font-size .9em
            #:font-weight 100
            #:position relative
            #:margin-left 1em
            #:text-transform lowercase]
    [.flash.alert #:color ,@success-color-dark]
    [.flash.notice #:color ,@failure-color-dark]

    [.separator #:border-bottom (1px solid ,@separator-color-normal)]
    [.spacer #:display inline-block]
    [.spacer.vertical.small #:height 1em]
    [.spacer.vertical.medium #:height 2em]
    [.spacer.vertical.large #:height 4em]
    [.spacer.horizontal.small #:width 1em]
    [.spacer.horizontal.medium #:width 2em]
    [.spacer.horizontal.large #:width 4em]
    [.tc #:text-align center]
    [.wsnw #:white-space nowrap]
    [.fwb #:font-weight bold]

    [.feed-subscription-toggle .article-archive-toggle
                               #:height .9em
                               #:width .9em
                               #:border-radius .9em
                               #:border (1px solid ,@border-color-normal)
                               #:margin (0 auto)
                               #:padding 0
                               #:display block
                               #:transition (background-color 100ms)]
    [.feed-subscription-toggle.subscribed .article-archive-toggle.unarchived
                                          #:background-color ,@success-color-normal]
    [.feed-subscription-toggle.unsubscribed .article-archive-toggle.archived
                                            #:background-color ,@failure-color-normal]
    [.feed-subscription-toggle.subscribed:hover .article-archive-toggle.unarchived:hover
                                                #:background-color ,@failure-color-normal]
    [.feed-subscription-toggle.unsubscribed:hover .article-archive-toggle.archived:hover
                                                  #:background-color ,@success-color-normal]

    [.feed-row.unsubscribed .article-row.archived
                            [* #:color ,@text-color-lighter]]

    [.article-preview #:border-bottom (1px solid ,@separator-color-light)
                      #:padding (2em 0)
                      [p #:font-size 0.9em
                         #:color ,@text-color-light]]
    [.show-on-hover-container
     [.show-on-hover #:opacity 0
                     #:transition (opacity .2s)]]
    [.show-on-hover-container:hover
     [.show-on-hover #:opacity 1]]

    [.reader-container #:column-gap 10px
                       #:display grid
                       #:grid-template-columns (22em auto)]

    [.reader-feed-item #:cursor pointer
                       #:column-gap 10px
                       #:display grid
                       #:grid-template-columns (auto 3em)]
    [.reader-feed-item:hover
     [.reader-feed-item-title #:font-weight bold]]
    [.reader-feed-item-title #:display inline-block
                             #:color black
                             #:white-space nowrap
                             #:text-overflow ellipsis
                             #:overflow hidden
                             #:font-size 0.9em]
    [.reader-feed-item-count #:display inline-block
                             #:white-space nowrap
                             #:text-overflow ellipsis
                             #:text-align right
                             #:overflow hidden
                             #:font-weight 200
                             #:font-size 0.8em]

    [.reader-articles
     #:overflow hidden
     #:text-overflow ellipsis]

    [.reader-article
     #:padding .5em
     #:display block
     #:font-size .95em
     #:white-space nowrap
     #:text-overflow ellipsis
     #:overflow hidden
     [.reader-article-title
      #:color ,@text-color-light
      #:font-weight bold]
     [.reader-article-description
      #:font-weight 200
      #:color ,@text-color-light
      #:padding-left .5em]]
    [(: .reader-article (apply not (: first-child)))
     #:border-top (1px solid ,@border-color-lighter)]
    [.reader-article:hover
     .reader-article:focus
     #:background-color ,@highlight-color-light
     [.reader-article-title
      .reader-article-description
      #:color black]]

    [.page-links #:padding 1em
                 #:text-align center
                 #:overflow scroll]
    [.page-link #:margin (0 .75em)
                #:color ,@text-color-light
                #:display inline-block
                #:min-width 20px]
    [.page-link.current #:color black
                        #:font-weight bold]
    [.page-skip #:margin (0 .5em)
                #:display inline-block])))
