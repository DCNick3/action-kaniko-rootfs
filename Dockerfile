FROM alpine as certs

RUN apk --update add ca-certificates

FROM golang:buster as undocker-build

COPY patches/undocker /patches
RUN apt-get update && \
    apt-get install patch && \
    mkdir /build && \
    cd /build && \
    git clone https://git.sr.ht/~motiejus/undocker --branch v1.0.2 . && \
    for i in /patches/*.patch; do patch -p1 < $i; done && \
    make


FROM gcr.io/kaniko-project/executor:debug

SHELL ["/busybox/sh", "-c"]

COPY --from=undocker-build /build/undocker /kaniko/undocker

RUN wget -O /kaniko/jq \
    https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /kaniko/jq && \
    wget -O /kaniko/reg \
    https://github.com/genuinetools/reg/releases/download/v0.16.1/reg-linux-386 && \
    chmod +x /kaniko/reg && \
    wget -O /crane.tar.gz \ 
    https://github.com/google/go-containerregistry/releases/download/v0.1.1/go-containerregistry_Linux_x86_64.tar.gz && \
    tar -xvzf /crane.tar.gz crane -C /kaniko && \
    rm /crane.tar.gz

COPY entrypoint.sh /
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["/entrypoint.sh"]

LABEL repository="https://github.com/DCNick3/action-kaniko-rootfs" \
    maintainer="Nikita Strygin <nikita6@bk.ru>"
