#lang racket/base

(require reader/lib/logger
         reader/app/components
         reader/app/servlet)

(parameterize ([current-logger application-logger])
  (start-servlet))
