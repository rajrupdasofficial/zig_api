const std = @import("std");
const pg = @import("pg");
const json = std.json;
const crypto = std.crypto;

const ws = struct {
    pub const Handshake = struct {};
    pub const Conn = struct {};
    pub const Server = struct {
        pub fn init(allocator: std.mem.Allocator, options: anytype) !@This() {
            _ = allocator;
            _ = options;
            return @This(){};
        }
        pub fn deinit(self: *@This()) void {
            _ = self;
        }
        pub fn run(self: *@This()) !void {
            _ = self;
        }
    };
};

const Credentials = struct {
    email: []const u8,
    password: []const u8,
};

const Handler = struct {
    conn: *ws.Conn,
    pg_conn: *pg.Connection,

    pub fn init(_: ws.Handshake, conn: *ws.Conn, pg_connection: *pg.Connection) !Handler {
        return Handler{
            .conn = conn,
            .pg_conn = pg_connection,
        };
    }

    pub fn clientMessage(self: *Handler, data: []const u8) !void {
        const credentials = try parseCredentials(data);
        try self.saveCredentials(credentials);
    }

    fn saveCredentials(self: *Handler, creds: Credentials) !void {
        const query =
            \\ INSERT INTO users (email, password_hash)
            \\ VALUES ($1, $2)
        ;

        _ = try self.pg_conn.exec(query, .{ creds.email, try hashPassword(creds.password) });
    }
};

fn parseCredentials(data: []const u8) !Credentials {
    // Proper JSON parsing
    var stream = std.json.TokenStream.init(data);
    const parsed = try std.json.parse(Credentials, &stream, .{
        .allocator = std.heap.page_allocator,
    });
    return parsed;
}

fn hashPassword(password: []const u8) ![32]u8 {
    var hash: [32]u8 = undefined;
    crypto.hash.sha2.Sha256.hash(password, &hash, .{});
    return hash;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // PostgreSQL Connection with pg.zig
    const pg_conn = try pg.connect(allocator, .{ .host = "localhost", .port = 5432, .database = "myapp", .user = "myuser", .password = "mypassword" });
    defer pg_conn.close();

    // Create users table if not exists
    try pg_conn.exec(
        \\CREATE TABLE IF NOT EXISTS users (
        \\  id SERIAL PRIMARY KEY,
        \\  email TEXT UNIQUE NOT NULL,
        \\  password_hash BYTEA NOT NULL
        \\)
    , .{});

    // WebSocket Server Setup
    var server = try ws.Server.init(allocator, .{ .port = 8080, .interface = "0.0.0.0" });
    defer server.deinit();

    try server.run();
}
