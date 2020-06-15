#!/bin/sh

set -e

if [ $# -lt 2 ]; then
    cat <<EOF

Re-target pull request(s) onto a new branch. Usage:

$ retarget.sh [--org org] [--base base] repo branch [pr]

where

* org is the Github organization (default user's own org)
* base is the name of the base branch to filter on (default "master")
* repo is the repo name
* branch is the new branch name
* pr is the pull request number (default to all open)

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
repo=$1; shift
branch=$1; shift
pr=$1

function retarget {
	org=$1
	base=$2
	repo=$3
	branch=$4
	pr=$5
	actual=`hub api /repos/${org}/${repo}/pulls/${pr} | jq -r '.base.ref'`
	if [ "${actual}" == "${base}" ]; then
		hub api /repos/${org}/${repo}/pulls/${pr} --field base=$branch > /dev/null && echo Changed target branch of PR ${pr}
	else
		echo PR ${pr} is based on ${actual} \(not ${base}\)
	fi
}

if [ -z ${pr} ]; then
	for pr in `hub api --obey-ratelimit --paginate /repos/${org}/${repo}/pulls | sed -e '/^]/ {N; s/]\n\[/,/g;}' | jq '.[].number'`; do
		retarget ${org} ${base} ${repo} ${branch} ${pr}
	done
else
	retarget ${org} ${base} ${repo} ${branch} ${pr}
fi
