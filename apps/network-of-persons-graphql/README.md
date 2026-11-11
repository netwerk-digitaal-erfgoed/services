# Network of Persons GraphQL API

This is the [Network of Terms GraphQL API](https://docs.nde.nl/services/network-of-terms/graphql)
over [person datasets](../../packages/network-of-persons-catalog/README.md#datasets). Its queries, [errors](https://docs.nde.nl/services/network-of-terms/graphql#query-a-single-source),
[language selection](https://docs.nde.nl/services/network-of-terms/graphql#language-selection)
and [timeouts](https://docs.nde.nl/services/network-of-terms/graphql#timeouts)
work as documented there; this README covers what is specific to persons.

> [!WARNING]
> The Network of Persons is a proof of concept. Its URL, datasets and data
> may change or disappear without notice. Do not build production integrations
> on it.

The [catalog README](../../packages/network-of-persons-catalog/README.md#datasets)
lists the datasets, with the source URIs to query. To match a column of names,
use the [reconciliation service](../network-of-persons-reconciliation/README.md).

## Endpoint

`https://personennetwerk.netwerkdigitaalerfgoed.nl/graphql`, with
[GraphiQL](https://personennetwerk.netwerkdigitaalerfgoed.nl) to try queries.

## Search persons

```graphql
query {
  terms(
    sources: [
      "https://data.niod.nl/WO2_personen"
      "https://www.openarchieven.nl/id/dataset_reconstructions"
      "https://n2t.net/ark:/60537/bD64Hu"
      "https://fryslan.regiotermen.nl/personen"
    ]
    query: "Zwanenveld"
    languages: [nl]
  ) {
    source {
      name
    }
    result {
      ... on TranslatedTerms {
        terms {
          uri
          prefLabel {
            value
          }
          person {
            birthDate
            deathDate
          }
        }
      }
      ... on Error {
        message
      }
    }
  }
}
```

A search matches whole words, in any order, against all names of a person,
including spelling variants: the observation names in WO2-personen and Gouda
Tijdmachine, the other names of a reconstruction in Open Archieven. So
‘Zwanenveld’ finds Dirk Zwaneveld in WO2-personen. The matching is done by the
full-text index of [QLever](https://github.com/ad-freiburg/qlever), which serves
the three PiCo datasets and splits names into words at every character that is
not a letter or digit. Hence:

- ‘Zwanenv’ finds nothing. For a prefix search, end the word with `*` and set
  `queryMode: RAW`. QLever has no infix or fuzzy search.
- Punctuation finds nothing: search for ‘Zwanenveld Dirk’, not
  ‘Zwanenveld, Dirk’.

Regiotermen Fryslân is served by GraphDB without a text index, so a name matches
when it contains the search string, in any case: ‘Zwanenv’ finds ‘Zwanenveld’
there, but ‘Jansen Jan’ does not find ‘Jan Jansen’. It returns at most 50
persons, as its endpoint drops results beyond 1000 triples.

When more persons match than `limit` allows, those with the shortest matching
name are returned, so ‘Jan de Vries’ goes before ‘Jan Hendrik de Vries’. Results are then sorted
alphabetically.

## Look up persons

Look up persons by URI, for example to follow a family relation. This query asks
for every field:

<!-- prettier-ignore -->
```graphql
query {
  lookup(
    uris: [
      "https://www.openarchieven.nl/id/reconstruction_f6b47b13-c9fa-18a3-274c-e91d26405e44"
    ]
    languages: [nl]
  ) {
    result {
      ... on TranslatedTerm {
        uri
        prefLabel { value }
        altLabel { value }
        hiddenLabel { value }
        scopeNote { value }
        seeAlso
        exactMatch { uri }
        person {
          givenName { value }
          familyName { value }
          birthDate
          deathDate
          birthPlace { uri name { value } }
          deathPlace { uri name { value } }
          gender { uri }
          hasOccupation {
            occupation { uri name { value } }
            roleName { value }
            startDate
            endDate
          }
          nationality { uri name { value } }
          parent { uri name { value } }
          children { uri name { value } }
          spouse { uri name { value } }
          sibling { uri name { value } }
        }
      }
      ... on Error {
        message
      }
    }
  }
}
```

```json
{
  "uri": "https://www.openarchieven.nl/id/reconstruction_f6b47b13-c9fa-18a3-274c-e91d26405e44",
  "prefLabel": [{ "value": "Ot Jansen" }],
  "altLabel": [],
  "hiddenLabel": [],
  "scopeNote": [],
  "seeAlso": [
    "https://www.openarchieven.nl/id/record_gld_21D2A2C2-7662-4487-86E3-4BF8E7D97939_Person3032775115",
    "https://www.openarchieven.nl/id/record_gld_3EB07A70-D9F3-4148-980B-8DEFE8872920_Person3100077875",
    "…"
  ],
  "exactMatch": [],
  "person": {
    "givenName": [{ "value": "Ot" }],
    "familyName": [{ "value": "Jansen" }],
    "birthDate": "1874-11-12",
    "deathDate": "1954-09-24",
    "birthPlace": [{ "uri": null, "name": [{ "value": "Putten" }] }],
    "deathPlace": [{ "uri": null, "name": [{ "value": "Putten" }] }],
    "gender": [{ "uri": "https://schema.org/Male" }],
    "hasOccupation": [
      {
        "occupation": null,
        "roleName": [{ "value": "arbeider" }],
        "startDate": null,
        "endDate": null
      },
      {
        "occupation": null,
        "roleName": [{ "value": "landbouwer" }],
        "startDate": null,
        "endDate": null
      }
    ],
    "nationality": [],
    "parent": [
      {
        "uri": "https://www.openarchieven.nl/id/reconstruction_ac5f0628-d832-42d9-b3a7-5fed2ee40ccf",
        "name": [{ "value": "Aart Jansen" }]
      },
      {
        "uri": "https://www.openarchieven.nl/id/reconstruction_76c58399-9ce7-fbe5-53e0-bd933d9519c5",
        "name": [{ "value": "Jacobje van de Biezen" }]
      }
    ],
    "children": [
      {
        "uri": "https://www.openarchieven.nl/id/reconstruction_476eab10-3849-4618-a327-3b2a6b7e3a05",
        "name": [{ "value": "Jacobje Jansen" }]
      }
    ],
    "spouse": [
      {
        "uri": "https://www.openarchieven.nl/id/reconstruction_0e2beae7-f80e-cba4-be50-518b50fda8f2",
        "name": [{ "value": "Wijmpje Kleijer" }]
      }
    ],
    "sibling": [
      {
        "uri": "https://www.openarchieven.nl/id/reconstruction_d54f9957-a379-423a-a04b-4c5f82a8e315",
        "name": [{ "value": "Barend Jansen" }]
      },
      {
        "uri": "https://www.openarchieven.nl/id/reconstruction_4467c506-f9d9-49c0-8d2b-37eb75cc5d72",
        "name": [{ "value": "Evert Jansen" }]
      }
    ]
  }
}
```

The response is abridged to two of the eight observations in `seeAlso`.

## Person fields

A person is a SKOS concept, so its names are in `prefLabel` and `altLabel` and
its links to other sources in `exactMatch`. What SKOS cannot express is in
`person`:

| Field                                     | Contents                                                                                                         |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `givenName`, `familyName`                 | Name parts; the family name includes its prefix (‘de Vries’)                                                     |
| `birthDate`, `deathDate`                  | [EDTF](https://www.loc.gov/standards/datetime/) string at the known precision: `1919-08-08`, `1872`, `1905/1906` |
| `birthPlace`, `deathPlace`                | Places, each with a `uri`, a `name` or both                                                                      |
| `gender`                                  | `https://schema.org/Male` or `https://schema.org/Female`, without a name                                         |
| `hasOccupation`                           | Occupations as spelled in the source, in `roleName`, or as an `occupation` with an AAT `uri`                     |
| `nationality`                             | Not stated by any dataset yet                                                                                    |
| `parent`, `children`, `spouse`, `sibling` | Persons in the same dataset, to look up by `uri`; also in `related`                                              |

Parse dates with an EDTF library: an interval such as `1905/1906` means the
observations disagree. WO2-personen states a place name and, for some persons, a
WO2 Thesaurus URI without pairing them, so they come back as separate entries.
3110 Open Archieven reconstructions state both genders (counted on 14 October
2026).

`seeAlso` links to the observations, which open the record on the publisher’s
website. Gouda Tijdmachine adds persons in
[Genealogie Online](https://www.genealogieonline.nl) family trees that it
matched with some uncertainty. `hiddenLabel` holds the observation names that
search matches on; show `prefLabel` and `altLabel` to users.

## Differences between datasets

A field the dataset doesn’t state is empty or `null`.

| Field                     | WO2-personen                         | Open Archieven                       | Gouda Tijdmachine                    | Regiotermen Fryslân             |
| ------------------------- | ------------------------------------ | ------------------------------------ | ------------------------------------ | ------------------------------- |
| `prefLabel`               | ✓                                    | Alphabetically first spelling        | ✓                                    | ✓                               |
| `altLabel`                | ✓                                    | Other spellings                      |                                      | ✓                               |
| `hiddenLabel`             | Observation names                    |                                      | Observation names                    |                                 |
| `scopeNote`               |                                      | ✓                                    |                                      |                                 |
| `exactMatch`              | ✓                                    |                                      |                                      | Wikidata, VIAF, NTA, RKDartists |
| `seeAlso`                 | Observations                         | Observations                         | Observations, family trees           | Biographies                     |
| `givenName`, `familyName` | From the observations                | ✓                                    | ✓                                    | ✓                               |
| Dates                     | ✓                                    | ✓                                    | ✓                                    | ✓                               |
| Places                    | Name and WO2 Thesaurus URI, unpaired | Name                                 | GemeenteGeschiedenis URI and name    | GeoNames URI, or name           |
| `gender`                  | ✓                                    | ✓                                    | ✓                                    | ✓                               |
| `hasOccupation`           |                                      | ✓                                    | ✓                                    | AAT URI, or name                |
| Family                    | Parents, children, spouses, siblings | Parents, children, spouses, siblings | Parents, children, spouses, siblings |                                 |

## Deployment

The image is the upstream Network of Terms GraphQL image with the
[Network of Persons catalog](../../packages/network-of-persons-catalog) copied
in. See the [catalog README](../../packages/network-of-persons-catalog/README.md#how-the-catalog-is-deployed).
