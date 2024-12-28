package main

import "core:fmt"
import "core:mem"
import "core:math/rand"
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
    side_effects: []proc(),
}

screen :: struct {
    image: rl.Texture2D,
    text: cstring,
    choices: []choice,
}

screens: map[cstring]screen

self_doubt: int

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
    crossroads_image := rl.LoadTexture("images/crossroads.png")
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

    // TODO: Build a map of screens programmatically using input XML data. Their choices are also built with this data.
    //   Ensure there is a good way to insert or overwrite screens for the sake of certain screens that loop with variations.
    screens = make(map[cstring]screen)
    defer delete(screens)

    screens["intro"] = {
        image = cave_entrance_image,
        text = "There stood a young man before the narrow mouth of a cave sticking out of the ground at a low level like an unsightly pimple. He had sandy hair and looked about 15 (maybe he was.) He was covered in bruises, some fresh and some a sickly yellow-and-purple, and he was dressed like a soldier in some antiquated war (maybe he was.) He had beat the road for a solid fortnight before entering a forest. It was unkind to him, so he followed an old path out and found himself here. His feet were sore and he had to make a decision.",
        choices = {
            {
                text = "Plunge in.",
                screen_id = "crystals",
            },
            {
                text = "Think about whether going into the cave is a good idea.",
                screen_id = "crystals",
            },
            {
                text = "Turn back.",
                screen_id = "early_ending",
            },
        },
    }
    screens["crystals"] = {
        image = crystals_image,
        // TODO
        text = "",
        choices = {
            {
                text = "Listen closely.",
                screen_id = "crystals_loop",
                side_effects = {generate_crystals_loop},
            },
            {
                text = "\"Hello?\"",
                screen_id = "crystals_silence",
            },
            {
                text = "Ignore it and keep moving.",
                screen_id = "crossroads",
                side_effects = {decrement_self_doubt},
            },
        },
    }
    screens["crystals_loop"] = {
        image = crystals_image,
        // TODO
        text = "",
        choices = {
            {
                text = "\"Hello?\"",
                screen_id = "crystals_loop",
                side_effects = {generate_crystals_loop, increment_self_doubt},
            },
            {
                text = "Keep listening.",
                screen_id = "crystals_loop",
                side_effects = {generate_crystals_loop, increment_self_doubt},
            },
            {
                text = "Ignore it and keep moving.",
                screen_id = "crossroads",
                side_effects = {decrement_self_doubt},
            },
        },
    }
    screens["crystals_silence"] = {
        image = crystals_image,
        // TODO
        text = "",
        choices = {
            {
                text = "\"Did someone follow me in here? Show yourself!\"",
                screen_id = "crossroads",
                side_effects = {increment_self_doubt},
            },
            {
                text = "Get moving.",
                screen_id = "crossroads",
            },
        },
    }
    screens["crossroads"] = {
        image = crossroads_image,
        // TODO
        text = "",
        choices = {
            {
                text = "Take the high path.",
                screen_id = "high_path",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Take the low path.",
                screen_id = "low_path",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Think about which path to take.",
                screen_id = "crossroads_loop",
                side_effects = {generate_crossroads_loop, increment_self_doubt},
            },
        },
    }
    screens["crossroads_loop"] = {
        image = crossroads_image,
        // TODO
        text = "",
        choices = {
            {
                text = "Take the high path.",
                screen_id = "high_path",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Take the low path.",
                screen_id = "low_path",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Think about which path to take.",
                screen_id = "crossroads_loop",
                side_effects = {generate_crossroads_loop, increment_self_doubt},
            },
        },
    }
    // TODO
    screens["high_path"] = {

    }
    // TODO
    screens["low_path"] = {

    }
    // TODO
    screens["owl"] = {

    }
    // TODO
    screens["owl_loop"] = {

    }
    // TODO
    screens["good_ending"] = {

    }
    // TODO
    screens["ambivalent_ending"] = {

    }
    // TODO
    screens["fall_down_ending"] = {

    }
    // TODO
    screens["skinwalker_ending"] = {

    }

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
    }
}

run_side_effects :: proc(choice: choice) {
    for side_effect in choice.side_effects {
        side_effect()
    }
}

increment_self_doubt :: proc() {
    self_doubt += 1
}

decrement_self_doubt :: proc() {
    self_doubt -= 1
}

generate_crystals_loop :: proc() {
    // To avoid another global, load again here. TODO: Do it up better after jam.
    crystals_image := rl.LoadTexture("images/crystals.png")

    screens["crystals_loop"] = {
        image = crystals_image,
        // TODO
        text = fmt.caprintf(""),
        choices = {
            {
                text = "\"Hello?\"",
                screen_id = "crystals_loop",
                side_effects = {generate_crystals_loop, increment_self_doubt},
            },
            {
                text = "Keep listening.",
                screen_id = "crystals_loop",
                side_effects = {generate_crystals_loop, increment_self_doubt},
            },
            {
                text = "Ignore it and keep moving.",
                screen_id = "crossroads",
                side_effects = {decrement_self_doubt},
            },
        },
    }
}

generate_crossroads_loop :: proc() {
    // To avoid another global, load again here. TODO: Do it up better after jam.
    crossroads_image := rl.LoadTexture("images/crossroads.png")

    screens["crossroads_loop"] = {
        image = crossroads_image,
        // TODO
        text = fmt.caprintf(""),
        choices = {
            {
                text = "Take the high path.",
                screen_id = "high_path",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Take the low path.",
                screen_id = "low_path",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Think about which path to take.",
                screen_id = "crossroads_loop",
                side_effects = {generate_crossroads_loop, increment_self_doubt},
            },
        },
    }
}

// TODO
generate_owl_loop :: proc() {

}
