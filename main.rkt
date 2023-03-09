#lang racket/base

(require reader/app/components/layout
         reader/app/dispatch
         reader/lib/parameters
         reader/lib/logger
         reader/lib/servlet)

(servlet-app-dispatch app-dispatch)
(default-layout layout)

(parameterize ([current-logger application-logger])
  (start-servlet))
