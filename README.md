# Run:
1. `docker-compose up db`
2. Restore dump to database via psql
3. copy-past filestore to openupgrade folder
4. Run migration proccess: `docker-compose up`
5. Check migration logs: `tail -f /openupgrade/log/migration.log`


# TODO:
1. Add submodule to new repository with odoo 13.0 addons for MCP

# Issues:

- Not found selections for `alias_contact` field in aram_mcp module
- `AssertionError: Element odoo has extra content: record, line 3` - user_dashboard module
- pre-migration script for queue_job 13.0.3.2.0
