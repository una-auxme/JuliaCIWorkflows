# JuliaCIWorkflows
Julia CI workflows that are used among several repositories. This reposiory keeps everything together. It is the root for all the shared workflows. Updates to actions are to be pushed here from where all the other repos, that use the shared workflows, pull their updates automatically dayly (on the default, most often main branch), on pushes and when triggered by the user in the specific repo.

# How to use
Copy the unmodified (!) .github/workflows/auxme_manage_JuliaCIWorkflows.yml from this repo to your own repo (keeping the name and path the same). This action updates itself and the other shared workflows by opening pullrequests for you to approve. 
To do that, the action needs an SSH Key (public part for deployment with write access, private part as repository secret, both to be set in the repository settings) to be generated and setup.
It needs a dedicated key, put under ... as secret or can reuse either ... or ... If at least one of these is available, the action automatically selects and uses it.

To add a shared workflow, go to your repo, actions and trigger auxme_manage_JuliaCIWorkflows, selecting the workflow you want to add from the dropdown menue (If the desired workflow has just been added to JuliaCIWorkflows, you will have to run through these instructions twice, first to update auxme_manage_JuliaCIWorkflows, second to download your desired workflow). Take a look at the log for printed notices and warnings and follow the recommended actions. If everything is fine, check the pullrequest opend by the action. When all checks pass, merge it. Now you have downloaded your desired workflow and any example files that go with it (e.g. docs/make.jl for the documentation action)

# How to register a workflow here to be used as a shared workflow by other repositorys
