---
runpage:
  required: [version]
  dependencies: [git, gem, curl]
  workdir: self
---

# Gembrew release checklist

Release verification for Gembrew. Run this document with
[runpage](https://github.com/DannyBen/runpage):

```console :noop
runpage release.md version:0.1.0
```

## Git is on master and clean

```bash :check
test "$(git branch --show-current)" = master && test -z "$(git status --porcelain)"
```

## Code version

```bash :check
grep -Fq "VERSION = '{{ version }}'" lib/gembrew/version.rb
```

## Local gem is installed

```bash :check
gem list --local --exact gembrew --installed --version "{{ version }}" >/dev/null
```

## Published gem version

```bash :check
curl -fsS -o /dev/null "https://rubygems.org/gems/gembrew/versions/{{ version }}"
```

## Local Git tag

```bash :check
git rev-parse --quiet --verify "refs/tags/v{{ version }}" >/dev/null
```

## Changelog

```bash :check
grep -Fq "v{{ version }} -" CHANGELOG.md
```

## GitHub tag

```bash :check
curl -fsS -o /dev/null "https://github.com/dannyben/gembrew/tree/v{{ version }}"
```

## GitHub release

```bash :check
location=$(
  curl -fsSI https://github.com/dannyben/gembrew/releases/latest |
    tr -d '\r' |
    awk 'tolower($1) == "location:" { print $2 }' |
    tail -n 1
)
test "$location" = "https://github.com/dannyben/gembrew/releases/tag/v{{ version }}"
```
