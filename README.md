# `can` 

`can` is a macOS command-line utility that provides an alternative to the `rm` command. Instead of permanently deleting files and directories, `can` moves them to the user's Trash, allowing for easy recovery if needed.

## Usage

```
usage: can [-h | -V] file ...
```

## Installation

The package for macOS which installs a universal binary can be downloaded from the [releases page](https://github.com/tshakalekholoane/can/releases).

### Homebrew

Alternatively, run the following commands using [Homebrew](https://brew.sh).

```shell
brew tap tshakalekholoane/taps
brew install can
```

### Source

The application can also be built from source by cloning the repository and running the following command which requires working versions of [Make](https://www.gnu.org/software/make/) and [Clang](https://clang.llvm.org) both of which come bundled with most macOS installations.

```shell
git clone https://github.com/tshakalekholoane/can && cd can
make
```
