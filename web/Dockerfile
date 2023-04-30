FROM racket/racket:8.7

WORKDIR /reader

CMD ["./main"]

COPY scripts scripts
COPY info.rkt info.rkt
RUN cd /reader && ./scripts/install

COPY . .
RUN cd /reader && ./scripts/build
