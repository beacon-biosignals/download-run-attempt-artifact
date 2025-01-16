#!/usr/bin/env bash

set -eo pipefail

function unwrap_regex() {
    param="${1:?}"
    if [[ "${param}" == /*/ ]]; then
        # shellcheck disable=SC2001
        sed 's|^/\(.*\)/$|\1|' <<<"${param}"
    fi
}

function jqe_artifacts_from_name() {
    artifact_name="${1:?}"
    artifact_name_regex="$(unwrap_regex "${artifact_name}")"
    if [[ -n "${artifact_name_regex}" ]]; then
        echo "map(select(.name | test(\"${artifact_name_regex//\\/\\\\}\")))"
    else
        echo "map(select(.name == \"${artifact_name//\\/\\\\}\"))"
    fi
}

path="${path:-.}"
allow_fallback="${allow_fallback:-false}"
merge_multiple="${merge_multiple:-false}"

echo "path=$path" >&2

# Determine the timeframe of the workflow run attempt.
run_timeframe="$(gh api -X GET --paginate "/repos/{owner}/{repo}/actions/runs/${run_id:?}/attempts/${run_attempt:?}/jobs" --jq '
    .jobs | {
        created_at: map(.created_at | select(. != null)) | min,  # Earliest non-null datetime (may be null if all entries null).
        completed_at: map(.completed_at) | (if all(. != null) then max else null end)  # Latest completed datetime or null if run is in progress.
    }')"
run_created_at="$(jq -r '.created_at' <<<"${run_timeframe}")"
run_completed_at="$(jq -r '.completed_at' <<<"${run_timeframe}")"

echo "Workflow run created at $run_created_at and completed at $run_completed_at" >&2

if [[ -z "$run_created_at" ]]; then
    echo "Workflow run has not started. Unable to determine the time frame associated with this run attempt." >&2
    exit 1
fi

# Arifacts for all workflow attempts are listed. In order to determine the artifacts
# generated for a specific run attempt we can only select the artifacts created during the
# timeframe of the run attempt. As GitHub disallows performing multiple re-runs
# concurrently this is a reasonable approximation.
#
# Additionally, since a re-run may only produce a subset of the artifacts it would normally
# generate we'll support falling back on using artifacts from prior run attempts. If a
# workflow run is "in_progress" we may end up falling back on using an artifact from a
# previous if the the running workflow has not yet created the artifact.
#
# https://docs.github.com/en/rest/actions/artifacts?apiVersion=2022-11-28#list-workflow-run-artifacts
artifacts="$(gh api -X GET "/repos/{owner}/{repo}/actions/runs/${run_id:?}/artifacts" --jq '.artifacts')"
if [[ -n "$run_completed_at" ]]; then
    artifacts="$(jq "map(select(.created_at <= \"${run_completed_at}\"))" <<<"${artifacts}")"
fi

if [[ "${allow_fallback}" == "true" ]]; then
    artifacts="$(jq "sort_by(.created_at) | reverse | unique_by(.name)" <<<"$artifacts")"
else
    artifacts="$(jq "map(select(.created_at >= \"${run_created_at}\"))" <<<"$artifacts")"
fi

# Optionally filter the list of artifacts by an exact name or a regex.
if [[ -n "${name}" ]]; then
    artifacts="$(jq -r "$(jqe_artifacts_from_name "${name:?}")" <<<"${artifacts}")"
    if [[ "$(jq -er 'length' <<<"${artifacts}")" -eq 0 ]]; then
        echo "Unable to locate artifact(s) using name \"${name}\"" >&2
        exit 1
    fi
fi

if [[ "$(jq -er 'length' <<<"${artifacts}")" -gt 1 ]]; then
    multiple_artifacts="true"
else
    multiple_artifacts="false"
fi

while read -r artifact; do
    artifact_id="$(jq -er '.id' <<<"$artifact")"
    artifact_name="$(jq -er '.name' <<<"$artifact")"

    echo "Downloading artifact: ${artifact_name} (${artifact_id})" >&2

    if [[ "${multiple_artifacts}" == "true" && "${merge_multiple}" != "true" ]]; then
        dest_dir="${path}/${artifact_name}"
        mkdir "${dest_dir}"
    else
        dest_dir="${path}"
    fi

    # https://docs.github.com/en/rest/actions/artifacts?apiVersion=2022-11-28#download-an-artifact
    gh api -X GET "/repos/{owner}/{repo}/actions/artifacts/${artifact_id}/zip" >"/tmp/${artifact_name}.zip"
    unzip -o "/tmp/${artifact_name}.zip" -d "${dest_dir}"
    rm "/tmp/${artifact_name}.zip"
done < <(jq -c '.[]' <<<"${artifacts:?}")

echo "download-path=$(realpath "$path")" >>"$GITHUB_OUTPUT"
