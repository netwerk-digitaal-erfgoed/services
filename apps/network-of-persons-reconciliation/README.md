# Network of Persons reconciliation service

Use the Network of Persons reconciliation service to **match a column of names
in your data to persons** in one of the
[datasets](../network-of-persons-graphql/README.md#datasets), typically in
[OpenRefine](https://openrefine.org). This is the
[Network of Terms Reconciliation API](https://docs.nde.nl/services/network-of-terms/reconciliation)
over person datasets: version 0.2 of the Reconciliation Service API, with the
same [language selection](https://docs.nde.nl/services/network-of-terms/reconciliation#language-selection).

> [!WARNING]
> The Network of Persons is a proof of concept. Its URL, datasets and data
> may change or disappear without notice. Do not build production integrations
> on it.

## Endpoints

Each dataset has its own reconciliation endpoint:

| Dataset                               | Endpoint                                                                                                              |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| WO2-personen                          | `https://personennetwerk.netwerkdigitaalerfgoed.nl/reconcile/https://data.niod.nl/WO2_personen`                       |
| Open Archieven Persoonsreconstructies | `https://personennetwerk.netwerkdigitaalerfgoed.nl/reconcile/https://www.openarchieven.nl/id/dataset_reconstructions` |
| Gouda Tijdmachine                     | `https://personennetwerk.netwerkdigitaalerfgoed.nl/reconcile/https://n2t.net/ark:/60537/bD64Hu`                       |

## Using the API from OpenRefine

Add an endpoint as a standard service and reconcile against the Person type
(`https://schema.org/Person`), which OpenRefine suggests, as described in
[Using the API from OpenRefine](https://docs.nde.nl/services/network-of-terms/reconciliation#using-the-api-from-openrefine).
Every person in these datasets is of that type.

Each candidate shows the person’s name, with the birth and death dates and the
other names in its description, so you can tell namesakes apart:

```bash
curl -X POST \
  -d 'queries={"q0":{"query":"Anne Frank"}}' \
  https://personennetwerk.netwerkdigitaalerfgoed.nl/reconcile/https://data.niod.nl/WO2_personen
```

```json
{
  "q0": {
    "result": [
      {
        "id": "https://n2t.net/ark:/59857/p4c489be0-a81c-474d-ad39-9bbca476a5e0",
        "name": "Annelies Marie Frank",
        "score": 100,
        "description": "1929-06-12 – 1945-03-31 • Anne Frank"
      }
    ]
  }
}
```

To tell every ‘Jan de Vries’ apart, send values from other columns along, such
as a birth date, birthplace or parent: the candidates whose values match rank
first, and a single candidate that matches on everything is matched
automatically. See
[Matching persons on more than their name](https://docs.nde.nl/services/network-of-terms/reconciliation#matching-persons-on-more-than-their-name).
Hover over a candidate for its preview, with the dates, places, occupations and
family members that set namesakes apart.

Names are matched as whole words, with the same QLever limitations as a
[GraphQL search](../network-of-persons-graphql/README.md#search-persons): a cell
with ‘Zwanenveld, Dirk’ finds nothing until you remove the comma.

## Adding columns from reconciled persons

Once a column is reconciled, choose **Edit column → Add columns from reconciled
values…** to fetch what the dataset states about each person:

| Property                                     | Values                                                            |
| -------------------------------------------- | ----------------------------------------------------------------- |
| `prefLabels`, `altLabels`                    | Names                                                             |
| `givenNames`, `familyNames`                  | Parts of the name                                                 |
| `scopeNotes`                                 | Descriptions, where the dataset has them                          |
| `birthDates`, `deathDates`                   | Dates, as [EDTF](https://www.loc.gov/standards/datetime/) strings |
| `birthPlaces`, `deathPlaces`                 | Place names, and for WO2-personen also WO2 Thesaurus URIs         |
| `genders`                                    | `https://schema.org/Male` or `https://schema.org/Female`          |
| `occupations`                                | Occupation names                                                  |
| `parents`, `children`, `spouses`, `siblings` | Family members, as persons reconciled in the same dataset         |
| `relatedTerms`                               | Family members, whatever the relation, except for WO2-personen    |
| `exactMatches`                               | The same person in other datasets, for WO2-personen               |
| `seeAlso`                                    | Web pages of the records the person was reconstructed from        |

A family member column is reconciled against Person too, so you can add its
properties in turn, such as the birth dates of each person’s parents. For what
each dataset states, see
[Differences between datasets](../network-of-persons-graphql/README.md#differences-between-datasets).

## Deployment

The image is the upstream Network of Terms reconciliation image with the
[Network of Persons catalog](../../packages/network-of-persons-catalog) copied
in. See the [catalog README](../../packages/network-of-persons-catalog/README.md#how-the-catalogue-is-deployed).
