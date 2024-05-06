#!/bin/bash

source ~/.bashrc

# We execute nvim in this way in order to ensure the bob nvim proxy has a parent process
set -e
exec "$@" &
wait
