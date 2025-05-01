FROM ghcr.io/actions/actions-runner:2.323.0

# Set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive
USER root

# Update and install core utilities
RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  apt-utils \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  software-properties-common \
  lsb-release \
  wget \
  zip \
  unzip \
  git \
  sudo

# Install basic system utilities
RUN apt-get install -y --no-install-recommends \
  dpkg \
  dpkg-dev \
  fakeroot \
  file \
  findutils \
  flex \
  fonts-noto-color-emoji \
  ftp \
  g++ \
  gcc \
  gnupg2 \
  haveged \
  iproute2 \
  iputils-ping \
  jq \
  libsqlite3-dev \
  libssl-dev \
  libtool \
  libyaml-dev \
  locales \
  lz4 \
  m4 \
  make \
  mediainfo \
  mercurial \
  net-tools \
  netcat \
  openssh-client

# Install development tools & languages
RUN apt-get install -y --no-install-recommends \
  build-essential \
  gdb \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  python3-setuptools \
  python3-wheel

# Install Clang versions
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
  echo "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy main" >> /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
  clang \
  clang-format \
  clang-tidy

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
  apt-get install -y nodejs && \
  npm install -g npm@10.8.2 yarn@1.22.22

# Install Ruby
RUN apt-get install -y --no-install-recommends \
  ruby-full \
  ruby-dev \
  rubygems

# Install MySQL
RUN apt-get install -y --no-install-recommends \
  mysql-server && \
  echo "MySQL root password: root" && \
  echo -e "[mysql]\nuser=root\npassword=root" > /root/.my.cnf && \
  chmod 600 /root/.my.cnf

# Install Apache and Nginx
RUN apt-get install -y --no-install-recommends \
  apache2 \
  nginx

# Install PowerShell
# RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb && \
#   dpkg -i packages-microsoft-prod.deb && \
#   apt-get update && \
#   apt-get install -y powershell && \
#   rm packages-microsoft-prod.deb

# Install Android SDK tools
# RUN mkdir -p /usr/local/lib/android && \
#   cd /usr/local/lib/android && \
#   wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
#   unzip commandlinetools-linux-*_latest.zip && \
#   rm commandlinetools-linux-*_latest.zip && \
#   mkdir -p /usr/local/lib/android/cmdline-tools/latest && \
#   mv /usr/local/lib/android/cmdline-tools/* /usr/local/lib/android/cmdline-tools/latest/ || true && \
#   cd /usr/local/lib/android/cmdline-tools/latest/bin && \
#   yes | ./sdkmanager --licenses && \
#   ./sdkmanager "platform-tools" "build-tools;34.0.0" "build-tools;35.0.0" "build-tools;35.0.1" "build-tools;36.0.0"

# Install Homebrew (not added to PATH by default)
RUN mkdir -p /home/linuxbrew && \
  git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew && \
  echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> /etc/bash.bashrc && \
  echo 'export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"' >> /etc/bash.bashrc && \
  echo 'export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"' >> /etc/bash.bashrc

# Install Miniconda
# RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
#   bash Miniconda3-latest-Linux-x86_64.sh -b -p /usr/share/miniconda && \
#   rm Miniconda3-latest-Linux-x86_64.sh && \
#   echo 'export PATH="/usr/share/miniconda/bin:$PATH"' >> /etc/bash.bashrc

# Install Vcpkg
RUN git clone https://github.com/Microsoft/vcpkg.git /usr/local/share/vcpkg && \
  /usr/local/share/vcpkg/bootstrap-vcpkg.sh && \
  echo 'export PATH="/usr/local/share/vcpkg:$PATH"' >> /etc/bash.bashrc && \
  echo 'export VCPKG_INSTALLATION_ROOT="/usr/local/share/vcpkg"' >> /etc/bash.bashrc

# Clean up
RUN apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Set up services to be disabled by default (same as GitHub runners)
RUN systemctl disable mysql.service apache2.service nginx.service || true

# Verify some key installations
RUN node --version && \
  npm --version && \
  python3 --version && \
  pip3 --version && \
  ruby --version && \
  gem --version

# Default to bash shell
SHELL ["/bin/bash", "-c"]

USER runner

# Copy and make init.sh executable
COPY init.sh .

# Use shell as entrypoint for proper signal handling
ENTRYPOINT ["/bin/bash", "init.sh"]
