#!/usr/bin/env bash

dk_install_pre_handler() {
  echo "Running pre-install event handler"
  # Add pre-install logic here
}

dk_on pre_install dk_install_pre_handler 10
