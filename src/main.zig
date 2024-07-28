const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("gl");
const zm = @import("zmath");
const zg = @import("zgui");

const glw = @import("./wrapper/wrapper.zig");
const Buffer = glw.Buffer;
const VertexArray = glw.VertexArray;
const ShaderProgram = glw.Program;
const Shader = glw.Shader;

const Camera = @import("./Camera.zig");

fn framebufferSizeCallback(_: *glfw.Window, w: i32, h: i32) callconv(.C) void {
    gl.Viewport(0, 0, w, h);
}

fn processInput(w: *glfw.Window) void {
    if (w.getKey(glfw.Key.escape) == glfw.Action.press) {
        w.setShouldClose(true);
    }
}

fn glGetProcAddress(procname: [*:0]const u8) ?glfw.GlProc {
    return glfw.getProcAddress(std.mem.span(procname));
}

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHintTyped(.context_version_major, 3);
    glfw.windowHintTyped(.context_version_minor, 3);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.client_api, .opengl_api);

    const window = try glfw.Window.create(800, 600, "learn-gl", null);
    defer window.destroy();

    glfw.makeContextCurrent(window);

    var procs: gl.ProcTable = undefined;
    _ = procs.init(glGetProcAddress);
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);
    gl.Viewport(0, 0, 800, 600);
    gl.Enable(gl.DEPTH_TEST);

    _ = window.setFramebufferSizeCallback(framebufferSizeCallback);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    zg.init(alloc);
    zg.backend.initWithGlSlVersion(window, "#version 330 core");
    defer zg.backend.deinit();

    var builder = ShaderProgram.builder(alloc);
    try builder.attach(try Shader.fromFile("shaders/vertex.vert", .vertex, alloc));
    try builder.attach(try Shader.fromFile("shaders/fragment.frag", .fragment, alloc));
    var shader_program = builder.link();
    defer shader_program.delete();

    const verticies = @import("./verticies.zig").VERTICIES;
    var vbo = Buffer.new(.array);
    defer vbo.delete();
    vbo.data(verticies.len, f32, &verticies, .static_draw);

    var vao = VertexArray.new();
    defer vao.delete();

    vao.bind();
    vbo.bind();

    VertexArray.vertexAtrribPointer(f32, 0, 3, false, 6, 0);
    VertexArray.enableVertexAtrribArray(0);
    VertexArray.vertexAtrribPointer(f32, 1, 3, false, 6, 3);
    VertexArray.enableVertexAtrribArray(1);

    VertexArray.unbind();

    var light_vao = VertexArray.new();
    light_vao.bind();

    vbo.bind();

    VertexArray.vertexAtrribPointer(f32, 0, 3, false, 6, 0);
    VertexArray.enableVertexAtrribArray(0);
    VertexArray.vertexAtrribPointer(f32, 1, 3, false, 6, 3);
    VertexArray.enableVertexAtrribArray(1);

    VertexArray.unbind();

    builder = ShaderProgram.builder(alloc);
    try builder.attach(try Shader.fromFile("shaders/vertex.vert", .vertex, alloc));
    try builder.attach(try Shader.fromFile("shaders/light.frag", .fragment, alloc));
    var light_program = builder.link();
    defer light_program.delete();

    var cam = Camera.default();
    const projection = zm.perspectiveFovRh(std.math.degreesToRadians(45.0), 800.0 / 600.0, 0.1, 100.0);

    var last_frame = glfw.getTime();

    var mouse_pos = window.getCursorPos();
    window.setInputMode(.cursor, glfw.Cursor.Mode.disabled);

    std.debug.print("Error: {} \n", .{gl.GetError()});

    //var shininess: i32 = 32;
    //var specularStrength: f32 = 0.5;
    var mouse_input = true;

    while (!window.shouldClose()) {
        const fb_size = window.getFramebufferSize();
        zg.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

        //_ = zg.sliderInt("Shininess: ", .{ .v = &shininess, .min = 0, .max = 4096 });
        //_ = zg.sliderFloat("Specular", .{ .v = &specularStrength, .min = 0.0, .max = 1.0 });

        if (window.getKey(glfw.Key.t) == glfw.Action.press) {
            if (mouse_input) {
                window.setInputMode(.cursor, glfw.Cursor.Mode.normal);
            } else {
                window.setInputMode(.cursor, glfw.Cursor.Mode.disabled);
            }

            mouse_input = !mouse_input;
        }

        const delta = glfw.getTime() - last_frame;
        last_frame = glfw.getTime();

        processInput(window);
        cam.processInput(window, @floatCast(delta));

        const new_mouse_pos = window.getCursorPos();
        if (mouse_input) {
            cam.mouseInput(.{ new_mouse_pos[0] - mouse_pos[0], new_mouse_pos[1] - mouse_pos[1] });
        }
        mouse_pos = new_mouse_pos;

        //gl.enable(gl.DEPTH_TEST);
        gl.ClearColor(0.1, 0.1, 0.1, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        const angle: f32 = @floatCast(glfw.getTime());
        const light_pos: zm.Vec = .{ @sin(angle) * 10.0, 0.0, @cos(angle) * 10.0, 0.0 };

        //std.debug.print("Light position: {}", .{light_pos});
        //const time: f32 = @floatCast(glfw.getTime());

        //const lightcolor = zm.Vec{ zm.sin(time * 2.0), zm.sin(time * 0.7), zm.sin(time * 1.3), 0.0 };
        const lightcolor = zm.Vec{ 1.0, 1.0, 1.0, 0.0 };
        const diffusecolor: zm.Vec = lightcolor * @as(zm.Vec, @splat(1.0));
        const ambientcolor: zm.Vec = diffusecolor * @as(zm.Vec, @splat(1.0));

        shader_program.use();
        shader_program.set("view", cam.viewMatrix());
        shader_program.set("projection", projection);

        shader_program.set("objectColor", zm.Vec{ 1.0, 0.5, 0.31, 0.0 });
        shader_program.set("light.specular", zm.Vec{ 1.0, 1.0, 1.0, 0.0 });
        shader_program.set("light.diffuse", diffusecolor);
        shader_program.set("light.ambient", ambientcolor);
        shader_program.set("light.position", light_pos);
        shader_program.set("viewPos", cam.position);
        shader_program.set("material.ambient", zm.Vec{ 0.0, 0.1, 0.06, 0.0 });
        shader_program.set("material.diffuse", zm.Vec{ 0.0, 0.5098, 0.5098, 0.0 });
        shader_program.set("material.specular", zm.Vec{ 0.5019, 0.5019, 0.5019, 0.0 });
        shader_program.set("material.shininess", 32.0);

        var model = zm.identity();

        shader_program.set("model", model);

        vao.bind();
        gl.DrawArrays(gl.TRIANGLES, 0, 36);

        light_program.use();

        model = zm.identity();
        model = zm.mul(model, zm.translationV(light_pos));
        model = zm.mul(model, zm.scaling(0.2, 0.2, 0.2));
        light_program.set("model", model);
        light_program.set("view", cam.viewMatrix());
        light_program.set("projection", projection);
        light_program.set("lightColor", lightcolor);

        light_vao.bind();
        gl.DrawArrays(gl.TRIANGLES, 0, 36);

        const err = gl.GetError();
        if (err != 0) {
            std.debug.print("Error: {} \n", .{gl.GetError()});
        }

        zg.backend.draw();
        window.swapBuffers();
        glfw.pollEvents();
    }
}
