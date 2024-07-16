const gl = @import("gl");

const This = @This();

id: u32,
type: Type,

const Type = enum(c_uint) {
    array = gl.ARRAY_BUFFER,
    element_array = gl.ELEMENT_ARRAY_BUFFER,
};

const DrawType = enum(gl.@"enum") { static_draw = gl.STATIC_DRAW };

pub fn new(t: Type) This {
    var buffer: This = .{ .id = undefined, .type = t };

    gl.GenBuffers(1, @ptrCast(&buffer.id));

    return buffer;
}

pub fn delete(this: This) void {
    gl.DeleteBuffers(1, @ptrCast(@constCast(&this.id)));
}

pub fn bind(this: *This) void {
    gl.BindBuffer(@intFromEnum(this.type), this.id);
}

pub fn data(this: *This, size: isize, comptime T: type, d: [*]const T, t: DrawType) void {
    this.bind();

    gl.BufferData(@intFromEnum(this.type), size * @sizeOf(T), d, @intFromEnum(t));
}
