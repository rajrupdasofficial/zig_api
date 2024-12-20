const std = @import("std");
const net = std.net;
const json = std.json;

const Config = @import("config.zig").Config;
const UserHandler = @import("user_handler.zig").UserHandler;
const pg = @import("pg");

pub fn main() !void {
    // Create a general-purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Load configuration
    const config = try Config.load(allocator);
    defer config.deinit(allocator);

    // Initialize PostgreSQL connection pool
    var pool = try pg.Pool.init(allocator, .{
        .size = 5, // Connection pool size
        .connect = .{
            .host = config.database.host,
            .port = config.database.port,
        },
        .auth = .{
            .username = config.database.username,
            .database = config.database.name,
            .password = config.database.password,
        },
    });
    defer pool.deinit();

    // Create user handler
    var user_handler = UserHandler.init(&config, &pool);

    // WebSocket server setup
    const address = try net.Address.parseIp(config.websocket.host, config.websocket.port);
    const listener = try net.tcpListener(address);
    defer listener.close();

    std.debug.print("WebSocket server listening on {}:{}\n", .{ config.websocket.host, config.websocket.port });

    // Accept connections
    while (true) {
        const conn = try listener.accept();
        defer conn.stream.close();

        // Handle WebSocket connection
        try handleWebSocketConnection(&user_handler, conn);
    }
}

fn handleWebSocketConnection(user_handler: *UserHandler, conn: net.StreamServer.Connection) !void {
    // Implement WebSocket handshake and message handling
    // This is a simplified example
    const reader = conn.stream.reader();
    const writer = conn.stream.writer();

    var buffer: [1024]u8 = undefined;
    const bytes_read = try reader.read(&buffer);
    if (bytes_read > 0) {
        // Parse WebSocket message
        const message = buffer[0..bytes_read];

        // Handle signup
        try user_handler.handleSignup(message);

        // Send response
        try writer.writeAll("User registered successfully");
    }
}
