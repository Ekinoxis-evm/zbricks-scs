# Skill: CI/CD with GitHub Actions

> Automated testing and quality gates on every push and PR.

## Workflow File

`.github/workflows/test.yml`

```yaml
name: test

on:
  push:
  pull_request:
  workflow_dispatch:

env:
  FOUNDRY_PROFILE: ci

jobs:
  check:
    strategy:
      fail-fast: true
    name: Foundry project
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
        with:
          version: nightly

      - name: Show Forge version
        run: forge --version

      - name: Run Forge fmt
        run: forge fmt --check
        id: fmt

      - name: Run Forge build
        run: forge build --sizes
        id: build

      - name: Run Forge tests
        run: forge test -vvv
        id: test
```

## Quality Gates

| Gate | Command | What It Checks |
|------|---------|----------------|
| Formatting | `forge fmt --check` | All .sol files follow standard formatting |
| Build | `forge build --sizes` | Contracts compile, none exceed 24KB |
| Tests | `forge test -vvv` | All unit tests pass |

## When It Runs

- **Push**: Every commit to any branch
- **Pull Request**: Every PR opened or updated
- **Manual**: `workflow_dispatch` allows manual trigger from GitHub UI

## CI Profile

The `FOUNDRY_PROFILE: ci` env var tells Foundry to use `[profile.ci]` settings from `foundry.toml` if defined. Falls back to `[profile.default]`.

## Adding More Gates (Future)

```yaml
# Gas snapshot comparison
- name: Gas snapshot
  run: forge snapshot --check

# Coverage threshold
- name: Coverage
  run: |
    forge coverage --report summary
    # Could fail if below threshold

# Slither static analysis
- name: Slither
  uses: crytic/slither-action@v0.4.0
  with:
    sarif: results.sarif
```

## Branch Protection (Recommended)

In GitHub repo settings → Branches → Add rule for `main`:
- Require status checks to pass: `check`
- Require branches to be up to date
- Require PR reviews before merge
