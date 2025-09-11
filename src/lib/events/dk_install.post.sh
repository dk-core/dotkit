#!/usr/bin/env bash

dk_install_post_handler() {
  echo "Running post-install event handler"
}

dk_on post_install dk_install_post_handler 90
