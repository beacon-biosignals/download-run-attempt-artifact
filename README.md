# Download Run Attempt Artifact

Downloads an artifact which was uploaded by workflow in the specified run attempt. This
action mirrors the `actions/download-artifact` but additionally supports downloading an
artifact from a specific `run-attempt`.

## Example

```yaml
---
jobs:
  test:
    # These permissions are needed to:
    # - Downloading a GHA artifact: 
    permissions:
      actions: read
    runs-on: ubuntu-latest
    steps:
      - uses: beacon-biosignals/download-run-attempt-artifact@v1
        with:
          name: my-artifact
          run-id:
          run-attempt: 
```

## Inputs

| Name                 | Description | Required | Example |
|:---------------------|:------------|:---------|:--------|
| `run-id`             | The workflow run ID where the desired artifact should be downloaded from. | Yes | `1536140711` |
| `run-attempt`        | The workflow run attempt for the given run ID. | Yes | `1` |
| `name`               | The name of the artifact to download. Can use a regex to match multiple artifacts. | Yes | `my-artifact`, `/^my/` |
| `path`               | Destination path. Defaults to `${{ github.workspace }}`. | No | `./artifact` |
| `merge-multiple`     | When multiple artifacts are matched, this changes the behavior of the destination directories. If `true`, the downloaded artifacts will be in the same directory specified by path. If `false`, the downloaded artifacts will be extracted into individual named directories within the specified path. Defaults to `false`. | Yes | `false` |
| `allow-fallback`     | Allow use of artifacts from previous run attempts if no artifact with the given `name` is present. If falling back is allowed and a workflow run is in progress users may be returned an artifact from a previous run attempt when this run attempt has not yet produced an updated artifact. To avoid this situation be sure to wait for the job which produces this artifact before running this action. Defaults to `false`. | Yes | `false` |
| `repository`         | The repository which ran the workflow containing the artifact. Defaults to `${{ github.repository }}`. | Yes | `beacon-biosignals/download-run-attempt-artifact` |
| `token`              | The GitHub token used to authenticate with the GitHub API. Need when attempting to access artifacts in a different repository. Defaults to `${{ github.token }}`. | Yes | `${{ secrets.MY_SECRET_TOKEN }}` |

## Outputs

| Name   | Description | Example |
|:-------|:------------|:--------|
| `download-path` | Absolute path where the artifact(s) were downloaded. | `/tmp/my/download/path` |

## Permissions

The follow [job permissions](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs) are required to run this action:

```yaml
permissions:
  actions: read
```
