const std = @import("std");
const os = std.os;

const ZigetError = error{
    CreateSockFail,
    InvalidAddr,
    ConnectError,
    SendError,
    RecvError,
};

pub fn main() anyerror!void {
    // Creating an arean using the page allocator?
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // Skip the step where the arena page is deinitialized?
    defer arena.deinit();

    // Save the arena page's allocator?
    var allocator = &arena.allocator;
    // Get an iterator for the processes' arguments?
    var args_it = std.process.args();

    // skip args[0] this is the process name.
    _ = args_it.skip();

    // Store the name of the host and allocate it using our page allocator?
    const host = try (args_it.next(allocator) orelse {
        // if we fail to store the host name, then that argument is missing
        // stop execution since we need an argument for the host.
        std.debug.warn("no host provided\n", .{});
        return error.InvalidArgs;
    });

    // For personal understanding print the type of "host"
    std.debug.warn("Type of host: {s}\n", .{@TypeOf(host)});

    // Store the name of the remote path and allocate it using our page allocator?
    const remote_path = try (args_it.next(allocator) orelse {
        std.debug.warn("no remote path provided\n", .{});
        return error.InvalidArgs;
    });

    // For personal understanding print the type of "remote_path"
    std.debug.warn("Type of remote_path: {s}\n", .{@TypeOf(remote_path)});
    
    // Store the output path and allocate it using our page allocator?
    const output_path = try (args_it.next(allocator) orelse {
        std.debug.warn("no path provided\n", .{});
        return error.InvalidArgs;
    });

    // For personal understanding print the type of "output_path"
    std.debug.warn("Type of output_path: {s}\n", .{@TypeOf(output_path)});
    
    // Print out the arguments we received.
    std.debug.warn("host: {s}\nremote: {s}\noutput path: {s}\n", .{ host, remote_path, output_path});

    // Attempt to connect to the host.
    // arg 0: Provided allocator
    // arg 1: The host to connect to
    // arg 2: The port to connect to
    var conn = try std.net.tcpConnectToHost(allocator, host, 80);
    // Skip closing the connection?
    defer conn.close();

    // Create a buffer of 256 characters
    var buffer: [256]u8 = undefined;
    // Get the base http?
    const base_http = "GET {s} HTTP/1.1\r\nHost: {s}\r\nConnection: close\r\n\r\n";
    // Store the message?
    var msg = try std.fmt.bufPrint(&buffer, base_http, .{ remote_path, host });

    _ = try conn.write(msg);

    var buf: [1024]u8 = undefined;
    var total_bytes: usize = 0;

    var file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();

    while (true) {
        const byte_count = try conn.read(&buf);
        if (byte_count == 0) break;

        _ = try file.write(&buf);
        total_bytes += byte_count;
    }

    std.debug.warn("written {any} bytes to file '{s}'\n", .{ total_bytes, output_path });
}
