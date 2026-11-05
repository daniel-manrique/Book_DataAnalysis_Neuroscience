# Data Analysis for Neuroscientists

A Quarto book on data analysis and statistical modeling for neuroscientists, with `brms` (Bayesian) and a frequentist counterpart side by side. The workflow notes below come from the Quarto template this project started from.

## Workflow

The book is rendered and deployed to Netlify via a [GitHub action](.github/workflows/build-book.yaml). Changes to the `main` branch trigger a deployment to the published site. Pull requests trigger a deployment preview.

Substantive changes are proposed using pull requests. 

The book project sets [`freeze` to `auto`](https://github.com/mine-cetinkaya-rundel/quarto-tdg/blob/c7f98329338d86c86580ccc81dd424283850cb7c/_quarto.yml#L69-L70), so when you propose changes you should:

1. Locally render the book
2. Examine the git diff for changes to `_freeze/`, and commit changes to relevant files.

Since the GitHub action that renders the book does not execute any code, forgetting to commit to `_freeze` will result in a failed check on the PR.

### Cached `brms` fits (`models/*.rds`)

The fits are too large for GitHub (214 files, about 2 GB), so they are **not in git**. The web edition does not need them: chapters are restored from `_freeze/`, which is committed. They are archived on Zenodo for anyone who wants to re-execute a chapter.

- To get them back: `Rscript scripts/fetch-models.R` (everything) or `Rscript scripts/fetch-models.R count-regression` (one chapter). It checks every file against `models/MANIFEST.csv`. The Zenodo record id is in `scripts/models-source.txt`.
- To publish a new version of the archive: `Rscript scripts/models-pack.R` rewrites `models/MANIFEST.csv` and writes one `.tar` per chapter to `models-archive/` (ignored by git); upload those to a new version of the Zenodo record, update `record:` in `scripts/models-source.txt`, and commit the manifest.
- Never commit `models/*.rds`.

### Reproducing the R environment locally

The R environment is managed with [renv](https://rstudio.github.io/renv/articles/renv.html). This should work automatically when opening the book project, and you'll be prompted by renv to get the required packages with `renv::restore()`.

If your contribution adds a dependency on an R package, make sure you run `renv::snapshot()`, and commit changes to `renv.lock`.

### Reproducing the python environment locally

#### Creating or recreating the environment

Use Python 3.12.

Create a virtual environment in the `env/` folder, in Terminal:

```{.bash}
python3 -m venv env
```

Activate the environment:

```bash
source env/bin/activate
```

Install packages from `requirements.txt`:

```bash
python3 -m pip install -r requirements.txt
```

#### Using the environment

VS Code + Python extension should pick up this environment automatically. 

Or on Terminal, activate the environment:

```bash
source env/bin/activate
```

#### Adding python packages

1. Activate the environment
2. Install the additional packages using `pip`
3. Update `requirements.txt`
    ```
    python3 -m pip freeze > requirements.txt
    ```
4. Commit `requirements.txt`
