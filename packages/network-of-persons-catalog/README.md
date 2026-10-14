# Network of Persons catalogue

The catalogue of the Network of Persons, a proof of concept that runs the
[Network of Terms](https://github.com/netwerk-digitaal-erfgoed/network-of-terms)
software over person datasets instead of terminology sources. It holds three
datasets, all in the Persons in Context (PiCo) model: the WO2-personen of
WO2Net, the person reconstructions of
[Open Archieven](https://www.openarchieven.nl/) and the person reconstructions
in the knowledge graph of the
[Gouda Tijdmachine](https://www.goudatijdmachine.nl/).

The format is the Network of Terms’: see its
[catalogue documentation](https://github.com/netwerk-digitaal-erfgoed/network-of-terms/tree/master/packages/catalog)
for the dataset descriptions and the query conventions.

```
catalog/
├── publishers.jsonld
├── datasets/
│   ├── gtm.jsonld
│   ├── oa.jsonld
│   └── wo2personen.jsonld
└── queries/
    ├── search/
    │   ├── gtm.rq
    │   ├── oa.rq
    │   └── wo2personen.rq
    └── lookup/
        ├── gtm.rq
        ├── oa.rq
        └── wo2personen.rq
```

## Gender

All three datasets state `schema:gender` as Schema.org’s `Male` or `Female`
IRI, and nothing else. Counted on 2026-10-14 over every subject, observations
included:

| Dataset           | Namespace             | Male    | Female  |
| ----------------- | --------------------- | ------- | ------- |
| WO2-personen      | `http://schema.org/`  | 1149700 | 386270  |
| Open Archieven    | `https://schema.org/` | 1621688 | 1632832 |
| Gouda Tijdmachine | `https://schema.org/` | 310252  | 329766  |

The queries construct the value as the source states it. The Network of Terms
returns both namespaces as `https://schema.org/Male` and
`https://schema.org/Female`. WO2-personen and Gouda Tijdmachine state at most
one gender per reconstruction; 3110 current Open Archieven reconstructions
state both, and come out with both.

Person sources in the Network of Terms catalogue state gender as literals,
which matters if one of them moves here:

- House of Legacies: “Man”, “Vrouw”, “Non-binair” and “Overig”, tagged `nl`.
- The Frisian thesaurus: “mannelijk”, “vrouwelijk” and “intersekse vrouw”, in
  varying case.
- The WO2-biografieën: Dutch and English mixed, in varying case and with stray
  spaces and newlines – “Man”, “male”, “Male\n”, “Female”.

The Network of Terms passes a literal through as stated, so these are not
normalised to the Schema.org IRIs.

## How the catalogue is deployed

The Network of Persons has no code of its own. The Network of Terms publishes
its GraphQL API and its reconciliation service as Docker images, and both read
their catalogue from the directory in `CATALOG_PATH`. Each of our two apps is a
Dockerfile that copies our catalogue in and points `CATALOG_PATH` at it:

```dockerfile
FROM ghcr.io/netwerk-digitaal-erfgoed/network-of-terms-graphql:<tag>
COPY . /catalog
ENV CATALOG_PATH=/catalog
```

If `CATALOG_PATH` names a directory that doesn’t exist or holds no datasets, the
server stops at startup with an error.

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
     -v "$PWD/catalog:/catalog:ro" -e CATALOG_PATH=/catalog \
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
