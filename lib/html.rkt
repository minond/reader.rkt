#lang racket/base

(provide html-entity->string)

(define entity-names
  (hash "&amp;"           38            ; Ampersand
        "&lt;"            60            ; Less than
        "&gt;"            62            ; Greater than
        "&nbsp;"          160           ; Non-breaking space
        "&iexcl;"         161           ; Inverted exclamation mark
        "&cent;"          162           ; Cent
        "&pound;"         163           ; Pound
        "&curren;"        164           ; Currency
        "&yen;"           165           ; Yen
        "&brvbar;"        166           ; Broken vertical bar
        "&sect;"          167           ; Section
        "&uml;"           168           ; Spacing diaeresis
        "&copy;"          169           ; Copyright
        "&ordf;"          170           ; Feminine ordinal indicator
        "&laquo;"         171           ; Opening/Left angle quotation mark
        "&not;"           172           ; Negation
        "&shy;"           173           ; Soft hyphen
        "&reg;"           174           ; Registered trademark
        "&macr;"          175           ; Spacing macron
        "&deg;"           176           ; Degree
        "&plusmn;"        177           ; Plus or minus
        "&sup2;"          178           ; Superscript 2
        "&sup3;"          179           ; Superscript 3
        "&acute;"         180           ; Spacing acute
        "&micro;"         181           ; Micro
        "&para;"          182           ; Paragraph
        "&cedil;"         184           ; Spacing cedilla
        "&sup1;"          185           ; Superscript 1
        "&ordm;"          186           ; Masculine ordinal indicator
        "&raquo;"         187           ; Closing/Right angle quotation mark
        "&frac14;"        188           ; Fraction 1/4
        "&frac12;"        189           ; Fraction 1/2
        "&frac34;"        190           ; Fraction 3/4
        "&iquest;"        191           ; Inverted question mark
        "&times;"         215           ; Multiplication
        "&divide;"        247           ; Divide
        "&forall;"        8704          ; For all
        "&part;"          8706          ; Part
        "&exist;"         8707          ; Exist
        "&empty;"         8709          ; Empty
        "&nabla;"         8711          ; Nabla
        "&isin;"          8712          ; Is in
        "&notin;"         8713          ; Not in
        "&ni;"            8715          ; Ni
        "&prod;"          8719          ; Product
        "&sum;"           8721          ; Sum
        "&minus;"         8722          ; Minus
        "&lowast;"        8727          ; Asterisk (Lowast)
        "&radic;"         8730          ; Square root
        "&prop;"          8733          ; Proportional to
        "&infin;"         8734          ; Infinity
        "&ang;"           8736          ; Angle
        "&and;"           8743          ; And
        "&or;"            8744          ; Or
        "&cap;"           8745          ; Cap
        "&cup;"           8746          ; Cup
        "&int;"           8747          ; Integral
        "&there4;"        8756          ; Therefore
        "&sim;"           8764          ; Similar to
        "&cong;"          8773          ; Congurent to
        "&asymp;"         8776          ; Almost equal
        "&ne;"            8800          ; Not equal
        "&equiv;"         8801          ; Equivalent
        "&le;"            8804          ; Less or equal
        "&ge;"            8805          ; Greater or equal
        "&sub;"           8834          ; Subset of
        "&sup;"           8835          ; Superset of
        "&nsub;"          8836          ; Not subset of
        "&sube;"          8838          ; Subset or equal
        "&supe;"          8839          ; Superset or equal
        "&oplus;"         8853          ; Circled plus
        "&otimes;"        8855          ; Circled times
        "&perp;"          8869          ; Perpendicular
        "&sdot;"          8901          ; Dot operator
        "&Alpha;"         913           ; Alpha
        "&Beta;"          914           ; Beta
        "&Gamma;"         915           ; Gamma
        "&Delta;"         916           ; Delta
        "&Epsilon;"       917           ; Epsilon
        "&Zeta;"          918           ; Zeta
        "&Eta;"           919           ; Eta
        "&Theta;"         920           ; Theta
        "&Iota;"          921           ; Iota
        "&Kappa;"         922           ; Kappa
        "&Lambda;"        923           ; Lambda
        "&Mu;"            924           ; Mu
        "&Nu;"            925           ; Nu
        "&Xi;"            926           ; Xi
        "&Omicron;"       927           ; Omicron
        "&Pi;"            928           ; Pi
        "&Rho;"           929           ; Rho
        "&Sigma;"         931           ; Sigma
        "&Tau;"           932           ; Tau
        "&Upsilon;"       933           ; Upsilon
        "&Phi;"           934           ; Phi
        "&Chi;"           935           ; Chi
        "&Psi;"           936           ; Psi
        "&Omega;"         937           ; Omega
        "&alpha;"         945           ; alpha
        "&beta;"          946           ; beta
        "&gamma;"         947           ; gamma
        "&delta;"         948           ; delta
        "&epsilon;"       949           ; epsilon
        "&zeta;"          950           ; zeta
        "&eta;"           951           ; eta
        "&theta;"         952           ; theta
        "&iota;"          953           ; iota
        "&kappa;"         954           ; kappa
        "&lambda;"        955           ; lambda
        "&mu;"            956           ; mu
        "&nu;"            957           ; nu
        "&xi;"            958           ; xi
        "&omicron;"       959           ; omicron
        "&pi;"            960           ; pi
        "&rho;"           961           ; rho
        "&sigmaf;"        962           ; sigmaf
        "&sigma;"         963           ; sigma
        "&tau;"           964           ; tau
        "&upsilon;"       965           ; upsilon
        "&phi;"           966           ; phi
        "&chi;"           967           ; chi
        "&psi;"           968           ; psi
        "&omega;"         969           ; omega
        "&thetasym;"      977           ; Theta symbol
        "&upsih;"         978           ; Upsilon symbol
        "&piv;"           982           ; Pi symbol
        "&OElig;"         338           ; Uppercase ligature OE
        "&oelig;"         339           ; Lowercase ligature OE
        "&Scaron;"        352           ; Uppercase S with caron
        "&scaron;"        353           ; Lowercase S with caron
        "&Yuml;"          376           ; Capital Y with diaeres
        "&fnof;"          402           ; Lowercase with hook
        "&circ;"          710           ; Circumflex accent
        "&tilde;"         732           ; Tilde
        "&ensp;"          8194          ; En space
        "&emsp;"          8195          ; Em space
        "&thinsp;"        8201          ; Thin space
        "&zwnj;"          8204          ; Zero width non-joiner
        "&zwj;"           8205          ; Zero width joiner
        "&lrm;"           8206          ; Left-to-right mark
        "&rlm;"           8207          ; Right-to-left mark
        "&ndash;"         8211          ; En dash
        "&mdash;"         8212          ; Em dash
        "&lsquo;"         8216          ; Left single quotation mark
        "&rsquo;"         8217          ; Right single quotation mark
        "&sbquo;"         8218          ; Single low-9 quotation mark
        "&ldquo;"         8220          ; Left double quotation mark
        "&rdquo;"         8221          ; Right double quotation mark
        "&bdquo;"         8222          ; Double low-9 quotation mark
        "&dagger;"        8224          ; Dagger
        "&Dagger;"        8225          ; Double dagger
        "&bull;"          8226          ; Bullet
        "&hellip;"        8230          ; Horizontal ellipsis
        "&permil;"        8240          ; Per mille
        "&prime;"         8242          ; Minutes (Degrees)
        "&Prime;"         8243          ; Seconds (Degrees)
        "&lsaquo;"        8249          ; Single left angle quotation
        "&rsaquo;"        8250          ; Single right angle quotation
        "&oline;"         8254          ; Overline
        "&euro;"          8364          ; Euro
        "&trade;"         8482          ; Trademark
        "&larr;"          8592          ; Left arrow
        "&uarr;"          8593          ; Up arrow
        "&rarr;"          8594          ; Right arrow
        "&darr;"          8595          ; Down arrow
        "&harr;"          8596          ; Left right arrow
        "&crarr;"         8629          ; Carriage return arrow
        "&lceil;"         8968          ; Left ceiling
        "&rceil;"         8969          ; Right ceiling
        "&lfloor;"        8970          ; Left floor
        "&rfloor;"        8971          ; Right floor
        "&loz;"           9674          ; Lozenge
        "&spades;"        9824          ; Spade
        "&clubs;"         9827          ; Club
        "&hearts;"        9829          ; Heart
        "&diams;"         983))         ; Diamond


(define (html-entity->string entity)
  (cond
    [(integer? entity)
     (string (integer->char entity))]
    [(symbol? entity)
     (html-entity->string (format "&~a;" entity))]
    [(string? entity)
     (html-entity->string (hash-ref entity-names entity 0))]
    [else ""]))
