# Malware Scanner Service

This repository contains the code to build a pipeline that scans objects
uploaded to GCS for malware, moving the documents to a clean or quarantined
bucket depending on the malware scan status. 

It illustrates how to use Cloud Run and Eventarc to build such a pipeline.

## How to use this example

Use the
[tutorial](https://cloud.google.com/solutions/automating-malware-scanning-for-documents-uploaded-to-cloud-storage)
to understand how to configure your Google Cloud Platform project to use Cloud
Run and Eventarc.

## Changes

*   2019-09-01 Initial version
*   2020-10-05 Fixes for ClamAV OOM
*   2021-10-14 Use Cloud Run and EventArc instead of Cloud Functions/App Engine
*   2021-10-22 Improve resiliency, Use streaming reads (no temp disk required),
    improve logging, and handles files in subdirectories
*   2021-11-08 Add support for scanning multiple buckets, improve error
    handling to prevent infinite retries,

## License

Copyright 2021 Google LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

```
https://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
