#!/bin/bash

set -e

if [ "$1" == "--help" ]; then
    cat <<EOF

Create a new branch called main if it doesn't exist and make it the default. Usage:

$ rename_master.sh [--org org] [--base base] [--repo repo] [branch]

where

* org is the Github organization (default user's own org)
* base is the name of the existing base branch (default "master")
* repo is the repo name (default all)
* branch is the new branch name (default "main")

The --* flags are optional, but if you use more than one, they have to be in that order.

EOF
	exit 1
fi

if [ "$1" == "--org" ]; then
	org=$2
	shift
	shift
else
	org=`hub api /user | jq -r '.login'`
fi
if [ "$1" == "--base" ]; then
	base=$2
	shift
	shift
else
	base=master
fi
if [ "$1" == "--repo" ]; then
	repo=$2
	shift
	shift
fi

branch=${1:-main}

function rename_master {
	org=$1
	base=$2
	repo=$3
	branch=$4
	if ! hub api /repos/${org}/${repo}/branches | jq -r '.[].name' | grep -q ${base}; then
		echo No ${base} branch in ${repo}
		return
	fi
	echo Processing ${repo}
	hub api /repos/${org}/${repo}/branches/${base}/rename --field new_name=${branch} > /dev/null && echo Changed default branch
}

if [ -z ${repo} ]; then
	for repo in `hub api --obey-ratelimit --paginate /users/${org}/repos | sed -e '/^]/ {N; s/]\n\[/,/g;}' | jq -r '.[] | select(.fork!=true) | .name'`; do
		rename_master ${org} ${base} ${repo} ${branch}
	done
else
	rename_master ${org} ${base} ${repo} ${branch}
fi
