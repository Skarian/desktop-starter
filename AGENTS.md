# Agent notes

See README.md for building, packaging and releasing.

- Work on a feature branch and open a PR against `main`.
- Before pushing, run `cargo fmt --all --check` and `cargo build --locked`.
- Release only when asked: push a `vX.Y.Z` tag matching the version in `Cargo.toml`. Never move or reuse a published release tag.
