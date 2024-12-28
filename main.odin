package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

TARGET_FPS :: 60
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Wonderlust"

TEXT_SIZE :: 20

IMAGE_X :: 140
IMAGE_Y :: 0

BANNER_Y :: 0
LEFT_BANNER_X :: 0
RIGHT_BANNER_X :: 1140

TEXT_AREA_COLOR :: rl.Color {201, 204, 161, 255}

TEXT_BOX_BACKGROUND_COLOR :: rl.Color {202, 160, 90, 255}
TEXT_BOX_TEXT_COLOR :: rl.Color {142, 160, 145, 255}

CHOICE_BOX_COLOR :: rl.Color {202, 160, 90, 255}

CHOICE_BACKGROUND_COLOR :: rl.Color {174, 106, 71, 128}
CHOICE_TEXT_COLOR :: rl.Color {202, 160, 90, 255}
CHOICE_RECT_X :: 45
CHOICE_RECT_Y :: 590
CHOICE_RECT_Y_OFFSET :: 40
CHOICE_RECT_WIDTH :: 1190
CHOICE_RECT_HEIGHT :: 38

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

    font := rl.LoadFont("PixAntiqua.ttf")

    left_banner_image := rl.LoadTexture("images/left_banner.png")
    right_banner_image := rl.LoadTexture("images/right_banner.png")

    cave_entrance_image := rl.LoadTexture("images/cave_entrance.png")
    cave_exit_image := rl.LoadTexture("images/cave_exit.png")
    crystals_image := rl.LoadTexture("images/crystals.png")
    high_path_image := rl.LoadTexture("images/high_path.png")
    low_path_image := rl.LoadTexture("images/low_path.png")
    owl_image := rl.LoadTexture("images/owl.png")
    skinwalker_image := rl.LoadTexture("images/skinwalker.png")

    current_image: rl.Texture2D

    text_area_rect := rl.Rectangle {0, 420, 1280, 300,}
    text_box_rect := rl.Rectangle {32, 430, 1216, 150,}
    choice_box_rect := rl.Rectangle {32, 585, 1216, 130,}

    choice_rect1 := rl.Rectangle {
        CHOICE_RECT_X,
        CHOICE_RECT_Y + 0,
        CHOICE_RECT_WIDTH,
        CHOICE_RECT_HEIGHT,
    }

    choice_rect2 := rl.Rectangle {
        CHOICE_RECT_X,
        CHOICE_RECT_Y + (CHOICE_RECT_Y_OFFSET * 1),
        CHOICE_RECT_WIDTH,
        CHOICE_RECT_HEIGHT,
    }

    choice_rect3 := rl.Rectangle {
        CHOICE_RECT_X,
        CHOICE_RECT_Y + (CHOICE_RECT_Y_OFFSET * 2),
        CHOICE_RECT_WIDTH,
        CHOICE_RECT_HEIGHT,
    }

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
        image = cave_entrance_image,
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

        rl.ClearBackground(rl.GRAY)

        current_image = current_screen.image

        rl.DrawTexture(current_image, IMAGE_X, IMAGE_Y, rl.WHITE)
        rl.DrawTexture(left_banner_image, LEFT_BANNER_X, BANNER_Y, rl.WHITE)
        rl.DrawTexture(right_banner_image, RIGHT_BANNER_X, BANNER_Y, rl.WHITE)

        rl.DrawRectangleRec(text_area_rect, TEXT_AREA_COLOR)
        rl.DrawRectangleRounded(text_box_rect, .45, 32, TEXT_BOX_BACKGROUND_COLOR)

        rl.DrawRectangleRounded(choice_box_rect, .45, 32, CHOICE_BOX_COLOR)

        rl.DrawRectangleRounded(choice_rect1, .45, 32, CHOICE_BACKGROUND_COLOR)
        rl.DrawRectangleRounded(choice_rect2, .45, 32, CHOICE_BACKGROUND_COLOR)
        rl.DrawRectangleRounded(choice_rect3, .45, 32, CHOICE_BACKGROUND_COLOR)
        // TODO: Draw choice text

        rl.DrawTextEx(font, current_screen.text, {0, 0}, TEXT_SIZE, 0, TEXT_BOX_TEXT_COLOR)
        for choice, index in current_screen.choices {
            rl.DrawTextEx(font, choice.text, {0, f32(TEXT_SIZE * index + TEXT_SIZE)}, 20, 0, CHOICE_TEXT_COLOR)
        }

        current_screen.choices[0].side_effects["example_side_effect"]()
    }
}

example_side_effect :: proc() {
    fmt.println("Example side effect completed")
}
