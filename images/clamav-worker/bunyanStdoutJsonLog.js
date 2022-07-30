/*
 * Copyright 2021 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
const {BUNYAN_TO_STACKDRIVER} = require('@google-cloud/logging-bunyan');
const {Writable} = require('stream');
const process = require('process');

/**
 * This class provides support for streaming your Bunyan logs to
 * stdout using structured logging for Google Cloud Logging.
 *
 * @class
 */
class BunyanStdoutJsonLog extends Writable {
  /** @param {Object=} options  */
  constructor(options = null) {
    super({objectMode: true});
    options = options || {};
    this.logName = options.logName || 'bunyan_log';
    this.resource = options.resource;
  }

  /**
   * Convenience method that Builds a bunyan stream object that you can put in
   * the bunyan streams list.
   *
   * @param {string} level
   * @return {Object}
   */
  stream(level) {
    return {level, type: 'raw', stream: this};
  }

  /**
   * Format a bunyan record into a Stackdriver log entry.
   * @param {Object} record
   * @return {string} JSON-formatted log record.
   */
  formatEntry_(record) {
    if (typeof record === 'string') {
      throw new Error('@google-cloud/logging-bunyan' +
                      'only works as a raw bunyan stream type.');
    }
    // Stackdriver Log Viewer picks up the summary line from the 'message' field
    // of the payload. Unless the user has provided a 'message' property also,
    // move the 'msg' to 'message'.
    if (!record.message) {
      // If this is an error, report the full stack trace. This allows
      // Stackdriver Error Reporting to pick up errors automatically (for
      // severity 'error' or higher). In this case we leave the 'msg' property
      // intact.
      // https://cloud.google.com/error-reporting/docs/formatting-error-messages
      //
      if (record.err && record.err.stack) {
        record.message = record.err.stack;
      } else if (record.msg) {
        // Simply rename `msg` to `message`.
        record.message = record.msg;
        delete record.msg;
      }
    }
    if (record.time) {
      record.timestamp = record.time;
      delete record.time;
    }
    record.resource = this.resource;
    record.severity = BUNYAN_TO_STACKDRIVER.get(Number(record.level));
    return JSON.stringify(record) + '\n';
  }
  // noinspection JSCheckFunctionSignatures

  /**
   * Write the log record.
   *
   * @param  {...any} args
   */
  write(...args) {
    const record = args[0];
    let encoding = null;
    let callback;
    if (typeof args[1] === 'string') {
      encoding = args[1];
      callback = args[2];
    } else {
      callback = args[1];
    }

    process.stdout.write(this.formatEntry_(record), encoding, callback);
  }
}

exports.BunyanStdoutJsonLog = BunyanStdoutJsonLog;
