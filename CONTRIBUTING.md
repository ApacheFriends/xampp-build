# Contributing to this repository

Thanks for taking the time to contribute! The following is a set of guidelines for contributing to our project.
We encourage everyone to follow them with their best judgement.

## Table of Contents

* [How to Prepare a Merge Request](#how-to-prepare-a-merge-request)
  * [The Essentials of a Code Contribution](#the-essentials-of-a-code-contribution)
    * [Git Client Configuration](#git-client-configuration)
    * [Making your Changes Clear and Traceable](#making-your-changes-clear-and-traceable)
  * [Creating the Merge Request](#creating-the-merge-request)
* [Branching Strategy](#branching-strategy)
  * [Key branches](#key-branches)
    * [stable](#stable)
  * [Supporting branches](#supporting-branches)
    * [release branches](#release-branches)
    * [feature branches](#feature-branches)
    * [bugfix branches](#bugfix-branches)
    * [revert branches](#revert-branches)
    * [hotfix branches](#hotfix-branches)
* [Merging a Merge Request](#merging-a-merge-request)

## How to Prepare a Merge Request

Merge requests let you tell others about changes you have pushed to a branch in our repository. They are a dedicated forum for discussing the implementation of the proposed feature or bugfix between committer and reviewer(s).
This is an essential mechanism to maintain or improve the quality of our codebase, so let's see what we look for in a merge request.

The following are all formal requirements to be met before considering the content of the proposed changes.

### The Essentials of a Code Contribution

Here we cover the configuration of the tools that will help you write code that complies with our standards and also the good practices that will make your contribution as useful as it can be!

#### Git Client Configuration

First things first, Git is the base from which everything is built upon, so we want to make it as solid as possible.

* Start off by configuring your `user.name` and `user.email` as seen in [Customizing Git](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration). The `user.email` parameter should always be the VMware corporate one. For your convenience, here is a good resource on [Maintaining Different Git Identities](https://xam.io/2017/gitconfig/).
* Next, we want to be able to verify that commits are actually from a trusted source, so we are going to sign and verify our work with GPG.
  * Github has a neat set of guides that will help you [check for existing GPG keys](https://docs.github.com/en/articles/checking-for-existing-gpg-keys), [generate a new GPG key](https://docs.github.com/en/articles/generating-a-new-gpg-key) in case you don't already have one, [tell Git about your signing key](https://docs.github.com/en/articles/telling-git-about-your-signing-key) and of course show you how to [sign commits](https://docs.github.com/en/articles/signing-commits).
* Finally, we want to publish our work and *only* our work. There is one thing that might bother us and the people we work with: line endings.
  * Fortunately, Github has us covered again, check [Configuring Git to handle line endings](https://docs.github.com/en/github/using-git/configuring-git-to-handle-line-endings) for Mac, Windows and Linux.

#### Making your Changes Clear and Traceable

There's a **Golden Rule** when addressing code changes: **Modify only what is related to the task**.

When developing the next feature or bugfix we should also strive for small, atomic commits or, in other words, commits that group changes focused on one context and one context only.
They are easier to read, understand, review, track and revert.

You can use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for the commit message structure. Regardless of that, the message itself should be descriptive. A well-crafted Git commit message is the best way to communicate context about a change. Here is a good resource on [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/) or just skip to the [guidelines](https://chris.beams.io/posts/git-commit/#seven-rules).

Also, note that the commits will be squashed when merging the pull request. Regarding the squash commit message:

* If the PR contains a single commit, there won't be any squash and the commit will go directly to the target branch.
* If there are multiple commits, the message will default to the merge request title.

A final caveat to be aware of is that the fast-forward strategy requires that your branch is up-to-date with the target branch, so you will have to rebase/merge the target branch into your branch before merging the merge request.

### Creating the Merge Request

There are three important parts in a merge request:

* **Title**.
  When the work is still in progress the title is also the place to inform about that: `WIP: Title`
* **Description**. Do your best to put only relevant information. It is perfectly valid to leave it empty! But please, don't leave all your commit messages there.
  * If you are creating a follow-up (*) merge request, then mention it on the description like `Follow-up #<PR-id>`.
* **Destination branch**. The destination branch is determined by the [Branching Strategy](#branching-strategy) section you can find below.

Additionally, there are other fields that can be useful:

* **Reviewers**. Set one or multiple reviewers when you want them to review, and eventually, approve your pull request.

> (*) **Note:** You should consider a follow-up pull request when
>
> 1. The work under a GitHub issue is more manageable if divided into smaller units or maybe easier to understand in the review process.
> 2. The merge request that closed the GitHub issue was incomplete.

Just create a branch following the same naming convention plus `-2` (or any subsequent number) like `feature/<ISSUE-ID>-2`. Also, make sure the pull request description is titled accordingly.

## Branching Strategy

[Git](https://git-scm.com/) is our version control system for tracking changes in our codebase. As you may know, in Git's implementation, branching is really cheap!
So we need an orderly, controlled way of dealing with them: Enter Branching Strategy. This is the set of rules on which we base our workflow.

### Key branches

#### main

* Always releasable: We consider `origin/main` to be the main branch where the source code of `HEAD` always reflects a *production-ready state*.
* Please do not push changes without a merge request
* Changes come from `feature` and `bugfix` branches
* Merge strategy is **always** `--squash`
* Releases are created from this branch

### Supporting branches

#### feature branches

* One branch per *feature*
* May branch off from `main`
* Naming convention is `feature/<ISSUE-ID>`

#### bugfix branches

* One branch per *bugfix*
* May branch off from `main`
* Naming convention is `bugfix/<ISSUE-ID>`

#### revert branches

* One branch per *revert*
* May branch off from `main`
* Naming convention is `revert/<ISSUE-ID>`

## Merging a Merge Request

Here there's one **Golden Rule**:

* **Who pushes the changes, merges the changes**. The author of the changes is the one who knows if the criteria of the related GitHub issue is completely met.
  * There may be exceptions to this rule.

There is also a set of requirements to fulfill before merging a merge request:

* **The criteria of the related GitHub issue are completely met**.
* **All comments by reviewers have been addressed**.
* **It is approved by whoever reviewed it**.
* **Sync before merge**. So you verify that everything works as expected with the latest revision of the destination branch.