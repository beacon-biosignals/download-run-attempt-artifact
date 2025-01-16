# Download Run Attempt Artifact

Downloads an artifact which was uploaded by workflow in the specified run attempt. This action mirrors the `actions/download-artifact` but additionally supports downloading an artifact from a specific `run-attempt`.

> Note: GitHub artifacts from previous run attempts will persist when you re-run a single job or if you use "Re-run failed jobs". Using "Re-run all jobs" however will cause artifacts from previous attempts to be deleted. For more details see: https://github.com/orgs/community/discussions/17854.

## Example

```yaml
---
jobs:
  test:
    permissions: {}
    runs-on: ubuntu-latest
    steps:
      - uses: beacon-biosignals/download-run-attempt-artifact@v1
        if: ${{ github.run-attempt > 1 }}
        with:
          run-id: ${{ github.run_id }}
          run-attempt: ${{ github.run_attempt }}
          allow-fallback: true
      - name: Show downloaded run-attempt file
        if: ${{ github.run_attempt > 1 }}
        run: |
          cat run-attempt
      - name: Create run-attempt file
        run: |
          echo "${{ github.run_attempt }}" >run-attempt
      - uses: actions/upload-artifact@v4
        with:
          name: my-artifact
          path: run-attempt
```

## Inputs

| Name                 | Description | Required | Example |
|:---------------------|:------------|:---------|:--------|
| `run-id`             | The workflow run ID where the desired artifact should be downloaded from. | Yes | `9035794515` |
| `run-attempt`        | The workflow run attempt for the given run ID. | Yes | `1` |
| `name`               | The name of the artifact to download. Can use a regex to match multiple artifacts. | Yes | `my-artifact`, `/^my/` |
| `path`               | Destination path. | No | `${{ github.workspace }}` |
| `merge-multiple`     | When multiple artifacts are matched, this changes the behavior of the destination directories. If `true`, the downloaded artifacts will be in the same directory specified by path. If `false`, the downloaded artifacts will be extracted into individual named directories within the specified path. | No | `false` |
| `allow-fallback`     | Allow use of artifacts from previous run attempts if no artifact with the given `name` is present. If falling back is allowed and a workflow run is in progress users may be returned an artifact from a previous run attempt when this run attempt has not yet produced an updated artifact. To avoid this situation be sure to wait for the job which produces this artifact before running this action. | No | `false` |
| `repository`         | The repository which ran the workflow containing the artifact. | No | `${{ github.repository }}` |
| `token`              | The GitHub token used to authenticate with the GitHub API. Need when attempting to access artifacts in a different repository. | No | `${{ github.token }}` |

## Outputs

| Name   | Description | Example |
|:-------|:------------|:--------|
| `download-path` | Absolute path where the artifact(s) were downloaded. | `${{ steps.download.outputs.download-path }}` |

## Permissions

No [job permissions](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs) are required to run this action.
