package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

TARGET_FPS :: 60
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Wonderlust"

choice :: struct {
    text: cstring,
    screen_id: cstring,
    side_effects: map[cstring]proc(),
}

screen :: struct {
    image: rl.Texture2D,
    text: cstring,
    choices: []choice,
}

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes.\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free.\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }

    rl.SetConfigFlags({.VSYNC_HINT})
    rl.SetTargetFPS(TARGET_FPS)

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
    defer rl.CloseWindow()

    example_choice := choice {
        "Example choice 1",
        "example_screen",
        map[cstring]proc() {"example_side_effect" = example_side_effect},
    }
    defer delete(example_choice.side_effects)

    example_choice2 := choice {
        "Example choice 2",
        "example_screen",
        map[cstring]proc() {"example_side_effect" = example_side_effect},
    }
    defer delete(example_choice2.side_effects)

    example_screen := screen {
        text = "Example screen",
        choices = []choice {example_choice, example_choice2}
    }

    // TODO: Build a map of screens programmatically using input XML data. Their choices are also built with this data.
    //   Ensure there is a good way to insert or overwrite screens for the sake of certain screens that loop with variations.
    screens := make(map[cstring]screen)
    defer delete(screens)
    screens[example_choice.screen_id] = example_screen

    current_screen := screens["example_screen"]

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.DrawText(current_screen.text, 0, 0, 10, rl.WHITE)
        for choice, index in current_screen.choices {
            rl.DrawText(choice.text, 0, 10 * i32(index) + 10, 10, rl.WHITE)
        }

        current_screen.choices[0].side_effects["example_side_effect"]()

        rl.ClearBackground(rl.GRAY)
    }
}

example_side_effect :: proc() {
    fmt.println("Example side effect completed")
}
