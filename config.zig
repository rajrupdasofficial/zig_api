const std = @import("std");

pub const Config = struct {
    database: Database,
    websocket: WebSocket,
    route: Route,
    security: Security,

    pub const Database = struct {
        host: []const u8,
        port: u16,
        name: []const u8,
        username: []const u8,
        password: []const u8,
    };

    pub const WebSocket = struct {
        host: []const u8,
        port: u16,
        max_connections: u32,
    };

    pub const Route = struct {
        name: []const u8,
        path: []const u8,
        method: []const u8,
    };

    pub const Security = struct {
        password_salt: []const u8,
        jwt_secret: []const u8,
        rate_limit: u32,
    };

    pub fn load(allocator: std.mem.Allocator) !Config {
        return Config{ .database = .{
            .host = try allocator.dupe(u8, "localhost"),
            .port = 5432,
            .name = try allocator.dupe(u8, "userdb"),
            .username = try allocator.dupe(u8, "postgres"),
            .password = try allocator.dupe(u8, "password"),
        }, .websocket = .{
            .host = try allocator.dupe(u8, "0.0.0.0"),
            .port = 8080,
            .max_connections = 100,
        }, .route = .{
            .name = try allocator.dupe(u8, "users/signup"),
            .path = try allocator.dupe(u8, "/users/signup"),
            .method = try allocator.dupe(u8, "POST"),
        }, .security = .{
            .password_salt = try allocator.dupe(u8, "random_salt"),
            .jwt_secret = try allocator.dupe(u8, "secret_key"),
            .rate_limit = 100,
        } };
    }

    pub fn deinit(self: Config, allocator: std.mem.Allocator) void {
        allocator.free(self.database.host);
        allocator.free(self.database.name);
        allocator.free(self.database.username);
        allocator.free(self.database.password);
        allocator.free(self.websocket.host);
        allocator.free(self.route.name);
        allocator.free(self.route.path);
        allocator.free(self.route.method);
        allocator.free(self.security.password_salt);
        allocator.free(self.security.jwt_secret);
    }
};
