FROM ghcr.io/netwerk-digitaal-erfgoed/network-of-terms-graphql:20261112151604-2c8d748
LABEL org.opencontainers.image.source="https://github.com/netwerk-digitaal-erfgoed/services"

# Serve our catalogue instead of the Network of Terms one.
# The build context is the catalogue directory of packages/network-of-persons-catalog.
COPY . /catalog
ENV CATALOG_PATH=/catalog
