FROM racket/racket:8.7

WORKDIR /reader

CMD ["./main"]

COPY info.rkt .
RUN cd /reader && \
      raco pkg install --no-docs --skip-installed --auto --name reader

COPY . .
RUN cd /reader && \
      raco exe main.rkt
