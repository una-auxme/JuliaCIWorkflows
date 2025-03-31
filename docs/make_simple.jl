import Pkg;
# as we want the documentation for the current version of the package as it is in the repo, not the registry, we use pkg develop instead of just adding it via the docs/Project.toml
Pkg.develop(path = joinpath(@__DIR__, "../../myPackage.jl"));
using myPackage
# obviously Documenter.jl is required for building and deployment to github-pages
using Documenter
using Documenter: GitHubActions
# if your package has additional functions, that are only available, if additional packages are loaded and you want those functions to be documented, make shure to include those packages too by calling "using AdditionalPackage"
# an example for this would be FMI.jl that provides additional functions for plotting results or loading data, if Plots, JLD2, DataFrames, CSV and MAT Packages are loaded, so the next line would be included
# using Plots, JLD2, DataFrames, CSV, MAT

# put all example pages here (located under docs/src/...), that are to be included in the docs. Provide a name for each one for the sidebar-navigation-menue
# typically, the overview pages (such as overview.md and workshops.md) are crafted manually and provided on the main branch under docs/src. 
# the specific examples are copyed to docs/src from the examples branch by the Documentation.yml action prior to execution of this script.
example_pages = [
    "Overview" => joinpath("examples", "overview.md"),
    "Example_1" => joinpath("examples", "exmple1.md"),
    "Example_2" => joinpath("examples", "exmple2.md"),
    "Pluto Workshops" => joinpath("examples", "workshops.md"),
]

# the Documenter.jl documentation on makedocs() is very helpful
# urls, that appear (as links) in the documentation are checked for http code (e.g. availability) on a "warnonly" basis, so that the docs are still build and deployed, if the linkcheck fails (which it does quite often, e.g. if external resources are moved)
# typically, the pages are crafted manually as md files and provided on the main branch under docs/src. 
# the pages can also contain multiple layers of nested Vectors as shown with the Examples element
makedocs(
    sitename = "myPackage.jl",
    format = Documenter.HTML(
        collapselevel = 1,
        sidebar_sitename = false,
        edit_link = nothing,
        size_threshold = 512000,
        size_threshold_ignore = [],
    ),
    modules = [myPackage],
    checkdocs = :exports,
    linkcheck = true,
    warnonly = :linkcheck,
    pages = Any[
        "Introduction" => "index.md"
        "Examples" => example_pages
        "Library Functions" => "library.md"
        "Contents" => "contents.md"
    ],
)

# if there where only warnings (no errors), this script is still running, the docs are built and we can deploy them

# this fuction returns the config required for deployment
function deployConfig()
    github_repository = get(ENV, "GITHUB_REPOSITORY", "")
    github_event_name = get(ENV, "GITHUB_EVENT_NAME", "")
    # as we trigger this action after completion of the Example action from within the Example action automatically, it gets triggered as "repository_dispatch". 
    # according to https://documenter.juliadocs.org/stable/man/hosting/#Documenter.GitHubActions deploying the docs is not possible in this case, so we emulate the triggering reason to be a "deployable one", such as a push to the branch of this action
    if github_event_name == "repository_dispatch"
        github_event_name = "push"
    end
    github_ref = get(ENV, "GITHUB_REF", "")
    return GitHubActions(github_repository, github_event_name, github_ref)
end
deploydocs(
    repo = string("github.com/", get(ENV, "GITHUB_REPOSITORY", ""), "git"),
    devbranch = "main",
    deploy_config = deployConfig(),
)

