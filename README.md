# `can`

![Continuous Integration](https://github.com/tshakalekholoane/can/actions/workflows/ci.yaml/badge.svg)

`can` is a macOS command-line utility that provides an alternative to the `rm` command. Instead of permanently deleting files and directories, `can` moves them to the user's Trash, allowing for easy recovery if needed.

## Usage

```
usage: can [-h | -V] [--] file ...
```

## Installation

### Homebrew

```shell
brew tap tshakalekholoane/taps && brew install can
```

### Source

The application can be built from source by cloning the repository and running the following commands which require working versions of [Clang](https://clang.llvm.org/) and [Make](https://www.gnu.org/software/make/) which come bundled with Command Line Tools for Xcode on macOS.

```shell
git clone https://github.com/tshakalekholoane/can && cd can
make
```

### See Also

`trash(8)`
