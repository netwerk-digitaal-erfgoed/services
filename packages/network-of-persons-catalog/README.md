# Network of Persons catalogue

The catalogue of the Network of Persons, a proof of concept that runs the
[Network of Terms](https://github.com/netwerk-digitaal-erfgoed/network-of-terms)
software over person datasets instead of terminology sources.

The format is the Network of Terms’: see its
[catalogue documentation](https://github.com/netwerk-digitaal-erfgoed/network-of-terms/tree/master/packages/catalog)
for the dataset descriptions and the query conventions.

```
catalog/
├── publishers.jsonld
├── datasets/wo2personen.jsonld
└── queries/
    ├── search/wo2personen.rq
    └── lookup/wo2personen.rq
```

## How the catalogue is deployed

The Network of Persons has no code of its own. The Network of Terms publishes
its GraphQL API and its reconciliation service as Docker images, and both read
their catalogue from `/app/catalog`. Each of our two apps is a Dockerfile that
replaces that directory:

```dockerfile
FROM ghcr.io/netwerk-digitaal-erfgoed/network-of-terms-graphql:<tag>
USER root
RUN rm -rf /app/catalog
COPY . /app/catalog
USER node
```

See [`apps/network-of-persons-graphql`](../../apps/network-of-persons-graphql)
and [`apps/network-of-persons-reconciliation`](../../apps/network-of-persons-reconciliation).
Their `docker:build` target uses this package’s `catalog` directory as the
Docker build context.

## Why derived images

We considered three other ways to run the Network of Terms with a different
catalogue.

- **Fork the Network of Terms.** A fork has to be kept in step with upstream by
  hand, for a change that touches no code.
- **Write our own server on the Network of Terms npm packages.** Only the
  catalogue and query packages are published, so we would have to rebuild the
  GraphQL schema, the resolvers and the reconciliation service.
- **Mount the catalogue as a volume on the upstream image.** This works and
  needs no build. We chose against it for deployment: the upstream version
  would then be set in the cluster configuration, and a catalogue change would
  reach production without having run against the image it is served by.

With a derived image, the `FROM` line pins the upstream version in this
repository. Dependabot proposes each new upstream image as a pull request, CI
builds the image with our catalogue, and a developer can run the result locally
before it is deployed.

## Run your own Network of Terms

You can run the Network of Terms over your own datasets the same way.

1. Write a catalogue in the layout above. Start by copying this directory or a
   few datasets from the
   [Network of Terms catalogue](https://github.com/netwerk-digitaal-erfgoed/network-of-terms/tree/master/packages/catalog/catalog).
2. To try it, mount it on the upstream image:

   ```sh
   docker run --rm -p 3123:3123 \
     -v "$PWD/catalog:/app/catalog:ro" \
     ghcr.io/netwerk-digitaal-erfgoed/network-of-terms-graphql
   ```

   GraphiQL is then at <http://localhost:3123/graphiql>. The reconciliation
   image, `network-of-terms-reconciliation`, listens on the same port and
   serves each dataset at `/reconcile/{dataset IRI}`.

3. To deploy it, build an image from a Dockerfile like the one above, pinned to
   an upstream tag.

Each dataset’s reconciliation `urlTemplate` contains the public address of the
reconciliation service, so change it to your own host.

## Validate

```sh
pnpm exec nx run-many -t test
```

The test builds both images, starts each and checks that it serves the dataset:
[`smoke-test.sh`](smoke-test.sh). It needs Docker. It does not run the queries
against the endpoint.
