#to get provider please navigate to terraform provider > browse > providers > select provider > click on use provider copy the code.


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.69.0"
    }
  }
}

provider "aws" {
  # Configuration options
}
