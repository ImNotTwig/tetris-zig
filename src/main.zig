const std = @import("std");
const rl = @import("raylib");
const mc = @import("my_colors.zig");
const Vec2 = rl.Vector2;

const hiddenTiles = 3;
const boardHeight = 23;
const boardWidth = 10;

const Tile = union(enum) {
    Filled: rl.Color,
    Empty,
};

const Shape = struct {
    blocks: [4]struct {
        point: Vec2,
        color: rl.Color,
    },

    fn rotate(self: *@This()) void {
        for (0.., self.blocks) |i, j| {
            const tmp = j.point.x;
            self.blocks[i].point.x = -j.point.y;
            self.blocks[i].point.y = tmp;
        }
    }

    const I: Shape = .{
        .blocks = .{
            .{ .point = Vec2.init(0, -1), .color = mc.FFCyan },
            .{ .point = Vec2.init(0, 0), .color = mc.FFCyan },
            .{ .point = Vec2.init(0, 1), .color = mc.FFCyan },
            .{ .point = Vec2.init(0, 2), .color = mc.FFCyan },
        },
    };
};

const Board = struct {
    fallingShape: Shape,
    tiles: [boardWidth][boardHeight]Tile,
};

const Game = struct {
    board: Board,
    bag: std.ArrayList(Shape),
    bgColors: [2]rl.Color,

    fn init(allocator: std.mem.Allocator) Game {
        var x: [boardWidth][boardHeight]Tile = undefined;
        for (0.., x) |i, v| {
            for (0.., v) |j, _| {
                x[i][j] = .Empty;
            }
        }

        return Game{
            .board = .{
                .fallingShape = undefined,
                .tiles = x,
            },
            .bag = std.ArrayList(Shape).init(allocator),
        };
    }
};

pub fn main() !void {
    const screenHeight = 1000;
    const screenWidth = 500;

    rl.setConfigFlags(.{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });

    rl.initWindow(screenWidth, screenHeight, "Tetris");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const g = Game.init();
    _ = g;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        rl.drawRectangle(0, 0, 100, 100, rl.Color.white);
    }
}
