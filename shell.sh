#!/bin/sh
set -eu

PIPER_HOME='/home/anon/skola'

cd "$PIPER_HOME/piper-ci-driver"
piper-shell "$PIPER_HOME/piper-ci/core.yml" 1
cd -