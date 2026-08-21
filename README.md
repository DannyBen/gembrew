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

`init` creates a tap repository containing `README.md`, `gembrew/`, `Formula/`,
and a GitHub Actions workflow that styles, audits, installs, and tests every
formula on Linux and macOS. It accepts an empty directory or an existing tap
containing `Formula/`.
Supplying a gem name also creates its first configuration. The gem name is
optional, so `gembrew init` can prepare an empty tap or add Gembrew to an
existing one. Existing README and workflow files are never overwritten.

For example, `gembrew init example` generates:

```text
README.md
.github/
  workflows/
    test.yml
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

The required settings are `gem`, `version`, `source`, and exactly one of `test`
or `test_from_file`.
The output defaults to `Formula/NAME.rb`, where `NAME` is the configuration
filename. Relative paths are resolved from the tap root.

```yaml
gem: example
version: "1.2.3"
source:
  type: gem

# Optional gem metadata overrides:
desc: Example command-line application
homepage: https://example.com
license: MIT
executable: example

# Optional additional Homebrew formula dependencies:
dependencies:
  - bash

# Optional output override. The default for gembrew/example.yml is shown here.
output: Formula/example.rb

test: |-
  system bin/"example", "--version"

# Use this instead of `test` to load the test body from another file:
# test_from_file: support/test.rb
```

To build the root gem from a GitHub tag while continuing to fetch its
dependencies from RubyGems, use:

```yaml
source:
  type: github
  repo: owner/repository
  # tag: v1.2.3
  # gemspec: example.gemspec
```

The tag defaults to `vVERSION`; the gemspec path defaults to
`GEMNAME.gemspec`.

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
