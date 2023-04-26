FROM racket/racket:8.7

WORKDIR /reader

COPY . .

CMD ["racket", "main.rkt"]

RUN cd /reader && \
      raco pkg install --no-docs --skip-installed --auto --name reader
