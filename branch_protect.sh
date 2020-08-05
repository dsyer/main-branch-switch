#!/bin/sh

set -e

if [ $# -lt 2 ]; then
    cat <<EOF

Update branch protections to protect the new branch. Usage:

$ branch_protections.sh [--org org] [--base base] repo branch [pr]

where

* org is the Github organization (default user's own org)
* base is the name of the base branch to filter on (default "master")
* repo is the repo name
* branch is the new branch name

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

function update_branch_protections {
	org=$1
	base=$2
	repo=$3
	branch=$4
  file=$5

  if jq -e '.message' < "$file" 2> /dev/null; then
      echo "${base} branch does not exist."
  else
     jq '{
  required_status_checks: {
    strict: .required_status_checks.strict,
    contexts: .required_status_checks.contexts
  },
  enforce_admins: .enforce_admins.enabled,
  required_pull_request_reviews: {
    dismissal_restrictions: {
      users: (.required_pull_request_reviews.dismissal_restrictions.users  | if . then map(.login) else [] end),
      teams: (.required_pull_request_reviews.dismissal_restrictions.teams  | if . then map(.slug) else [] end)
    },
    dismiss_stale_reviews: (.required_pull_request_reviews.dismiss_stale_reviews | if . then true else false end),
    require_code_owner_reviews: (.required_pull_request_reviews.require_code_owner_reviews  | if . then true else false end),
    required_approving_review_count: (if .required_approving_review_count then .required_approving_review_count else 1 end)
  },
  restrictions: {
    users: (.restrictions.users | if . then map(.login) else [] end),
    teams:(.restrictions.teams | if . then map(.slug) else [] end),
    apps: (.restrictions.apps | if . then map(.slug) else [] end)
  },
  required_linear_history: (.required_linear_history.enabled | if . then true else false end),
  allow_force_pushes: (.allow_force_pushes.enabled  | if . then true else false end),
  allow_deletions: (.allow_deletions.enabled | if . then true else false end)
}' < "$file" | hub api -X PUT "/repos/${org}/${repo}/branches/${branch}/protection" \
                   -H 'Accept: application/vnd.github.luke-cage-preview+json' --input - && \
         hub api -X DELETE "/repos/${org}/${repo}/branches/${base}/protection"
  fi
}


file=`mktemp`
trap "rm ${file}" EXIT

hub api "/repos/${org}/${repo}/branches/${base}/protection" > "$file"

update_branch_protections ${org} ${base} ${repo} ${branch} ${file}
