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

## Packages

Install packages with `yay-install` to both install them now and record them in
this repository:

```bash
yay-install package-name
yay-install package-one package-two
```

The command asks for confirmation before installing and recording each package.
Pass `--no-confirm` to install every requested package without prompting:

```bash
yay-install --no-confirm package-one package-two
```

The command creates one `install/install-<package>` script per package. Commit
those scripts with the rest of your dotfiles.

After formatting or setting up a new machine, restore every recorded package
and run the other installers with:

```bash
./install.sh
```

The restore command asks for confirmation before running each installer.
To run every installer without confirmation, use:

```bash
./install.sh --no-confirm
```

`yay` must already be installed before running the restore command.
