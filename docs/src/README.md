# Introduction

This flake provides a number of modules for creating and managing 
steam game severs by leveraging [nix-steam-fetcher] to download the
game server files into the `/nix/store`.

It loosely grouped into two components:
1. A generic `services.steam-servers.servers` module that provides a 
   convenient set of options for setting up most steam servers
2. Opinionated modules (such as `services.steam-servers.stationeers`)
   which provide a more tailored experience for specific games.
   These modules use `services.steam-servers.servers` under-the-hood.