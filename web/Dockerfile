FROM racket/racket:8.7

WORKDIR /reader

CMD ["./main"]

COPY info.rkt .
RUN cd /reader && ./scripts/install

COPY . .
RUN cd /reader && ./scripts/build
