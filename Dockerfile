# syntax=docker/dockerfile:1

FROM ubuntu:24.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    clang \
    lld \
    libboost-dev \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN CXX=clang++ \
    OUTPUT=/out/pastafari-http \
    sh build_http_api.sh

FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libstdc++6 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /out/pastafari-http /app/pastafari-http

EXPOSE 10000

CMD ["sh", "-c", "exec /app/pastafari-http 0.0.0.0 \"${PORT:-10000}\""]
