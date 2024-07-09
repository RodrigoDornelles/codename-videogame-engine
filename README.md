# codename-videogame-engine

[<img align="right" width="40%" src="https://raw.githubusercontent.com/RodrigoDornelles/RodrigoDornelles/master/media/ginga-asteroids.gif">](https://github.com/RodrigoDornelles/codename-videogame-engine/blob/main/examples/asteroids/game.lua)

[![codecov](https://codecov.io/github/RodrigoDornelles/codename-videogame-engine/graph/badge.svg?token=MM0TY7VVAT)](https://codecov.io/github/RodrigoDornelles/codename-videogame-engine)

> A cross-platform embeddable LUA game engine such as ginga, pc, mobile, browser and its own console like a Wii clone.

 * **Progressive "Television" Apps** _(PWA but is for Brazilian TVs)_
 * **Many testing tools** _(REPL, Unit Tests, [TAS](https://tasvideos.org/WelcomeToTASVideos#WhatIsATas) Tests)_
 * **Pure functions**

### Love 2D :heart_decoration: :desktop_computer:

```bash
$ ./cli.sh build ./examples/asteroids/game.lua --core love --run
```

### Ginga :brazil: :tv:

 * :octocat: [telemidia/ginga](https://github.com/TeleMidia/ginga)

```bash
$ ./cli.sh build ./examples/asteroids/game.lua --core ginga --run
```

### Browser :globe_with_meridians:

Need a web server to work, use live server in your vscode for development and github/cloudflare pages for production.

```bash
$ ./cli.sh build ./examples/asteroids/game.lua --core html5
```

---
This game engine is **open source** and **free** for all uses, focusing on promoting content for our **commercial platform**.
