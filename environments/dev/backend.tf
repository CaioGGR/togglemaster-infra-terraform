terraform {
  backend "s3" {
    bucket         = "togglemaster-tfstate-0u7t92"        # Bucket S3 onde o state será salvo
    key            = "dev/togglemaster/terraform.tfstate" # Caminho do arquivo de estado dentro do bucket
    region         = "us-east-1"                          # Região da AWS
    dynamodb_table = "terraform-locks"                    # Tabela DynamoDB para lock ativo do estado
    encrypt        = true                                 # Força criptografia em trânsito e em repouso
  }
}
