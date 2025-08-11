# Project Zomboid Mod: Extra Keybind for Reading Books

## Overview

This mod is designed for Project Zomboid version 42. It adds an extra keybind that allows players to read books more conveniently by automatically scanning for and reading all unread books in the vicinity.

### Target Platform

- **Game**: Project Zomboid
- **Version**: Build 42
- **Mod Type**: Lua Client-side

### Core Concept

A single keybind that intelligently finds and reads all unread books from multiple sources around the player, automating the tedious process of manually reading each book individually.

## Current Status

We have a working implementation (`ReadAll.lua.disabled`) that:

- Reads books from player inventory, equipped bags, containers, and floor (3x3 area)
- Returns books to their original locations after reading
- Uses game's native book detection and reading systems

## What We Want to Build

Enhanced version of the current system with **player options** using Build 42's native mod options API.

### New Features

- **Literature Categories**: Players can choose which types of literature to read
- **Starting Category**: Magazines
- **Mod Options Integration**: Use PZ Build 42's native options system
- **Keybind in Mod Options**: Move keybind from game's keybind menu to mod options menu

### Categories to Define

- **Magazines**: Focus on magazine-type literature first
- Future categories can be added later

### Implementation Notes

- Keep all existing functionality from `ReadAll.lua.disabled`
- Create new files (don't modify the .disabled reference file)
- Use Project Zomboid Build 42 mod options API for settings
- Reference `GameFilesForReference/` folder for PZ API examples
