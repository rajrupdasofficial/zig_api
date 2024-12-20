const std = @import("std");
const websocket = @import("websocket.zig");

pub fn main() !void {
    try websocket.main();
}
