# TODO

## [] Render backend
A backend should be implemented in it's own file. Every backend needs to implement the same functions with the same signatures.
And will later be imported as:
```Odin
  when RENDER_BACKEND == "RAYLIB" {
    import backend "render_backends/raylib"
  } else when RENDER_BACKEND == "SOKOL" {
    import backend "render_backends/sokol"
  }
```
Every function should also be inlined.
Look into if a signature file can be created `render_backends/signature`

```Odin
  draw_rect :: proc(...)
```

look into if input should be split in a similar manner, or if input always comes from render_backend.

## [] System

## [] EventSystem
