ARG BUN_VERSION="1.3.4"
ARG GO_VERSION="1.25.4"
ARG RUBY_VERSION="3.4.7"

FROM golang:$GO_VERSION AS gobuilder
RUN go install github.com/jackc/sqlfmt/cmd/sqlfmt@latest
RUN go install github.com/steveyegge/beads/cmd/bd@latest

FROM oven/bun:$BUN_VERSION AS bunbuilder

FROM ruby:$RUBY_VERSION-slim-bookworm AS rubybuilder

FROM heroku/heroku:24-build
LABEL maintainer="Matt Rohrer <matt@prognostikos.com>"

COPY --from=gobuilder /go/bin/sqlfmt /usr/local/bin/sqlfmt
COPY --from=gobuilder /go/bin/bd /usr/local/bin/bd
COPY --from=bunbuilder /usr/local/bin/bun /usr/local/bin/bun
COPY --from=rubybuilder /usr/local/bin/ruby /usr/local/bin/
COPY --from=rubybuilder /usr/local/bin/erb /usr/local/bin/
COPY --from=rubybuilder /usr/local/bin/gem /usr/local/bin/
COPY --from=rubybuilder /usr/local/bin/irb /usr/local/bin/
COPY --from=rubybuilder /usr/local/bin/racc /usr/local/bin/
COPY --from=rubybuilder /usr/local/bin/rdoc /usr/local/bin/
COPY --from=rubybuilder /usr/local/bin/ri /usr/local/bin/
COPY --from=rubybuilder /usr/local/lib/libruby.so* /usr/local/lib/
COPY --from=rubybuilder /usr/local/lib/ruby /usr/local/lib/ruby

ARG BUNDLER_VERSION="2.7.2"
ARG NEOVIM_VERSION="0.11.5"
ARG NODE_MAJOR_VERSION="22"
ARG PHRASE_VERSION="2.49.0"

ARG USERNAME=dev
ARG USER_UID=2000
ARG USER_GID=2000

# Use BuildKit's built-in platform ARG for multi-architecture builds
ARG TARGETPLATFORM

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_MAJOR_VERSION=${NODE_MAJOR_VERSION} \
    PHRASE_VERSION=${PHRASE_VERSION}

USER root

# Update shared library cache for libruby
RUN ldconfig

# Create hardlink for bunx
RUN ln /usr/local/bin/bun /usr/local/bin/bunx

# Install packages from Ubuntu repos first (before adding Debian repo)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  bat \
  bubblewrap \
  ca-certificates \
  cargo \
  dnsutils \
  direnv \
  fd-find \
  fzf \
  gdb \
  gh \
  git-delta \
  gnupg2 \
  htop \
  iftop \
  iotop \
  jq \
  libjemalloc2 \
  libvips \
  locales \
  lsof \
  ltrace \
  man-db \
  manpages \
  manpages-dev \
  ncdu \
  net-tools \
  netcat-openbsd \
  nginx \
  nodejs \
  postgresql-client \
  ripgrep \
  rustc \
  shellcheck \
  silversearcher-ag \
  socat \
  strace \
  sudo \
  sysstat \
  tcpdump \
  tmux \
  tig \
  tree \
  universal-ctags \
  vim \
  vim-doc \
  yarn \
  zsh

# we want man to work, even though it "bloats" the image
RUN yes | unminimize

# The path to jemalloc will change depending on the architecture, so we create
# a link that will always be the same for this image for LD_PRELOAD
RUN ln -s $(find /usr/lib -type f -name libjemalloc.so.2) /usr/lib/libjemalloc.so.2

# Setup locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Install Neovim using BuildKit platform detection
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      ARCH_NAME="x86_64"; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      ARCH_NAME="arm64"; \
    else \
      echo "Unsupported platform: $TARGETPLATFORM" && exit 1; \
    fi && \
    echo "Installing Neovim for $ARCH_NAME" && \
    mkdir -p /opt/nvim && \
    curl -sSL "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${ARCH_NAME}.tar.gz" | tar -C /opt/nvim --strip-components=1 -xz && \
    ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

# Install AWS CLI using BuildKit platform detection
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      ARCH_SUFFIX="x86_64"; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      ARCH_SUFFIX="aarch64"; \
    else \
      echo "Unsupported platform: $TARGETPLATFORM" && exit 1; \
    fi && \
    echo "Installing AWS CLI for $ARCH_SUFFIX" && \
    curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_SUFFIX}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -r aws awscliv2.zip

ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2" \
    USERNAME=$USERNAME \
    USER_UID=$USER_UID \
    USER_GID=$USER_GID \
    LANG=en_US.UTF-8

# Install Ruby gems
RUN gem install bundler:$BUNDLER_VERSION ruby-lsp ruby-lsp-rails ruby-lsp-rspec

# add developer user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && chsh -s /usr/bin/zsh $USERNAME

RUN mkdir /workspaces && chown $USERNAME:$USERNAME /workspaces

USER $USERNAME

RUN mkdir -p ~/.local/bin && ln -s $(which fdfind) ~/.local/bin/fd
RUN ln -s $(which batcat) ~/.local/bin/bat

RUN echo "postgres:5432:*:postgres:postgres" > ~/.pgpass && chmod 600 ~/.pgpass

# Install "global" js tools
RUN bun install --global \
  @anthropic-ai/claude-code \
  typescript \
  typescript-language-server \
  vscode-langservers-extracted

WORKDIR /workspaces

ENV RUNNING_IN_DEVCONTAINER=1
