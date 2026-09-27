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
#     --build-context arteries=arteries .
# Use:
#   HEART_SANDBOX=docker-sbx HEART_SANDBOX_IMAGE=heart-agent:vascular plexus run ...
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

USER agent
