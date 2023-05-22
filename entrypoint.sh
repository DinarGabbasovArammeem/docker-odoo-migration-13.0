#!/bin/bash
set -e

# function for checking PostgreSQL server availability
postgres_ready() {
  PGPASSWORD="$1" psql -h "$2" -p "$3" -U "$4" -d "$5" -c '\q' >/dev/null 2>&1
}

# waiting for PostgreSQL server availability
until postgres_ready "$DB_PASSWORD" "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_NAME"; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 5
done

echo "Initializing environment parameters"

# workdir path of OpenUpgrade
OPENUPGRADE_PATH=${OPENUPGRADE_PATH:-/openupgrade}

# path of extra addons
EXTRA_ADDONS_PATH=$OPENUPGRADE_PATH"/extra-addons"

# new database name
NEW_DB_NAME=$DB_NAME"_13.0"
# Check if the new database already exists, and if it does, drop it before creating a new one
if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $NEW_DB_NAME; then
    echo "Database $NEW_DB_NAME already exists. Dropping it."
    PGPASSWORD=$DB_PASSWORD dropdb -h $DB_HOST -p $DB_PORT -U $DB_USER $NEW_DB_NAME
fi

echo "Creating a new database"

# create new database to migration
PGPASSWORD=$DB_PASSWORD createdb -h $DB_HOST -p $DB_PORT -U $DB_USER -T $DB_NAME $NEW_DB_NAME

echo "Run migration process. Check logs: tail -f openupgrade/log/migration.log"

# run migration process
python3 $OPENUPGRADE_PATH/odoo-bin -d $NEW_DB_NAME --db_user=$DB_USER --db_password=$DB_PASSWORD --db_host=$DB_HOST --db_port=$DB_PORT --update all --stop-after-init --data-dir /var/lib/odoo --addons-path=$OPENUPGRADE_PATH/addons,$EXTRA_ADDONS_PATH > $OPENUPGRADE_PATH/log/migration.log 2>&1

echo "Migration process has been finished"
