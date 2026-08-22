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
and a GitHub Actions workflow that uses Homebrew's `test-bot` on Linux, Apple
Silicon, and Intel macOS. Pull requests test changed formulae; pushes, scheduled
runs, and manual runs test every formula. It accepts an empty directory or an
existing tap containing `Formula/`.
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
  example/
    formula.yml
    test.rb
Formula/
```

`gembrew/example/formula.yml` contains the gem metadata and source:

```yaml
gem: example
version: "" # required
source:
  type: rubygems
```

`gembrew/example/test.rb` contains the generated default test:

```ruby
system bin/"example", "--version"
```

Edit these files as needed, then generate `Formula/example.rb`:

```shell
gembrew build
```

Each directory under `gembrew/` describes one formula. Add more published gems with:

```shell
gembrew add another-gem
```

Plain `build` generates every configured formula. Pass a configuration name to
generate just one:

```shell
gembrew build example
```

The required settings in `formula.yml` are `gem`, `version`, and `source`.
The output defaults to `Formula/NAME.rb`, where `NAME` is the configuration
directory name. Relative output paths are resolved from the tap root.

```yaml
gem: example
version: "1.2.3"
source:
  type: rubygems

# Optional gem metadata overrides:
desc: Example command-line application
homepage: https://example.com
license: MIT
executable: example

# Optional additional Homebrew formula dependencies:
dependencies:
  - bash
  - bash :macos_only
  - libffi :system_on_macos

# Optional output override. The default for gembrew/example is shown here.
output: Formula/example.rb
```

Tag a dependency with `:system_on_macos` when macOS provides it and Homebrew
should install its formula only on other platforms. Tag it with `:macos_only`
when Homebrew should install it only on macOS.

You may add these optional Ruby hook files beside `formula.yml`:

```text
install_extra.rb  Runs after the standard gem installation
test.rb           Defines the formula test
```

Gembrew generates a basic `COMMAND --version` test when `test.rb` is absent.
`gembrew init GEM` and `gembrew add GEM` create that test file so it can be
replaced with a meaningful functional test. Gembrew inserts `install_extra.rb`
at the end of the formula's `install` method, after installing the gem and
creating its executable wrapper.

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
brew style gembrew/tap/example
brew audit --new --online gembrew/tap/example
brew install --build-from-source gembrew/tap/example
brew test gembrew/tap/example
brew linkage --test gembrew/tap/example
```

To use a stock, current Homebrew container without mounting the local
repository or changing Homebrew's update, API, or cleanup behavior, open a
pristine shell:

```shell
gembrew shell --pristine
```

Run the complete workflow non-interactively in one clean container:

```shell
gembrew check
```

This rebuilds every configured formula, then runs Homebrew style, online audit,
source installation, the formula test, and linkage validation in disposable
Homebrew containers. Use `gembrew check example` to check only one formula.
Gembrew invokes Docker directly; the tap does not need generated container
support files.

## Contributing / Support

If you experience any issue, have a question or a suggestion, or if you wish
to contribute, feel free to [open an issue][issues].

---

[issues]: https://github.com/DannyBen/gembrew/issues
