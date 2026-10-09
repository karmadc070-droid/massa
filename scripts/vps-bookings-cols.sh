#!/bin/bash
docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
 -c "select column_name from information_schema.columns where table_name='bookings' order by ordinal_position;" | tr '\n' ' '
echo
