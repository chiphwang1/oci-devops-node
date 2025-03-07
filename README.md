# Getting Started with OCI DevOps

This is an example project is using Ruby and the Rails web framework. You will be able to build, test and deploy this application to Oracle Container Engine for Kubernetes (OKE).

In this example, you'll build a container image of a sample Rails app, and deploy your built container to the OCI Container Registry, then deploy the sample Rails app to Oracle Container Engine for Kubernetes (OKE) all using the OCI DevOps service!

Let's go!

## Download the repo

The first step to get started is to download the repository to your local workspace

```shell
git https://github.com/chiphwang1/oci-devops-node.git
cd oci-devops-node
```

## Install Ruby, Rails and create new application


1. Install Ruby and Rails: https://guides.rubyonrails.org/v5.0/getting_started.html
2. Generate a new Rails application: \
   $ rails new demo
4. Run the application:   
   $ cd demo \
   $ rails server 
4. Verify the app locally, open your browser to http://localhost:3000/ or whatever port you set, if you've changed the local port 

## Build a container image for the app

You can locally build a container image using docker (or your favorite container image builder), to verify that you can run the app within a container

```
docker build --pull --rm -t ruby-demo -f DOCKERFILE .
```

Verify that your image was built, with `docker images` 

```
docker image ls
```

Next run your local container and confirm you can access the app running in the container
```
docker run --rm -d -p 3000:3000 --name ruby-demo  ruby-demo:latest
```

And open your browser to [http://localhost:3000/](http://localhost:3000/)

# Build and test the app in OCI DevOps

Now that you've seen you can locally build and test this app, let's build our CI/CD pipeline in OCI DevOps

## Create your Git repo

1. [Create a DevOps project](https://docs.oracle.com/en-us/iaas/Content/devops/using/devops_projects.htm), or use an existing project
1. Create a Code Repository in your DevOps project
1. Add the new Code Repository as a remote to your local git repo
```
git remote add devops ssh://devops.scmservice.us-ashburn-1.oci.oraclecloud.com/namespaces/MY-TENANCY/projects/MY-PROJECT/repositories/MY-REPO
```
1. View the Getting Started Guide to connect to your Code Repository via https or ssh

## Setup your Build Pipeline

Create a new Build Pipeline to build, test and deliver artifacts from a recent commit

## Managed Build stage

In your Build Pipeline, first add a Managed Build stage
1. The Build Spec File Path is the relative location in your repo of the build_spec.yaml . Leave the default, for this example
1. For the Primary Code Repository choose your Code Repository you created above
   - The Name of your Primary Code Repository is used in the build_spec.yaml. In this example, you will need to use the name `node_express` for the build_spec.yaml instructions to acess this source code
   - Select the `main` branch

## Create a Container Registry repository

Create a [Container Registry repository](https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrycreatingarepository.htm) for the `node-express-getting-started` container image built in the Managed Build stage. 
1. You can name the repo: `node-express-getting-started`. So if you create the repository in the Ashburn region, the path is iad.ocir.io/TENANCY-NAMESPACE/node-express-getting-started
1. Set the repostiory access to public so that you can pull the container image without authorization, from OKE. Under "Actions", choose `Change to public`.


## Create a DevOps Artifact for your container image repository

The version of the container image that will be delivered to the OCI repository is defined by a [parameter](https://docs.oracle.com/en-us/iaas/Content/devops/using/configuring_parameters.htm) in the Artifact URI that matches a Build Spec exported variable or Build Pipeline parameter name.

Create a DevOps Artifact to point to the Container Registry repository location you just created above. Enter the information for the Artifact location:
1. Name: node-express-getting-started container
1. Type: Container image repository
1. Path: `iad.ocir.io/TENANCY-NAMESPACE/node-express-getting-started`
1. Replace parameters: Yes

Next, you'll set the container image tag to use the the Managed Build stage `exportedVariables:` name for the version of the container image to deliver in a run of a build pipeline. In the build_spec.yaml for this project, the variable name is: `BUILDRUN_HASH`
```
  exportedVariables:
    - BUILDRUN_HASH
```

Edit the DevOps Artifact path to add the tag value as a parameter name.
1. Path: `iad.ocir.io/TENANCY-NAMESPACE/node-express-getting-started:${BUILDRUN_HASH}`

### Edit your k8s manifest to refer to the container location

Now that you've created a Container Registry repo, edit the [`gettingstarted-manifest.yaml`](gettingstarted-manifest.yaml) image path to match the repo you just created, e.g. `iad.ocir.io/TENANCY-NAMESPACE/node-express-getting-started:${BUILDRUN_HASH}`

## Add a Deliver Artifacts stage

Let's add a **Deliver Artifacts** stage to your Build Pipeline to deliver the `node-express-getting-started` container to an OCI repository. 

The Deliver Artifacts stage **maps** the ouput Artifacts from the Managed Build stage with the version to deliver to a DevOps Artifact resource, and then to the OCI repository.

Add a **Deliver Artifacts** stage to your Build Pipeline after the **Managed Build** stage. To configure this stage:
1. In your Deliver Artifacts stage, choose `Select Artifact` 
1. From the list of artifacts select the `node-express-getting-started container` artifact that you created above
1. In the next section, you'll assign the  container image outputArtifact from the `build_spec.yaml` to the DevOps project artifact. For the "Build config/result Artifact name" enter: `output01`


# Run your Build in OCI DevOps

## From your Build Pipeline, choose `Manual Run`

Use the Manual Run button to start a Build Run

Manual Run will use the latest commit to your Primary Code Repository, if you want to specify a specific commit, you can optionally make that choice for the Primary Code Repository in the dropdown and selection below the Parameters section.


## Connect your Code Repository to your Build Pipeline

To automatically start your Build Pipeline from a commit to your Code Repository, navigate to your Project and create a Trigger. 

A Trigger is the resource to 
filter the events from your Code Repository and on a matching event will start the run of a Build Pipeline.

## Push a commit to your DevOps Code Repository

Test out your Trigger by editing a file in this repo and pushing a change to your DevOps code repository.

# Connect your Build Pipeline with a Deployment Pipeline

For CI + CD: continous integration with a Build Pipeline and continuous deployment with a Deployment Pipeline, first create the Deployment Pipeline to deploy this example web application service to your OKE cluster. To review Deployment Pipelines, see the [example Reference Architecture](https://docs.oracle.com/en/solutions/build-pipeline-using-devops/index.html), and [docs](https://docs.oracle.com/en-us/iaas/Content/devops/using/deploy_oke.htm#deploy_to_oke). You'll need to [setup the policies](https://docs.oracle.com/en-us/iaas/Content/devops/using/devops_policy_examples.htm) to enable deployments, as well.

Because the K8s manifest doesn't change each build, we're just going to create a single version of the K8s manifest by hand (or via API/CLI), in the Artifact Registry.

## Create a DevOps Environment, Artifact Registry file, and DevOps Artifact

1. Create an [Enivornment](https://docs.oracle.com/en-us/iaas/Content/devops/using/create_oke_environment.htm) to point to your OKE cluster destination for this example. You will already need to have an OKE cluster created, or go through the [Reference Architecture automated setup](https://docs.oracle.com/en/solutions/build-pipeline-using-devops/index.html).

### Create the K8s manifest in the Artifact Registry

1. Create a new, or use an existing [Artifact Registry repository]()
1. Upload the sample k8s resources manifest to your new repository
    1. Name this artifact: `web-app-manifest.yaml`
    1. Specify a version, ie: `1.0`. You won't change this in the example
    1. From your upload choice (Console, Cloud Shell, or CLI) choose the included manifest in this repo: [`gettingstarted-manifest.yaml`](gettingstarted-manifest.yaml)
1. Now create a [DevOps Artifact](https://docs.oracle.com/en-us/iaas/Content/devops/using/artifact_registry_artifact.htm) to point to your Artifact Registry repository file
    1. Select Type: "Kubernetes manifest" so that you can use this artifact in your Deployment pipeline stage.
    1. Select `Artifact Registry repository` as the Artifact source
    1. Select the Artifact Registory repository that you just created
    1. For the Artifact location, choose `Select Existing Location` and select the file and version: `web-app-manifest.yaml:1.0` that you just uploaded above
    1. Save!

## Create your Deployment Pipeline

You've created the references to your OKE cluster and manifest to deploy, now create your [Deployment Pipeline](https://docs.oracle.com/en-us/iaas/Content/devops/using/deployment_pipelines.htm)
1. Create a new Deployment Pipeline
1. Add your first stage - choose the type to release to OKE: `Apply manifest to your Kubernetes cluster`
    1. Choose the Environment that you created above
    1. For Select Artifact, select the Kubernetes manifest DevOps artifact that points to `web-app-manifest.yaml`
    1. Add
1. Add the pipeline parameters needed by the K8s manifest: `${namespace}`
    1. From the Parameters tab, add new values:
       - Name: `namespace`
       - Default value: whatever you want here: `devops-sample-app`
       - Description: namespace value needed by the k8s manifest
    1. Smash that "+" button

To run this pipeline on its own, you can add a parameter for `BUILDRUN_HASH` or, trigger it from the Build Pipeline which will forward the `build_spec.yaml` exported variables to the Deployment Pipeline.

## Add a Trigger Deployment stage to your Build Pipeline

Once you've created your Deployment Pipeline, you can add a **Trigger Deployment** stage as the last step of your Build Pipeline.

After the latest version of the container image is delivered to the Container Registry via the **Deliver Artifacts** stage, we can start a deployment to an OKE cluster

1. Add stage to your Build Pipeline
1. Choose a **Trigger Deployment** stage type
1. Choose `Select Deployment Pipeline` to choose the Deployment Pipeline that you created above.

From the Deployment Pipeline you selected, you can confirm the parameters of that pipeline in the Deployment Pipeline details.

# Make this your own

Fork this repo from Github and make changes if you want to play around with the sample app, the OCI DevOps build configuration, and the k8s manifest.
