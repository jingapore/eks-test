output "codecommit-url" {
    value = aws_codecommit_repository.eks_test.clone_url_http
}