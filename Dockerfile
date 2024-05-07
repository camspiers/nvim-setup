FROM ubuntu:noble

# Install all basic dependencies
RUN apt-get update && \
  apt-get install -y \
  git \
  curl \
  cmake \
  unzip \
  wget \
  python3 \
  python3-pip \
  python3-venv \
  file

# Install a node manager
RUN curl -fsSL https://fnm.vercel.app/install | bash

# Update path to include fnm
ENV PATH="${PATH}:/root/.local/share/fnm"

# Install a default version of node
ARG NODE_VERSION="lts/latest"
RUN bash -c "$(fnm env --use-on-cd) && fnm use --install-if-missing ${NODE_VERSION} && fnm default ${NODE_VERSION}"

# Install fnm shell integration
COPY .bashrc /root/.bashrc

# Install lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') && \
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
  tar xf lazygit.tar.gz lazygit && \
  install lazygit /usr/local/bin

# Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Update path to include cargo
ENV PATH="${PATH}:/root/.cargo/bin"

# Install nvim manager and ripgrep
RUN cargo install \
  bob-nvim \
  ripgrep

# Update path to include bob
ENV PATH="${PATH}:/root/.local/share/bob/nvim-bin"

# Install the latest version of nvim
ARG NVIM_VERSION="nightly"
RUN bob use ${NVIM_VERSION}

# Install a nvim config
ARG NVIM_CONFIG_URL=https://github.com/LazyVim/starter
RUN mkdir ~/.config && \
  git clone ${NVIM_CONFIG_URL} ~/.config/nvim && \
  rm -rf ~/.config/nvim/.git

# Set the WORKDIR to root
WORKDIR /root/dev

# Allow git to use /root/dev
RUN git config --system --add safe.directory /root/dev

COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

ENTRYPOINT [ "/root/entrypoint.sh", "nvim" ]
