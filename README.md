# ODDT Terraform

Manages the Office of Open Data and Digital Transformation (ODDT) AWS infrastructure. We use [Terraform](https://www.terraform.io/) to implement "infrastructure as code" style management.

Only the data pipelining infrastructure is managed at this time.

## Usage

Make changes in a new branch. Optionally (though ideally), have someone review your changes.

### Plan

Run plan first, review the plan, make sure it looks correct. Paste the plan in a PR description if doing code review.

```sh
terraform plan
```

Run apply after you have reviewed and verified your plan.

### Apply

```sh
terraform apply
```
