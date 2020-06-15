#!/bin/sh

set -e

if [ "$1" == "--help" ]; then
    cat <<EOF

Create a new branch called main if it doesn't exist and make it the deafult. Usage:

$ main_branch.sh [--org org] [--repo repo] [branch]

where

* org is the Github organization (default user's own org)
* repo is the repo name (default all)
* branch is the new branch name (default "main")

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
if [ "$1" == "--repo" ]; then
	repo=$2
	shift
	shift
fi
branch=${1:-main}

function main_branch {
	org=$1
	repo=$2
	branch=$3
	if ! hub api /repos/${org}/${repo}/branches | jq -r '.[].name' | grep -q master; then
		echo No master branch in ${repo}
		return
	fi
	echo Processing ${repo}
	rm -rf tmp
	hub clone ${org}/${repo} tmp
	cd tmp
	(git checkout -b ${branch}; git push origin ${branch} --set-upstream) || git checkout ${branch}
	hub api /repos/${org}/${repo} --field name="${repo}" --field default_branch="${branch}" > /dev/null && echo Changed default branch
	retarget.sh --org ${org} ${repo} ${branch}
	git push origin :master
}

if [ -z ${repo} ]; then
	for repo in `hub api --obey-ratelimit --paginate /users/${org}/repos | sed '/^\]/ {N; s/\]\n\[/,/g}' | jq -r '.[] | select(.fork!=true) | .name'`; do
		main_branch ${org} ${repo} ${branch}
	done
else
	main_branch ${org} ${repo} ${branch}
fi
