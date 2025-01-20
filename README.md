# Download Run Attempt Artifact

Downloads an artifact which was uploaded by workflow in the specified run attempt. This action mirrors the `actions/download-artifact` but additionally supports downloading an artifact from a specific `run-attempt`.

Primarily, this action is useful in scenarios where you are interating with other GitHub Action workflows and want to ensure that multiple steps are consistently downloading artifacts from the exact same run ID and attempt. Most users needs are probably met by using [`actions/download-artifact`](https://github.com/actions/download-artifact) which always downloads from the latest run attempt.

## Limitations

GitHub artifacts from previous run attempts will persist when you re-run a single job or if you use "Re-run failed jobs". Using "Re-run all jobs" however will cause artifacts from previous attempts to be deleted. For more details see: https://github.com/orgs/community/discussions/17854.

## Example

```yaml
---
name: Generate Report
on:
  workflow_dispatch:
    inputs:
      run-id:
        description: Numeric ID for the GHA workflow run.
        type: string
        required: true
      run-attempt:
        description: Attempt number for the provided `run-id`.
        type: string
        required: true
jobs:
  example:
    # These permissions are needed to:
    # - Download the run attempt artifact: https://github.com/beacon-biosignals/download-run-attempt-artifact#permissions
    permissions:
      actions: read
    permissions: {}
    runs-on: ubuntu-latest
    steps:
      - uses: beacon-biosignals/download-run-attempt-artifact@v1
        id: download-run-attempt
        with:
          run-id: ${{ inputs.run-id }}
          run-attempt: ${{ inputs.run-attempt }}
          allow-fallback: true  # Re-running an single job may require us to fetch the artifact from a previous attempt
      - name: Show artifact contents
        run: |
          ls -la "${{ steps.download-run-attempt.outputs.download-path }}"
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

The following [job permissions](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs) are required to run this action:

```yaml
permissions:
  actions: read
```
