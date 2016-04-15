# Contributing Code to the токамак

This CONTRIBUTING rules are exact copy of [Berlin Brain-Computer Interface](https://github.com/bbci) group.

## tl;dr

The very short summary (tl;dr = too long; didn't read) describing how to
contribute code to the токамак is:

* Fork the токамак repository
* Clone your fork
* Create a feature branch to add a feature or fix a bug
* Push the feature branch to your fork
* Create a pull request

A detailed explanation follows below.


## General Workflow

Instead of committing directly to the project's repository, you *create your own
private fork* of the project. Forking a repository allows you to freely
experiment with changes without affecting the original project.

In order to fix a bug or creating a new feature, it is best to create a new
*feature branch* for each bugfix or new feature. Those branches can be pushed to
your fork and merged back into the original токамак repository independently.

When you're happy with your changes, you can propose to get the changes merged
back into the original project by creating a *pull request* for the feature
branch.


## Forking the токамак Repository

We assume you already have a GitHub account. If you don't have a GitHub account,
please [create an account][join_github] now, it's free.

1. Goto the [токамак repository page on github][tokamak]
2. In the top-right corner of the page, click **Fork**.

That's it! Now you have a *fork* of the original токамак repository. You are
free to add files, modify files, or even delete the repository without affecting
the original project.


## Cloning Your Fork

Right now, you have a fork of the токамак repository, but you don't have any
files of that repository on your computer. Let's create a *clone* of your fork
on your computer.

1. On GitHub, navigate to *your fork* of the токамак repository
   (https://github.com/YOUR_USERNAME/tokamak).
2. In the right sidebar you'll find the *clone URL* of your fork. Copy that URL.
3. Open a terminal.
4. Type `git clone`, and paste the URL you copied in step 2 and press Enter:

   ```sh
   $ git clone git@github.com:YOUR-USERNAME/tokamak.git
   Cloning into 'tokamak'...
   remote: Counting objects: 5262, done.
   remote: Total 5262 (delta 0), reused 0 (delta 0), pack-reused 5262
   Receiving objects: 100% (5262/5262), 3.28 MiB | 700.00 KiB/s, done.
   Resolving deltas: 100% (3646/3646), done.
   Checking connectivity... done.
   ```

   Now, you have a local copy of your fork of the токамак repository! You can
   add, modify, and delete files, make commits and push changes to your fork,
   without affecting the original токамак repository.


## Keep Your Fork Synced

Right now, your fork and your clone are an island, disconnected from the
original токамак repository. In the next steps we configure git so it allows you
to pull changes from the original, or *upstream*, repository into the local
clone of your fork.

1. On GitHub, navigate to the [original vertexclique токамак page][tokamak]
2. In the right sidebar, copy that *clone URL* of the repository.
3. Open a terminal and change into the directory of your local clone.
4. Type `git remote -v` and press Enter. You'll see the current configured
   repository for your fork:

   ```sh
   $ git remote -v
   origin    git@github.com:YOUR_USERNAME/tokamak.git (fetch)
   origin    git@github.com:YOUR_USERNAME/tokamak.git (push)
   ```

5. Type `git remote add upstream`, and then paste the URL you copied in Step 7
   and press Enter:

   ```sh
   $ git remote add upstream git@github.com:vertexclique/tokamak.git
   ```

6. To verify the new upstream repository, type again `git remote -v`. You
   should see the URL for your fork as `origin` and the original repository as
   `upstream`.

   ```sh
   $ git remote -v
   origin    git@github.com:YOUR_USERNAME/tokamak.git (fetch)
   origin    git@github.com:YOUR_USERNAME/tokamak.git (push)
   upstream  git@github.com:vertexclique/tokamak.git (fetch)
   upstream  git@github.com:vertexclique/tokamak.git (push)
   ```

## Pulling Changes From Upstream

In order to actually update your fork with the new commits from the upstream
repository, you need to pull in upstreams changes. Usually it's recommended to
use your `develop` branch to follow upstreams `develop` branch. All your commits
should go into separate branches.

1. Checkout the `develop` branch of your repository:

   ```sh
   $ git checkout develop
   ```

2. Pull in the changes from upstream's `develop` branch:

   ```sh
   $ git pull upstream develop
   ```

   Your local `develop` branch is updated with the latest changes from upstream.

3. To push your local `develop` to the `develop` branch of your fork:

   ```sh
   $ git push
   ```

## Working on a Feature Branch

Let's assume you want to fix a bug or write a new feature. Instead of working
directly on the `develop` branch of the repository, it is often preferable to
make changes in a separate branch and merge that branch back into `develop` once
everything is ready. Let's create a new branch for our feature, called
`myfeature`:

```sh
$ git checkout -b myfeature
```

You've now created a branch `myfeature` and git automatically switched to that
branch for you. In this branch, you can now make changes and commits as usually:

```sh
# edit files foo and bar
$ git add foo bar
$ git commit
# create file baz
$ git add baz
$ git commit
# ...
```

You can also switch back and forth between branches:

```sh
$ git checkout develop
# you are now in the develop branch

$ git checkout myfeature
# you're back in the feature branch
```

## Creating a Pull Request

So far you have added a new feature or fixed a bug in a *feature branch* of your
local clone of your fork of the original токамак repository. You now want these
changed to be merged into the original repository.

1. Push your feature branch into *your* GitHub repository:

   ```sh
   $ git checkout myfeature
   $ git push origin myfeature
   ```
2. Navigate to your GitHub repository and switch to the `myfeature` branch by
   selecting it from the dropdown box above the file listing.
3. Click **Pull Request** above the file listing, fill out the form, and
   finish by clicking **Create Pull Request**

You've now created a pull request. That pull request appears in the original,
upstream repository where the maintainers can comment on your pull request,
request some more changes, reject or accept your pull request.


[tokamak]: https://github.com/vertexclique/tokamak
[join_github]: https://github.com/join
