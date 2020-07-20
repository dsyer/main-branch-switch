Scripts for switching Github repos to use a "main" branch as the default. Original source at https://github.com/dsyer/main-branch-switch

Pre-requisites: you need the [Hub CLI](https://hub.github.com/) to interact with Github, and you need [JQ](https://stedolan.github.io/jq/) for parsing and mangling JSON. Make sure all three of the scripts in this repo are on your `PATH`. You may need to authenticate with Github via Hub before you start (or it might prompt you the first time it needs it).

```
$ git clone https://github.com/heroku/main-branch-switch && cd $_
$ export PATH=`pwd`:$PATH
```

To create a "main" branch and retarget all the pull requests for a repo at Heroku:

```
$ main_branch.sh --repo <myrepo>
```

You can switch orgs `--org <myorg>` and you can target a specific repository with `--repo <myrepo>`.

The retarget.sh script can be used on its own to re-target pull requests (it is used by the `main_branch.sh` script):

```
$ retarget.sh --org <myorg> <myrepo> main 1234
```

If your repository uses branch protections, the branch_protect.sh script can be used to copy the settings from the base branch to the new branch. (it is used by the `main_branch.sh` script by default):

```
$ branch_protect.sh --org <myorg> <myrepo> main 
```

The default org is "heroku", and the default pull request is all of them (the open ones).

## What to do in your Fork

If you have a fork of a project that has changed its default branch, you probably want to update the remote:

```
$ git fetch origin --prune
$ git checkout main
$ git branch -d master
$ git remote set-head origin main
```

If you normally work with `origin` as the upstream then you are good to go. If you want your remote fork to be the upstream then you need to also do this, or something equivalent:

```
$ git push <myorg> main --set-upstream
```
