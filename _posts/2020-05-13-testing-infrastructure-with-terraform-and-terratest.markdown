---
excerpt: Software testing proves the existence of bugs not their absence.
layout: page
title: Testing Infrastructure with Terraform And Terratest
permalink: testing-infrastructure-with-terraform-and-terratest
tags: Terraform testing Terratest CI CD Gcloud google cloud GCP instances instance group modules
published: true
---

<br/>
<p align="center">
  <a href="https://edermunizz.itch.io/free-pixel-art-forest">
    <img alt="pixel_art_forest" title="Pixel art forest" src="assets/images/2020_05_13_pixel_art_forest.png" height="600px" align="middle">
  </a>
</p>
<br/>
> Software testing proves the existence of bugs not their absence.<br/> - Anonymous

<br/>

In this blog post, I will show you how you can test your infrastructure with [Terraform] and [Terratest] on [Google Cloud], but first,

## **Let's Talk About Terraform Modules**

Terraform modules are reusable, composable, and testable components, which pack all of the complexity into a single versatile and modifiable unit. This so-called unit can be controlled by input variables that extend or change its usability and its use cases. There are many modules out there, some official, and some provided by the community. You can explore them at Terraform's module registry: [https://registry.terraform.io/browse/modules].

As for creating them, the examples in the registry serve as a solid starting point as well as this guideline by Hashicorp:
[https://www.terraform.io/docs/modules/index.html].

<p align="center">
  <img alt="terraform_modules" title="Terraform Modules" src="assets/images/2020_05_13_terraform_modules.png">
</p>


## **Why Do We Need Testing?**
Testing code has always required a lot of additional work that I believe that most people dread, including myself. Without testing though, we’ve no way of telling if our code will behave the way it was intended to, especially at present, where code logic tends to get sophisticated in most of the cases. Terratest can test real infrastructure into a real environment, a single unit like Terraform module if you will, evaluating the resources, results and outputs immediately.

## **Setting Up The Environment**

- **[Golang]**
- **[Terraform]**
- **[Golang Dependencies]**
- **[Golang Package Testing]**
- **[Google Application Credentials]**

*I will be using the latest versions of both golang and Terraform as of the time of writing this blog post*

**Golang**

The instructions for installing and configuring golang are provided here: [https://golang.org/doc/install]

**Terraform**

Get Terraform either by [downloading it] and placing it in your "bin path", or by using [tfenv].

**Vendoring dependencies**

Because this example is not operating within the GOPATH, we need to specify a module name with the convention:

`github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>`

If you want to start from scratch instead of using [my example], follow the steps below.

These are the packages I am importing.

```golang
import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
)
```

Create a test directory in the root of the folder if it is not there. Copy or create a file that ends in `_test.go`, then "cd" into the "test" directory and initialize the module.

```sh
$ mkdir test
$ cd test/
$ curl -O https://raw.githubusercontent.com/parabolic/terraform_ci_cd/master/test/terraform_ci_cd_test.go
$ go mod init github.com/parabolic/terraform_ci_cd
go: creating new go.mod: module github.com/parabolic/terraform_ci_cd
$ go mod vendor
```

The "go mod vendor" command downloads (vendors) all of the dependent packages to the same directory.

We will end up with a folder structure like this:

```sh
test/
├── go.mod
├── go.sum
├── terraform_ci_cd_test.go
└── vendor
```


**Google Application Credentials**

As part of the last phase, we would need to provide credentials for authenticating to Google Cloud. Please follow the steps outlined in google's documentation on how to [create a service account and export its keys]. I would recommend creating a separate service account only for running Terraform or Terratest.

After we've got the google cloud key file onto our system, we should export an environment variable that points to the location of the file. That way both Terratest and Terraform can authenticate to Google Cloud and conduct the tests.
```sh
export GOOGLE_APPLICATION_CREDENTIALS="/home/cloudlad/.gcloud/cloudlad-project.json"
```

**Verification**

Let's do a small check-up before we move on.

**Golang**
```sh
$ go version
go version go1.14.1 linux/amd64
```

**GOPATH**
```sh
$ printenv GOPATH
/go
```

**Terraform**
```sh
$ terraform -v
Terraform v0.12.24
```

**Google Application Credentials**
```sh
$ printenv GOOGLE_APPLICATION_CREDENTIALS
/home/cloudlad/.gcloud/cloudlad-project.json
```

<br>
## **How It All Works Together**

<p align="center">
  <img alt="terraform_modules" title="Terraform Modules" src="assets/images/2020_05_13_terratest_terraform.png">
</p>


Now that we have all set up and verified, we are ready to begin testing.

Terratest uses golang's testing framework, so for those familiar with it this will be straightforward. The terratest GCP module is very limited as of writing this blog post so I am unable to test a lot of other resources that GCP has to offer. For that reason, my Terraform configuration is fairly simple, which for showcasing purposes is a good thing. Hopefully, we will see more contributions to the module in the future.

*If you want to find out which resources are supported by Terratest, head on to [https://godoc.org/github.com/gruntwork-io/terratest/modules/gcp].*

Although we can test any Terraform configuration, Terratest works the best when testing Terraform modules as single small units. That is because it is easier to create a test for small components and Terratest can control the state with [input variables]. Input variables serve as parameters, changing the behaviour of the module without changing its source code.

Let us take [https://github.com/parabolic/terraform_ci_cd] as an example repository that has a Terraform module. It creates a bucket, and an instance group with an "N" number of instances. These are the current input variables that are accepted by the this module:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | n/a | `string` | n/a | yes |
| project\_id | n/a | `string` | n/a | yes |
| instance\_number | n/a | `number` | `1` | no |
| machine\_type | n/a | `string` | `"n1-standard-1"` | no |
| name | n/a | `string` | `"cloudlad"` | no |
| region | n/a | `string` | `"europe-west4"` | no |
| zone | n/a | `string` | `"europe-west4-c"` | no |


Here's how the directory structure of the Terraform module looks like.

```sh
.
├── example
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── LICENSE
├── main.tf
├── outputs.tf
├── README.md
├── test
│   ├── go.mod
│   ├── go.sum
│   ├── terraform_ci_cd_test.go
└── variables.tf
```
The "example" directory holds the Terraform templates needed to call and use the module. The source to the module is set to a local path `source = "../"`, which points to the top-level directory, which holds the files of the actual Terraform module.

The "test" directory contains the terratest golang code, along with the "go.mod" and "go.sum" files (the vendor directory is not checked in and it will be created after vendoring the dependencies).

We can change and control any of the input variables with Terratest. As you can see every input variable is set and preferably randomized to cover all of the possible test cases.

```golang
environment := "ci"
instanceNumber := 3
name := "terratest"
environmentName := fmt.Sprintf("%s-%s", name, environment)
projectID := gcp.GetGoogleProjectIDFromEnvVar(t)
randomRegion := gcp.GetRandomRegion(t, projectID, nil, nil)
randomZone := gcp.GetRandomZoneForRegion(t, projectID, randomRegion)
// Relative path to the terraform configuration
terraformDir := "../example/"
```
Note the `terraformDir` variable at the end.
This is a common pattern with which we check the validity and usability of both the module and the provided example, better known as "Eating your own dog food".

The variables that were previously defined are passed onto the Terraform template with `terraformOptions`. Consequently controlling and adjusting the Terraform module to fit our needs.

```golang
terraformOptions := &terraform.Options{
  TerraformDir: terraformDir,

  Vars: map[string]interface{}{
    "environment":     environment,
    "instance_number": instanceNumber,
    "name":            name,
    "project_id":      projectID,
    "region":          randomRegion,
    "zone":            randomZone,
  },

  EnvVars: map[string]string{
    "GOOGLE_CLOUD_PROJECT": projectID,
  },
}
```

Going further down the test file, we see the `defer` statement. 

```golang
// Destroy all resources in any exit case
defer terraform.Destroy(t, terraformOptions)
```
Defer makes sure that all the resources are destroyed no matter the exit status of the function. It is commonly used for "clean-up" purposes. In our case the defer statement will issue a non-interactive `terraform destroy` for every run of the function.

After the defer we specify the `terraform.InitAndApply` function which will execute "terraform init, terraform get, terraform apply", with the provided input variables.

```golang
// Run terraform init and apply
terraform.InitAndApply(t, terraformOptions)
```

Now the testing phase starts.

Checking if the bucket exists with the `gcp.AssertStorageBucketExists` function.

```golang
// Check if the bucket exists
gcp.AssertStorageBucketExists(t, environmentName)
```

Getting the name of the instance group is done via an output, additionally validating our naming scheme.
```golang
// Get the instance group name from the output
instanceGroupName := terraform.Output(t, terraformOptions, "instance_group_name")
```

Lastly, we check for the number of instances present within the instance group. The test will fail if the number does not match the number we have specified with the variable `instanceNumber`.

```golang
// Check the instance number
retry.DoWithRetry(t, "Geting instances from, instance group", maxRetries, sleepBetweenRetries, func() (string, error) {
  instances, err := instanceGroup.GetInstancesE(t, projectID)
  if err != nil {
    return "", fmt.Errorf("Failed to get Instances: %s", err)
  }

  if len(instances) != instanceNumber {
    return "", fmt.Errorf("Expected to find exactly %d Compute Instances in Instance Group but found %d.", instanceNumber, len(instances))
  }
  return "", nil
})
```

<br>
We've covered all of the clarifications and preparations, so we can safely start our test.

*`go test` recompiles each package along with any files with names matching the file pattern "*_test.go".*

```sh
$ cd test/
$ go test -v
=== RUN   TestTerraformGcp
=== PAUSE TestTerraformGcp
=== CONT  TestTerraformGcp
TestTerraformGcp 2020-05-10T12:21:52Z region.go:163: Looking up all GCP regions available in this account
TestTerraformGcp 2020-05-10T12:21:52Z retry.go:72: Attempting to request a Google OAuth2 token
TestTerraformGcp 2020-05-10T12:21:52Z compute.go:606: Successfully retrieved default GCP client
TestTerraformGcp 2020-05-10T12:21:52Z region.go:67: Using Region asia-east1
TestTerraformGcp 2020-05-10T12:21:52Z retry.go:72: Attempting to request a Google OAuth2 token
TestTerraformGcp 2020-05-10T12:21:52Z compute.go:606: Successfully retrieved default GCP client
TestTerraformGcp 2020-05-10T12:21:53Z region.go:148: Using Zone asia-east1-c
TestTerraformGcp 2020-05-10T12:21:53Z retry.go:72: terraform [init -upgrade=false]
....
....
....
....
TestTerraformGcp 2020-05-10T12:26:14Z command.go:168: Destroy complete! Resources: 6 destroyed.
--- PASS: TestTerraformGcp (261.97s)
PASS
ok      github.com/parabolic/terraform_ci_cd    261.982s
```
If our test passed, it should conclude with output similar to the one above (the output is truncated).

## Conclusion
Even though the GCP module for Terratest is still in infancy, we can still use it to test out basic resources, and the more it is used the more features and better support it will have. Testing is a relevant part of the CI/CD pipeline and I hope I've given you a glimpse of how easy it is to start testing your infrastructure with Terraform and Terratest.


Until next time! Please share this blog post if you liked it.

[https://registry.terraform.io/browse/modules]:https://registry.terraform.io/browse/modules
[https://www.terraform.io/docs/modules/index.html]:https://www.terraform.io/docs/modules/index.html
[https://golang.org/doc/install]:https://golang.org/doc/install
[downloading it]:https://www.terraform.io/downloads.html
[tfenv]:https://github.com/tfutils/tfenv
[create a service account and export its keys]:https://cloud.google.com/docs/authentication/getting-started
[Input variables]:https://www.terraform.io/docs/configuration/variables.html
[local values]:https://www.terraform.io/docs/configuration/locals.html
[https://github.com/parabolic/terraform_ci_cd]:https://github.com/parabolic/terraform_ci_cd
[terraform_ci_cd_test.go]:https://github.com/parabolic/terraform_ci_cd/blob/master/test/terraform_ci_cd_test.go#L16-L24
[https://godoc.org/github.com/gruntwork-io/terratest/modules/gcp]:https://godoc.org/github.com/gruntwork-io/terratest/modules/gcp
[Terratest]: https://terratest.gruntwork.io/
[Google Cloud]:https://cloud.google.com/
[Terraform]:https://registry.terraform.io/
[Golang]:https://golang.org/
[Golang Dependencies]:https://blog.golang.org/using-go-modules
[Google Application Credentials]:https://cloud.google.com/docs/authentication/getting-started
[Golang Package Testing]:https://golang.org/pkg/testing/
[my example]:https://github.com/parabolic/terraform_ci_cd/blob/master/test/terraform_ci_cd_test.go
