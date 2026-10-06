FROM ghcr.io/netwerk-digitaal-erfgoed/network-of-terms-reconciliation:20261001120546-da0f375
LABEL org.opencontainers.image.source="https://github.com/netwerk-digitaal-erfgoed/services"

# The Network of Terms image serves the catalogue in /app/catalog; replace it with ours.
# The build context is the catalogue directory of packages/network-of-persons-catalog.
USER root
RUN rm -rf /app/catalog
COPY . /app/catalog
USER node
