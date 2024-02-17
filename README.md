# Dotfiles

This is the repo where I store my dotfiles. I use [GNU Stow](https://www.gnu.org/software/stow/) to manage them.

This repo is inspired by the youtube video [Stow has forever changed the way I manage my dotfiles](https://youtu.be/y6XCebnB9gs) by Dreams of Authonomy.

## Requirements

- [GNU Stow](https://www.gnu.org/software/stow/)

## Usage

```bash
git clone https://github.com/nahumsa/dotfiles.git
```

Run stow to create symlinks for the desired dotfiles:

```bash
stow . 
```
