FROM racket/racket:8.7

WORKDIR /reader

CMD ["racket", "main.rkt"]

COPY info.rkt .
RUN cd /reader && \
      raco pkg install --no-docs --skip-installed --auto --name reader

COPY . .
RUN cd /reader && \
      raco pkg install --no-docs --skip-installed --auto --name reader
