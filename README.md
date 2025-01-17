# Download Run Attempt Artifact

Downloads an artifact which was uploaded by workflow in the specified run attempt. This action mirrors the `actions/download-artifact` but additionally supports downloading an artifact from a specific `run-attempt`.

Primarily, this action is useful in scenarios where you are interating with other GitHub Action workflows and want to ensure that multiple steps are consistently downloading artifacts from the exact same run ID and attempt. Most users needs are probably met by using [`actions/download-artifact`](https://github.com/actions/download-artifact) which always downloads from the latest run attempt.

## Limitations

GitHub artifacts from previous run attempts will persist when you re-run a single job or if you use "Re-run failed jobs". Using "Re-run all jobs" however will cause artifacts from previous attempts to be deleted. For more details see: https://github.com/orgs/community/discussions/17854.

## Example

TODO: update

```yaml
---
jobs:
  example:
    # These permissions are needed to:
    # - Get the workflow run: https://github.com/beacon-biosignals/get-workflow-run#permissions
    # - Download the run attempt artifact: https://github.com/beacon-biosignals/download-run-attempt-artifact#permissions
    permissions:
      actions: read
    permissions: {}
    runs-on: ubuntu-latest
    steps:
      # Utilize another action to determine a specific run ID and attempt for consistent
      # access to another workflow.
      - name: Determine latest build
        id: build
        uses: beacon-biosignals/get-workflow-run@v1
        with:
          workflow-file: build.yaml  # Another GHA workflow
          commit-sha: ${{ github.event.pull_request.head.sha || github.sha }}
      - uses: beacon-biosignals/download-run-attempt-artifact@v1
        with:
          run-id: ${{ steps.build.outputs.run-id }}
          run-attempt: ${{ steps.build.outputs.run-attempt }}
          allow-fallback: true
      - name: Show download contents
        run: |
          ls "${{ steps.download-run-attempt.outputs.download-path }}"
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
