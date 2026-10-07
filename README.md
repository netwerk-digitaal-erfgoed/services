# NDE Services

The services that make up the [Netwerk Digitaal Erfgoed](https://netwerkdigitaalerfgoed.nl)
platform, deployed on the NDE/SURF Kubernetes infrastructure.

This is an [Nx](https://nx.dev) monorepo using pnpm workspaces:

- **`apps/*`** – deployable services. They are not published to npm.
- **`packages/*`** – libraries that the services share, such as a catalogue that
  more than one image is built from. They are not published either.

## Services

- **Network of Persons** (proof of concept) – search and reconciliation over
  person datasets at <https://personennetwerk.netwerkdigitaalerfgoed.nl>. It
  runs the [Network of Terms](https://github.com/netwerk-digitaal-erfgoed/network-of-terms)
  images with its own catalogue,
  [`packages/network-of-persons-catalog`](packages/network-of-persons-catalog/catalog),
  so it has no code of its own: `apps/network-of-persons-graphql` and
  `apps/network-of-persons-reconciliation` are each a Dockerfile that replaces
  the catalogue in the upstream image.

## Develop

```sh
pnpm install                        # install dependencies (also sets up husky hooks)
pnpm exec nx test <app>             # run one app’s tests
pnpm exec nx run-many -t test       # or: pnpm test — run every app’s tests
```

Common per-app targets: `build`, `test`, `typecheck`, `lint`.

## Validate

Before committing, run the full checks across all apps (this is what CI runs):

```sh
pnpm exec nx run-many -t lint typecheck test build
```

## Add a service

```sh
pnpm exec nx g @nx/node:app apps/<name>
pnpm exec nx g @nx/vitest:configuration --project=@netwerk-digitaal-erfgoed/<name>
pnpm exec nx g @nx/node:setup-docker --project=@netwerk-digitaal-erfgoed/<name>   # optional
```

Tests are configured in a second step because the Node application generator
only offers Jest. Afterwards, in the generated `apps/<name>/vitest.config.mts`,
set `environment: 'node'` (the generator defaults to `jsdom`), and delete the
`vitest.workspace.ts` it may add at the workspace root – the root
`vitest.config.ts` already picks up every project.

## Release

Every push to `main` runs `.github/workflows/release.yml`, which uses
[Nx release](https://nx.dev/features/manage-releases) with conventional commits
to version each app independently and write its changelog and GitHub release.
Nothing is published to npm. An app with a `Dockerfile` and the `release:docker`
tag is built with `@nx/docker` and pushed to
`ghcr.io/netwerk-digitaal-erfgoed/<repositoryName>`, tagged with the release
time and commit (`20261006093739-f911e19`); Flux on the cluster rolls out the
newest tag. A breaking change must be marked with `!` or a `BREAKING CHANGE:`
footer.

To preview a release locally:

```sh
pnpm exec nx release --dry-run
```

## Maintenance

- Dependencies are updated by Dependabot; its pull requests are auto-merged once
  CI passes.
- Nx is bumped as a group (`nx` plus `@nx/*`) by Dependabot, and
  `.github/workflows/nx-migrate.yml` runs `nx migrate` on the resulting pull
  request to add the code migrations Dependabot cannot generate.

Both call the reusable workflows from
[netwerk-digitaal-erfgoed/workflows](https://github.com/netwerk-digitaal-erfgoed/workflows),
which authenticate with the organisation’s GitHub App (`GH_APP_ID` and
`GH_APP_PRIVATE_KEY`).

## Licence

Licensed under the [EUPL 1.2](LICENSE).
