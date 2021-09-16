#!/bin/sh

sudo amazon-linux-extras install ruby2.6 -y >/dev/null
rake test
