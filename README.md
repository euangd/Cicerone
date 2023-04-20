# Cicerone

A GUI for the `Brew` CLI tool found at [brew.sh](https://brew.sh). `Brew` is a build artifact and/or source code distribution tool similar to `Choco` and `WinGet`, but for macOS and Linux. This GUI tool aims to make it easier to use and control on macOS. See [the Features section](#Features).

Cicerone is based on Bruno Philipe's [Cakebrew](https://github.com/brunophilipe/Cakebrew), which itself is based on Vincent Saluzzo's [Homebrew-GUI](https://github.com/vincentsaluzzo/Homebrew-GUI). The commit histories of both are still attached to this branch in Git.

See [the Credits file](Credits.MD) for more information on the historical context of the source code and other content distributed with this file.

## Features

<details>

<summary>

### Feature List: Current and WIP

</summary>

- [ ] Install from URI
    - [ ] Folders
    - [ ] Archvial Formats:- [ ] ZIP, [ ] DMG, [?] -Tar-Ball, [?] =-Others
    - [ ] GUI-Convenience (such-as: Pull in Folder or URI Text)
    - [ ] Auto-Paste
- [ ] Browse
    - Casual Browsable List of Distributions (Formulae)
- [-] Search
    - [ ] Looser Matches
        - [ ] Meta Information (if Available)
    - [ ] GitHub Search
    - [ ] Cask (Formulae for Distributable Binaries) Search
    - [ ] Match Distributions (Formulae) from Known Alternate Feeds and Self-Contained Distribution Entries (Formulae, such-as: Git-Hosted, Local (Known Other Folder or Drive, et cetera), et cetera)
- [ ] Better Installs
    - [ ] Browse and Install Chosen Version
    - [ ] Install Git-Hosted Direct Distributions (Formulae and Casks)
- [ ] Better Information
    - [ ] Content Preview
    - [ ] Possible Actions Preview
- [-] Follow Alternative Feeds
    - [ ] Allow Browse:- [ ] Even Casks
    - [ ] Fix Cask Installs
- [-] Edit and View Local Installs (Leaves)
- [ ] Power Tools
    - [ ] Control Addition of Installed Files to Shell Search Paths
        - [ ] Different Selections for Each Shell and/or Terminal
        - [ ] Version Switch (think: Xcodes)
    - [ ] Re-Build Formulae
    - [ ] Use Alternate Versions of Sub-Referenced Distributions (Formulae)
- [ ] Allow Non-Default Brew Installation with Simulated Defaults (as-in: Installed on Different Drive or Folder, et cetera)
- [?] Embedded Brew Instance
    - [?] Self-Contained Distribution (as-in: Includes Brew)
- [ ] Better Tasks
    - [ ] Editable Queue
    - [ ] Worker Tasks
        - [?] Parallel
        - [ ] While in Non-Alerted State, Allow:
            - [ ] Access to Browse and Search
            - [ ] Addition of Tasks to Queue
    - [ ] Better View into and Information on Current Tasks (such as: Install, Delete, Build, et cetera)
        - [-] Real-Time Verbose Terminal Standard Out Echo
        - [ ] Information:- [ ] Task Name, [] Process Name and ID
        - [ ] Link to macOS Console for Process
- [ ] Local Action Tracked Histories
    - [ ] View Previous States
        - [ ] from Errored States
- [ ] Publish Distributions (Formulae)
    - [ ] Generate Local Distribution Entries (Formulae)
- [?] Other Distribution Tools
    - [?] Differences Between Distributions
- [?] Cross-Platform

</details>

Feel free to contibute! See [the license](#License).

### Points

- Easier to Browse Distributables
- More Control Over Local Files
- Less Error-Prone
- Easier to Fix Local Errored States
- Easier Use of Non-Defaults
- Easier to Use Source Code from Various Locations (Git, Local Folder, Archive File, Remote Location (FTP, NGinX, et cetera))

### Future

#### Swift Version

The intent with Cicerone is to write a fresh MIT-licensed version of Cakebrew, built on Swift and SwiftUI. The current source tree has some serious bloat (no shade!) for a CLI tool GUI, which can be solved with the more modern sensibilities aforementioned around choice of native macOS stack. This should make it easier to add features, which I'll note is the main reason I set out to make this fork, but I wanted to address some concerns that are easier than the others.

## Pictures

![Home UI](https://www.cakebrew.com/assets/img/app-bg.png)

## Build and/or Install

The intention is to, at some later time, distribute build artifacts for Cicerone on Brew itself, but at the moment, this is WIP. This code also does not build; also WIP.

## Localizations

Contributions are welcome, but otherwise no further localization work will be done until the [Swift version](#Swift-Version) is done.

## License

The source code and other content distributed with this file is licensed under [Version `3.0+` of the `GNU General Public License` (the `GPL`)](https://www.gnu.org/licenses/gpl-3.0-standalone.html); [SPDX: `GPL-3.0-or-later`](https://spdx.org/licenses/GPL-3.0-or-later.html).

Copyright © 2014-2021 Bruno Philipe, © 2023 Alex Fânaț. All rights reserved.

<details>

<summary>

### FOSS Author Liabilities Information

</summary>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <[http://www.gnu.org/licenses/](https://www.gnu.org/licenses/gpl-3.0-standalone.html)>.

</details>

