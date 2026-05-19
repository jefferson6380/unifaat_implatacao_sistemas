#!/bin/bash

aws rds create-db-instance \
--db-instance-identifier tf10-postgres \
--engine postgres \
--db-instance-class db.t3.micro \
--master-username postgres \
--master-user-password Senha123! \
--allocated-storage 20 \
--backup-retention-period 7 \
--multi-az \
--publicly-accessible