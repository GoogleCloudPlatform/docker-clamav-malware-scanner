/*
* Copyright 2019 Google LLC

* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at

*     https://www.apache.org/licenses/LICENSE-2.0

* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

const request = require('request-promise');

/**
 * Background Cloud Function that handles the 'google.storage.object.finalize'
 * event. It invokes the Malware Scanner service running in App Engine Flex
 * requesting a scan for the uploaded document.
 *
 * @param {object} data The event payload.
 * @param {object} context The event metadata.
 */
exports.requestMalwareScan = async (data, context) => {

  const file = data;
  console.log(`  Event ${context.eventId}`);
  console.log(`  Event Type: ${context.eventType}`);
  console.log(`  Bucket: ${file.bucket}`);
  console.log(`  File: ${file.name}`);

  let options = {
    method: 'POST',
    uri: process.env.SCAN_SERVICE_URL,
    body: {
      location: `gs://${file.bucket}/${file.name}`,
      filename: file.name,
      bucketname: file.bucket
    },
    json: true
  }

  try {
    if(context.eventType === "google.storage.object.finalize") {
      await request(options);
      console.log(`Malware scan succeeded for: ${file.name}`);
    } else {
      console.log('Malware scanning is only invoked when documents are uploaded or updated');
    }
  } catch(e) {
    console.error(`Error occurred while scanning ${file.name}`, e);
  }
}