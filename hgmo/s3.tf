# Per-region S3 buckets hold bundle objects. Each region should be
# identically configured except for the per-region differences.

variable bundle_short_regions {
    type = "list"
    default = ["use1", "usw1", "usw2", "euc1"]
}

variable bundle_regions {
    type = "list"
    default = ["us-east-1", "us-west-1", "us-west-2", "eu-central-1"]
}

resource "aws_s3_bucket" "hg_bundles_region" {
    # Buckets are pinned to a specific region and therefore have to use
    # an explicit provider for that region.
    count = 4

    region = "${element(var.bundle_regions, count.index)}"
    bucket = "moz-hg-bundles-${element(var.bundle_regions, count.index)}"
    acl = ""

    tags {
        App = "hgmo"
        Env = "prod"
        Owner = "gps@mozilla.com"
        Bugid = "1041173"
    }

    # Serve the auto-generated index when / is requested.
    website {
        index_document = "index.html"
    }

    # Send access logs to S3 so we can audit and monitor.
    logging {
        target_bucket = "moz-devservices-logging-${element(var.bundle_regions, count.index)}"
        target_prefix = "s3/hg-bundles/"
    }

    # Objects automatically expire after 1 week.
    lifecycle_rule {
        enabled = true
        prefix = ""
        expiration {
            days = 7
        }
        noncurrent_version_expiration {
            days = 1
        }
    }
}

resource "aws_s3_bucket_policy" "hg_bundles_region" {
    count = 4

    provider = "aws.${element(var.bundle_short_regions, count.index)}"
    bucket = "${aws_s3_bucket.hg_bundles_region.*.bucket}"
    policy = "${data.aws_iam_policy_document.hg_bundles.json}"
}

# Bucket to hold data about replication events.

resource "aws_s3_bucket" "hg_events_usw2" {
    provider = "aws.usw2"
    bucket = "moz-hg-events-us-west-2"
    acl = ""

    tags {
        App = "hgmo"
        Env = "prod"
        Owner = "gps@mozilla.com"
        Bugid = "1316952"
    }

    logging = {
        target_bucket = "moz-devservices-logging-us-west-2"
        target_prefix = "s3/hg-events/"
    }
}

resource "aws_s3_bucket_policy" "hg_events_usw2" {
    provider = "aws.usw2"
    bucket = "${aws_s3_bucket.hg_events_usw2.bucket}"
    policy = "${data.aws_iam_policy_document.s3_hg_events_usw2.json}"
}
