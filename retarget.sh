#!/bin/sh

set -e

if [ $# -lt 2 ]; then
    cat <<EOF

Re-target pull request(s) onto a new branch. Usage:

$ retarget.sh [--org org] repo branch [pr]

where

* org is the Github organization (default user's own org)
* repo is the repo name
* branch is the new branch name
* pr is the pull request number (default to all open)

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
repo=$1; shift
branch=$1; shift
pr=$1

function retarget {
	org=$1
	repo=$2
	branch=$3
	pr=$4
	hub api /repos/${org}/${repo}/pulls/${pr} --field base=$branch > /dev/null && echo Changed target branch of PR ${pr}
}

if [ -z ${pr} ]; then
	for pr in `hub api --obey-ratelimit --paginate /repos/${org}/${repo}/pulls | sed '/^\]/ {N; s/\]\n\[/,/g}' | jq '.[].number'`; do
		retarget ${org} ${repo} ${branch} ${pr}
	done
else
	retarget ${org} ${repo} ${branch} ${pr}
fi
