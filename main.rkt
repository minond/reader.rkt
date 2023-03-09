#lang racket/base

(require reader/lib/logger
         reader/app/components/layout
         reader/app/servlet)

(parameterize ([current-logger application-logger])
  (start-servlet))
