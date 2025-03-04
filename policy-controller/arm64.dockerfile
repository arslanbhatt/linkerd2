ARG RUST_IMAGE=docker.io/library/rust:1.54.0-buster
ARG RUNTIME_IMAGE=gcr.io/distroless/cc:nonroot

FROM $RUST_IMAGE as build
RUN apt-get update && \
    apt-get install -y --no-install-recommends g++-aarch64-linux-gnu libc6-dev-arm64-cross && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/ && \
    rustup target add aarch64-unknown-linux-gnu
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
WORKDIR /build
COPY . /build
RUN --mount=type=cache,target=target \
    --mount=type=cache,from=rust:1.54.0-buster,source=/usr/local/cargo,target=/usr/local/cargo \
    cargo build --locked --release --target=aarch64-unknown-linux-gnu --package=linkerd-policy-controller && \
    mv target/aarch64-unknown-linux-gnu/release/linkerd-policy-controller /tmp/

FROM --platform=linux/arm64 $RUNTIME_IMAGE
COPY --from=build /tmp/linkerd-policy-controller /bin/
ENTRYPOINT ["/bin/linkerd-policy-controller"]
