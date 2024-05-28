# Malware Scanner Service

This repository contains the code to build a pipeline that scans objects
uploaded to GCS for malware, moving the documents to a clean or quarantined
bucket depending on the malware scan status.

It illustrates how to use Cloud Run and Eventarc to build such a pipeline.

![Architecture diagram](architecture.svg)

## How to use this example

Use the
[tutorial](https://cloud.google.com/solutions/automating-malware-scanning-for-documents-uploaded-to-cloud-storage)
to understand how to configure your Google Cloud Platform project to use Cloud
Run and Eventarc.

## Using Environment variables in the configuration

The tutorial above uses a configuration file `config.json` built into the Docker
container for the configuration of the unscanned, clean, quarantined and CVD
updater cloud storage buckets.

Environment variables can be used to vary the deployment in 2 ways:

### Expansion of environment variables

Any environment variables specified using shell-format within the `config.json`
file will be expanded using
[`envsubst`](https://manpages.debian.org/bookworm/gettext-base/envsubst.1.en.html).

### Passing entire configuration as environment variable

An alternative to building the configuration file into the container is to use
environmental variables to contain the configuration of the service, so that
multiple deployments can use the same container, and configuration updates do
not need a container rebuild.

This can be done by setting the environmental variable `CONFIG_JSON` containing
the JSON configuration, which will override any config in the `config.json`
file.

If using the `gcloud run deploy` command line, this environment variable must be
set using the
[`--env-vars-file`](https://cloud.google.com/sdk/gcloud/reference/run/deploy#--env-vars-file)
argument, specifying a YAML file containing the environment variable definitions
(This is because the commas in JSON would break the parsing of `--set-env-vars`)

Take care when embedding JSON in YAML - it is recommended to use the
[Literal Block Scalar style](https://yaml-multiline.info/) using `|`, as this
preserves newlines and quotes

For example, the `CONFIG_JSON` environment variable could be defined in a file
`config-env.yaml` as follows:

```yaml
CONFIG_JSON: |
  {
    "buckets": [
      {
        "unscanned": "unscanned-bucket-name",
        "clean": "clean-bucket-name",
        "quarantined": "quarantined-bucket-name"
      }
    ],
    "ClamCvdMirrorBucket": "cvd-mirror-bucket-name"
  }
```

An example commandline using this file to specify the environment:

```sh
gcloud beta run deploy "${SERVICE_NAME}" \
  --source . \
  --region "${REGION}" \
  --no-allow-unauthenticated \
  --memory 4Gi \
  --cpu 1 \
  --concurrency 20 \
  --min-instances 1 \
  --max-instances 5 \
  --no-cpu-throttling \
  --cpu-boost \
  --service-account="${SERVICE_ACCOUNT}" \
  --env-vars-file=config-env.yaml
```

If you are using Terraform to deploy, then the equivalent way to specify the
environment variable using the
[`google_cloud_run_v2_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service)
resource is by using the
[env](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service#env)
block and
[jsonencode](https://developer.hashicorp.com/terraform/language/functions/jsonencode):

```tf
resource "google_cloud_run_v2_service" "malware-scanner" {
  name = "malware-scanner"
  // other service parameters...
  template {
    // other template parameters...
    containers {
      // other container parameters...
      env {
        name = "CONFIG_JSON"
        value = jsonencode({
          buckets = [
            {
              unscanned   = "unscanned-bucket-name",
              clean       = "clean-bucket-name",
              quarantined = "quarantined-bucket-name"
            }
          ]
          ClamCvdMirrorBucket = "cvd-mirror-bucket-name"
        })
      }
    }
  }
}
```

## Change history

See [CHANGELOG.md](cloudrun-malware-scanner/CHANGELOG.md)

## Upgrading from v1.x to v2.x

Version 2 has a different way of handling ClamAV updates to avoid issues with
the ClamAV content distribution network.

See [upgrade_from_v1.md](upgrade_from_v1.md) for upgrading instructions.

## License

```text
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
```
