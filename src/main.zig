const std = @import("std");
const rand = std.crypto.random;
const rl = @import("raylib");
const mc = @import("my_colors.zig");
const Vec2 = rl.Vector2;

const hiddenTiles = 3;
const boardHeight = 23;
const boardWidth = 10;

const boardScale: f32 = 0.75;

var screenHeight: i32 = 1000 * boardScale;
var screenWidth: i32 = 500 * boardScale;

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

    //TODO: check for collision while rotating
    fn rotate(self: *@This()) void {
        var newBlocks: [4]struct { point: Vec2, color: rl.Color } = undefined;
        for (0.., self.blocks) |i, j| {
            const tmp = j.point.x - self.blocks[self.origin].point.x;
            newBlocks[i].point.x = -(j.point.y - self.blocks[self.origin].point.y);
            newBlocks[i].point.y = tmp;
        }
        for (0.., newBlocks) |i, v| {
            self.blocks[i].point.x = v.point.x + self.blocks[self.origin].point.x;
            self.blocks[i].point.y = v.point.y + self.blocks[self.origin].point.y;
        }
    }
    fn rotateLeft(self: *@This()) void {
        var newBlocks: [4]struct { point: Vec2, color: rl.Color } = undefined;
        for (0.., self.blocks) |i, j| {
            const tmp = j.point.x - self.blocks[self.origin].point.x;
            newBlocks[i].point.x = (j.point.y - self.blocks[self.origin].point.y);
            newBlocks[i].point.y = -tmp;
        }
        for (0.., newBlocks) |i, v| {
            self.blocks[i].point.x = v.point.x + self.blocks[self.origin].point.x;
            self.blocks[i].point.y = v.point.y + self.blocks[self.origin].point.y;
        }
    }

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
            std.debug.print("xWidth: {}\n", .{xWidth});
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
            std.debug.print("yWidth: {}\n", .{yWidth});
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
        std.debug.print("pad: {}\n", .{pad});
        if (self.fallingShape.width() < self.fallingShape.height()) {
            self.fallingShape.rotateLeft();
        }
        for (&self.fallingShape.blocks) |*i| {
            i.point.x += pad + 1;
            i.point.y -= hiddenTiles;
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

    //FIXME: bag is not drawing an equal amount of each piece
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

    fn drawBoard(self: @This()) void {
        const fScreenWidth: f32 = @floatFromInt(screenWidth);
        const fScreenHeight: f32 = @floatFromInt(screenHeight);
        const fBoardWidth: f32 = @floatFromInt(boardWidth);
        const fBoardHeight: f32 = @floatFromInt(boardHeight);

        const monitorHeight: f32 = @floatFromInt(rl.getMonitorHeight(rl.getCurrentMonitor()));

        const maxSize: f32 = (boardScale * monitorHeight / (fBoardHeight - hiddenTiles));

        var tileWidth: f32 = fScreenWidth / fBoardWidth - 1;
        var tileHeight: f32 = fScreenHeight / fBoardHeight;
        if (tileWidth > maxSize) tileWidth = maxSize;
        if (tileHeight > maxSize) tileHeight = maxSize;

        const padH = (fScreenWidth - (fBoardWidth * (tileWidth + 1))) / 2;
        const padV = (fScreenHeight - (fBoardHeight * (tileHeight - hiddenTiles - 1))) / 2;

        for (0..boardWidth) |x| {
            for (0..boardHeight - hiddenTiles) |y| {
                const c = switch (self.board.tiles[x][y]) {
                    .Filled => |c| c,
                    .Empty => if ((x + y) % 2 == 0) self.bgColors[0] else self.bgColors[1],
                };

                const fx: f32 = @floatFromInt(x);
                const fy: f32 = @floatFromInt(y);

                rl.drawRectangleV(
                    Vec2{ .x = (tileWidth * fx) + fx + padH, .y = (tileWidth * fy) + fy + padV },
                    Vec2{ .x = tileWidth, .y = tileWidth },
                    c,
                );
            }
        }

        for (self.board.fallingShape.blocks) |v| {
            rl.drawRectangleLinesEx(.{
                .height = tileWidth,
                .width = tileWidth,
                .x = (tileWidth * v.point.x) + v.point.x + padH,
                .y = (tileWidth * v.point.y) + v.point.y + padV,
            }, 5, v.color);
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
    rl.setTargetFPS(60);

    var g = Game.init(allocator);

    var deltaFall = try std.time.Timer.start();
    var deltaMove = try std.time.Timer.start();
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

        if (std.meta.eql(g.board.fallingShape, undefined)) {
            try g.nextShape();
        }

        if (rl.isKeyPressed(.key_r) and !rl.isKeyDown(.key_left_shift)) {
            g.board.fallingShape.rotate();
        }
        if (rl.isKeyPressed(.key_r) and rl.isKeyDown(.key_left_shift)) {
            g.board.fallingShape.rotateLeft();
        }

        if (deltaMove.read() / std.time.ns_per_ms >= 75) {
            if (rl.isKeyDown(.key_left)) {
                g.board.moveShapeLeft();
            }
            if (rl.isKeyDown(.key_right)) {
                g.board.moveShapeRight();
            }
            deltaMove.reset();
        }

        if (deltaFall.read() / std.time.ns_per_ms >= 100) {
            if (!g.board.updateFallingShape()) {
                var canFinalize = true;
                for (g.board.fallingShape.blocks) |i| {
                    if (i.point.y < 0) {
                        canFinalize = false;
                    }
                }
                if (canFinalize) try g.finalizeFallingShape() else g.clearBoard();
                if (g.bag.items.len == 0) {
                    try g.mixNewBag();
                }
            }

            deltaFall.reset();
        }
        g.drawBoard();
    }
}
