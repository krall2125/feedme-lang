// *
// Global variables and constants
// *
const std = @import("std");
const lexer = @import("lexer.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const log = std.debug.print;
const tt = lexer.TokenType;

// *
// The main bytecode operation type
// *
pub const OpType = enum {
    OpNumConst,
    OpStrConst,

    OpAddr,         // * Get a pointer to a cell.
                    // The syntax is:
                    // &index_of_cell
                    // The operator evaluates to the pointer to cells[index_of_cell]
                    // *

    OpDeref,        // * Dereference a pointer.
                    // The syntax is:
                    // ^(ptr)
                    // It evaluates to the value which ptr points to.
                    // *

    OpVal,          // * Get the value of a cell
                    // The syntax is:
                    // $index_of_cell
                    // The operator evaluates to cells[index_of_cell]
                    // *

    OpAdd,          // * Add two cells
                    // The syntax is:
                    // +($cell_1, $cell_2)
                    // It evaluates to $cell_1 + $cell_2

    OpSubtr,        // * Subtract two cells.
                    // The syntax is:
                    // -($cell_1, $cell_2)
                    // It evaluates to $cell_1 - $cell_2
                    // *

    OpMulti,        // * Multiply two cells.
                    // The syntax is:
                    // *($cell_1, $cell_2)
                    // It evaluates to $cell_1 * $cell_2
                    // *

    OpDiv,          // * Divide two cells.
                    // The syntax is:
                    // /($cell_1, $cell_2)
                    // It evaluates to $cell_1 / $cell_2
                    // *

    OpMod,          // * Modulo two cells.
                    // The syntax is:
                    // %($cell_1, $cell_2)
                    // It evaluates to $cell_1 mod $cell_2
                    // *

    OpPrintNum,     // * Print the numeric value of the current cell.
                    // Fails if the current cell contains a pointer/string.

    OpPrintChr,     // * Print a character to stdout. It takes the numeric value of the current cell and prints it's corresponding character.
                    // Fails if the current cell contains a pointer/string.

    OpEachPtr,      // * Iterates through elements of a pointer/array in the current cell and stuff.
                    // The syntax is just:
                    // each_ptr(func)
                    // func can be any callable function which takes in one argument.
                    // It calls func on every element of a pointer/array.
                    // *
};

// *
// The actual compiler.
// Sorry for this monster. I know it's probably unreadable as hell.
// *
pub const Compiler = struct {
    // *
    // List of operations.
    // We store them as f64 because we need to store values of constants *somehow*
    // *
    operations: std.ArrayList(f64),

    // *
    // List of tokens
    // *
    tokens: std.ArrayList(lexer.Token),

    // *
    // Iterator
    // *
    iterator: usize,

    // *
    // Should we print debug info, or not?
    // Set by main.zig
    // *
    print_debug_info: bool,

    // *
    // Error reporting and kicking into panic mode.
    // *
    fn error_report(self: *Compiler, comptime msg: []const u8, args: anytype) void {
        // *
        // Print a default message which accompanies every single error
        // *
        std.debug.print("An exception encountered at line {d}:\n", .{
            self.tokens.items[self.iterator].line
        });

        // *
        // Print the message provided by the arguments
        // *
        std.debug.print(msg, args);

        // *
        // Get into panic mode
        // *
        self.panic_mode();
    }

    // *
    // Panic mode error recovery.
    // Prints some debug info too.
    // *
    fn panic_mode(self: *Compiler) void {
        // *
        // The first debug message
        // *
        if (self.print_debug_info) {
            std.debug.print("<---> {s: ^48} <--->\n", .{ "DEBUG: Kicking into panic mode." });
        }

        // *
        // Current line, used to look for newlines as a recovery point.
        // *
        const c_line = self.tokens.items[self.iterator].line;

        // *
        // Print the header of the debug info in a nice format
        // *
        if (self.print_debug_info) {
            std.debug.print(" <--> {s: ^48} <-->\n", .{ "DEBUG: Skipping over tokens." });
        }

        // *
        // The loop with the monstrous contition.
        // I am sorry.
        // *
        while (self.tokens.items[self.iterator].t != tt.SpecialDbg and
                self.tokens.items[self.iterator].t != tt.Eof and
                self.tokens.items[self.iterator].line <= c_line)
                    : (self.iterator += 1) {

            // *
            // Continue if print_debug_info is false
            // *
            if (!self.print_debug_info) {
                continue;
            }

            // *
            // Print debug info in a nice format if print_debug_info is true
            // *
            std.debug.print("  <-> {s: ^48} <->\n", .{ @tagName(self.tokens.items[self.iterator].t) });
        }

        // *
        // Return if print_debug_info is false
        // *
        if (!self.print_debug_info) {
            return;
        }

        // *
        // Print debug footers
        // *
        std.debug.print(" <--> {s: ^48} <-->\n", .{ "DEBUG: End of skipping tokens." });
        std.debug.print("<---> {s: ^48} <--->\n", .{ "DEBUG: Kicking out of panic mode." });
    }

    // *
    // Basically, if the next token's type is not equal to 'expected', report an error.
    // *
    fn consume(self: *Compiler, expected: tt) void {

        // *
        // If the next token would be out of bounds, report an error.
        // *
        if (self.tokens.items[self.iterator].t == tt.Eof) {
            self.error_report("Expected {s} - Found EOF.\n", .{ @tagName(expected) });
            return;
        }

        // *
        // If the next token's type is not equal to 'expected', report an error.
        // *
        if (self.tokens.items[self.iterator + 1].t != expected) {
            // *
            // I love @tagName
            // *
            self.error_report("Expected {s} - Found {s}.\n", .{
                @tagName(expected),
                @tagName(self.tokens.items[self.iterator].t)
            });
            return;
        }

        self.iterator += 1;
    }

    // *
    // Check if the next token's type is 'maybe'
    // *
    fn match(self: *Compiler, maybe: tt) bool {
        if (self.iterator >= self.tokens.items.len) return false;
        if (self.tokens.items[self.iterator + 1].t == maybe) self.iterator += 1;
        return self.tokens.items[self.iterator + 1].t == maybe;
    }

    // *
    // Compile tokens to bytecode
    // *
    fn actually_parse(self: *Compiler, operations: *std.ArrayList(f64)) !void {
        // *
        // Just a switch through the current token's type
        // *
        switch (self.tokens.items[self.iterator].t) {
            tt.IntegerConstant => {
                // *
                // Add the OpNumConst operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpNumConst))));

                // *
                // Parse the lexeme of the current token as an unsigned 64bit int (we won't have to deal with signs)
                // *
                const val = try std.fmt.parseInt(u64, self.tokens.items[self.iterator].l.items, 10);

                // *
                // Add the value
                // *
                try operations.append(@as(f64, @floatFromInt(val)));

                // *
                // Add the TypeID: 8 for uint64
                // *
                try operations.append(@as(f64, 8.0));
            },
            tt.FloatConstant => {
                // *
                // Add the OpNumConst operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpNumConst))));

                // *
                // Parse the lexeme of the current token as 64bit float
                // *
                const val = try std.fmt.parseFloat(f64, self.tokens.items[self.iterator].l.items);

                // *
                // Add the value
                // *
                try operations.append(val);

                // *
                // Add the TypeID: 10 for float64
                // *
                try operations.append(@as(f64, 10.0));
            },
            tt.StringConstant => {
                // *
                // Add the OpStrConst operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpStrConst))));

                // *
                // Add the length of the string
                // *
                try operations.append(@as(f64, @floatFromInt(self.tokens.items[self.iterator].l.items.len)));

                // *
                // Push the actual bytes of the string
                // *
                for (self.tokens.items[self.iterator].l.items) |byte| {
                    try operations.append(@as(f64, @floatFromInt(byte)));
                }

                // *
                // Push the TypeID: 11 for string
                // *
                try operations.append(@as(f64, 11.0));
            },
            tt.AddressOf => {
                // *
                // Add the OpAddr operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpAddr))));

                // *
                // TODO: Parse the index of the cell as an expression
                // *
            },
            tt.Deref => {

            },
            tt.Add => {
                // *
                // Add the OpAdd operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpAdd))));
            },
            tt.Subtract => {
                // *
                // Add the OpSubtr operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpSubtr))));
            },
            tt.Multiply => {
                // *
                // Add the OpMulti operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpMulti))));
            },
            tt.Divide => {
                // *
                // Add the OpDiv operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpDiv))));
            },
            tt.Modulo => {
                // *
                // Add the OpMod operation
                // *
                try operations.append(@as(f64, @floatFromInt(@intFromEnum(OpType.OpMod))));
            },
            else => {
                // eh
            },
        }
    }

    // *
    // The actual function which calls all other functions - the thing you're supposed to call from main()
    // *
    pub fn parse(self: *Compiler) !void {
        self.operations = std.ArrayList(f64).init(gpa.allocator());
        // *
        // Loop throught tokens using iterator
        // *
        while (self.iterator < self.tokens.items.len) : (self.iterator += 1) {
            try self.actually_parse(&self.operations);
        }

        // *
        // Print the operation dump in a nice format
        // *
        if (self.print_debug_info) {
            // *
            // Print the header
            // *
            std.debug.print("<---> {s: ^48} <--->\n", .{ "OPERATION DUMP" });

            // *
            // Print the elements
            // *
            for (self.operations.items) |operation| {
                std.debug.print(" <--> {d: ^48.17} <-->\n", .{ operation });
            }

            // *
            // Print the footer
            // *
            std.debug.print("<---> {s: ^48} <--->\n", .{ "END OPERATION DUMP" });
        }

        // *
        // Deallocate and check allocator status
        // *
        defer {
            self.operations.deinit();

            const status = gpa.deinit();

            if (status == std.heap.Check.leak) {
                std.debug.print("Memory leaks during parsing: compile in debug mode to find the cause.\n", .{});
            }
        }
    }
};
