#!/bin/bash

# Override this for local mirrors if needed.
: ${GIT_REPOSITORY_PREFIX:=https://github.com}
export GIT_REPOSITORY_PREFIX
