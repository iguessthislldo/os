const builtin = @import("builtin");
const std = @import("std");

const t_path = "tmp/";
const k_path = "kernel/";
const p_path = k_path ++ "platform/";

const s_sources = [_][]const u8 {
    p_path ++ "threading.s",
};

const boot_path = t_path ++ "iso/boot/";

pub fn build(b: *std.build.Builder) void {
    var arena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = &arena_alloc.allocator;

    const build_mode = b.standardReleaseOptions();
    const multiboot_vga_request = b.option(bool, "multiboot_vga_request",
        \\Ask the bootloader to switch to a graphics mode for us.
        ) orelse false;
    const debug_log = b.option(bool, "debug_log",
        \\Print debug information by default
        ) orelse true;

    const target = b.standardTargetOptions(.{
        .default_target = std.zig.CrossTarget.parse(.{
            .arch_os_abi = "i386-freestanding-gnu",
            .cpu_features = "pentiumpro"
            // TODO: This is to forbid SSE code. See SSE init code in
            // kernel_start_x86_32.zig for details.
        }) catch @panic("Failed Making Default Target"),
    });
    const platform = switch (target.cpu_arch.?) {
        .i386 => "x86_32",
        else => {
            std.debug.warn("Unsupported Platform: {}\n", .{@tagName(target.cpu_arch.?)});
            @panic("Unsupported Platform");
        },
    };

    // Kernel
    const root_file = std.fmt.allocPrint(
        alloc, "{}kernel_start_{}.zig", .{k_path, platform}) catch @panic("root_file");
    const kernel = b.addExecutable("kernel.elf", root_file);
    kernel.setLinkerScriptPath(p_path ++ "linking.ld");
    kernel.setTarget(target);
    kernel.setBuildMode(build_mode);
    kernel.addBuildOption(bool,
        "multiboot_vga_request", multiboot_vga_request);
    kernel.addBuildOption(bool, "debug_log", debug_log);
    for (s_sources) |s_source| {
        kernel.addAssemblyFile(s_source);
    }
    // ACPICA
    if (false) { // TODO: Disabled for now
        var acpica = b.addObject("acpica", null);
        acpica.setTarget(target);
        const components = [_][]const u8 {
            "dispatcher",
            "events",
            "executer",
            "hardware",
            "namespace",
            "parser",
            "resources",
            "tables",
            "utilities",
        };
        const acpica_path = p_path ++ "acpica/";
        const source_path = acpica_path ++ "acpica/source/";

        // Configure Source
        var configure_step = b.addSystemCommand(&[_][]const u8{
            acpica_path ++ "prepare_source.py", acpica_path});
        acpica.step.dependOn(&configure_step.step);

        // Includes
        for ([_]*std.build.LibExeObjStep{kernel, acpica}) |obj| {
            obj.addIncludeDir(acpica_path ++ "include");
            obj.addIncludeDir(source_path ++ "include");
            obj.addIncludeDir(source_path ++ "include/platform");
        }

        // Add Sources
        for (components) |component| {
            const component_path = std.fs.path.join(alloc,
                &[_][]const u8{source_path, "components", component}) catch unreachable;
            var walker = std.fs.walkPath(alloc, component_path) catch unreachable;
            var i = walker.next() catch unreachable;
            while (i != null) {
                const path = i.?.path;
                if (std.mem.endsWith(u8, path, ".c") and
                        !std.mem.endsWith(u8, path, "dump.c")) {
                    std.debug.warn("{}\n", .{path});
                    acpica.addCSourceFile(path, &[_][]const u8{});
                }
                i = walker.next() catch unreachable;
            }
        }
        kernel.addObject(acpica);
    }
    kernel.install();

    // libcommon
    const libcommon = b.addStaticLibrary("common", "programs/common/common.zig");
    libcommon.setTarget(target);

    // programs/echoer
    const echoer = b.addExecutable("echoer.elf", "programs/echoer/echoer.zig");
    echoer.setLinkerScriptPath("programs/common/linking.ld");
    echoer.setTarget(target);
    echoer.linkLibrary(libcommon);
    echoer.addPackagePath("system_calls", "programs/common/system_calls.zig");
    echoer.install();

    // programs/a
    const a_prog = b.addExecutable("a.elf", "programs/a/a.zig");
    a_prog.setLinkerScriptPath("programs/common/linking.ld");
    a_prog.setTarget(target);
    a_prog.linkLibrary(libcommon);
    a_prog.addPackagePath("system_calls", "programs/common/system_calls.zig");
    a_prog.install();

    // programs/b
    const b_prog = b.addExecutable("b.elf", "programs/b/b.zig");
    b_prog.setLinkerScriptPath("programs/common/linking.ld");
    b_prog.setTarget(target);
    b_prog.linkLibrary(libcommon);
    b_prog.addPackagePath("system_calls", "programs/common/system_calls.zig");
    b_prog.install();
}
