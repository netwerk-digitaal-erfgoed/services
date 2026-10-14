FROM ghcr.io/netwerk-digitaal-erfgoed/network-of-terms-reconciliation:20261014113300-abe9b67
LABEL org.opencontainers.image.source="https://github.com/netwerk-digitaal-erfgoed/services"

# Serve our catalogue instead of the Network of Terms one.
# The build context is the catalogue directory of packages/network-of-persons-catalog.
COPY . /catalog
ENV CATALOG_PATH=/catalog
