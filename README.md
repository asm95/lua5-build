### Introduction

Repository containing a script to compile Lua 5.3.6 in Windows. It is based of `@alain-riedinger`'s [script](https://github.com/alain-riedinger/lua53/blob/master/src/Build-lua.cmd).

The script will automatically download the source from a [official](http://luabinaries.sourceforge.net/download.html) mirror site.

### Running

Tested on Windows 10 with Visual Studio 2019 and PowerShell, but should work in older versions. You can also use `-v` to enable verbose messages.

```powershell
# build win-x86 binaries and libs
.\build.ps1 -arch x86
# build win-x64 binaries and libs
.\build.ps1 -arch x64
# use -clear to remove all built files
.\build.ps1 -clear
```

### TODO

- [ ] Support other systems such as Linux and MacOS
