const builtin = @import("builtin");
const build_options = @import("build_options");

pub const platform = @import("platform.zig");
pub const print = @import("print.zig");
pub const Memory = @import("memory.zig").Memory;
pub const io = @import("io.zig");

pub var panic_message: []const u8 = "";

pub fn panic(msg: []const u8, trace: ?*builtin.StackTrace) noreturn {
    panic_message = msg;
    if (trace) |t| {
        print.format("index: {}\n", t.index);
        for (t.instruction_addresses) |addr| {
            if (addr == 0) break;
            print.format(" - {:a}\n", addr);
        }
    } else {
        print.string("No Stack Trace\n");
    }
    platform.panic(msg, trace);
}

pub const Kernel = struct {
    const Files = io.Files(32);

    memory: Memory = Memory{},
    file_io: Files = Files{},
    console: ?*io.File = null,

    pub fn initialize(self: *Kernel) !void {
        // Get the Console Ready
        try self.file_io.initialize();
        self.console = try self.file_io.new_file();
        print.initialize(self.console, build_options.debug_log);

        // Do a Whole Bunch of Stuff
        try platform.initialize(self);
    }
};

pub export fn kernel_main() void {
    panic_message = ""; // TODO: This is garbage when a panic happens
    var kernel = Kernel{};
    if (kernel.initialize()) |_| {} else |e| {
        panic(@errorName(e), @errorReturnTrace());
    }
    platform.impl.ata.do_read();
    print.string("Done\n");
    platform.done();
}
