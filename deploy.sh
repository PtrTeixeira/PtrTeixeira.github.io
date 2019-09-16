#!/bin/bash
set -eo pipefail

cat <<HEREDOC > ~/.gitconfig
[user]
  email = PtrTeixeira@gmail.com
  name = CircleCI

HEREDOC

cd public/ && \
  git add --all && \
  git commit -m "Deploy website [skip ci]" && \
  git push origin gh-pages
