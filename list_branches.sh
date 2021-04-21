#!/bin/bash

set -e

if [ $# -lt 2 ]; then
    cat <<EOF

List the default branch for github repos. Usage:

$ list_branches.sh [--org org] [--format txt]

where

* org is the Github organization (default user's own org)
* fmt is the output format (json, txt or csv), default to txt

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
if [ "$1" == "--format" ]; then
	fmt=$2
	shift
	shift
else
	fmt=txt
fi

json=`hub api --obey-ratelimit --paginate /users/${org}/repos | sed -e '/^]/ {N; s/]\n\[/,/g;}' | jq -r '.[] | select(.fork!=true) | select(.archived!=true)' | jq -s '[.[] | {name: .name, branch: .default_branch}]'`
if [ "${fmt}" == "csv" ]; then 
	echo 'repo,branch';
	echo $json | jq -r '.[] | [.name,.branch] | @csv'
elif [ "${fmt}" == "txt" ]; then
	echo $json | jq -r '.[] | [.branch,.name] | join(" ")' | sort
else
	echo $json
fi
