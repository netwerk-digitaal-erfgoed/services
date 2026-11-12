# Network of Persons catalog

The catalog of the Network of Persons, a proof of concept that runs the
[Network of Terms](https://github.com/netwerk-digitaal-erfgoed/network-of-terms)
software over person datasets instead of terminology sources. To search the
datasets, use the [GraphQL API](../../apps/network-of-persons-graphql/README.md);
to match a column of names, the
[reconciliation service](../../apps/network-of-persons-reconciliation/README.md).

## Datasets

| Dataset                                                                                        | Publisher         | Source URI                                                | Persons |
| ---------------------------------------------------------------------------------------------- | ----------------- | --------------------------------------------------------- | ------- |
| [WO2-personen](https://www.oorlogsbronnen.nl/personen)                                         | WO2Net            | `https://data.niod.nl/WO2_personen`                       | 813747  |
| [Open Archieven Persoonsreconstructies](https://www.openarchieven.nl/datasets/reconstructions) | Open Archieven    | `https://www.openarchieven.nl/id/dataset_reconstructions` | 8835746 |
| [Gouda Tijdmachine](https://www.goudatijdmachine.nl/) Kennisgraaf: persoonsreconstructies      | Gouda Tijdmachine | `https://n2t.net/ark:/60537/bD64Hu`                       | 648161  |
| [Regiotermen Fryslân: Personen](https://fryslan.regiotermen.nl/)                               | Tresoar           | `https://fryslan.regiotermen.nl/personen`                 | 4347    |

Persons counted on 2026-11-11; for Open Archieven, the current reconstructions
only.

The first three use the [Persons in Context (PiCo)](https://personsincontext.org)
model, where a person is a _reconstruction_ put together from _observations_:
the mentions of that person in birth certificates, marriage records and
population registers. The APIs return reconstructions. Regiotermen Fryslân is a
regional thesaurus in Schema.org: see [Regiotermen Fryslân](#regiotermen-fryslân).

## Catalog format

The format is the Network of Terms’: see its
[catalog documentation](https://github.com/netwerk-digitaal-erfgoed/network-of-terms/tree/master/packages/catalog)
for the dataset descriptions and the query conventions.

```
catalog/
├── publishers.jsonld
├── datasets/
│   ├── gtm.jsonld
│   ├── oa.jsonld
│   ├── rtf-personen.jsonld
│   └── wo2personen.jsonld
└── queries/
    ├── search/
    │   ├── gtm.rq
    │   ├── oa.rq
    │   ├── rtf-personen.rq
    │   └── wo2personen.rq
    └── lookup/
        ├── gtm.rq
        ├── oa.rq
        ├── rtf-personen.rq
        └── wo2personen.rq
```

## Triples a person has once come from one row

The three PiCo datasets are served by QLever, which constructs the `CONSTRUCT`
template once per result row and does not drop the duplicate triples. The
queries return a row per value of each property – one `UNION` branch per
multi-valued property, as the Network of Terms’ query conventions prescribe – so
a template triple whose variables every row binds comes back once per row:
`?uri a skos:Concept` for every name, observation and relative of the person.
QLever can deduplicate (`--construct-deduplication`), but these endpoints are
not ours to configure.

So **bind what a person has once – the classes, and a preferred label a
subquery picks – on one row per person only**, and leave it unbound on the
others, where the template triple is then not constructed. Keep a value that
can occur several times, such as a place’s names, out of that row, in a branch
of its own:

- Open Archieven: in a first `UNION` branch that every person matches. The
  preferred label, which a subquery picks as the first name, gets a branch of
  its own, filtered to that name, as the alternative labels are filtered to
  the others.
- Gouda Tijdmachine: in the branch with the name, which every reconstruction
  has exactly one of.
- WO2-personen: in extra columns of the `VALUES` table on the `schema:name`
  row, `UNDEF` on the others. The spellings, and the given and family names,
  which the reconstructions do not state, come from the observations in a
  `UNION` branch of their own, through one property/value pattern with a
  `VALUES` table of its own. In an `OPTIONAL` per property they would
  multiply: one observation states 22 names, 16 alternate names, 16 given
  names and 9 family names. Both branches repeat the search subquery, which
  QLever computes once and caches: without it, QLever evaluates the branch, or
  an `OPTIONAL`, over every observation in the dataset before joining it to
  the results. A branch without the subquery ran QLever out of memory, and an
  `OPTIONAL` took 2.4 of a search’s 3.3 seconds; with the subquery, the
  branch takes 10 milliseconds. The Network of Terms replaces every `#LIMIT#`,
  so both subqueries find the same persons.
- Regiotermen Fryslân: in the branch with the name, as for the Gouda
  Tijdmachine. Its GraphDB endpoint does not repeat triples, but the query
  follows the same rule, so it doesn’t depend on that.

A person the bound row misses loses its classes, and the Network of Terms then
leaves it out. Counted on 2026-11-02: every Gouda Tijdmachine and WO2-personen
reconstruction has exactly one name. Counted on 2026-11-10: every Regiotermen
Fryslân person has exactly one name.

Some duplicates remain, and are not worth a more complex query: a relative or
place that several persons in a result share is described once for each of
them, and a spelling or name part found in several observations of a person
comes back once for each.

## WO2-personen family names

Some WO2-personen sources leave the prefix out of the family name: ‘Vries’ for
Dick de Vries, whose name is ‘Dick de Vries’. No property states the prefix.
On 2026-11-05, 248513 observations did include it, such as ‘de Vries’. The
queries take the prefix from the observation’s name: the lowercase words
before the family name at the end of it. A family name that is not at the end
of the name, or follows no lowercase word, is returned as the source states it.
They do this in a `BIND` after the joins: inside an `OPTIONAL`, QLever
computes it for every observation in the dataset, which took a search from 1
to 15 seconds.

For ‘Jan Jansen’ at a limit of 1000, this made the search responses 53–79%
smaller – Open Archieven from 11.6 to 4.4 MB – with the same distinct triples.

## Gender

The three PiCo datasets state `schema:gender` as Schema.org’s `Male` or `Female`
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

Regiotermen Fryslân states gender as a literal, in varying case, some tagged
`nl`. On 2026-11-10, 2459 persons stated one, and none more than one: 2160
“mannelijk”, 298 “vrouwelijk” and 1 “intersekse vrouw”. The queries return
“mannelijk” as `https://schema.org/Male` and “vrouwelijk” as
`https://schema.org/Female`, in any case, so the persons compare with those of
the other datasets. Schema.org has no IRI for “intersekse vrouw”, which is
returned as stated.

Other person sources in the Network of Terms catalog state gender as literals
too, which matters if one of them moves here:

- House of Legacies: “Man”, “Vrouw”, “Non-binair” and “Overig”, tagged `nl`.
- The WO2-biografieën: Dutch and English mixed, in varying case and with stray
  spaces and newlines – “Man”, “male”, “Male\n”, “Female”.

The Network of Terms passes a literal through as stated, so these are not
normalised to the Schema.org IRIs.

## Regiotermen Fryslân

Tresoar keeps its persons in Omeka S and publishes them in three named graphs
on its GraphDB endpoint. The Network of Terms queries
`https://fryslan.regiotermen.nl/personen`, which holds SKOS only. We query
`https://fryslan.regiotermen.nl/personen/clean`, which describes the same 4347
persons, under the same IRIs, in Schema.org: given and family names, dates,
GeoNames places, AAT occupations, gender and alignments. A third graph,
`…/personen/staging`, is the raw Omeka S export. It also states PNV name parts
and relations such as `schema:spouse`, but under Omeka API IRIs, so we leave it
out.

The data as stated, on 2026-11-10:

- Dates are mostly `xsd:date`, some `xsd:gYear` or `xsd:gYearMonth`, and a few
  persons have two birth or death dates, days apart.
- Places are GeoNames IRIs, as `https://sws.geonames.org/{id}` or
  `https://www.geonames.org/{id}`, without the canonical trailing slash, or
  names where the source links none. The queries pass them through.
- Occupations are AAT IRIs, or names where the source links none.

The endpoint returns at most 1000 results for any query, and drops the rest
without notice. A person comes to 16 triples on average and 30 at most, so the
search returns at most 50 persons, the closest matches, though the
reconciliation service asks for 1000 when it ranks on properties and the
GraphQL API for 100 by default. Should 50 persons still exceed 1000 triples,
the query’s order makes the endpoint drop the weakest matches first, though
the person at the cut may lose only some of its properties.

## How the catalog is deployed

The Network of Persons has no code of its own. The Network of Terms publishes
its GraphQL API and its reconciliation service as Docker images, and both read
their catalog from the directory in `CATALOG_PATH`. Each of our two apps is a
Dockerfile that copies our catalog in and points `CATALOG_PATH` at it:

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
catalog.

- **Fork the Network of Terms.** A fork has to be kept in step with upstream by
  hand, for a change that touches no code.
- **Write our own server on the Network of Terms npm packages.** Only the
  catalog and query packages are published, so we would have to rebuild the
  GraphQL schema, the resolvers and the reconciliation service.
- **Mount the catalog as a volume on the upstream image.** This works and
  needs no build. We chose against it for deployment: the upstream version
  would then be set in the cluster configuration, and a catalog change would
  reach production without having run against the image it is served by.

With a derived image, the `FROM` line pins the upstream version in this
repository. Dependabot proposes each new upstream image as a pull request, CI
builds the image with our catalog, and a developer can run the result locally
before it is deployed.

## Run your own Network of Terms

You can run the Network of Terms over your own datasets the same way.

1. Write a catalog in the layout above. Start by copying this directory or a
   few datasets from the
   [Network of Terms catalog](https://github.com/netwerk-digitaal-erfgoed/network-of-terms/tree/master/packages/catalog/catalog).
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
