const std = @import("std");
const json = std.json;
const Config = @import("config.zig").Config;
const pg = @import("pg");

pub const User = struct {
    email: []const u8,
    password: []const u8,
    username: ?[]const u8 = null,
};

pub const UserHandler = struct {
    config: *const Config,
    pool: *pg.Pool,

    pub fn init(config: *const Config, pool: *pg.Pool) UserHandler {
        return UserHandler{
            .config = config,
            .pool = pool,
        };
    }

    pub fn handleSignup(self: *UserHandler, data: []const u8) !void {
        const user = try parseUserData(data);
        const hashed_password = try hashPassword(user.password, self.config.security.password_salt);
        try self.saveUser(user.email, hashed_password);
    }

    fn parseUserData(data: []const u8) !User {
        var stream = std.json.TokenStream.init(data);
        return try std.json.parse(User, &stream, .{
            .allocator = std.heap.page_allocator,
        });
    }

    fn hashPassword(password: []const u8, salt: []const u8) ![32]u8 {
        var hash: [32]u8 = undefined;
        const combined = try std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}", .{ password, salt });
        defer std.heap.page_allocator.free(combined);

        std.crypto.hash.sha2.Sha256.hash(combined, &hash, .{});
        return hash;
    }

    fn saveUser(self: *UserHandler, email: []const u8, password_hash: [32]u8) !void {
        const conn = try self.pool.acquire();
        defer self.pool.release(conn);

        const query =
            \\ INSERT INTO users (email, password_hash, created_at)
            \\ VALUES ($1, $2, CURRENT_TIMESTAMP)
        ;

        _ = try conn.exec(query, .{ email, password_hash });
    }
};
