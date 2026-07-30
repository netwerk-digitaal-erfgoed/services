# NDE Services

The services that make up the [Netwerk Digitaal Erfgoed](https://netwerkdigitaalerfgoed.nl)
platform, deployed on the NDE/SURF Kubernetes infrastructure.

This is an [Nx](https://nx.dev) monorepo using pnpm workspaces:

- **`apps/*`** – deployable services. They are not published to npm.

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
Nothing is published to npm; releases exist to track what gets deployed. A
breaking change must be marked with `!` or a `BREAKING CHANGE:` footer.

To preview a release locally:

```sh
pnpm exec nx release --dry-run
```

## Maintenance

- Nx itself is upgraded by the nightly `.github/workflows/nx-migrate.yml`
  workflow, which runs `nx migrate latest` and opens a pull request.
- Other dependencies are updated by Dependabot; its pull requests are
  auto-merged once CI passes.

## Licence

Licensed under the [EUPL 1.2](LICENSE).
