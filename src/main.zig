const std = @import("std");
const lexer = @import("lexer.zig");
const compiler = @import("compiler.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var print_debug_info = false;

const build_nr = 19;

pub fn main() !void {
    std.debug.print("feedme-lang InDevelopment Build {d}\n", .{ build_nr });

    // *
    // Get the command line arguments
    // *
    if (std.os.argv.len == 1) {
        std.debug.print("Usage: feedme-lang <options> [filename]\n", .{});
        return;
    }

    const args: [][*:0]u8 = std.os.argv[1..];

    // *
    // Loop through the arguments, where arg is type [*:0]u8
    // *
    for (args) |arg| {
        if (arg[0] == '-') {
            if (std.mem.len(arg) == 1) {
                std.debug.print("Incomplete option.\n", .{});
                return;
            }

            const arg_rest = std.mem.span(arg[1..]);

            if (std.mem.eql(u8, arg_rest, "debug")) {
                print_debug_info = true;
            }
            continue;
        }

        // *
        // Lex the script
        // *
        var tokens: std.ArrayList(lexer.Token) = try lexer.lex(arg);

        // *
        // Print debug info about the tokens
        // *
        if (print_debug_info) {
            // *
            // Print the header
            // *
            std.debug.print("<---> {s: ^48} <--->\n", .{ "TOKEN DUMP" });

            // *
            // Loop through the tokens
            // *
            for (tokens.items) |token| {
                var allocation: []u8 = undefined;

                defer gpa.allocator().free(allocation);

                // *
                // Basically like C's sprintf, but it allocates memory for you.
                // *
                allocation = try std.fmt.allocPrint(gpa.allocator(),
                    "[ \"{s}\" {s} {d} ]",
                    .{
                        token.l.items,
                        @tagName(token.t), token.line
                    });

                // *
                // Print the current token's info
                // *
                std.debug.print(" <--> {s: ^48} <-->\n", .{ allocation });
            }
            // *
            // Print the footer
            // *
            std.debug.print("<---> {s: ^48} <--->\n", .{ "END TOKEN DUMP" });
        }

        var c: compiler.Compiler = compiler.Compiler {
            .tokens = &tokens,
            .debug_flag = print_debug_info,
            .i = 0
        };

        _ = c.expression();

        // *
        // Free the tokens
        // *
        defer tokens.deinit();
    }

    // *
    // GPA deinit, check for memory leaks
    // *
    defer {
        const status: std.heap.Check = gpa.deinit();

        if (status == std.heap.Check.leak) {
            std.debug.print("Memory leaks detected: build in debug mode to find them.\n", .{});
        }
    }
}
