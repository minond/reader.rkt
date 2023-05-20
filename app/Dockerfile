FROM python:3.10.11-slim-buster

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends ca-certificates curl sqlite3 \
    && apt-get clean

RUN curl --retry 5 -Ls "https://download.racket-lang.org/installers/8.7/racket-minimal-8.7-x86_64-linux-natipkg.sh" > racket-install.sh \
    && echo "yes\n1\n" | sh racket-install.sh --create-dir --unix-style --dest /usr/ \
    && rm racket-install.sh

ENV SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
ENV SSL_CERT_DIR="/etc/ssl/certs"

RUN raco setup
RUN raco pkg config --set catalogs \
    "https://download.racket-lang.org/releases/8.7/catalog/" \
    "https://pkg-build.racket-lang.org/server/built/catalog/" \
    "https://pkgs.racket-lang.org" \
    "https://planet-compats.racket-lang.org"

WORKDIR /reader

CMD ["./main"]

COPY scripts scripts
COPY info.rkt info.rkt
RUN cd /reader && ./scripts/install
RUN raco pyffi configure

COPY . .
RUN cd /reader && ./scripts/build