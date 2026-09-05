# Tests

Install [Bats](https://bats-core.readthedocs.io/en/stable/installation.html)
with `brew install bats-core` on macOS or `sudo apt-get install bats` on Debian
and Ubuntu. Then run all tests from the repository root:

```sh
bats test
```

To run only the signing tests:

```sh
bats test/git-sign-branch.bats
```

The tests require Bash, Zsh, Git 2.38 or later, and OpenSSH with SSH signing
support. Each test uses a separate temporary directory. The signing tests create
temporary repositories and SSH keys. They do not use your Git settings or keys.
Bats removes the temporary files after the tests.

Keep test files, helpers, and fixtures in this directory. These files belong in
Git; do not add `test/` to `.gitignore`. Setup excludes this directory, and Bash
and Zsh do not load its aliases, configuration files, or completion files.
`discovery.bats` checks these exclusions with temporary fixtures.
