# rss-reader

A small Perl CLI that fetches podcast RSS feeds, lists the most recent
unplayed episodes, and lets you mark episodes as rejected or download them
to a local directory. State is persisted in a local SQLite database.

## Features

- Fetches and parses multiple podcast feeds (RSS 2.0 / Atom) in parallel.
- Lists the N most recent undownloaded, unrejected episodes.
- Marks individual episodes as rejected by id.
- Downloads selected episodes with `wget`, into a configurable directory.
- Skips episodes whose title or description matches configurable unwanted
  keywords (defaults: `antipanel`, `reprise`, `trær`, `plante`).
- Auto-refreshes the feed cache at most once every 7 days; force a full
  refresh with `--update`.
- Honors `--dryrun` for all mutating actions.

## Requirements

- Perl 5.38 or newer.
- The CPAN modules listed in `PERL-MODULES.txt`:
  - `Mojo::SQLite`
  - `Mojo::Feed`
  - `XML::DOM`
  - `StreamFinder::Apple`
  - `Archive::Zip`
  - `PPR`
  - `Carp::Always`
  - `Test::Perl::Critic` (test-only)
- A sibling checkout of `utilities-perl` (provides `SH::UseLib` and
  `SH::ScriptX`). The expected layout is:

  ```
  git/
  ├── rss-reader/
  └── utilities-perl/
      └── lib/
          ├── SH/
          │   ├── UseLib.pm
          │   └── ScriptX.pm
          └── Model/
  ```

  The tests use `$FindBin::Bin/../../utilities-perl/lib` to locate it.
- `wget` on `PATH` (for the `--download` action).
- `cpanm` (App::cpanminus) for installing Perl dependencies.

## Install

```bash
# from a parent directory that already contains utilities-perl/
git clone <your-fork-url> rss-reader
cd rss-reader
cpanm --notest --installdeps .   # see PERL-MODULES.txt
prove -l t/                       # verify the install
```

The codebase has no `cpanfile` or `Makefile.PL` yet, so `--installdeps .`
will install everything in `PERL-MODULES.txt` (plus their transitive deps).

## Configuration

`rss-reader.pl` reads a YAML config file:

```
$CONFIG_DIR/rss-reader.yml
# or, if $CONFIG_DIR is unset:
$HOME/etc/rss-reader.yml
```

The only required key is `downloaddir`:

```yaml
downloaddir: /mnt/usb/podcasts
```

The file is parsed with `YAML::Syck`.

## Usage

```bash
# List the 7 most recent undownloaded/unrejected episodes (default).
rss-reader.pl --list

# List 20.
rss-reader.pl --list=20

# Mark two episodes as rejected.
rss-reader.pl --reject=guid1,guid2

# Download two episodes into the configured directory.
rss-reader.pl --download=guid3,guid4

# Override the download directory for a single run.
rss-reader.pl --download=guid5 --downloaddir=/tmp/dl

# Force a full feed refresh (ignore the 7-day window).
rss-reader.pl --update

# Print what would happen without making any changes.
rss-reader.pl --download=guid6 --dryrun
```

You can combine `--update` with `--list`/`--reject`/`--download`.

## State

Runtime data is stored in `data/RSS.db` (a SQLite database). The schema is
in `migrations/tabledefs.sql`:

- `episodes(id, feed, title, description, published_epoch, url, ...)` — one
  row per fetched episode.
- `states_integer(name, value)` — key/value pairs; the tool uses
  `retrieve_episodes_epoch` to track the last successful refresh.

The DB is `.gitignore`d. To start fresh, delete `data/RSS.db` and re-run
with `--update`.

## Tests

```bash
prove -l t/
```

The suite runs 7 test files:

- `t/rss-reader.t` — integration smoke test for the CLI's `--help`.
- `t/RSS.t` — integration test for `Model::RSS` against a temp SQLite DB.
- `t/basic-pod-coverage.t` — every public symbol has POD.
- `t/basic-test-pod.t` — POD structure is valid (NAME, SYNOPSIS, etc.).
- `t/basic-script-compile.t` — every script in `bin/` compiles.
- `t/basic-script-help.t` — every script with a `::ScriptX` base supports
  `--help`.
- `t/perl-critic.t` — Perl::Critic policy gate (uses `~/.perlcriticrc`).

`prove -lv t/` for verbose output.

## Project layout

```
rss-reader/
├── bin/
│   ├── rss-reader.pl          # main CLI
│   ├── apple-url-finder.pl    # ad-hoc Apple podcast inspector
│   └── mp3-tags.pl            # ad-hoc MP3 tag inspector
├── lib/
│   └── Model/
│       └── RSS.pm             # SQLite-backed episode store
├── t/                         # test suite
├── migrations/
│   └── tabledefs.sql          # SQLite schema
├── data/                      # gitignored: runtime SQLite DB
├── old/                       # legacy scripts (kept for history)
├── tryout/                    # scratch experiments
├── PERL-MODULES.txt           # hand-maintained dep list
├── .perlcriticrc              # symlink to ~/.perlcriticrc
├── .perltidyrc                # symlink to ~/.perltidyrc
├── README.md
└── LICENSE
```

## License

MIT — see `LICENSE`.
