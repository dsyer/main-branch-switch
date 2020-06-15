Scripts for switching Github repos to use a "main" branch as the default.

Pre-requisites: you need the [Hub CLI](https://hub.github.com/) to interact with Github, and you need [JQ](https://stedolan.github.io/jq/) for parsing and mangling JSON. Make sure both the scripts in this repo are on your `PATH`. You may need to authenticate with Github via Hub before you start (or it might prompt you the first time it needs it).

To create a "main" branch and retarget all the pull requests in all the repositories in your personal Github organization:

```
$ main_branch.sh
```

You can switch orgs `--org <myorg>` and you can target a specific repository with `--repo <myrepo>`.

The other script can be used on its own to re-target pull requests (it is used by the `main_branch.sh` script):

```
$ retarget.sh --org <myorg> <myrepo> main 1234
```

The default org is your personal org, and the default pull request is all of them (the open ones).

