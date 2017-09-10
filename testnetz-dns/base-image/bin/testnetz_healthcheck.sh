#!/bin/bash 

# Run all scripts in the following directory.
# Additional checks can be added by putting executable scripts in there.
# --regex="": Match everything, so nothing gets accidentally skipped.
run-parts --exit-on-error --regex="" /etc/testnetz_healthcheck.d/ || exit 1
