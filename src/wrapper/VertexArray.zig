const gl = @import("gl");

const This = @This();

id: u32,

pub fn new() This {
    var array: This = .{ .id = undefined };

    gl.GenVertexArrays(1, @ptrCast(&array.id));

    return array;
}

pub fn delete(this: This) void {
    gl.DeleteVertexArrays(1, @ptrCast(@constCast(&this.id)));
}

pub fn bind(this: *This) void {
    gl.BindVertexArray(this.id);
}

pub fn unbind() void {
    gl.BindVertexArray(0);
}

pub fn vertexAtrribPointer(comptime T: type, index: u32, size: i32, normalized: bool, step: i32, pointer: usize) void {
    gl.VertexAttribPointer(index, size, resolveType(T), @intFromBool(normalized), step * @sizeOf(T), pointer * @sizeOf(T));
}

fn resolveType(comptime T: type) gl.@"enum" {
    return switch (T) {
        f32 => gl.FLOAT,
        i32 => gl.INT,
        else => @compileError("Not supported! (yet)"),
    };
}

pub fn enableVertexAtrribArray(i: u32) void {
    gl.EnableVertexAttribArray(i);
}
