# julia SDL3 test (SDL3Test.jl)

![screenshot](./docs/screenshot.png)

## Run

```bash
$ julia --project=@. -e 'using Pkg; Pkg.instantiate()'
$ julia --project=@. -e 'using SDL3Test; SDL3Test.main()'

# on linux:
LD_LIBRARY_PATH=. julia --project=@. -e 'using SDL3Test; SDL3Test.main()'

# on mac:
DYLD_LIBRARY_PATH=. julia --project=@. -e 'using SDL3Test; SDL3Test.main()'
```

## Compile standalone executable

NOTE: This takes minutes. Be patient.

```bash
$ julia --project=@. -e 'using Pkg; Pkg.add("PackageCompiler")'
$ julia --project=@. -e 'using PackageCompiler; create_app(".", "build", force=true, incremental=true)'

$ ./build/bin/SDL3Test

# on windows:
$ cp libui.dll build/bin
$ ./build/bin/SDL3Test.exe

# on linux:
$ cp libui.so build/bin
$ LD_LIBRARY_PATH=. ./build/bin/SDL3Test

# on mac:
$ cp libui.dylib build/bin
$ DYLD_LIBRARY_PATH=. ./build/bin/SDL3Test
```
