#lang racket/base

(require crypto
         crypto/libcrypto)

(provide hexsha1
         make-password
         check-password)

(crypto-factories libcrypto-factory)

(define (hexsha1 in)
  (if (bytes? in)
      (bytes->hex-string (digest 'sha1 in))
      (hexsha1 (string->bytes/utf-8 in))))

(define (make-password password #:salt [salt (crypto-random-bytes 128)])
  (let* ([bytes (string->bytes/utf-8 password)]
         [enc (scrypt bytes salt #:N (expt 2 14))])
    (values enc salt)))

(define (check-password #:unencrypted unencrypted
                        #:encrypted encrypted
                        #:salt salt)
  (let*-values ([(enc _) (make-password unencrypted #:salt salt)])
    (equal? enc encrypted)))
