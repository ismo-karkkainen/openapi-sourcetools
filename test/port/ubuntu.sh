#!/bin/sh

sudo apt-get install -y -q ruby rake >/dev/null
rake test
