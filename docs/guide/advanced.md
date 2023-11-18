# Advanced Usage

For games that don't (yet) have an opinionated module written for them,
it is possible to use the generic `services.steam-servers.servers` module
that all the opinionated modules are built on top of.

The key part of generic servers is the `executable` option.
This is the path to the executable that will be started.
It may be an absolute path, or a path relative to the `datadir`.

The other primary feature that `services.steam-server.servers` provides
is the ability to construct files in the `datadir` by either symlinking them
in, or by creating a writeable file with pre-defined contents.
There are three options to this effect: `symlinks`, `files`, and `dirs`.
Both `symlinks` and `files` accept a struct where the keys are the file/symlink
that will be created in `datadir` and the values are either an absolute path
to copy/symlink or a struct defining how to create the file.

