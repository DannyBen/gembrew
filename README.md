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

`init` creates a tap repository containing `README.md`, `gembrew/`, and
`Formula/`. It accepts an empty directory or an existing tap containing
`Formula/`. Supplying a gem name also creates its first configuration. The gem
name is optional, so `gembrew init` can prepare an empty tap or add Gembrew to
an existing one. An existing `README.md` is never overwritten.

For example, `gembrew init example` generates:

```text
README.md
gembrew/
  example.yml
Formula/
```

`gembrew/example.yml` contains:

```yaml
gem: example

test: |-
  system bin/"example", "--version"
```

Edit the configuration as needed, then generate `Formula/example.rb`:

```shell
gembrew build
```

Each YAML file under `gembrew/` describes one formula. Add more published gems
with:

```shell
gembrew add another-gem
```

Plain `build` generates every configured formula. Pass a configuration name to
generate just one:

```shell
gembrew build example
```

The required settings are `gem` and exactly one of `test` or `test_from_file`.
The output defaults to `Formula/NAME.rb`, where `NAME` is the configuration
filename. Relative paths are resolved from the tap root.

```yaml
gem: example

# Optional published gem version. The latest stable version is used by default.
version: "1.2.3"

# Optional repository shown in the generated formula header. An owner/repository
# value refers to GitHub; an HTTPS URL is used unchanged.
repository: owner/homebrew-tap

# Optional gem metadata overrides:
desc: Example command-line application
homepage: https://example.com
license: MIT
executable: example

# Optional output override. The default for gembrew/example.yml is shown here.
output: Formula/example.rb

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

To test a published tap without mounting the local repository, open a pristine
Homebrew shell:

```shell
gembrew shell --pristine
```

Run the complete workflow non-interactively in one clean container:

```shell
gembrew check
```

This rebuilds every configured formula, then runs Homebrew style, online audit,
source installation, and the formula test in disposable Homebrew containers.
Use `gembrew check example` to check only one formula. Gembrew invokes Docker
directly; the tap does not need generated container support files.

## Contributing / Support

If you experience any issue, have a question or a suggestion, or if you wish
to contribute, feel free to [open an issue][issues].

---

[issues]: https://github.com/DannyBen/gembrew/issues
