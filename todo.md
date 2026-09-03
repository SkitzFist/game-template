# TODO

## Window
[] Should be able to create window at desired resolution
[] window impl should notify when window has changed. Should loop through all callbacks at beginning of frame
   current approach will loop through as soon as window event reports a change. This leads to lesser control
   over when the resizing is happening in the chain. 
[] Support multi window. Should move over to having a window handle, creating a window should return the handle. GLFW and other impls should receive the handle as well so
   callbacks can be directed properly. Input handling also needs a window handle attached (possibly only handle input on focused window, that way no separate handling, only delegating).

## Render

[] Shape outline rendering.
[] Curved lines.
[x] HIGH PIRO add support for blend modes
[] BUG HIGH PRIO when adding texture, it binds that texture, but opengl assumes all binding goes through its binder code.

## Other
[] HIGH PRIO Benchmark testing with file save, so it's easy to compare. Should be able to 'commit' result or 'discard'.
[] HIGH PRIO must include assets folder when building for release
