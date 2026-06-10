#!/bin/bash

psql -h tf10-postgres.c56824c8uup2.sa-east-1.rds.amazonaws.com \
-U postgres \
-d postgres \
-c "\dt"