FROM debian as builder

RUN apt update && apt install -y curl \
    libssl-dev \
    libxml2-dev \
    libyaml-dev \
    libgmp-dev \
    libz-dev \
    gnupg2

RUN \
    curl -sSL https://dist.crystal-lang.org/apt/setup.sh | bash && \
    apt install crystal -y



WORKDIR /app/

COPY . .

RUN ls -lah /app

RUN crystal build --release --static src/pix.cr -o /app/pix


FROM debian

RUN apt update && \
  apt-get install -y build-essential imagemagick -y

RUN useradd -ms /bin/bash hanami --uid 1000

ENV KEMAL_ENV=production
EXPOSE 3003

WORKDIR /app

COPY --from=builder /app/pix /app/

COPY public public
RUN mkdir -p /app/public/upload && \
    chown -R hanami:hanami /app/public/upload

VOLUME /app/public/upload

USER hanami

CMD ["/app/pix"]
