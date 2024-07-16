//const glm = @import("./glm/glm.zig");
const glfw = @import("zglfw");
const math = @import("std").math;
const zm = @import("zmath");

const This = @This();

position: zm.Vec,
front: zm.Vec,
up: zm.Vec,
world_up: zm.Vec,
right: zm.Vec,
speed: f32,
yaw: f32,
pitch: f32,

pub fn default() This {
    // zig fmt: off
    return This{
        .position = .{0.0, 0.0, 5.0, 0.0},
        .front = .{0.0, 0.0, -1.0, 0.0},
        .up = .{0.0, 1.0, 0.0, 0.0},
        .world_up = .{0.0, 1.0, 0.0, 0.0},
        .right = .{0.0, 0.0, 0.0, 0.0},
        .speed = 2.5,
        .yaw = -90.0,
        .pitch = 0.0
    };
    // zig fmt: on
}

pub fn viewMatrix(this: *This) zm.Mat {
    this.front[0] = @cos(math.degreesToRadians(this.yaw)) * @cos(math.degreesToRadians(this.pitch));
    this.front[1] = @sin(math.degreesToRadians(this.pitch));
    this.front[2] = @sin(math.degreesToRadians(this.yaw)) * @cos(math.degreesToRadians(this.pitch));

    this.front = zm.normalize3(this.front);
    this.right = zm.normalize3(zm.cross3(this.front, this.world_up));
    this.up = zm.normalize3(zm.cross3(this.right, this.front));

    return zm.lookAtRh(this.position, this.position + this.front, this.up);
}

pub fn processInput(this: *This, w: *glfw.Window, delta: f32) void {
    const speed: zm.Vec = @splat(this.speed * delta);

    if (w.getKey(glfw.Key.w) == glfw.Action.press) {
        this.position += this.front * speed;
    }
    if (w.getKey(glfw.Key.s) == glfw.Action.press) {
        this.position -= this.front * speed;
    }
    if (w.getKey(glfw.Key.a) == glfw.Action.press) {
        this.position -= zm.normalize3(zm.cross3(this.front, this.up)) * speed;
    }
    if (w.getKey(glfw.Key.d) == glfw.Action.press) {
        this.position += zm.normalize3(zm.cross3(this.front, this.up)) * speed;
    }
}

pub fn mouseInput(this: *This, offset: [2]f64) void {
    var o = offset;

    const sensitivity = 0.1;
    o[0] = o[0] * sensitivity;
    o[1] = o[1] * sensitivity;

    this.yaw += @floatCast(o[0]);
    this.pitch -= @floatCast(o[1]);

    this.pitch = math.clamp(this.pitch, -89.0, 89.0);
}
