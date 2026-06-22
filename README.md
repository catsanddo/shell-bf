# Shell BF
This is a brainf*ck interpreter written entirely in POSIX compliant shell script.

## What this means
There are no external programs called from the source code.
For now, the only known exception to this is the use of `dirname` in `src/bf.sh`.
This will change in a future version.
The *only* programs called by these scripts are shell built-in commands.
All behavior for string manipulation, list processing, and other features used in the program were derived from these primitives.

It is intended that any POSIX compliant shell should be able to run this interpreter.
So far the following shells have been tested:
- `busybox ash`

## Performance
As you would expect from a program written like this, it is *extremely* slow.
Running `examples/hello-world.bf` takes about 20 seconds on my machine.
There are some optimizations in place right now, and I will try to do everything I can to further improve its performace in the future.

## Behavior
The tape is unbounded in both directions and consists of 8-bit unsigned cells which wrap on over/underflow.
Reading EOF replaces the current cell with 0.
Due to the way shell scripts and the `read` command handle trailing newlines, newlines are handled manually when reading and return 10.
When outputting, no effort is made to translate line endings.
Output comes directly from `printf`.
It is unclear (to the author) what this will actually result in across different platforms and shells, but there will be no effort made to change this for the present time.

When program execution finishes, the interpreter prints out the final state of the tape and the tape index.

## Examples
You can run a program directly from the command-line like so:
```
sh src/bf.sh '+[>,.]'
```
You can also run programs from files:
```
sh src/bf.sh examples/hello-world.bf
```

There is also an interactive debugger mode that can be accessed by supplying the `-z` option.
