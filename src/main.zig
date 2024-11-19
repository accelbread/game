// game -- To be determined
// Copyright (C) 2024 Archit Gupta <archit@accelbread.com>
// Copyright (C) 2024 Jonathan Hendrickson <jonathan@jhendrickson.dev>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option) any
// later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const w4 = @import("wasm4.zig");
const images = @import("images.zig");
const Entity = @import("Entity.zig");

var tick: u8 = 0;

var prng: std.rand.DefaultPrng = undefined;
var random: std.rand.Random = undefined;

const init_lane = 1;

var bike: Entity = .{
    .x = 5,
    .y = lane_y[init_lane],
    .type = &Entity.Bike,
    .velocity = 1,
    .direction = .left,
};

var game_over = false;

// https://lospec.com/palette-list/coral-4
export fn start() void {
    prng = std.rand.DefaultPrng.init(0);
    random = prng.random();

    w4.PALETTE.* = .{
        0xffd0a4,
        0xf4949c,
        0x7c9aac,
        0x68518a,
    };

    entities[0] = Entity{
        .x = 160,
        .y = lane_y[2],
        .type = &Entity.Car,
        .velocity = -1,
        .direction = .left,
    };
}

var prev_input: u8 = 0;
var input_level: u8 = 0;
var input_edge: u8 = 0;

export fn update() void {
    tick +%= 1;

    input_level = w4.GAMEPAD1.*;
    input_edge = input_level & (input_level ^ prev_input);

    drawBg();

    if (game_over) {
        bike.render();
        for (entities) |slot| {
            if (slot) |entity| {
                entity.render();
            }
        }
        return;
    }

    bg_tick -%= 1;

    spawnEntities();

    handleInput();

    handleEntities();

    prev_input = input_level;
}

var bg_tick: u8 = 0;

fn drawBg() void {
    images.map.render(-@as(i32, 256) + bg_tick, 0, false);
    images.map.render(bg_tick, 0, false);
}

const lane_y: [6]u8 = .{ 38, 56, 78, 102, 125, 145 };
var lane: u8 = init_lane;

fn handleInput() void {
    if (input_edge & w4.BUTTON_UP != 0) {
        lane -|= 1;
        if (lane < 1) {
            lane = 1;
        }
    }
    if (input_edge & w4.BUTTON_DOWN != 0) {
        lane += 1;
        if (lane > 4) {
            lane = 4;
        }
    }
    bike.y = lane_y[lane];
    bike.velocity = 1;
    if ((input_level & w4.BUTTON_LEFT != 0) and
        (bike.x + bike.type.hitbox.x1 > 0))
    {
        bike.velocity -= 1;
    }
    if ((input_level & w4.BUTTON_RIGHT != 0) and
        (bike.x + bike.type.hitbox.x2 < 160))
    {
        bike.velocity += 1;
    }
}

fn spawnEntities() void {
    if (random.uintAtMost(u8, 25) < 1) {
        for (&entities) |*slot| {
            if (slot.* == null) {
                const entity_type = if (random.uintAtMost(u8, 3) < 3)
                    &Entity.Car
                else
                    &Entity.Truck;
                const entity_lane = random.uintAtMost(usize, 3) + 1;
                const left = entity_lane <= 2;
                var velocity: i8 = 2;
                if (random.uintAtMost(u8, 10) == 0) {
                    velocity += 1;
                }
                if (left) {
                    velocity *= -1;
                }
                slot.* = Entity{
                    .type = entity_type,
                    .x = if (left) 160 else -@as(i32, entity_type.hitbox.x2),
                    .y = @as(i32, lane_y[entity_lane]) + entity_type.y_offset,
                    .velocity = velocity,
                    .direction = if (left) .left else .right,
                };

                return;
            }
        }
        w4.trace("Spawn slots full.");
    }
}

var entities: [100]?Entity = .{null} ** 100;

fn handleEntities() void {
    bike.move();
    bike.render();

    for (&entities) |*slot| {
        if (slot.*) |*entity| {
            entity.move();
            entity.render();
            if (bike.collides(entity)) {
                game_over = true;
                w4.PALETTE.* = .{
                    0x68518a,
                    0x7c9aac,
                    0xf4949c,
                    0xffd0a4,
                };
            }
            if (entity.cleanup()) {
                slot.* = null;
            }
        }
    }
}
