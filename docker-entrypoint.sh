#!/bin/bash
set -e
set -x

service nginx start

exec "$@";