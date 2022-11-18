const std = @import("std");
const Builder = std.build.Builder;
//const deps = @import("./deps.zig");
const libs = @import("./src/lib.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // Create 4 static libraries because bugs lol
    const temp_libs = [_]*std.build.LibExeObjStep{ b.addStaticLibrary("zig-bearssl1", "src/lib.zig"), b.addStaticLibrary("zig-bearssl2", "src/lib.zig"), b.addStaticLibrary("zig-bearssl3", "src/lib.zig"), b.addStaticLibrary("zig-bearssl4", "src/lib.zig") };

    for (temp_libs) |lib, idx| {
        // Target and mode
        lib.setTarget(target);
        lib.setBuildMode(mode);

        // Optimizations
        lib.single_threaded = true;
        if (lib.build_mode != .Debug) {
            lib.strip = true;
        }

        // C runtime
        lib.linkLibC();

        // Path to headers
        lib.addIncludePath("." ++ "/BearSSL/inc");
        lib.addIncludePath("." ++ "/BearSSL/src");

        // Include some sources
        inline for (libs.bearssl_sources) |srcfile, idx2| {
            if (idx2 % temp_libs.len == idx) {
                lib.addCSourceFile("." ++ srcfile, &[_][]const u8{
                    "-Wall",
                    "-DBR_LE_UNALIGNED=0", // this prevent BearSSL from using undefined behaviour when doing potential unaligned access
                });
            }
        }

        // Required on Windows
        if (target.isWindows()) {
            lib.linkSystemLibrary("advapi32");
        }
    }

    // Create exe target
    const exe = b.addExecutable("zig-bearssl", "src/main.zig");

    // Target and mode
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Optimizations
    exe.single_threaded = true;
    if (exe.build_mode != .Debug) {
        exe.strip = true;
    }

    // Set for libc and include BearSSL path
    exe.linkLibC();
    exe.addIncludePath("./BearSSL/inc");

    // Link against our libraries
    for (temp_libs) |lib| {
        exe.linkLibrary(lib);
    }

    // Create install step entry for exe
    var exe_install_step = b.addInstallArtifact(exe);
    b.getInstallStep().dependOn(&exe_install_step.step);

    // Make run step
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
