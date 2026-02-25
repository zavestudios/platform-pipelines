FROM rust:1.85-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git bash \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) asset_arch="linux_amd64" ;; \
      arm64) asset_arch="linux_arm64" ;; \
      *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    version="$(curl -fsSL https://api.github.com/repos/rhysd/actionlint/releases/latest | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p' | head -n1)"; \
    test -n "$version"; \
    asset="actionlint_${version}_${asset_arch}.tar.gz"; \
    curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${version}/${asset}" -o /tmp/actionlint.tgz; \
    tar -xzf /tmp/actionlint.tgz -C /tmp; \
    install -m 0755 /tmp/actionlint /usr/local/bin/actionlint; \
    rm -rf /tmp/actionlint /tmp/actionlint.tgz

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) ziz_arch="x86_64-unknown-linux-gnu" ;; \
      arm64) ziz_arch="aarch64-unknown-linux-gnu" ;; \
      *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    ziz_tag="$(curl -fsSL https://api.github.com/repos/zizmorcore/zizmor/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n1)"; \
    test -n "$ziz_tag"; \
    ziz_asset="zizmor-${ziz_arch}.tar.gz"; \
    curl -fsSL "https://github.com/zizmorcore/zizmor/releases/download/${ziz_tag}/${ziz_asset}" -o /tmp/zizmor.tgz; \
    tar -xzf /tmp/zizmor.tgz -C /tmp; \
    install -m 0755 /tmp/zizmor /usr/local/bin/zizmor; \
    rm -rf /tmp/zizmor /tmp/zizmor.tgz

WORKDIR /work

CMD ["bash", "-lc", "actionlint .github/workflows/*.yml && zizmor .github/workflows"]
