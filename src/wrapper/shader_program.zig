const gl = @import("gl");
const std = @import("std");
const zm = @import("zmath");

const fs = std.fs;
const Allocator = std.mem.Allocator;

pub const Shader = struct {
    id: u32,
    type: Type,

    const Type = enum(c_uint) { fragment = gl.FRAGMENT_SHADER, vertex = gl.VERTEX_SHADER };

    pub fn new(source: [*]const u8, t: Type) Shader {
        var shader = Shader{ .id = undefined, .type = t };

        shader.id = gl.CreateShader(@intFromEnum(t));
        gl.ShaderSource(shader.id, 1, &[1][*]const u8{source}, null);
        gl.CompileShader(shader.id);

        if (!checkErrors(gl.GetShaderiv, gl.COMPILE_STATUS, shader.id)) {
            @panic("Shader compilation failed:\n " ++ getInfoLog(gl.GetShaderInfoLog, shader.id));
        }

        return shader;
    }

    pub fn delete(this: Shader) void {
        gl.DeleteShader(this.id);
    }

    pub fn fromFile(path: []const u8, t: Type, alloc: Allocator) !Shader {
        var file = try fs.cwd().openFile(path, .{});

        const code = try file.readToEndAlloc(alloc, std.math.maxInt(usize));

        return Shader.new(@ptrCast(code), t);
    }
};

pub const Program = struct {
    const Builder = struct {
        shaders: std.ArrayList(u32),
        id: u32,

        pub fn attach(this: *Builder, shader: Shader) !void {
            gl.AttachShader(this.id, shader.id);
            try this.*.shaders.append(shader.id);
        }

        pub fn link(this: Builder) Program {
            gl.LinkProgram(this.id);

            if (!checkErrors(gl.GetProgramiv, gl.LINK_STATUS, this.id)) {
                @panic("Program linking failed:\n " ++ getInfoLog(gl.GetProgramInfoLog, this.id));
            }

            for (this.shaders.items) |id| {
                gl.DeleteShader(id);
            }
            this.shaders.deinit();

            return Program{ .id = this.id };
        }
    };

    id: u32,

    pub fn builder(alloc: Allocator) Builder {
        var b = Builder{ .shaders = std.ArrayList(u32).init(alloc), .id = undefined };

        b.id = gl.CreateProgram();

        return b;
    }

    pub fn delete(this: Program) void {
        gl.DeleteProgram(this.id);
    }

    pub fn use(this: *Program) void {
        gl.UseProgram(this.id);
    }

    pub fn set(this: *Program, name: [*c]const u8, value: anytype) void {
        const location = gl.GetUniformLocation(this.id, name);

        switch (@TypeOf(value)) {
            f32, comptime_float => gl.Uniform1f(location, value),
            *zm.Vec, zm.Vec, *const zm.Vec => gl.Uniform3fv(location, 1, &value[0]),
            zm.Mat, *zm.Mat, *const zm.Mat => gl.UniformMatrix4fv(location, 1, 0, zm.arrNPtr(&value)),
            u32 => gl.Uniform1ui(location, value),
            i32, comptime_int => gl.Uniform1i(location, value),
            else => @compileError(std.fmt.comptimePrint("Type: {s} isn't supported!", .{@typeName(@TypeOf(value))})),
        }
    }
};

const check_fn = fn (c_uint, c_uint, *c_int) void;

fn checkErrors(comptime function: check_fn, what: gl.@"enum", id: u32) bool {
    var success: i32 = 0;

    function(id, what, &success);

    return success == 1;
}

const log_fn = fn (c_uint, c_int, ?*c_int, [*]u8) void;

fn getInfoLog(comptime function: log_fn, id: u32) [512]u8 {
    var info_log: [512]u8 = undefined;

    function(id, 512, null, &info_log);

    return info_log;
}
