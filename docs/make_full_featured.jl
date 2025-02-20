import Pkg;
# as we want the documentation for the current version of the package as it is in the repo, not the registry, we use pkg develop instead of just adding it via the docs/Project.toml
Pkg.develop(path = joinpath(@__DIR__, "../../myPackage.jl"));
using myPackage
# also additional Packages that should be documented in this documentation have to be added
using subPackage
# obviously Documenter.jl is required for building and deployment to github-pages
using Documenter
using Documenter: GitHubActions
# as we want the output of documenter to be available as warnings on the github action for better early warning and issue prevention, we use Suppressor.jl to analyse the printed output
using Suppressor
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
    "SubPackage Examples" => [
        "Example_A" =>
            joinpath("examples", "subpackage_examples", "exmpleA.md"),
    ],
]

# helper function for geneartion of github-warnings on example pages:
# creates a list of Strings. If you pass a vector of pairs (also nested vectors), it recursively follows the list and finds all filenames provided as second element of the pairs of "Name in sidebar"=>"filename or nested vector" 
function recursive_second(vec)
    s = []
    for e in vec
        if typeof(e[2]) == String
            push!(s, e[2])
        else
            append!(s, recursive_second(e[2]))
        end
    end
    return s
end

# helper function for geneartion of github-warnings on example pages:
# this function is used to remove all elements from a vector of pairs (can be nested) passed to it as a, that second arguments do not fullflill function f (e.g. if a is a list of examples to be included in the docs, but some filenames do not exist in the docs/src folder (f would be "isfile"), then remove those elements from a)
function recursive_second_filter!(f, a)
    deleteat = []
    for i in keys(a)
        if typeof(a[i][2]) == String
            if f(a[i]) == false
                push!(deleteat, i)
            end
        else
            recursive_second_filter!(f, a[i][2])
            if length(a[i][2]) == 0
                push!(deleteat, i)
            end
        end
    end
    deleteat!(a, deleteat)
    return a
end

# get a flat list of all md files in the docs/src/examples directory and subfolders 
mdFilesInExampleDir = filter(
    f -> endswith(f, ".md"),
    collect(
        Iterators.flatten([
            (length(item[3]) > 0) ? [joinpath(item[1], f) for f in item[3]] : [] for
            item in walkdir(joinpath("docs", "src", "examples"))
        ]),
    ),
)

### geneartion of github-action-warnings:

# check if all md-files in "docs/src/examples" (and subfolders) are included in docs (if those examples exist, they sould be part of the documentation...)
for md_file in mdFilesInExampleDir
    if !occursin("README", md_file) &&
       all([!endswith(md_file, file) for file in recursive_second(example_pages)])
        print(
            string(
                "::warning title=Example-Warning::example \"",
                md_file,
                "\" is not included in the doc-manual. Either include it in the docs by adding it to example_pages in docs/make.jl and the overwiev.md page or remove it from the examples branch and examples-CI-bulids\r\n",
            ),
        )
    end
end

# remove any example pages from example_pages, for witch the example can not be found at the given path (otherwise, there will be an error and doc build would fail)
# and remove svgs if md building failed (this should no longer occur due to "Fix SVGs" step in the Examples.yml action, but who knows, if jupyter nbconvert will change its behavior again in the future. At least out docs will still build then with this precaution)
for md_file in recursive_second(example_pages)
    # check if md_file is missing
    if !(any([occursin(md_file, file) for file in mdFilesInExampleDir]))
        print(
            string(
                "::warning title=Example-Warning::example-page \"",
                md_file,
                "\" is to be included in the doc-manual, but could not be found on the examples branch or in \"docs/src/examples\". Either add it to the example-CI-buliding pipeline or remoce it from the example_pages in docs/make.jl\r\n",
            ),
        )
        println(md_file)
        # remove from pages-list if it is missing
        recursive_second_filter!(e -> e[2] ≠ md_file, example_pages)
    else
        # removal of svgs is here if there is xml data in the md_file
        r = open(joinpath("docs", "src", md_file), "r")
        s = read(r, String)
        close(r)
        if occursin("<svg", s) && occursin("</svg>", s)
            print(
                string(
                    "::warning title=SVG-Warning::example-page \"",
                    md_file,
                    "\" has svg-xml text in it. Most likely, linking of support-files generated by jupyter is broken. The svg-xml text has been removed for the doc-manual, but also no plot will be displayed\r\n",
                ),
            )
            # regex replace exeeds stack limit: s = replace(s, r"\<\?xml(?!<\/svg>)(.|\n)*?<\/svg>" => "")
            # so take the manual iterative approach (xml svg string starts with "<?xml" and ends with "</svg>"):
            while occursin("<?xml", s) && occursin("</svg>", s)
                a = findfirst("<?xml", s)[1] - 1
                b = findfirst("</svg>", s)[end] + 1
                s = string(s[1:a], s[b:end])
            end
            w = open(joinpath("docs", "src", md_file * "tmp"), "w+")
            write(w, s)
            close(w)
        end
        if isfile(joinpath("docs", "src", md_file * "tmp"))
            mv(
                joinpath("docs", "src", md_file * "tmp"),
                joinpath("docs", "src", md_file),
                force = true,
            )
        end
    end
end

# we create a shortcut, as we want to execute makedocs with the same arguments more than once
# the Documenter.jl documentation on makedocs() is very helpful
# urls, that appear (as links) in the documentation are checked for http code (e.g. availability) on a "warnonly" basis, so that the docs are still build and deployed, if the linkcheck fails (which it does quite often, e.g. if external resources are moved)
# typically, the pages are crafted manually as md files and provided on the main branch under docs/src. 
# the pages can also contain multiple layers of nested Vectors as shown with the Examples element
my_makedocs() = makedocs(
    sitename = "myPackage.jl",
    format = Documenter.HTML(
        collapselevel = 1,
        sidebar_sitename = false,
        edit_link = nothing,
        size_threshold = 512000,
        size_threshold_ignore = [
            # a list of files, that result in too big html files can go here. just comma seperated list of strings of the original md_filenames (second element of "pages" argument) is sufficent
        ],
    ),
    modules = [myPackage, subPackage],
    checkdocs = :exports,
    linkcheck = true,
    warnonly = :linkcheck,
    pages = Any[
        "Introduction" => "index.md"
        "Examples" => example_pages
        "User Level API - myPackage.jl" => "library.md"
        "Developer Level API" => Any[
            "subPackage content"=>Any[
                "subPackage_contentA.md",
                "subPackage_contentB.md",
            ],
        ]
        "Contents" => "contents.md"
        hide("Deprecated" => "deprecated.md") # not visible in the naviagation sidebar (see also https://documenter.juliadocs.org/stable/lib/public/#Documenter.hide)
    ],
)

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

# variable for printed output of documenter
output = ""
try
    global output = @capture_err begin
        my_makedocs()
    end
    # if no terminating error occured, we should have all warning and info outputs logged into "output"
catch e
    # if my_makedocs fails due to an error, we re-run without capturing. This is to print stderr to the console/logs.
    # this is required for debugging, as in that case "output" does not contain any captured output
    my_makedocs() 
    # it still makes this script fail here, but at least we find the reason in the logs. 
end

# get a list of all warnings and print them in a way, so that the github-actions-runner finds them in the logs, parses them and puts them onto the runs overview page as warnings
warns = findall(r"Warning:.*", output)
for w in warns
    s = string("::warning title=Documenter-Warning::", output[w], "\r\n")
    print(s)
end

# if there where only warnings (no errors), this script is still running, the docs are built and we can deploy them
deploydocs(
    repo = string("github.com/", get(ENV, "GITHUB_REPOSITORY", ""), "git"),
    devbranch = "main",
    deploy_config = deployConfig(),
)

