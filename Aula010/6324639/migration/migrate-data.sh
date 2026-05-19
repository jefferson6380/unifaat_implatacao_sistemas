#!/bin/bash

pg_dump -h localhost -p 2001 -U postgres northwind > northwind.sql

psql -h tf10-postgres.c56824c8uup2.sa-east-1.rds.amazonaws.com \
-U postgres \
-d postgres \
-f northwind.sql