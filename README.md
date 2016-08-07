# токамак

![Tokamak](http://i.imgur.com/b0t3Hsf.png)

**Fusion Reactor for Rust** -
[![apm](https://img.shields.io/apm/v/tokamak.svg?style=flat-square)](https://atom.io/packages/tokamak)

* Syntax highlighting
* Creating Cargo project
* Support for Cargo projects
* Code Completion with Racer
* Managing Rust toolchains
* Code Linting
* Project specific configuration
* Code formatting

## токамак project configuration

токамак supports project configuration for each project. This helps to resolve
editor and project options. `tokamak.toml` file will be used by helper in the future.
It should resides in with same level of `Cargo.toml`.
By default Cargo project generated with tokamak will create it also.
Here is an example `tokamak.toml` file.

```
[helper]
path = ""                                  # Reserved for future helper path and configurations
[options]
save_buffers_before_run = true             # Saving buffers before every cargo command run
general_warnings = true                    # Show general warnings
[project]
auto_format_timing = 5                     # Run auto formatting for project for specified interval (seconds)
```

## Contributing
Contribution rules are written in [CONTRIBUTING.md](https://github.com/vertexclique/tokamak/blob/master/CONTRIBUTING.md).

## License

Copyright (c) 2016 Mahmut Bulut

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

<sub><sup>Tokamak logo built from "3D picture of JET vessel equipped with the ITER-Like Wall" - Copyright © EUROfusion 2014 - 2018</sup></sub>
