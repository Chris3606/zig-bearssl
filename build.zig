const std = @import("std");
const Builder = std.build.Builder;
//const deps = @import("./deps.zig");
const libs = @import("./src/lib.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-bearssl", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.single_threaded = true;
    if (exe.build_mode != .Debug) {
        exe.strip = true;
    }

    libs.linkBearSSL(".", exe, target);

    //deps.addAllTo(exe);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
