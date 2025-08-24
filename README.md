<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit 

[![License](https://img.shields.io/badge/license-MIT-f59e42.svg?style=flat-square)](LICENSE)

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs.

## overview

a dotfiles approach that focuses on dotfile distribution and user profiles  
this is simply a collection of scripts and a system design to support all dotfiles old and new to be:

- easy to install
- easy to maintain
- easy to customize
- easy to share
- easy to switch between

imagine: grab dotfiles with one command, swap setups in a snap.  
want to share or remix a theme? one command does it.  

and the best part is you never worry about losing your custom configurations

eg.\
`dk install <github dotfile url>`\
`dk theme install <github dotfile theme url>`

## how does it work?

dotkit uses what i'm going to called a "layered desktop environment" approach.

- the "base" layer is the tooling dotkit provides to start up and maintain your own dotfiles
- the "dotfiles" layer is the dotfiles layer with your own or community dotfiles applied
- the "themes" layer is the optional layer with a theme applied (if your dotfiles support theming)
- the final "profile" layer is the user profile layer with a user profile applied

the "base" layer is dotkit itself, providing scripts and hooks to make up the system design

the "dotfiles" layer is the dotkit community, providing a collection of dotfiles and a way to install them

user profiles are your own personal customizations to all the other layers

all work together to create a "current" layer, which is your active system.

in the end, the user has full control over their system

## so whats next?

first step is making the dk cli\
then i need to make an initial dotfile template, most likely a hyprland one\
i plan to migrate other successful dotfiles to dotkit, with as much feature parity as possible

you can follow [todo](todo.md) to get a grasp of my goals and progress for this project
