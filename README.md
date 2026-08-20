# Gembrew

![repocard](https://repocard.dannyben.com/svg/gembrew.svg)

Generate conventional Homebrew formulae for published Ruby command-line gems.

## Install

```shell
gem install gembrew
```

## Usage

```shell
mkdir homebrew-tap
cd homebrew-tap
gembrew init GEM
gembrew build
gembrew check
```

`init` requires an empty directory, with the exception of Git's `.git`
directory. It creates a tap repository containing `gembrew.yml`, `Formula/`,
and a Docker Compose environment under `support/`. `build` reads the
configuration and writes the formula.

The configuration filename is always `gembrew.yml`.

For example, `gembrew init example` generates:

```yaml
gem: example
output: Formula/example.rb

test: |-
  system bin/"example", "--version"
```

Edit `gembrew.yml` as needed, then generate the formula:

```shell
gembrew build
```

The required settings are `gem`, `output`, and exactly one of `test` or
`test_from_file`. Relative paths are resolved from `gembrew.yml`.

```yaml
gem: example
output: Formula/example.rb

# Optional published gem version. The latest stable version is used by default.
version: "1.2.3"

# Optional gem metadata overrides:
desc: Example command-line application
homepage: https://example.com
license: MIT
executable: example

test: |-
  system bin/"example", "--version"

# Use this instead of `test` to load the test body from another file:
# test_from_file: support/test.rb
```

Gembrew resolves the generic Ruby dependency graph and generates a Homebrew
`resource` for every runtime dependency. Original `.gem` archives are reused
from RubyGems' local cache when available. Downloaded archives are retained in
`${XDG_CACHE_HOME:-~/.cache}/gembrew/gems`.

Open the generated Homebrew environment with:

```shell
gembrew shell
```

The repository is mounted as a local tap, so formulae can be addressed by gem
name inside the shell:

```shell
brew style example
brew audit --new --online example
brew install --build-from-source example
brew test example
```

Run the complete workflow non-interactively in one clean container:

```shell
gembrew check
```

This rebuilds the formula, then runs Homebrew style, online audit, source
installation, and the formula test. The generated Compose `check` service can
also be invoked directly.

## Contributing / Support

If you experience any issue, have a question or a suggestion, or if you wish
to contribute, feel free to [open an issue][issues].

---

[issues]: https://github.com/DannyBen/gembrew/issues
