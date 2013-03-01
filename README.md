# Artful.ly OSE

Welcome to Artful.ly OSE

## About

Artful.ly Open Source Edition is the core code of the Artful.ly app downloadable for free and ready for you to roll up your sleeves and build a custom management system for your arts business. The Artful.ly OSE framework gives software developers a base from which they can add features, integrate with other apps, and much more!

## Before You Begin

You'll want the following running on your machine:

- Ruby 1.9.3
- MySQL 

## Usage

### More info to come.

## Contributing

We prefer using subtrees to make changes to the ArtfullyOSE Rails Engine, and collaborate on changes that way.

### *First*, add ArtfullyOSE as a remote.

    git remote add ose git://github.com/fracturedatlas/artfully_ose.git

### Add ArtfullyOSE into your repository as a subtree.

    git subtree add --prefix=lib/artfully_ose ose master

### Pull changes from lib/artfully_ose out to ArtfullyOSE.

    git subtree push --prefix=lib/artfully_ose ose master

### Prepare local changes in lib/artfully_ose to be pushed out to ArtfullyOSE.

    git subtree split --prefix=lib/artfully_ose --rejoin

### Push changes from lib/artfully_ose out to ArtfullyOSE.

    git subtree push --prefix=lib/artfully_ose ose master

## Contributors

Gary Moore - Lead Developer at Fractured Atlas

Clinton Judy - Open Source Lead at Fractured Atlas

## ?

