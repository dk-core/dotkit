const std = @import("std");

pub fn exists(path: []const u8) !bool {
    const file = std.fs.openFileAbsolute(path, .{}) catch |err| {
        if (err == error.FileNotFound) return false;
        return err;
    };
    defer file.close();
    return true;
}

pub fn ensureDir(path: []const u8) !void {
    try std.fs.makeDirAbsolute(path);
} 