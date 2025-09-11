#!/usr/bin/env bash

dk_install_handler() {
  echo "Running install event handler"
  # Add install logic here
}

dk_on install dk_install_handler 50
