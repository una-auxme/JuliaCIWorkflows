# JuliaCIWorkflows
Julia CI workflows that are shared among several repositories. Updates to actions are to be pushed here from where all the other repos, that use the shared workflows, pull their updates automatically dayly, on pushes and when triggered by the user in the specific repo. After pulling, they create PRs to themselves, that (as of now) have to be merged manually.

# Prepare this repo (JuliaCIWorkflows)
We need a ssh-key-pair for the auxme_manage_JuliaCIWorkflows.yml action. In this repo, we require the private part to set in the repository secrets (named JULIA_CI_WORKFLOWS_UPDATE_KEY, no other name will be accepted for the JuliaCIWorkflows-repo!) and the public part (name does not matter) to be added to the deployment keys. For details see SSH_Key handling below. Also under 

# How to use in other repos
Copy the unmodified (!) .github/workflows/auxme_manage_JuliaCIWorkflows.yml from this repo to your own repo (keeping the name and path the same). This action updates itself and the other shared workflows by opening pullrequests for you to approve. Make shure workflows are allowed to do that under Repositorysettings -> (Code and automation) Actions ->  Workflow permissions -> Read and Write permissions AND allow Actions to create Pullrequests -> Save.

IT IS (currently and as long as this has not been properly tested) YOUR RESPONSIBILITY TO MONITOR THIS REPO (JuliaCIWorkflows) FOR DEPENDABOT-PRs, CHECK THEM AND MERGE THEM.
ALSO YOU HAVE TO APPROVE ALL PRs TO KEEP THE SHARED WORKFLOWS IN OTHER REPOS UP TO DATE !!! (see TODOs at the end of this file)

For opening the PRs, the action needs an SSH Keypair (public part for deployment with write access, private part as repository secret, both to be set in the repository settings) to be generated and setup. For Repos, that want to use the shared workflows, the key can be named JULIA_CI_WORKFLOWS_UPDATE_KEY, COMPATHELPER_PRIV or DOCUMENTER_KEY. Therefore any of those will be reused automatically (in this order) if one is available. If none is available, you have to generate them as follows:

Generate a new SSH key
	<ssh-keygen -m PEM -N "" -f juliaCI_key>

Create a new GitHub secret
	Copy the private key, <cat juliaCI_key> (copy whole content, including begin and end flags !)
	Go to your repositories settings page
	Select Secrets, and New Repository Secret
	Name the secret JULIA_CI_WORKFLOWS_UPDATE_KEY, paste the copied private key

Create a new deploy key
	Copy the public key, <cat juliaCI_key.pub> (copy the whole line; e.g.: ssh-ed25519 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx uni-augsburg\user@pc)
	Go to your repositories settings page
	Select Deploy Keys, and Add Deploy Key
	Name the deploy key however you want, paste in the copied public key
	Ensure that the key has Write Access by selecting the checkbox (!) 

Cleanup the SSH key from your computer, <rm -f juliaCI_key juliaCI_key.pub>

To add a shared workflow, go to your repo, actions and trigger auxme_manage_JuliaCIWorkflows, selecting the workflow you want to add from the dropdown menue (If the desired workflow has just been added to JuliaCIWorkflows, you will have to run through these instructions twice, first to update auxme_manage_JuliaCIWorkflows, second to download your desired workflow). Take a look at the log for printed notices and warnings and follow the recommended actions. If everything is fine, check the pullrequest opend by the action. When all checks pass, merge it. Now you have downloaded your desired workflow [and any example files that go with it (e.g. docs/make.jl for the documentation action); not yet implemented, see TODOs]

# How to register a workflow here to be used as a shared workflow by other repositorys
Just drop the vaild .yml file of the workflow in this repos .github/workflows/ folder and run the auxme_manage_JuliaCIWorkflows action here in JuliaCIWorkflows repo (or wait for the scheduled run). Merge the PR, that adds it to the list in auxme_manage_JuliaCIWorkflows.yml . Now the workflow is available and can be added to other repos as described above. Additionaly you can privode files named XYZ_WARNING and XYZ_MESSAGE for a workflow named XYZ.yml . Those files shall contain warnings, that will be printed, when a user adds this workflow to his repo (meight be overlooked) or an addition to the PRs message (meight be more visible to the User). You should also provide a XYZ_README, just for the user.

# How to test changes in 


### TODOs:
- Implement functionality to pull supportfiles (like runtests.jl or docs/make.jl) if they do not exist at the destination yet (and create such files in this repo, only docs/make are available but do not get distributed by themselfs as of now) Also it would be nice for these dummys to enable the shared workflows in this repo to run (currently they fail). This would imporve maintainability, as the failiure of the dummy actions would probably show issues before they are rolled out to other repos (e.g. a failing TestLatest.yml here would indicate TestLatest.yml is broken, even before the real tests in e.g. FMI.jl get updated and fail afterwards). In that case, maybe even prevent the scheduled PRs in the client repos, as long as the shared workflows on dummys in this repo fail, maybe even open issues here automatically if an action fails, ...
- Handle case where the requested workflow is already present (currently, this does not create errors, but also no PR, so the user meight be confused)
- Example action: currently if there more than 16 .ipynb files in jupyter-src folder, the access ones get skipped. Implement a error, so that an update to the examples action, increasing the matrix-jobcount can be made, if we are ever at this point (or a worker queue if you want it to be overly fancy, but be warned: I doubt this will ever make sense)
- Example action: improve gif handling: better would be a solution that grabs the base64 data translates it, and puts it into a file directly. I would recommend a julia command for that, as PowerShell is hell (you have no idea how long I fought with this awk command)
- Implement auto merging of PRs after this has been tested thoroughly
