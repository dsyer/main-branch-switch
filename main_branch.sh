#!/bin/sh

set -e

if [ "$1" == "--help" ]; then
    cat <<EOF

Create a new branch called main if it doesn't exist and make it the default. Usage:

$ main_branch.sh [--org org] [--base base] --repo repo [--no-protect] [branch]

where

* org is the Github organization (default "heroku")
* base is the name of the existing base branch (default "master")
* repo is the repo name (required)
* branch is the new branch name (default "main")
* with no-protect, branch protections are not migrated

The --* flags are optional, but if you use more than one, they have to be in that order.

EOF
	exit 1
fi

hub --version | grep "hub version 2.14.2"
if [ $? != 0 ]; then
   echo "hub version 2.14.2 required, please 'brew upgrade hub'"
   exit 1
fi

if [ "$1" == "--org" ]; then
	org=$2
	shift
	shift
else
	org="heroku"
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
else
	echo "--repo required"
	exit 1
fi
if [ "$1" == "--no-protect" ]; then
  noprotect="true"
  shift
fi
branch=${1:-main}

function main_branch {
	org=$1
	base=$2
	repo=$3
	branch=$4
	if ! hub api /repos/${org}/${repo}/branches | jq -r '.[].name' | grep -q ${base}; then
		echo No ${base} branch in ${repo}
		return
	fi
	echo Processing ${repo}
	rm -rf tmp
	hub clone ${org}/${repo} tmp
	cd tmp
	(git checkout -b ${branch}; git push origin ${branch} --set-upstream) || git checkout ${branch}
	hub api /repos/${org}/${repo} --field name="${repo}" --field default_branch="${branch}" > /dev/null && echo Changed default branch

	retarget.sh --org ${org} --base ${base} ${repo} ${branch}

	if [ "$noprotect" != "true" ]; then
		branch_protect.sh --org ${org} --base ${base} ${repo} ${branch}
	fi

	git push origin :${base}
}

main_branch ${org} ${base} ${repo} ${branch}
