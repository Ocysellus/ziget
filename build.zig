const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    // Get a build mode from the builder
    // build mode?
    const mode = b.standardReleaseOptions();
    // Create an executable using the builder
    // arg 0 = file / project name?
    // arg 1 = main file location?
    const exe = b.addExecutable("ziget", "src/main.zig");
    // sets the build mode for the executable?
    exe.setBuildMode(mode);

    // Create the run command for the executable?
    const run_cmd = exe.run();

    // Set up the run steps?
    const run_step = b.step("run", "Run the app");
    // In order to run the run step you need to have the run_cmd?
    run_step.dependOn(&run_cmd.step);

    // Builder's default step must depend on the execution steps?
    b.default_step.dependOn(&exe.step);
    // Install the artifact?
    b.installArtifact(exe);
}
