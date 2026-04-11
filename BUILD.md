# Building the Documentation

The documentation site is built with [MkDocs](https://www.mkdocs.org/) using the [Material theme](https://squidfunk.github.io/mkdocs-material/).

## Prerequisites

You need the following Python packages:

- `mkdocs` ≥ 1.5.0
- `mkdocs-material` ≥ 9.0.0
- `mkdocs-awesome-nav` ≥ 0.3.0

These are listed in `requirements.txt`.

---

## Option 1: Nix (recommended)

A `flake.nix` is provided that supplies a development shell with all required packages.

### Enter the development shell

```sh
nix develop
```

This drops you into a shell with `mkdocs` and all required plugins available.

### Build the site

```sh
mkdocs build
```

The built site is written to `site/`.

### Serve locally with live reload

```sh
mkdocs serve
```

The site is served at `http://127.0.0.1:8000` and rebuilds automatically when source files change.

---

## Option 2: pip

If you are not using Nix, install dependencies via pip (preferably inside a virtual environment):

```sh
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Then build or serve as above:

```sh
mkdocs build
mkdocs serve
```

---

## Deployment

The site is published automatically to GitHub Pages via the GitHub Actions workflow on every push to the default branch. To deploy manually:

```sh
mkdocs gh-deploy
```
