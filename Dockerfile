FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc make libc6-dev libcrypt-dev autoconf \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY configure ./
COPY cnf/ ./cnf/
COPY src/ ./src/
RUN chmod +x ./configure \
    && ./configure \
    && mkdir -p bin lib/world/wld \
    && cd src \
    && make

FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libcrypt1 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 mud \
    && useradd -u 1000 -g 1000 -m -s /bin/bash mud

WORKDIR /app
COPY --from=builder /build/bin/ /app/bin/
COPY --from=builder /build/lib/world/wld/map /app/bin/util/map
COPY --from=builder /build/lib/world/wld/read_map /app/bin/util/read_map
COPY autorun /app/autorun
RUN chmod +x /app/autorun /app/bin/* /app/bin/util/* \
    && mkdir -p /app/lib /app/log /app/data \
    && chown -R mud:mud /app

USER mud
EXPOSE 4000
CMD ["./autorun"]
