#lang racket/base

(require css-expr

         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/lib/app/components/script
         reader/lib/app/components/flash
         reader/lib/parameters
         reader/lib/web/session)

(provide layout)

(define (layout content #:body-class [body-class ""])
  (:xml->string
   (list (:doctype 'html)
         (:html
          (:head
           (:meta 'charset: "utf-8")
           (:meta 'name: "viewport"
                  'content: "width=device-width, initial-scale=1.0")
           (:title "Reader")
           (:style (:literal css)))
          (:body 'data-user-id: (current-user-id)
                 'class: body-class
                 (:header
                  (:table
                   (:tr
                    (:td
                     (:a 'class: "serif" 'href: "/" "Reader")
                     (:flash))
                    (:td 'class: "actions"
                         (if (authenticated?)
                             (list (:script/component 'AddItem)
                                   (:a 'href: "/feeds" "Manage feeds")
                                   (:a 'href: "/sessions/destroy" "Sign out"))
                             null))))
                  (:div 'class: "separator"))
                 (:main content))))))

(define font-styles-url
  "https://fonts.googleapis.com/css2?family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&family=Nunito:wght@200;400;700&display=swap")

(define body-background-color (css-expr (apply rgb 252 252 252)))
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
(define image-color-idle (css-expr (apply rgb 158 158 158)))
(define image-color-active (css-expr (apply rgb 53 50 252)))
(define loading-placeholder-color (css-expr (apply rgb 226 232 240)))

(define selection-hover-color(css-expr (apply rgb 244 247 255)))
(define code-color-border (css-expr (apply rgb 215 215 215)))
(define code-color-background (css-expr (apply rgb 250 250 250)))

(define content-max-width (css-expr 100%))
(define article-max-width (css-expr 40em))
(define article-column-gap (css-expr 5em))
(define content-horizontal-padding (css-expr 2em))

(define spinning-ring-color (css-expr (apply rgb 61 77 255)))

(define css
  (css-expr->css
   (css-expr
    [@import ,font-styles-url]

    [body #:cursor default
          #:font-family (Nunito) (sans-serif)
          #:background-color ,@body-background-color
          #:margin 0
          #:line-height 1.6
          #:font-size 14px
          #:color |#444|
          #:padding 0]

    [.serif #:font-family (Libre Baskerville) (serif)]
    [.sans-serif #:font-family (Nunito) (sans-serif)]

    [header #:font-weight bold
            #:position fixed
            #:transition (background-color .2s)
            #:display block
            #:background-color ,@body-background-color
            #:width 100%
            #:top 0
            #:left 0
            #:z-index 1

            [(: td (apply nth-child 1)) #:padding (.5em 0em .5em ,content-horizontal-padding)]
            [(: td (apply nth-child 2)) #:padding (.5em ,content-horizontal-padding .5em 0em)]
            [a #:color initial]
            [.actions #:text-align right
                      [a #:font-size 0.9em
                         #:margin-left 2em
                         #:white-space nowrap
                         #:color ,@text-color-light
                         #:font-weight bold]]]
    [@media (and screen (#:max-width 320px))
            [header
             [.actions [a #:margin-left 10px]]]]
    [header main
            #:margin (0 auto)
            #:max-width ,@content-max-width]

    [body.hidden-header
     [header
      #:background-color transparent
      [.separator
       .actions
       #:transition (opacity .2s)
       #:opacity 0]]
     [header:hover
      #:background-color ,@body-background-color
      [.separator
       .actions
       #:opacity 1]]]
    [@media (and screen (#:max-width (apply calc (,@article-max-width * 2 + ,article-column-gap * 4))))
            [body.hidden-header
             [header
              #:background-color ,@body-background-color
              [.actions
               .separator
               #:opacity 1]]]]

    [main #:padding ,@content-horizontal-padding]

    [table #:width 100%
           #:border-collapse collapse]
    [td #:padding 0]
    [(> td p) #:margin-top 0]

    [.table-content
     #:font-size 1.1em
     #:max-width (apply calc (,article-max-width * 2))
     #:margin (0 auto)
     [td th
         #:padding (0.75em 0 0.75em 0.75em)
         #:margin 0]
     [th #:text-align left
         #:font-weight 900]
     [td #:border-top (1px solid ,@border-color-light)]]

    [.table-content.with-indicator
     [(: td first-child) #:width 20px]]

    [a .link
       #:color ,@link-color-normal
       #:text-decoration none]
    [a:hover .link:hover
             #:cursor pointer
             #:text-decoration underline]
    [h1 h2 h3 h4 h5 h6
        #:line-height 1.2
        #:color initial
        [a #:color initial]]

    [.session-create-form
     .user-registration-form
     .add-feed-form
     #:margin (3em auto)
     #:max-width ,@article-max-width
     [(attribute input (= type "url"))
      (attribute input (= type "text"))
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
      #:box-sizing border-box
      #:margin (0.25em 0)]
     [(attribute input (= type "button"))
      (attribute input (= type "submit"))
      (attribute input (= type "cancel"))
      #:font-size 1.1em
      #:margin-top 0.5em
      #:margin-right 0.25em]]

    ; Taken from https://loading.io/css/
    [.spinning-ring #:display block
                    #:margin (0 auto)
                    [div #:box-sizing border-box
                         #:display block
                         #:position absolute
                         #:margin 8px
                         #:border-width 2px
                         #:border-style solid
                         #:border-radius 50%
                         #:animation (spinning-ring 1.2s (apply cubic-bezier 0.5 0 0.5 1) infinite)
                         #:border-color (,@spinning-ring-color transparent transparent transparent)]
                    [(: div (apply nth-child 1)) #:animation-delay -0.45s]
                    [(: div (apply nth-child 2)) #:animation-delay -0.3s]
                    [(: div (apply nth-child 3)) #:animation-delay -0.15s]]
    [@keyframes spinning-ring
                [0% #:transform (apply rotate 0deg)]
                [100% #:transform (apply rotate 360deg)]]

    [.pulse #:animation (pulse 2s (apply cubic-bezier .4 0 .6 1) infinite)]
    [@keyframes pulse
                [50% #:opacity .5]]

    [.reading #:max-width (apply calc (,article-max-width * 2 + ,article-column-gap))
              #:margin (2.5em auto 0 auto)
              #:font-family (Libre Baskerville) (serif)

              [.container #:display grid
                          #:max-width (apply calc (,article-max-width * 2))
                          #:grid-template-columns (60% 40%)]
              [@media (and screen (#:min-width (apply calc (,article-max-width * 2))))
                      [.container
                       [article #:padding-right 2.5em]
                       [aside #:padding-left 2.5em]]]
              [@media (and screen
                           (#:min-width (apply calc (,article-max-width)))
                           (#:max-width (apply calc (,article-max-width * 2))))
                      [.container
                       [article #:padding-right 1em]
                       [aside #:padding-left 1em]]]
              [@media (and screen (#:max-width ,article-max-width))
                      [.container
                       #:grid-template-columns (100% 0%)
                       [aside #:display none]]]

              [h1 h2 h3
                  #:margin (1em 0)]
              [h3 h4 h5 h6
                  #:margin (0.6em 0)]
              [figcaption #:text-align center;
                          #:font-size .9em;
                          #:color ,@text-color-light]
              [blockquote #:font-style italic]
              [time #:font-size 0.8em
                    #:color ,@text-color-light]
              [.action #:font-size 0.9em
                       #:margin-left 0.5em]
              [img iframe
                   #:max-width 100%
                   #:height auto
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

    [.input-container
     #:position relative
     #:border-width 1px
     #:border-style solid
     #:border-color ,border-color-lighter
     #:overflow hidden
     [input #:margin 0
            #:padding 0.75em
            #:width (apply calc (100% - 30px))
            #:font-size 1.1em
            #:box-sizing border-box
            #:outline none
            #:border none]
     [.spinning-ring #:display none
                     #:position absolute
                     #:top 5px
                     #:right 5px]]
    [.input-container.loading
     [.spinning-ring #:display block]]

    [.chat
     #:position relative
     [.input-wrapper #:margin-top 1em
                     #:position relative
                     #:box-shadow (0 2px 7px 1px (apply rgb 193 193 193))
                     #:border-radius 4px
                     #:overflow hidden
                     [textarea #:display block
                               #:width 100%
                               #:box-sizing border-box
                               #:resize none
                               #:font-size 1em
                               #:padding .5em
                               #:border none
                               #:outline none]
                     [.spinning-ring #:display none
                                     #:position absolute
                                     #:top 0
                                     #:right 5px]]
     [.disclaimer #:font-style italic
                  #:text-align center
                  #:font-size .75em
                  #:padding 0
                  #:margin (.75em 0)]]
    [.chat.sticky
     #:top 10px
     #:position -webkit-sticky
     #:position sticky]
    [.chat.loading
     [.spinning-ring #:display block]]

    [.summary #:padding (0 1em)]
    [.summary.loading
     [.line #:background-color ,loading-placeholder-color
            #:height .7em
            #:width 100%
            #:margin-bottom 1em]]
    [.shadow #:opacity 0
             #:transition opacity .25s
             #:height 6px
             #:width 100%
             #:background-color (apply rgba 128 128 128 0.09)
             #:position absolute
             #:top 0]
    [.messages #:overflow-y scroll]
    [.messages.animated #:transition max-height .2s]
    [.message #:padding 1em
              #:position relative
              [time #:opacity 0
                    #:transition (opacity .2s)
                    #:position absolute
                    #:bottom 0px
                    #:right 0px
                    #:background-color (apply rgb 240 240 240)
                    #:padding (2px 8px)]
              [p #:padding 0
                 #:margin 0]
              [(p + p) #:margin-top 14px]]
    [.message:hover
     [time #:opacity 1]]
    [.message.user
     (.message.user time)
     #:background-color ,body-background-color]
    [.message.assistant
     (.message.assistant time)
     #:background-color (apply rgb 240 240 240)]

    [.system-error #:color ,@failure-color-dark
                   #:text-align center
                   #:font-size 1.5em
                   #:margin-top 2em]

    [.fadein #:animation (fadein .25s linear 0s)]
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
            #:font-weight 400
            #:position relative
            #:margin-left 1em
            #:text-transform lowercase]
    [.flash.alert #:color ,@success-color-dark]
    [.flash.notice #:color ,@failure-color-dark]

    [.separator #:border-bottom (1px solid ,@separator-color-normal)]
    [.spacer #:display inline-block]
    [.spacer.vertical.tiny #:height .5em]
    [.spacer.vertical.smaller #:height .75em]
    [.spacer.vertical.small #:height 1em]
    [.spacer.vertical.medium #:height 2em]
    [.spacer.vertical.large #:height 4em]
    [.spacer.horizontal.tiny #:width .5em]
    [.spacer.horizontal.smaller #:width .75em]
    [.spacer.horizontal.small #:width 1em]
    [.spacer.horizontal.medium #:width 2em]
    [.spacer.horizontal.large #:width 4em]
    [.tc #:text-align center]
    [.wsnw #:white-space nowrap]
    [.fwb #:font-weight bold]
    [.dn #:display none]
    [.vc-container #:position relative]
    [.vc #:margin 0
         #:position absolute
         #:top 50%
         #:transform (apply translateY -50%)]
    [.w--4 #:width 4em]
    [.w--5 #:width 5em]
    [.w--6 #:width 6em]
    [.w--7 #:width 7em]
    [.w--8 #:width 8em]
    [.w--9 #:width 9em]
    [.w--10 #:width 10em]

    [.error-message
     #:color ,failure-color-dark]

    [.registration-form #:max-width ,article-max-width
                        #:margin (0 auto)
                        #:padding-top 2em
                        [p #:font-size 1.25em]
                        [form #:margin-top 0]]

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

    [.reader
     [.no-articles #:max-width ,article-max-width
                   #:margin (0 auto)
                   #:padding-top 2em
                   [p #:font-size 1.25em]
                   [form #:margin-top 0]]]

    [.reader-articles
     #:max-width 60em
     #:margin (3em auto 2em auto)
     #:overflow hidden
     #:text-overflow ellipsis]

    [.reader-article
     #:padding (1em 0)
     #:outline none
     #:display block
     [.reader-article-title
      .reader-article-description
      #:color black]
     [.reader-article-title
      #:font-size 1.25em
      #:font-weight bold]
     [.reader-article-description
      #:margin-bottom 0
      #:outline 0]
     [.reader-article-details
      .reader-article-actions
      #:margin-top 7px
      #:height 25px]
     [.reader-article-details
      #:color ,text-color-lighter]
     [.reader-article-actions
      #:display none]]
    [(: .reader-article (apply not (: first-child)))
     #:border-top (1px solid ,@border-color-lighter)]
    [.reader-article:hover
     .reader-article:focus
     [.reader-article-details #:display none]
     [.reader-article-actions #:display block]
     [a #:text-decoration none]]

    [.tags
     #:padding (0 1em)
     [.tag #:display inline-block
           #:font-size .85em
           #:padding (.1em .4em)
           #:border (1px solid ,border-color-lighter)
           #:margin (0 .5em .5em 0)]
     [.tag.loading #:background-color ,loading-placeholder-color]]

    [.add-item-form
     #:margin (22vh auto)
     #:max-width ,@article-max-width
     #:text-align left
     #:padding 1em
     [.add-item-form-content
      #:background-color white
      #:position relative
      #:box-shadow
      ((apply rgb 255 255 255) 0px 0px 0px 0px)
      ((apply rgba 24 24 27 0.075) 0px 0px 0px 1px)
      ((apply rgba 0 0 0 0.1) 0px 20px 25px -5px)
      ((apply rgba 0 0 0 0.1) 0px 8px 10px -6px)]
     [.suggestions
      #:transition (opacity .2s)
      #:opacity 1
      #:border (1px solid ,border-color-lighter)
      #:background-color white
      [.suggestion
       #:padding (.75em 1em)
       #:display grid
       #:grid-gap 0px
       #:transition (background-color .1s)
       #:grid-template-columns (90% 10%)]
      [(: .suggestion (apply not (: first-child)))
       #:border-top (1px solid ,separator-color-light)]
      [.suggestion:hover
       #:cursor pointer
       #:background-color ,selection-hover-color
       [.suggestion-title
        #:text-decoration underline]]
      [.suggestion-title
       #:grid-column 1
       #:font-weight bold]
      [.suggestion-url
       #:grid-column 1
       #:color ,text-color-light]
      [.suggestion-kind
       #:text-align right
       #:grid-column 2
       #:grid-row (1 / span 2)
       #:align-self center]
      [.suggestion-kind-container
       #:border (1px solid (apply rgb 245 223 70))
       #:display inline-block
       #:padding (1px 6px)
       #:margin 0
       #:font-size .8em
       #:background-color (apply rgba 255 249 208 1)
       #:font-weight bold
       #:text-transform lowercase]]]
    [.add-item-form.loading
     [.suggestions
      #:opacity .6]]

    [.backdrop
     #:animation (fadein .1s linear 0s)
     #:transition (opacity .15s)
     #:position fixed
     #:background-color (apply hsla 240 4.83% 65.33% 0.07)
     #:width 100%
     #:left 0
     #:top 0
     #:height 100%
     #:z-index 1
     #:-webkit-backdrop-filter (apply blur 4px)
     #:-webkit-font-smoothing antialiased]

    [.image
     #:transition (fill .2s)
     #:fill ,image-color-idle]
    [.image:hover
     #:fill ,image-color-active]

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