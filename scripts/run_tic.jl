using Pkg
Pkg.activate("testitemcontroller"; shared = true) # Just contains the TestItemControllers package
Pkg.status()

@info "Starting test item controller on Julia $VERSION"

if !isempty(ARGS)
    if "--debug-tic" in ARGS
        @info "Debugging TestItemControllers.jl"
        ENV["JULIA_DEBUG"] = get(ENV, "JULIA_DEBUG", "") * ",TestItemControllers"
    end
end

using TestItemControllers

global conn_in = stdin
global conn_out = stdout
redirect_stdout(stderr)
redirect_stdin()

controller = JSONRPCTestItemController(
    conn_in,
    conn_out,
    (err, bt) -> begin 
        println("error from controller")
        Base.display_error(err,bt)
    end
)
run(controller)
