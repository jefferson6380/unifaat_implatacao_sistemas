#!/bin/bash

aws rds delete-db-instance \
--db-instance-identifier tf10-postgres \
--skip-final-snapshot