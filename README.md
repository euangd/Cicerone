# Cicerone

A GUI for the `Brew` CLI tool found at [brew.sh](https://brew.sh). `Brew` is a build artifact and/or source code distribution tool similar to `Choco` and `WinGet`, but for macOS and Linux. This GUI tool aims to make it easier to use and control on macOS. See [the Features section](#Features).

Cicerone is based on Bruno Philipe's [Cakebrew](https://github.com/brunophilipe/Cakebrew), which itself is based on Vincent Saluzzo's [Homebrew-GUI](https://github.com/vincentsaluzzo/Homebrew-GUI). The commit histories of both are still attached to this branch in Git.

See [the Credits file](Credits.MD) for more information on the historical context of the source code and other content distributed with this file.

## Future

### Swift Version

The final idea for Cicerone is to write a fresh MIT-licensed analog of Cakebrew, built on SwiftUI; this should make it easier to add [features](#Feature-List), which is the main reason for this fork. It is not clear if or when the Swift version will be viable, so the intent is for this fork to also address some of the more trivial concerns with the current state of the source.

## Features

<details>

<summary>

### Feature List

</summary>

- [~] Cask Formulae
    - [+] Cellar Control Features
    - [+] Browse
    - [ ] Search
- [ ] Use Interface Builder

#### Swift Version Features

- [ ] Better Browse
    - Sort List of Formulae
    - Show More Information in List
- [ ] Search
    - [ ] Looser Matches
        - [ ] Match Meta Information
- [ ] Better Installs
    - [ ] Choose Version
    - [ ] Parallel Alternate-Version Installs
- [ ] Better Information
    - [ ] Rich Links to Related Formulae
- [ ] Better Cellar Features
    - [ ] Non-Default Location
    - [ ] Move Cellar
    - [ ] Multiple Cellars
- [ ] Better Tasks
    - [ ] Editable Queue
    - [ ] Better Status
        - [ ] Default-Hidden Verbose Status
        - [ ] Access to Process Information
            - [ ] Link to macOS Console for Process
- [ ] More Brew Tools
    - [ ] Link to Cellar Shell Search Path
    - [ ] Re-Build Formulae
    - [ ] Create & Edit Formulae

#### Pipedreams

- [ ] Search
    - [ ] Tags
        - [ ] Related Packages
- [ ] Better Browse
    - [ ] Browse & Search Feed
- [ ] Better Installs
    - [ ] Pick Formula File
- [ ] Power Tools
    - [ ] Content Tree Previews
        - [ ] Compare
    - [ ] Per-Shell Search Path Link
    - [ ] Create, Edit, & Publish Feeds
    - [ ] Publish Formulae
    - [ ] Pick Version for Dependencies
- [ ] Better Tasks
    - [ ] Better Status
        - [ ] Brew Sub-Tasks
- [ ] Other Distribution Tools
    - [ ] Differences Between Equivalent Packages

</details>

Feel free to contibute! See [the license](#License).

### Points

- Modern macOS (14.4) Idioms
- Easier to Use With Modern Homebrew (Casks, Multiple Cellars – for Rosetta 2, et cetera)

## Pictures

![Home UI](https://www.Cicerone.com/assets/img/app-bg.png)

## Build and/or Install

The intention is to, at some later time, distribute build artifacts for Cicerone on Brew itself, but at the moment, this is WIP. This code also does not build; also WIP.

## Localizations

Contributions are welcome, but otherwise no further localization work will be done until the [Swift version](#Swift-Version) is done.

## License

The source code and other content distributed with this file is licensed under [Version `3.0+` of the `GNU General Public License` (the `GPL`)](https://www.gnu.org/licenses/gpl-3.0-standalone.html); [SPDX: `GPL-3.0-or-later`](https://spdx.org/licenses/GPL-3.0-or-later.html).

Copyright © 2014–2021 Bruno Philipe, © 2023–2024 Alex Fânaț. All rights reserved.

<details>

<summary>

### FOSS Author Liabilities Information

</summary>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <[http://www.gnu.org/licenses/](https://www.gnu.org/licenses/gpl-3.0-standalone.html)>.

</details>

