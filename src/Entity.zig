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

const HitBox = struct { x1: u8, y1: u8, x2: u8, y2: u8 };

const EntityType = struct {
    hitbox: HitBox,
    render: *const fn (x: i32, y: i32, flip: bool) void,
    y_offset: i16 = 0,
};

pub const Bike: EntityType = .{
    .hitbox = .{ .x1 = 0, .y1 = 0, .x2 = 13, .y2 = 11 },
    .render = images.bike.render,
};

pub const Car: EntityType = .{
    .hitbox = .{ .x1 = 0, .y1 = 0, .x2 = 24, .y2 = 12 },
    .render = images.car.render,
};

pub const Truck: EntityType = .{
    .hitbox = .{ .x1 = 0, .y1 = 0, .x2 = 33, .y2 = 17 },
    .render = images.truck.render,
    .y_offset = -1,
};

const Direction = enum { left, right };

type: *const EntityType,
direction: Direction,
velocity: i8,
x: i32,
y: i32,

const Self = @This();

pub fn render(self: *const Self) void {
    self.type.render(self.x, self.y, self.direction == .right);
}

pub fn cleanup(self: *const Self) bool {
    return switch (self.direction) {
        .left => (self.x + self.type.hitbox.x2) < 0,
        .right => (self.x + self.type.hitbox.x1) > 160,
    };
}

pub fn move(self: *Self) void {
    self.x += self.velocity - 1;
}

const Bounds = struct {
    x1: i32,
    y1: i32,
    x2: i32,
    y2: i32,

    fn overlap(b1: Bounds, b2: Bounds) bool {
        const x_hit = ((b1.x1 >= b2.x1) and (b1.x1 < b2.x2)) or
            ((b1.x2 <= b2.x2) and (b1.x2 > b2.x1));
        const y_hit = ((b1.y1 >= b2.y1) and (b1.y1 < b2.y2)) or
            ((b1.y2 <= b2.y2) and (b1.y2 > b2.y1));
        return x_hit and y_hit;
    }
};

fn getBounds(self: *const Self) Bounds {
    return Bounds{
        .x1 = self.x + self.type.hitbox.x1,
        .x2 = self.x + self.type.hitbox.x2,
        .y1 = self.y + self.type.hitbox.y1,
        .y2 = self.y + self.type.hitbox.y2,
    };
}

pub fn collides(self: *const Self, other: *const Self) bool {
    return self.getBounds().overlap(other.getBounds());
}
