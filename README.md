<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit 

[![License](https://img.shields.io/badge/license-MIT-14b8a6.svg?style=flat-square)](LICENSE)

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
total control, endless combos—your setup, your rules.

eg.\
`dk install <github dotfile url>`\
`dk theme install <github dotfile theme url>`

## motivation

let's be real - dotfiles are usually a beautiful mess.

everyone does their own thing, which is awesome for making your setup uniquely yours...  
but it can be a real pain when you want to:

- share your configs with others
- maintain them long-term
- and as a user, try out different setups

that's why i'm building dotkit

the idea is simple: have some structure, but don't box anyone in. want to:

- try out someone's cool terminal setup? just grab their module.
- test different status bar configs? install as many as you want.
- switch between setups? no conflicts, no stress.

never worry about losing your custom configurations

## how does it work?

dotkit uses what i'm going to called a "layered desktop environment" approach.

- the "base" layer is the tooling dotkit provides to start up and maintain your own dotfiles
- the "dotfiles" layer is the dotfiles layer with your own or community dotfiles applied
- the "themes" layer is the optional layer with a theme applied (if your dotfiles support theming)
- the final "profile" layer is the user profile layer with a user profile applied

the "base" layer is dotkit itself, providing scripts and hooks to make up the system design

the "dotfiles" layer is the dotkit community, providing a collection of dotfiles and a way to install them

the "themes" layer is an optional layer. if the dotfiles support theming, you can easily swap out themes either made by the dotfile team or by the community

user profiles are the last layer, they are your own personal customizations to all the other layers

all work together to create a "current" layer, which is your active system.

in the end, the user has full control over their system

## so whats next?

first step is making the dk cli\
then i need to make an initial dotfile template, most likely a hyprland one\
i plan to migrate other successful dotfiles to dotkit, with as much feature parity as possible

you can follow [todo](TODO.md) to get a grasp of my goals and progress for this project
