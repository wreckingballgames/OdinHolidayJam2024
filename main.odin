package main

import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Odin Holiday Jam 2024 Submission"

main :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(rl.GRAY)
    }
}
