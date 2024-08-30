const std = @import("std");
const rand = std.crypto.random;
const rl = @import("raylib");
const mc = @import("my_colors.zig");
const Vec2 = rl.Vector2;

const hiddenTiles = 3;
const boardHeight = 23;
const boardWidth = 10;

const tileSpacing = 5;

const boardScale: f32 = 0.75;

var screenHeight: i32 = 1000;
var screenWidth: i32 = 500;

const Tile = union(enum) {
    Filled: rl.Color,
    Empty,
};

const Shape = struct {
    blocks: [4]struct {
        point: Vec2,
        color: rl.Color,
    },
    origin: usize, // should always be the index of the block at 0,0 initially

    fn maxWidth(self: @This()) usize {
        const w = self.width();
        const h = self.height();
        if (w > h) return w else return h;
    }

    fn width(self: @This()) usize {
        var sortedBlocks = self.blocks;
        std.mem.sort(@TypeOf(self.blocks[0]), &sortedBlocks, {}, struct {
            fn f(_: void, a: @TypeOf(self.blocks[0]), b: @TypeOf(a)) bool {
                return a.point.x < b.point.x;
            }
        }.f);

        var xWidth: usize = 1;
        var curX = sortedBlocks[0].point.x;
        for (1.., self.blocks) |i, _| {
            if (i >= self.blocks.len) continue;
            if (curX < sortedBlocks[i].point.x) {
                xWidth += 1;
                curX = sortedBlocks[i].point.x;
            }
        }
        return xWidth;
    }

    fn height(self: @This()) usize {
        var sortedBlocks = self.blocks;
        std.mem.sort(@TypeOf(self.blocks[0]), &sortedBlocks, {}, struct {
            fn f(_: void, a: @TypeOf(self.blocks[0]), b: @TypeOf(a)) bool {
                return a.point.y < b.point.y;
            }
        }.f);

        var yWidth: usize = 1;
        var curY = sortedBlocks[0].point.y;
        for (1.., self.blocks) |i, _| {
            if (i >= self.blocks.len) continue;
            if (curY < sortedBlocks[i].point.y) {
                yWidth += 1;
                curY = sortedBlocks[i].point.y;
            }
        }
        return yWidth;
    }

    fn minX(self: @This()) i8 {
        var minx: i8 = 0;
        for (self.blocks) |i| {
            if (@as(i8, @intFromFloat(i.point.x)) < minx) {
                minx = @intFromFloat(i.point.x);
            }
        }
        return minx;
    }
    fn minY(self: @This()) i8 {
        var miny: i8 = 0;
        for (self.blocks) |i| {
            if (@as(i8, @intFromFloat(i.point.y)) < miny) {
                miny = @intFromFloat(i.point.y);
            }
        }
        return miny;
    }
    fn maxY(self: @This()) i8 {
        var maxy: i8 = 0;
        for (self.blocks) |i| {
            if (@as(i8, @intFromFloat(i.point.y)) > maxy) {
                maxy = @intFromFloat(i.point.y);
            }
        }
        return maxy;
    }

    const I = Shape{
        .origin = 1,
        .blocks = .{
            .{ .point = Vec2.init(0, -1), .color = mc.FFCyan },
            .{ .point = Vec2.init(0, 0), .color = mc.FFCyan },
            .{ .point = Vec2.init(0, 1), .color = mc.FFCyan },
            .{ .point = Vec2.init(0, 2), .color = mc.FFCyan },
        },
    };
    const J = Shape{
        .blocks = .{
            .{ .point = Vec2.init(-1, 1), .color = mc.FFMagenta },
            .{ .point = Vec2.init(0, -1), .color = mc.FFMagenta },
            .{ .point = Vec2.init(0, 0), .color = mc.FFMagenta },
            .{ .point = Vec2.init(0, 1), .color = mc.FFMagenta },
        },
        .origin = 2,
    };
    const L = Shape{
        .blocks = .{
            .{ .point = Vec2.init(0, -1), .color = mc.FFBlue },
            .{ .point = Vec2.init(0, 0), .color = mc.FFBlue },
            .{ .point = Vec2.init(0, 1), .color = mc.FFBlue },
            .{ .point = Vec2.init(1, 1), .color = mc.FFBlue },
        },
        .origin = 1,
    };
    const Z = Shape{
        .blocks = .{
            .{ .point = Vec2.init(-1, 0), .color = mc.FFRed },
            .{ .point = Vec2.init(0, 0), .color = mc.FFRed },
            .{ .point = Vec2.init(0, 1), .color = mc.FFRed },
            .{ .point = Vec2.init(1, 1), .color = mc.FFRed },
        },
        .origin = 1,
    };
    const S = Shape{
        .blocks = .{
            .{ .point = Vec2.init(-1, 1), .color = mc.FFGreen },
            .{ .point = Vec2.init(0, 0), .color = mc.FFGreen },
            .{ .point = Vec2.init(0, 1), .color = mc.FFGreen },
            .{ .point = Vec2.init(1, 0), .color = mc.FFGreen },
        },
        .origin = 1,
    };
    const O = Shape{
        .blocks = .{
            .{ .point = Vec2.init(-1, 0), .color = mc.FFYellow },
            .{ .point = Vec2.init(-1, 1), .color = mc.FFYellow },
            .{ .point = Vec2.init(0, 0), .color = mc.FFYellow },
            .{ .point = Vec2.init(0, 1), .color = mc.FFYellow },
        },
        .origin = 2,
    };
    const T = Shape{
        .blocks = .{
            .{ .point = Vec2.init(-1, 0), .color = mc.FFPurple },
            .{ .point = Vec2.init(0, 0), .color = mc.FFPurple },
            .{ .point = Vec2.init(0, -1), .color = mc.FFPurple },
            .{ .point = Vec2.init(1, 0), .color = mc.FFPurple },
        },
        .origin = 1,
    };
    fn getShape(i: usize) Shape {
        switch (i) {
            0 => return Shape.I,
            1 => return Shape.J,
            2 => return Shape.L,
            3 => return Shape.O,
            4 => return Shape.S,
            5 => return Shape.T,
            6 => return Shape.Z,
            else => unreachable,
        }
    }
};

const Board = struct {
    fallingShape: Shape,
    tiles: [boardWidth][boardHeight]Tile,

    fn newFallingShape(self: *@This(), shape: Shape) void {
        self.fallingShape = shape;
        const pad: f32 = @as(f32, @floatFromInt((boardWidth - self.fallingShape.maxWidth()) / 2));
        if (self.fallingShape.width() < self.fallingShape.height()) {
            self.rotateLeft();
        }
        for (&self.fallingShape.blocks) |*i| {
            i.point.x += pad + 1;
            i.point.y -= hiddenTiles;
        }
    }

    //FIXME: Hey this rotation shit aint cutting it, it doesnt work like traditional tetris at all tbh

    fn rotateNew(self: *@This()) void {
        var averageCoord = Vec2{ .x = 0, .y = 0 };
        for (self.fallingShape.blocks) |block| {
            averageCoord.x += block.point.x;
            averageCoord.y += block.point.y;
        }
        averageCoord.x /= self.fallingShape.blocks.len;
        averageCoord.y /= self.fallingShape.blocks.len;
    }

    fn rotate(self: *@This()) void {
        var newBlocks: [4]struct { point: Vec2, color: rl.Color } = undefined;
        const ox = self.fallingShape.blocks[self.fallingShape.origin].point.x;
        const oy = self.fallingShape.blocks[self.fallingShape.origin].point.y;

        for (0.., self.fallingShape.blocks) |i, j| {
            const tmp = j.point.x - self.fallingShape.blocks[self.fallingShape.origin].point.x;
            newBlocks[i].point.x = -(j.point.y - self.fallingShape.blocks[self.fallingShape.origin].point.y);
            newBlocks[i].point.y = tmp;
            if (newBlocks[i].point.x + ox >= 0 and newBlocks[i].point.y + oy >= 0) {
                const ix: usize = @intFromFloat(newBlocks[i].point.x + ox);
                const iy: usize = @intFromFloat(newBlocks[i].point.y + oy);
                if (ix >= boardWidth or iy >= boardHeight) return;
                switch (self.tiles[ix][iy]) {
                    .Filled => return,
                    else => {},
                }
            } else if (newBlocks[i].point.x + ox < 0) return;
        }
        for (0.., newBlocks) |i, v| {
            self.fallingShape.blocks[i].point.x = v.point.x + ox;
            self.fallingShape.blocks[i].point.y = v.point.y + oy;
            if (self.fallingShape.blocks[i].point.x == 0 and self.fallingShape.blocks[i].point.y == 0) self.fallingShape.origin = i;
        }
    }
    fn rotateLeft(self: *@This()) void {
        var newBlocks: [4]struct { point: Vec2, color: rl.Color } = undefined;
        const ox = self.fallingShape.blocks[self.fallingShape.origin].point.x;
        const oy = self.fallingShape.blocks[self.fallingShape.origin].point.y;

        for (0.., self.fallingShape.blocks) |i, j| {
            const tmp = j.point.x - self.fallingShape.blocks[self.fallingShape.origin].point.x;
            newBlocks[i].point.x = (j.point.y - self.fallingShape.blocks[self.fallingShape.origin].point.y);
            newBlocks[i].point.y = -tmp;
            if (newBlocks[i].point.x + ox >= 0 and newBlocks[i].point.y + oy >= 0) {
                const ix: usize = @intFromFloat(newBlocks[i].point.x + ox);
                const iy: usize = @intFromFloat(newBlocks[i].point.y + oy);
                if (ix >= boardWidth or iy >= boardHeight) return;
                switch (self.tiles[ix][iy]) {
                    .Filled => return,
                    else => {},
                }
            } else if (newBlocks[i].point.x + ox < 0) return;
        }
        for (0.., newBlocks) |i, v| {
            self.fallingShape.blocks[i].point.x = v.point.x + ox;
            self.fallingShape.blocks[i].point.y = v.point.y + oy;
        }
    }

    fn moveShapeLeft(self: *@This()) void {
        for (self.fallingShape.blocks) |i| {
            if (i.point.x - 1 < 0) return;
            if (i.point.y >= 0) {
                switch (self.tiles[@intFromFloat(i.point.x - 1)][@intFromFloat(i.point.y)]) {
                    .Filled => return,
                    else => {},
                }
            }
        }
        for (&self.fallingShape.blocks) |*i| {
            i.point.x -= 1;
        }
    }

    fn moveShapeRight(self: *@This()) void {
        for (self.fallingShape.blocks) |i| {
            if (i.point.x + 1 >= boardWidth) return;
            if (i.point.y >= 0) {
                switch (self.tiles[@intFromFloat(i.point.x + 1)][@intFromFloat(i.point.y)]) {
                    .Filled => return,
                    else => {},
                }
            }
        }
        for (&self.fallingShape.blocks) |*i| {
            i.point.x += 1;
        }
    }

    fn updateFallingShape(self: *@This()) bool {
        if (self.fallingShape.maxY() + 1 >= boardHeight - hiddenTiles) return false;
        for (0.., self.tiles) |i, columns| {
            for (0.., columns) |j, tile| {
                switch (tile) {
                    .Filled => {
                        for (self.fallingShape.blocks) |b| {
                            if (b.point.x == @as(f32, @floatFromInt(i)) and b.point.y + 1 == @as(f32, @floatFromInt(j))) {
                                return false;
                            }
                        }
                    },
                    .Empty => {},
                }
            }
        }
        for (&self.fallingShape.blocks) |*i| {
            i.point.y += 1;
        }
        return true;
    }
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
            .bgColors = .{ mc.FFBg, mc.FFBgAlt },
            .bag = std.ArrayList(Shape).init(allocator),
        };
    }

    fn finalizeFallingShape(self: *@This()) !void {
        for (self.board.fallingShape.blocks) |i| {
            self.board.tiles[@intFromFloat(i.point.x)][@intFromFloat(i.point.y)] = .{ .Filled = i.color };
        }
        try self.nextShape();
    }

    fn mixNewBag(self: *@This()) !void {
        const contains = struct {
            fn contains(arr: std.ArrayList(Shape), target: Shape) bool {
                for (arr.items) |element| {
                    if (std.meta.eql(element, target)) {
                        return true;
                    }
                }
                return false;
            }
        }.contains;
        var i = rand.intRangeAtMost(usize, 0, 6);
        var shape = Shape.getShape(i);
        while (self.bag.items.len < 7) {
            while (contains(self.bag, shape)) {
                i = rand.intRangeAtMost(usize, 0, 6);
                shape = Shape.getShape(i);
            }

            try self.bag.append(shape);
        }
    }

    fn nextShape(self: *@This()) !void {
        if (self.bag.popOrNull()) |x| {
            self.board.newFallingShape(x);
        } else {
            try self.mixNewBag();
            try self.nextShape();
        }
    }

    fn clearBoard(self: *@This()) void {
        for (0.., self.board.tiles) |i, v| {
            for (0.., v) |j, _| {
                self.board.tiles[i][j] = .Empty;
            }
        }
    }

    fn drawBoard(self: @This()) !void {
        const fScreenWidth: f32 = @floatFromInt(screenWidth);
        const fScreenHeight: f32 = @floatFromInt(screenHeight);
        const fBoardWidth: f32 = @floatFromInt(boardWidth);
        const fBoardHeight: f32 = @floatFromInt(boardHeight);

        // const monitorHeight: f32 = @floatFromInt(rl.getMonitorHeight(rl.getCurrentMonitor()));

        // const maxSize: f32 = (monitorHeight / (fBoardHeight));

        const tileWidth: f32 = boardScale * (fScreenHeight / (fBoardHeight));
        const tileHeight: f32 = boardScale * (fScreenHeight / (fBoardHeight));

        const padH = (fScreenWidth - fBoardWidth * tileWidth) / 2;
        const padV = ((fScreenHeight - fBoardHeight * tileHeight) + hiddenTiles * tileHeight) / 2;

        for (0..boardWidth) |x| {
            for (0..boardHeight - hiddenTiles) |y| {
                const c = switch (self.board.tiles[x][y]) {
                    .Filled => |c| c,
                    .Empty => if ((x + y) % 2 == 0) self.bgColors[0] else self.bgColors[1],
                };

                const tileSpaceScale: f32 = switch (self.board.tiles[x][y]) {
                    .Filled => 1,
                    .Empty => 0,
                };

                const fx: f32 = @floatFromInt(x);
                const fy: f32 = @floatFromInt(y);

                rl.drawRectangleV(
                    Vec2.init(
                        (tileWidth * fx) + tileSpaceScale * (tileSpacing / 2) + padH,
                        (tileWidth * fy) + tileSpaceScale * (tileSpacing / 2) + padV,
                    ),
                    Vec2.init(
                        tileWidth - tileSpaceScale * (tileSpacing),
                        tileWidth - tileSpaceScale * (tileSpacing),
                    ),
                    c,
                );
            }
        }
        var x = true;
        var ghost = self.board.fallingShape;
        while (x) {
            if (ghost.maxY() + 1 >= boardHeight - hiddenTiles) x = false;
            for (0.., self.board.tiles) |i, columns| {
                for (0.., columns) |j, tile| {
                    switch (tile) {
                        .Filled => {
                            for (ghost.blocks) |b| {
                                if (b.point.x == @as(f32, @floatFromInt(i)) and b.point.y + 1 == @as(f32, @floatFromInt(j))) {
                                    x = false;
                                }
                            }
                        },
                        .Empty => {},
                    }
                }
            }
            if (!x) break;
            for (&ghost.blocks) |*i| {
                i.point.y += 1;
            }
        }
        for (self.board.fallingShape.blocks, ghost.blocks) |v, k| {
            rl.drawRectangleLinesEx(.{
                .height = tileWidth - tileSpacing,
                .width = tileWidth - tileSpacing,
                .x = (tileWidth * v.point.x) + tileSpacing / 2 + padH,
                .y = (tileWidth * v.point.y) + tileSpacing / 2 + padV,
            }, 5, v.color);
            rl.drawRectangleV(
                Vec2.init(
                    (tileWidth * k.point.x) + tileSpacing / 2 + padH,
                    (tileWidth * k.point.y) + tileSpacing / 2 + padV,
                ),
                Vec2.init(
                    tileWidth - tileSpacing,
                    tileWidth - tileSpacing,
                ),
                mc.FFFg,
            );
        }
    }

    fn tryFinalize(self: *@This()) !void {
        var canFinalize = true;
        if (!self.board.updateFallingShape()) {
            for (self.board.fallingShape.blocks) |i| {
                if (i.point.y < 0) {
                    canFinalize = false;
                }
            }
            if (canFinalize) try self.finalizeFallingShape() else self.clearBoard();
            if (self.bag.items.len == 0) {
                try self.mixNewBag();
            }
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    rl.setConfigFlags(.{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });

    rl.initWindow(screenWidth, screenHeight, "Tetris");
    defer rl.closeWindow();

    var g = Game.init(allocator);

    var deltaFall = try std.time.Timer.start();
    var deltaMove = try std.time.Timer.start();
    var deltaSlowDrop = try std.time.Timer.start();
    var paused = false;

    while (!rl.windowShouldClose()) {
        if (rl.isWindowResized()) {
            screenHeight = rl.getScreenHeight();
            screenWidth = rl.getScreenWidth();
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        if (rl.isKeyPressed(.key_p)) {
            paused = !paused;
        }
        if (paused) continue;

        rl.clearBackground(mc.FFBg);
        // rl.drawFPS(0, 0);

        if (std.meta.eql(g.board.fallingShape, undefined)) {
            try g.nextShape();
        }

        if (rl.isKeyPressed(.key_r) and !rl.isKeyDown(.key_left_shift)) {
            g.board.rotate();
        }
        if (rl.isKeyPressed(.key_r) and rl.isKeyDown(.key_left_shift)) {
            g.board.rotateLeft();
        }

        if (deltaSlowDrop.read() / std.time.ns_per_ms >= 40) {
            if (rl.isKeyDown(.key_down)) {
                _ = g.board.updateFallingShape();
            }
            deltaSlowDrop.reset();
        }

        if (rl.isKeyPressed(.key_space)) {
            while (g.board.updateFallingShape()) {}
            try g.tryFinalize();
        }

        if (deltaMove.read() / std.time.ns_per_ms >= 40) {
            if (rl.isKeyDown(.key_left) or rl.isKeyPressed(.key_left)) {
                g.board.moveShapeLeft();
            }
            if (rl.isKeyDown(.key_right) or rl.isKeyPressed(.key_right)) {
                g.board.moveShapeRight();
            }
            deltaMove.reset();
        }

        //TODO: make an infiniy mechanic eg: https://tetris.fandom.com/wiki/Infinity
        if (deltaFall.read() / std.time.ns_per_ms >= 1000) {
            try g.tryFinalize();
            deltaFall.reset();
        }
        try g.drawBoard();
    }
}
