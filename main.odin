package main

import "core:fmt"
import "core:mem"
import "core:math/rand"
import rl "vendor:raylib"

TARGET_FPS :: 60
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Wonderlust"

Wrap_State :: enum {
    Measure_State,
    Draw_State,
}

TEXT_SIZE :: 20

IMAGE_X :: 140
IMAGE_Y :: 0

BANNER_Y :: 0
LEFT_BANNER_X :: 0
RIGHT_BANNER_X :: 1140

TEXT_AREA_COLOR :: rl.Color {84, 51, 68, 255}

TEXT_BOX_BACKGROUND_COLOR :: rl.Color {81, 82, 98, 255}
TEXT_BOX_TEXT_COLOR :: rl.Color {202, 160, 90, 255}

CHOICE_BOX_COLOR :: rl.Color {174, 106, 71, 128}

CHOICE_BACKGROUND_COLOR :: rl.Color {81, 82, 98, 255}
CHOICE_TEXT_COLOR :: rl.Color {202, 160, 90, 255}
SELECTED_CHOICE_BACKGROUND_COLOR :: rl.Color {202, 160, 90, 255}
SELECTED_CHOICE_TEXT_COLOR :: rl.Color {81, 82, 98, 255}
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

restart_choice := choice {
    text = "Restart.",
    screen_id = "intro",
    side_effects = {reset_self_doubt},
}

screen :: struct {
    image: rl.Texture2D,
    text: cstring,
    choices: []choice,
}

screens: map[cstring]screen

self_doubt: int

main :: proc() {
    // Tracking allocator code adapted from Karl Zylinski's tutorials.
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
                screen_id = "intro_loop",
                side_effects = {increment_self_doubt},
            },
            {
                text = "Turn back.",
                screen_id = "early_ending",
            },
        },
    }
    screens["intro_loop"] = {
        image = cave_entrance_image,
        text = "Maybe it wasn't such a hot idea. That forest was something else, but at least the boy knew the long and short of it. There could be anything in that cave. There could be nothing. Then again, maybe everything would be okay if he went underground.",
        choices = {
            {
                text = "Keep thinking about it.",
                screen_id = "intro_loop",
                side_effects = {increment_self_doubt, generate_intro_loop},
            },
            {
                text = "Go in.",
                screen_id = "crystals",
            },
            {
                text = "Turn back.",
                screen_id = "early_ending",
            },
        },
    }
    screens["early_ending"] = {
        image = cave_entrance_image,
        text = "It was probably for the best. Who could tell?",
        choices = {
            restart_choice,
        },
    }
    screens["crystals"] = {
        image = crystals_image,
        text = "The young man squeezed through the low mouth of the cave. He had to stoop for a few moments of shuffling in the dark before the mouth let out into a dimly illuminated tunnel. He could stand here. The source of light was plain to see; a massive growth of shimmering, golden crystals sticking out of the tunnel wall. The young man started to move on, but stopped when he thought he heard something. It sounded like running water rushing away somewhere. There was a monotonous dripping sound, too. Actually, the young man thought it sounded like whispering.",
        choices = {
            {
                text = "Listen closely.",
                screen_id = "crystals_loop",
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
        text = "The boy held his breath and inclined his head toward the wall. The drip-dropping (whispering?) seemed to recede. Then he heard it again, more clearly. He thought he could make out a few words. Something like \"drip drip drip pssh woods drip tonight psssh\".",
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
        text = "The whispering or dripping or whatever it was stopped immediately (the boy thought he could still hear it for a second, but definitely not.) The sound of rushing water was still proceeding steadily, presumably somewhere far away. Or was that just the sound of the inside of the boy's ears?",
        choices = {
            {
                text = "\"Did someone follow me in here? Show yourself!\"",
                screen_id = "crystals_loop",
                side_effects = {generate_crystals_loop, increment_self_doubt},
            },
            {
                text = "Get moving.",
                screen_id = "crossroads",
            },
        },
    }
    screens["crossroads"] = {
        image = crossroads_image,
        text = "The tunnel let out two ways, separated by a craggy cavern wall; one went higher and the other went lower. The young man had to choose a path.",
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
                side_effects = {increment_self_doubt},
            },
        },
    }
    screens["crossroads_loop"] = {
        image = crossroads_image,
        text = "It was a tough choice. The boy figured going higher probably meant heading toward the overground. Then again, going lower might mean he would be aided by gravity. He thought his father had said something like that once. Did he laugh when he said that?",
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
    screens["high_path"] = {
        image = high_path_image,
        text = "The young man had to squeeze through a narrow part of the cave to come out onto an even narrower ledge. No longer afforded the crystal's dim glow, he had to let his eyes adjust to the darkness. Once, he nearly stepped off into nothing. When his eyes adjusted, he still couldn't see the bottom of the space he nearly walked off into.",
        choices = {
            {
                text = "Shut your eyes and sidle along.",
                screen_id = "owl",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Look down.",
                screen_id = "look_down",
                side_effects = {increment_self_doubt},
            },
        },
    }
    screens["look_down"] = {
        image = high_path_image,
        text = "The boy felt a sudden rush of vertigo nearly caused him to keel over the edge then and there. He gripped the wall behind him as best he could, scrabbling to hold onto the crumbling, sheer stone. Somehow he didn't fall. His eyes were still peering into the chasm below (he could see now, clearly, that it was deep.) He thought he saw something shiny and golden down there. Some part of the boy's subconscious stirred at that sight. His hands were shaking and his breath was ragged, still enduring that lightheadedness brought on by nearly falling to one's death (or maybe he just imagined it and his footing had been just fine.)",
        choices = {
            {
                text = "Squint your eyes and lean in to get a better look.",
                screen_id = "fall_down_ending",
            },
            {
                text = "Breathe slowly until you regain your nerve.",
                screen_id = "owl",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Shut your eyes and look away.",
                screen_id = "owl",
            },
        },
    }
    screens["low_path"] = {
        image = low_path_image,
        text = "The young man had an easy enough time proceeding down the low path. He just had to avoid stumbling on the little rocks and cracks in the ground, as well as his own feet. The path let out into a tunnel, wider than the one he had just left, but pitch black. He went on for a while and all the ambient sounds that could be distant echoes of the cavern's ecosystem faded out. It was completely still. The only sounds were his own footfalls. Every once in a while, he thought he heard a scraping sound some distance behind him, like someone was raking the cavern wall with a spade.",
        choices = {
            {
                text = "Stop and listen closely.",
                screen_id = "who_goes_there",
            },
            {
                text = "Keep walking.",
                screen_id = "owl",
                side_effects = {decrement_self_doubt},
            },
        },
    }
    screens["who_goes_there"] = {
        image = low_path_image,
        text = "After he heard the scraping sound one too many times for him to discount it completely, the boy stopped and snapped around a hundred and eighty degrees. He inclined his head in the direction he had come from and listened. Silence. He still couldn't see a thing and strongly wished that he could. After what seemed like an hour (was it really?) he heard the scraping sound again, closer and more regular and different some other way. It was like the same sound had echoed and laid over itself three or four times again.",
        choices = {
            {
                text = "Hurry along.",
                screen_id = "owl",
                side_effects = {decrement_self_doubt},
            },
            {
                text = "Confront whoever's making the sound.",
                screen_id = "skinwalker_ending",
            },
        },
    }
    screens["owl"] = {
        image = owl_image,
        text = "The path crested into a small chamber. The young man could see a little better there. At the far end of the chamber was a small rock with something moving sitting on top. His heart raced for a moment and then relented when he realized it was an owl. The animal's flashing gray eyes seemed to stare into the young man's and give him some comfort. To the owl's left, a light shone dimly from the entrance of another narrow path.",
        choices = {
            {
                text = "Examine the owl.",
                screen_id = "owl_loop",
            },
            {
                text = "\"Who, owl?\"",
                screen_id = "owl_loop",
            },
            {
                text = "Ignore the owl and move on.",
                screen_id = "ending",
                side_effects = {generate_ending},
            },
        },
    }
    screens["owl_loop"] = {
        image = owl_image,
        text = "The owl hooted.",
        choices = {
            {
                text = "\"Who?\"",
                screen_id = "owl_loop",
                side_effects = {increment_self_doubt},
            },
            {
                text = "Smirk and move on.",
                screen_id = "ending",
                side_effects = {generate_ending},
            },
        },
    }
    screens["fall_down_ending"] = {
        image = low_path_image,
        text = "The boy squinted his eyes like he was trying to light a fire with his dusty ‘lids. He leaned further and further…and further. Finally, he leaned too far and lost his footing. He plunged into that yawning abyss and was never seen or heard from again. All that glitters is not gold.",
        choices = {
            restart_choice,
        },
    }
    screens["skinwalker_ending"] = {
        image = skinwalker_image,
        text = "The boy hitched up his britches and marched back up the tunnel, double-time. He had suspected for some days that he was being followed and now he intended to interrogate his stalker. He bumped into something and realized the space in front of him was a richer black than the space his eyes had become accustomed to. Grasping around in front of him, he grabbed handfuls of thick strands like a rabbit skin cap he owned as a small child. He looked up and saw a cracked, yellowish coyote skull with two black chasms peering down in his direction and was never seen or heard from again. Beware things that go bump in the night.",
        choices = {
            restart_choice,
        },
    }

    current_screen := screens["intro"]

    mouse_position: rl.Vector2

    for !rl.WindowShouldClose() {
        mouse_position = rl.GetMousePosition()

        choice1_selected: bool
        choice2_selected: bool
        choice3_selected: bool

        if rl.CheckCollisionPointRec(mouse_position, choice_rect1) {
            choice1_selected = true
        } else if rl.CheckCollisionPointRec(mouse_position, choice_rect2) {
            choice2_selected = true
        } else if rl.CheckCollisionPointRec(mouse_position, choice_rect3) {
            choice3_selected = true
        }

        if rl.IsMouseButtonReleased(.LEFT) {
            if choice1_selected {
                current_screen = screens[current_screen.choices[0].screen_id]
            } else if choice2_selected && len(current_screen.choices) >= 2 {
                current_screen = screens[current_screen.choices[1].screen_id]
            } else if choice3_selected && len(current_screen.choices) == 3 {
                current_screen = screens[current_screen.choices[2].screen_id]
            }
        }

        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(rl.GRAY)

        current_image = current_screen.image

        rl.DrawTexture(current_image, IMAGE_X, IMAGE_Y, rl.WHITE)
        rl.DrawTexture(left_banner_image, LEFT_BANNER_X, BANNER_Y, rl.WHITE)
        rl.DrawTexture(right_banner_image, RIGHT_BANNER_X, BANNER_Y, rl.WHITE)

        rl.DrawRectangleRec(text_area_rect, TEXT_AREA_COLOR)
        rl.DrawRectangleRec(text_box_rect, TEXT_BOX_BACKGROUND_COLOR)

        draw_text_boxed(font, current_screen.text, text_box_rect, TEXT_SIZE, 0, TEXT_BOX_TEXT_COLOR)

        rl.DrawRectangleRec(choice_box_rect, CHOICE_BOX_COLOR)

        if choice1_selected {
            rl.DrawRectangleRec(choice_rect1, SELECTED_CHOICE_BACKGROUND_COLOR)
            draw_text_boxed(font, current_screen.choices[0].text, choice_rect1, TEXT_SIZE, 0, SELECTED_CHOICE_TEXT_COLOR)
        } else {
            rl.DrawRectangleRec(choice_rect1, CHOICE_BACKGROUND_COLOR)
            draw_text_boxed(font, current_screen.choices[0].text, choice_rect1, TEXT_SIZE, 0, CHOICE_TEXT_COLOR)
        }
        if len(current_screen.choices) >= 2 {
            if choice2_selected {
                rl.DrawRectangleRec(choice_rect2, SELECTED_CHOICE_BACKGROUND_COLOR)
                draw_text_boxed(font, current_screen.choices[1].text, choice_rect2, TEXT_SIZE, 0, SELECTED_CHOICE_TEXT_COLOR)
            } else {
                rl.DrawRectangleRec(choice_rect2, CHOICE_BACKGROUND_COLOR)
                draw_text_boxed(font, current_screen.choices[1].text, choice_rect2, TEXT_SIZE, 0, CHOICE_TEXT_COLOR)
            }
        }
        if len(current_screen.choices) == 3 {
            if choice3_selected {
                rl.DrawRectangleRec(choice_rect3, SELECTED_CHOICE_BACKGROUND_COLOR)
                draw_text_boxed(font, current_screen.choices[2].text, choice_rect3, TEXT_SIZE, 0, SELECTED_CHOICE_TEXT_COLOR)
            } else {
                rl.DrawRectangleRec(choice_rect3, CHOICE_BACKGROUND_COLOR)
                draw_text_boxed(font, current_screen.choices[2].text, choice_rect3, TEXT_SIZE, 0, CHOICE_TEXT_COLOR)
            }
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

generate_intro_loop :: proc() {
    // To avoid another global, load again here. TODO: Do it up better after jam.
    cave_entrance_image := rl.LoadTexture("images/cave_entrance.png")

    screens["intro"] = {
        image = cave_entrance_image,
        // TODO
        text = fmt.caprintf(""),
        choices = {
            {
                text = "Plunge in.",
                screen_id = "crystals",
            },
            {
                text = "Think about whether going into the cave is a good idea.",
                screen_id = "intro_loop",
                side_effects = {increment_self_doubt},
            },
            {
                text = "Turn back.",
                screen_id = "early_ending",
            },
        },
    }
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

generate_ending :: proc() {
    cave_exit_image := rl.LoadTexture("images/cave_exit.png")

    screens["ending"] = {
        image = cave_exit_image,
        // TODO
        text = fmt.caprintf(""),
        // TODO
        choices = {
            restart_choice,
        },
    }
}

reset_self_doubt :: proc() {
    self_doubt = 0
}

// Adapted from an example by Vlad Adrian and Ramon Santamaria
draw_text_boxed :: proc(font: rl.Font, text: cstring, rect: rl.Rectangle, font_size: f32, spacing: f32, tint: rl.Color) {
    draw_text_boxed_selectable(font, text, rect, font_size, spacing, tint, 0, 0, rl.WHITE, rl.WHITE)
}

draw_text_boxed_selectable :: proc(font: rl.Font, text: cstring, rect: rl.Rectangle, font_size: f32, spacing: f32, tint: rl.Color, select_start: int, select_length: int, select_tint: rl.Color, select_back_tint: rl.Color) {
    select_start := select_start

    text_as_bytes := transmute([^]u8)text

    length := rl.TextLength(text)

    text_offset_x: f32
    text_offset_y: f32

    scale_factor := font_size / f32(font.baseSize)

    // Word/character wrapping mechanism variable
    state := Wrap_State.Draw_State

    start_line := -1
    end_line := -1
    last_k := -1

    for i, k in 0..<length {
        i := i
        k := k
        // Get next codepoint from byte string and glyph index in font
        codepoint_byte_count: i32
        codepoint := rl.GetCodepoint(cstring(&text_as_bytes[i]), &codepoint_byte_count)
        index := rl.GetGlyphIndex(font, codepoint)

        // NOTE: Normally we exit the decoding sequence as soon as a bad byte is found (and return 0x3f)
        // but we need to draw all of the bad bytes using the '?' symbol moving one byte
        if codepoint == 0x3f {
            codepoint_byte_count = 1
        }
        i += u32(codepoint_byte_count - 1)

        glyph_width: f32
        if codepoint != '\n' {
            glyph_width = (font.glyphs[index].advanceX == 0) ? font.recs[index].width * scale_factor : f32(font.glyphs[index].advanceX) * scale_factor

            if i + 1 < length {
                glyph_width = glyph_width + spacing
            }
        }

        if state == .Measure_State {
            if codepoint == ' ' || codepoint == '\t' || codepoint == '\n' {
                end_line = int(i)
            }

            if text_offset_x + glyph_width > rect.width {
                end_line = end_line < 1 ? int(i) : end_line
                if i == u32(end_line) {
                    end_line -= int(codepoint_byte_count)
                }
                if start_line + int(codepoint_byte_count) == end_line {
                    end_line = int(i) - int(codepoint_byte_count)
                }

                state = toggle_wrap_state(state)
            } else if i + 1 == length {
                end_line = int(i)
                state = toggle_wrap_state(state)
            } else if codepoint == '\n' {
                state = toggle_wrap_state(state)
            }

            if state == .Draw_State {
                text_offset_x = 0
                i = u32(start_line)
                glyph_width = 0

                // Save character position when we switch states
                tmp := last_k
                last_k = k - 1
                k = tmp
            }
        } else {
            if codepoint == '\n' {
                text_offset_y += f32(font.baseSize + font.baseSize / 2) * scale_factor
                text_offset_x = 0
            } else {
                if text_offset_x + glyph_width > rect.width {
                    text_offset_y += f32(font.baseSize + font.baseSize / 2) * scale_factor
                    text_offset_x = 0
                }

                // When text overflows rectangle height limit, just stop drawing
                if text_offset_y + f32(font.baseSize) * scale_factor > rect.height {
                    break
                }

                // Draw selection background
                is_glyph_selected: bool
                if select_start >= 0 && k >= select_start && k < select_start + select_length {
                    rl.DrawRectangleRec({rect.x + text_offset_x - 1, rect.y + text_offset_y, glyph_width, f32(font.baseSize) * scale_factor}, select_back_tint)
                    is_glyph_selected = true
                }

                // Draw current character glyph
                if codepoint != ' ' && codepoint != '\t' {
                    rl.DrawTextCodepoint(font, codepoint, {rect.x + text_offset_x, rect.y + text_offset_y}, font_size, is_glyph_selected ? select_tint : tint)
                }
            }
        }

        // Avoid leading spaces
        if text_offset_x != 0 || codepoint != ' ' {
            text_offset_x += glyph_width
        }
    }
}

toggle_wrap_state :: proc(state: Wrap_State) -> Wrap_State {
    if state == .Draw_State {
        return .Measure_State
    } else {
        return .Draw_State
    }
}
