FROM python:3.12-slim-trixie

ARG TARGETARCH
ARG UNSHACKLE_BRANCH=dev

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/unshackle/.venv \
    PATH="/root/.local/bin:/opt/unshackle/.venv/bin:${PATH}" \
    TZ=Europe/Dublin

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git ffmpeg mkvtoolnix mediainfo \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) SHAKA_ASSET="packager-linux-x64" ;; \
      arm64) SHAKA_ASSET="packager-linux-arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fL \
      "https://github.com/shaka-project/shaka-packager/releases/download/v2.6.1/${SHAKA_ASSET}" \
      -o /usr/local/bin/packager; \
    chmod +x /usr/local/bin/packager

WORKDIR /opt/unshackle

RUN git clone --depth 1 --branch "${UNSHACKLE_BRANCH}" \
    https://github.com/unshackle-dl/unshackle.git .

RUN uv sync --no-dev --compile-bytecode

RUN mkdir -p /root/.config/unshackle \
    /data/services /data/cookies /data/WVDs /data/PRDs \
    /data/cache /data/logs /data/exports /data/dcsl \
    /data/temp /downloads \
    && ln -s /config/unshackle.yaml \
       /root/.config/unshackle/unshackle.yaml

EXPOSE 8786

CMD ["unshackle", "serve", "--host", "0.0.0.0", "--port", "8786", "--api-only"]
