#!/usr/bin/env bash

# Copyright 2020 Hewlett Packard Enterprise Development LP

# Add cray-internal repo if not already configured
REPO="$(helm repo list -o yaml | yq r - '(url==http://helmrepo.dev.cray.com:8080*).name')"
if [[ -z "$REPO" ]]; then
    REPO="cray-internal"
    echo >&2 "+ Adding Helm repo: $REPO"
    helm repo add "$REPO" "http://helmrepo.dev.cray.com:8080" >&2
fi

function list-charts() {
    while [[ $# -gt 0 ]]; do
        echo >&2 "$1"
        yq r -j --stripComments "$1" '**.charts' \; \
            | jq -r '. | keys[] as $k | .[$k][] | "\($k)\t\(.)"'
        shift
    done
}

function render-chart() {
    echo >&2 "+ Rendering chart: ${1} ${2}"
    helm template "$1" "${REPO}/${1}" --version "$2"
}

function get-images() {
    yq r -d '*' - 'spec.**.image' | sort -u | grep .
}


ROOTDIR="$(dirname "${BASH_SOURCE[0]}")/.."

export REPO
export -f render-chart get-images
list-charts "$@" | parallel --group -C '\t' render-chart '{1}' '{2}' | get-images
