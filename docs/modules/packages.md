<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit/packages - dotkit core module for package management

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs, the below is subject to change.

## overview

package management is often a problem for dotfile maintainers, many provide their own functionality to handle this, but it's not always easy to maintain and can be a source of bugs.

dotkit/packages provides simple functionality:

- declarative package manager selection
- automatic package installation
- diffing packages between updates
- user blacklists