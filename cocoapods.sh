#!/bin/sh

if [ $# -eq 0 ]; then
  echo "Usage $0 lint|push"
  exit 1
fi

if [ $1 == "lint" ]; then
  bundle exec pod spec lint --use-libraries --allow-warnings --no-clean --verbose
elif [ $1 == "push" ]; then
  bundle exec pod trunk push --use-libraries --allow-warnings --verbose
else
  echo "Usage $0 lint|push"
  exit 1
fi
