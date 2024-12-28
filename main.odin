package main

import rl "vendor:raylib"

TARGET_FPS :: 60
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Wonderlust"

main :: proc() {
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.SetTargetFPS(TARGET_FPS)

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(rl.GRAY)
    }
}
