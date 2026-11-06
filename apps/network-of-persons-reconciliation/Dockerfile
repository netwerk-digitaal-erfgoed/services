FROM ghcr.io/netwerk-digitaal-erfgoed/network-of-terms-reconciliation:20261105183419-b76fdde
LABEL org.opencontainers.image.source="https://github.com/netwerk-digitaal-erfgoed/services"

# Serve our catalogue instead of the Network of Terms one.
# The build context is the catalogue directory of packages/network-of-persons-catalog.
COPY . /catalog
ENV CATALOG_PATH=/catalog
