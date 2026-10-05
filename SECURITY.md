# Security

## Reporting a vulnerability

Report security problems privately, not in a public issue. On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**. Only the maintainers can see the report.

Include what you found, how to reproduce it, and what an attacker could do with it.

## What counts

A security problem in this module is anything that leaves a global database less protected than its inputs say: for example, storage left unencrypted by default, deletion protection turned off without being asked, a change that replaces or deletes the global cluster without warning, or a password reaching the Terraform state or an output.

## Supported versions

Fixes are made to the latest release.
