# The sandbox image, plus what every repo's suite needs to run inside it.
#
# heart's verifier container has no network, so a suite can't `uv sync` there.
# heart and plexus are stdlib-only and ran fine; arteries and capillaries never
# could (psycopg2, dspy, and arteries imports capillaries). This bakes their
# third-party deps in, plus capillaries itself for arteries to import.
#
# heart and capillaries are baked because other suites import them; every
# suite pins pytest's pythonpath to its own src/, so the repo under test always
# wins over its baked copy. (Before those pins, heart's suite tested the image's
# stale heart instead of the diff.) heart is re-baked from the checkout here
# because heart-agent:latest carries whatever heart it was built with.
#
# Build (from this directory; the named contexts can point at any checkouts):
#   docker build -f verifier.Dockerfile -t heart-agent:vascular \
#     --build-context heart=heart --build-context capillaries=capillaries \
#     --build-context arteries=arteries --build-context pulse=pulse .
# Use:
#   HEART_SANDBOX=docker-sbx HEART_SANDBOX_IMAGE=heart-agent:vascular plexus run ...
#
# Point the named contexts at checkouts that hold what was merged (the dev
# checkouts beside this umbrella, e.g. heart=../heart). The umbrella's own
# submodule dirs can be far behind.
#
# ponytail: heart and capillaries are snapshots from build time, so plexus,
# marrow and arteries check against those until the next rebuild. Rebuild after
# either lands anything the others import.
FROM heart-agent:latest

# the base image ends as the unprivileged `agent`; install as root, hand it back
USER root

COPY --from=ghcr.io/astral-sh/uv:0.9.18 /uv /usr/local/bin/uv

COPY --from=heart pyproject.toml /opt/heart-src/pyproject.toml
COPY --from=heart src /opt/heart-src/src
COPY --from=capillaries pyproject.toml /opt/capillaries/pyproject.toml
COPY --from=capillaries src /opt/capillaries/src
COPY --from=arteries pyproject.toml /tmp/arteries/pyproject.toml

# a host checkout's egg-info comes along in the copy and setuptools can't touch it
RUN rm -rf /opt/capillaries/src/*.egg-info /opt/heart-src/src/*.egg-info \
 && uv pip install --system --no-cache --reinstall-package heart /opt/heart-src /opt/capillaries \
        -r /tmp/arteries/pyproject.toml --extra ontology \
 && rm -rf /tmp/arteries

# Rust, for pulse (and any component ported later). The toolchain is copied from
# the official image at a pinned version; gcc + libc6-dev are the linker cargo
# needs. The checkout is mounted read-only, so build output goes to /tmp, and
# CARGO_HOME belongs to `agent` because cargo takes a lock file inside it even
# when nothing is downloaded.
COPY --from=rust:1.99.0-slim-trixie /usr/local/rustup /usr/local/rustup
COPY --from=rust:1.99.0-slim-trixie /usr/local/cargo /usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo \
    CARGO_TARGET_DIR=/tmp/cargo-target PATH=/usr/local/cargo/bin:$PATH
RUN apt-get update \
 && apt-get install -y --no-install-recommends gcc libc6-dev \
 && rm -rf /var/lib/apt/lists/*

# The verifier has no network, so everything cargo and rustup would download is
# fetched here: pulse's rust-toolchain.toml components (without them rustup
# tries the network on every cargo call) and every crate in pulse's Cargo.lock.
# Rebuild whenever pulse's dependencies change, exactly like the Python deps.
COPY --from=pulse Cargo.toml Cargo.lock rust-toolchain.toml /tmp/pulse/
RUN rustup component add rustfmt clippy \
 && mkdir /tmp/pulse/src && touch /tmp/pulse/src/lib.rs \
 && cd /tmp/pulse && cargo fetch --locked \
 && rm -rf /tmp/pulse \
 && chown -R agent:agent /usr/local/cargo

USER agent
