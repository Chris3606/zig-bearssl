const std = @import("std");
const ssl = @import("./lib.zig");

// comptime {
//     std.testing.refAllDecls(ssl);
// }

const server_cert = @embedFile("./certs/cert.crt");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});

    const alloc = std.heap.c_allocator;

    // Create trust anchor and append custom cert
    var trust_anchor = ssl.TrustAnchorCollection.init(alloc);
    defer trust_anchor.deinit();
    try trust_anchor.appendFromPEM(server_cert);
    var x509 = ssl.x509.Minimal.init(trust_anchor);

    // Create client, reset for target hostname, and create buffer
    var client = ssl.Client.init(x509.getEngine());
    client.relocate();
    try client.reset("127.0.0.1", false);

    // // For some reason, Zig's standard lib doesn't do this for us...
    // _ = try std.os.windows.WSAStartup(2, 2);
    // defer std.os.windows.WSACleanup() catch {};

    // Connect to python server
    var sock_stream = try std.net.tcpConnectToHost(alloc, "127.0.0.1", 9999);
    defer sock_stream.close();
    var sock_reader = sock_stream.reader();
    var sock_writer = sock_stream.writer();

    // Wrap socket in SSL
    var ssl_stream = ssl.initStream(client.getEngine(), &sock_reader, &sock_writer);
    // TODO: This is bugged, even with the socket version commented out; not sure why
    //defer ssl_stream.close() catch {};
    var reader = ssl_stream.reader();
    var writer = ssl_stream.writer();

    // Send message (we MUST flush to ensure it sends)
    const message = "Hello, oh great and powerful echo server!";
    try writer.writeAll(message);
    try ssl_stream.flush();

    // Receive reply
    var reply = try alloc.alloc(u8, message.len);
    defer alloc.free(reply);
    try reader.readNoEof(reply);

    // Print reply
    std.debug.print("Read from server: {s}\n", .{reply});
}
