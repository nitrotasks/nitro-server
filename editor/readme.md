# Nitro Sync Database Editor

This is just a simple util to edit data (tasks, lists, etc)  saved in the database.

Why not use an SQL client like phpmyadmin? Because tasks and lists aren't saved
in tables, but as a giant blob of compressed msgpack data.

It's possible we will save tasks in their own table, but until we do, this tool
will hopefully help.
