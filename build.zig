const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-vulkan", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.linkLibC();
    add_lib(exe, b,
      ".\\glfw-3.3.8.bin.WIN64\\",
      "include",
      "lib-static-ucrt",
      "glfw3dll"
    );

    //add_lib(exe, b,
    //  "..\\..\\vulkan_SDK_1.3\\",
    //  "Include",
    //  "Lib",
    //  "vulkan-1"
    //);

    //do not install the vulkan-1.lib but use the system library/dll instead
    exe.addIncludePath("..\\..\\vulkan_SDK_1.3\\" ++ "Include");
    exe.addLibraryPath("..\\..\\vulkan_SDK_1.3\\" ++ "Lib");
    exe.linkSystemLibrary("vulkan-1");


    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    //const clean_step = b.step("clean", "cleans the zig-cache");
    //const clean_cache = b.addRemoveDirTree("zig-cache\\o");
    //clean_step.dependOn(&clean_cache.step);
}

fn add_lib(exe: *std.build.LibExeObjStep, b: *std.build.Builder, comptime lib_root: []const u8, comptime include_dir: []const u8, comptime lib_path: []const u8, comptime lib_name : []const u8) void {
  exe.addIncludePath(lib_root ++ include_dir);
  exe.addLibraryPath(lib_root ++ lib_path);

  const file_name = lib_name ++ ".lib";
  b.installBinFile(lib_root ++ lib_path ++ "\\" ++ file_name, file_name);

  exe.linkSystemLibrary(lib_name);
}
