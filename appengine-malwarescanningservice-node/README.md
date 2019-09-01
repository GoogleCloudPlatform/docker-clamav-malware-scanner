# Malware Scanner Service

Pre-reqs : See the tutorial that accompanies the code example at the following [link](https://cloud.google.com/solutions/automating-malware-scanning-for-documents-uploaded-to-cloud-storage)

This directory contains the code to build a pipeline that scans documents
uploaded to GCS for malware. It illustrates how to use App Engine Flex to build
such a pipeline. This service is invoked from a background function that
responds to a GCS event i.e. when a document is uploaded to a predetermined GCS
bucket. This service downloads a copy of the document into the Docker container
running in App Engine Flex and requests a ClamAV scan. Upon completion, the
service moves the scanned document apprpropriately based on the outcome i.e.
clean vs infected. It also deletes the local copy of the document.

## How to use this example

Use the tutorial to understand how to configure your Google Cloud Platform
project to use Cloud functions and App Engine Flex.

1.  Clone it from GitHub.
2.  Develop and enhance it for your use case

## Quickstart

Clone this repository

```sh
git clone https://github.com/GoogleCloudPlatform/docker-clamav-malware-scanner.git
```

Change directory to one of the example directories

Follow the walkthrough in the tutorial associated with the Nodejs example for
configuration details of Cloud platform products (Cloud Storage, Cloud Functions
and App Engine Flex) and adapt accordingly using the accompanying README for
each example.

## License

Copyright 2019 Google LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
