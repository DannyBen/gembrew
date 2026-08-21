# Homebrew Tap

<!-- Replace OWNER/TAP with your Homebrew tap name, for example dannyben/tools. -->

## Install

```shell
brew tap OWNER/TAP
brew install example
```

Or install the formula directly:

```shell
brew install OWNER/TAP/example
```

## Development

Install [Gembrew](https://github.com/DannyBen/gembrew):

```shell
gem install gembrew
```

The generated GitHub Actions workflow uses Homebrew's `test-bot` on Linux,
Apple Silicon, and Intel macOS. Pull requests test changed formulae; pushes,
scheduled runs, and manual runs test every formula.

Generate all formulae:

```shell
gembrew build
```

Generate or check one formula:

```shell
gembrew build example
gembrew check example
```

Check every formula:

```shell
gembrew check
```

Add another Ruby gem:

```shell
gembrew add another-gem
```

Open an interactive Homebrew environment:

```shell
gembrew shell
```
